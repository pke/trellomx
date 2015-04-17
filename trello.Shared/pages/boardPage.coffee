# 4d5ea62fd76aa1136000000c - trello dev
# 545a4dcabd3b29a164b303b3 - Jobs
# 54c93f6f836da7c4865460d2 - Agile Board

WinJS.UI.Pages.define "/pages/boardPage.html",
  init: (element, @options = {}) ->
    pinUnpin.winControl.onclick = () =>
      @loader.then (board) ->
        tile = new Windows.UI.StartScreen.SecondaryTile(board.id,
          board.name, # i18n
          "/boards/#{board.id}",
          new Windows.Foundation.Uri("ms-appx:///images/logo.png"),
          Windows.UI.StartScreen.TileSize.square310x150)
        selectionRect = pinUnpin.getBoundingClientRect()
        buttonCoordinates = { x: selectionRect.left, y: selectionRect.top, width: selectionRect.width, height: selectionRect.height }
        placement = Windows.UI.Popups.Placement.above
        if backgroundColor = cssColorToWinRTColor(board.prefs.backgroundColor)
          tile.visualElements.backgroundColor = backgroundColor
        tile.visualElements.showNameOnSquare150x150Logo = true
        tile.visualElements.showNameOnSquare310x150Logo = true
        tile.visualElements.wide310x150Logo = new Windows.Foundation.Uri("ms-appx:///images/logo.png")
        require ["ui/TileNotification", "models/ImageMixin"], (TileNotification, ImageMixin) ->
          args = []
          getClosest = WinJS.Promise.as(args)
          if closest = ImageMixin.closestImage(board.prefs.backgroundImageScaled, 310, 150)
            args.push("TileWide310x150Image")
            getClosest = WinJS.xhr(
              type: "HEAD"
              url: closest.url
            ).then (request) ->
              if parseInt(request.getResponseHeader("Content-Length")) > 200*1024
                args.push(board.prefs.backgroundImageScaled[0].url)
              else
                args.push(closest.url)
                args.push(board.name)
              args
          else
            args.push("TileSquare150x150Text02")
            args.push(board.name)
          getClosest.then (args) ->
            # Create as much as we can before we are suspended on the Phone due to start tile creation
            tileUpdater = TileNotification.createFromTemplate.apply(@, args).branding("name")
            updateTile = () ->
              tileUpdater.updateSecondaryTile(board.id)
              updateTile = null
            if WinJS.Utilities.isPhone
              WinJS.Application.addEventListener "checkpoint", listener = (event) ->
                WinJS.Application.removeEventListener("checkpoint", listener)
                updateTile?()
            tile.requestCreateForSelectionAsync(buttonCoordinates, placement)
            .then (result) ->
              updateTile?() if result

    @lists = new WinJS.Binding.List()
    id = @options
    if typeof @options is 'string'
      @options = {}
      @options["id"] = id

    # HACK: use a default board if none given
    # Remove this and display a proper page error message
    @options["id"] or= "551b25da3abbdf64c940d774" or "54c93f6f836da7c4865460d2" or "545a4dcabd3b29a164b303b3" or "4d5ea62fd76aa1136000000c"
    window.console.debug(@options.id)
    @loader = trello.api.getBoardAsync(@options.id, lists: "open", fields: "all")
    return # Don't wait for the loader!

  processed: (element, options) ->
    @loader
    .then (board) =>
      WinJS.Binding.processAll(element,
        board: board
        lists: @lists
      )

      listById = (lists, id) ->
        found = null
        lists.some (list) ->
          found = list if list.idList is id
        found
      cardById = (list, id) ->
        found = null
        list.some (card) ->
          found = card if card.id is id
        found
      WinJS.Application.addEventListener "notification/#{board.id}", ({action, model}) =>
        board.performAction?(action, model)
        if action.type is "updateCard"
          if action.data.listBefore and action.data.listAfter
            card = null
            if oldList = listById(@lists, action.data.listBefore.id)
              if (index = oldList.cards.indexOf(card = cardById(oldList.cards, action.data.card.id))) isnt -1
                oldList.cards.splice(index, 1)
            unless card
              # Fetch card data from server, if we did not know the card
              return
            if newList = listById(@lists, action.data.listAfter.id)
              newList.cards.push(card)
          else if action.data.list
            if list = listById(@lists, action.data.list.id)
              if card = cardById(list.cards, action.data.card.id)
                card.pos = action.data.card.pos
                list.cards.notifyMutated(list.cards.indexOf(card))
      if trello.api.loggedIn
        canEditPromise = trello.api.meAsync().then (me) ->
          board.memberships.some (membership) ->
            membership.idMember is me.id and membership.memberType in ["admin", "normal"]
        , (error) -> false
      else
        canEditPromise = WinJS.Promise.as(false)
      element.querySelector(".pagetitle").textContent = board.name
      if fragment = element.querySelector(".fragment")
        if board.prefs.backgroundImage
          fragment.style.backgroundImage = "url(#{board.prefs.backgroundImage})"
        else
          fragment.style.backgroundImage = ""
      board.lists.forEach (list, index) =>
        section = if WinJS.Utilities.isPhone then new WinJS.UI.PivotItem() else new WinJS.UI.HubSection()
        section.header = list.name
        section.isHeaderStatic = true
        cards = new WinJS.Binding.List(null, binding:true)
        section.cards = cards
        section.idList = list.id
        cards.addEventListener "itemmoved", (event) ->
          card = event.detail.value
          if event.detail.newIndex is 0
            card.pos = 0.0
          else
            if event.detail.newIndex is cards.length - 1
              nextPos = 0x7fffffff
            else
              nextPos = cards.getAt(event.detail.newIndex + 1).pos
            prevPos = cards.getAt(event.detail.newIndex - 1).pos
            card.pos = 0.5 * (nextPos + prevPos)
          trello.api.putAsync("/cards/#{card.id}/pos", value:card.pos)

        WinJS.UI.Fragments.renderCopy("/pages/_list.html", section.contentElement)
        .then (element) ->
          WinJS.UI.processAll(section.contentElement)
        .then (contentElement) =>
          listView = contentElement.querySelector(".cardList").winControl
          listView.itemDataSource = (cards.createSorted (a,b) ->
            a.pos - b.pos
          ).dataSource
          canEditPromise.then (result) ->
            listView.itemsReorderable = result
        @lists.push(section)
        trello.api.getPublicAsync("/lists/#{list.id}", cards: "open")
        .then (list) ->
          list.cards.forEach (card) ->
            card.labels = new WinJS.Binding.List(card.labels)
            card.badges = new WinJS.Binding.List(Object.keys(card.badges).map (key) ->
                value = card.badges[key]
                if key is "checkItems"
                  description = i18n.translate("badges/" + key, { count: value, checked: card.badges.checkItemsChecked})
                  value = "#{card.badges.checkItemsChecked}/#{value}"
                else
                  description = i18n.translate("badges/" + key, { count: value })
                return {
                  type: key,
                  description: description,
                  # We want to display `true` elements (with their icon) but want see no text.
                  # Since all data-value='' elements are hidden, we need to set the text to " " (space)
                  value: if value is true then " " else value
                }
            )
            cards.push(card)

  unload: () ->
    document.body.style.backgroundImage = ""

  ready: (element, options) ->
    element.querySelector(".win-searchbox")?.addEventListener "querysubmitted", (event) =>
      trello.api.getPublicAsync("/search",
        query: event.detail.queryText
        partial: true
        idBoards : @options.id
      ).then (searchResults) ->
        return searchResults
