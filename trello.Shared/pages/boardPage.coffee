# 4d5ea62fd76aa1136000000c - trello dev
# 545a4dcabd3b29a164b303b3 - Jobs
# 54c93f6f836da7c4865460d2 - Agile Board

###
The board page displays a board with its lists and cards

Its model contains
  * lists by id
  * cards by id
for easy lookup.
So when a change notification comes in for a list or card
we simply update that card (that is part of a list) and
it will update in the UI as well.

Connection retry strategies
Remember the actions that could not fetch fresh data from the server
and try them again in the order they were remembered at later time when connection
is available again
###

cssColorToWinRTColor = (cssColor) ->
  if cssColor and cssColor[0] is '#'
    r = parseInt(cssColor.substr(1, 2), 16)
    g = parseInt(cssColor.substr(3, 2), 16)
    b = parseInt(cssColor.substr(5, 2), 16)
    a = 255
    return Windows.UI.ColorHelper.fromArgb(a,r,g,b)

filtered = Object.getPrototypeOf(new WinJS.Binding.List().createFiltered())
filtered.changeFilter = (newFilter = @_filter) ->
  list = @_list
  filter = @_filter = newFilter
  keys = @_filteredKeys
  i = keys.length - 1
  while i >= 0
    key = keys[i]
    item = list.getItemFromKey(key)
    if (!newFilter(item.data))
      keys.splice(i, 1)
      @_notifyItemRemoved(key, i, item.data, item)
    i--

  i = 0
  j = 0

  while i < list.length
    item = list.getItem(i)
    key = keys[j]
    if item.key is key
      j++
    else if (newFilter(item.data))
      keys.splice(j, 0, item.key)
      @_notifyItemInserted(key, j, item.data)
      j++
    #else
    # was't in the list before and isn't in the list now.
    i++
  return

badgeDueDateFormatter = new Windows.Globalization.DateTimeFormatting.DateTimeFormatter("shortdate")

createLabel = (label) ->
  unless label.color
    label.color = ""
  WinJS.Binding.as(label)

updateBadge = (badge, value) ->
  if value is "+1"
    badge.value = badge.value + 1
  else if value is "-1"
    badge.value = badge.value - 1
  else
    if badge.type is "due" and value
      dueDate = new Date(value)
      now = new Date()
      value = badgeDueDateFormatter.format(dueDate)
    badge.value = value
  badge.description = i18n.translate("badges/#{badge.type}", count: badge.value)
  badge

WinJS.UI.Pages.define "/pages/boardPage.html",

  _updateCheckListItem: (badge, checkItems, checkItemsChecked) ->
    badge.checkItems = checkItems if checkItems isnt undefined
    badge.checkItemsChecked = checkItemsChecked if checkItemsChecked isnt undefined
    badge.description = i18n.translate("badges/checkList", count: badge.checkItems, checked: badge.checkItemsChecked)
    badge.value = "#{badge.checkItemsChecked}/#{badge.checkItems}"

  _updateCardBadge: (cardId, badgeType, value) ->
    if card = @cards[cardId]
      card.badges.some (badge) =>
        if badge.type is badgeType
          updateBadge(badge, value)
          true

  _addCardToList: (list, card) ->
    card.labels = new WinJS.Binding.List(card.labels?.map((label) => @labels[label.id]) or null)
    card.attachmentPreviews = new WinJS.Binding.List()
    #TODO: Cancel this when the board is changed
    trello.api.getAsync("/cards/#{card.id}/attachments")
    .then (attachments) ->
      card.attachmentPreviews.push.apply(card.attachmentPreviews, attachments.map((attachment) ->
        attachment.previews[1]
      ))
    badges = card.badges or {
      checkItems: 0
      checkItemsChecked: 0
    }
    card.badges = new WinJS.Binding.List()
    # Checklists are a special beast
    # The badge is composed of 2 badge properties "checkItemsChecked" + "checkItems"
    # We create a composite badge "checkList" from both of them and save it on the card
    # for easier access during notifications
    card.checkListBadge = WinJS.Binding.as(
      type: "checkList"
      description: ""
      value: ""
    )
    @_updateCheckListItem(card.checkListBadge, badges.checkItems, badges.checkItemsChecked)
    delete badges.checkItems
    delete badges.checkItemsChecked
    card.badges.push(card.checkListBadge)

    card.badges.push.apply(card.badges, Object.keys(badges).map (type) ->
        value = badges[type]
        badge = WinJS.Binding.as(
          type: type,
          description: "",
          value: ""
        )
        updateBadge(badge, value)
    )
    unless card.pos
      # Position the card 1000 ticks after the last card in the list or if its the first card at postion 1000
      if list.cards.length
        card.pos = list.cards.getAt(list.cards.length-1).pos
      else
        card.post = 0
      card.pos = 1000 + card.pos
    @cards[card.id] = card = WinJS.Binding.as(card)
    list.cards.push(card)

  commands: () ->
    ["createList", "addCard", "archiveList"]

  pinAsync: () ->

  # Returns a model with the following properties:
  # pinned: true/false
  # runAsync: Runs the pin/unpin action
  getPinModelAsync: () ->

  getPinUnpinAsync: () ->
    @loader.then (board) ->
      if Windows.UI.StartScreen.SecondaryTile.exists(board.id)
        "unpin"
      else
        "pin"

  init: (element, @options = {}) ->
    addBoard.winControl.hidden = true
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

    archiveList.winControl.onclick = () ->
      require ["ui/MessageDialog"], (MessageDialog) ->
        MessageDialog("This will hide, but not delete the list from this board.\nYou can always restore archived lists later.", "Archive This List").button("Archive Now").showAsync()
    @lists = new WinJS.Binding.List()
    @cards = {}
    @labels = {}
    if @options.board #FIXME not working yet, remove "s"
      @loader = trello.api.getBoardAsync(@options.board.id, labels: "all", lists: "open", fields: "all") # WinJS.Promise.as(@options.board)
    else
      id = @options
      if typeof @options is 'string'
        @options = {}
        @options["id"] = id

      # HACK: use a default board if none given
      # Remove this and display a proper page error message
      @options["id"] or= "551b25da3abbdf64c940d774" or "54c93f6f836da7c4865460d2" or "545a4dcabd3b29a164b303b3" or "4d5ea62fd76aa1136000000c"
      window.console.debug(@options.id)
      @loader = trello.api.getBoardAsync(@options.id, labels: "all", lists: "open", fields: "all")
    return # Don't wait for the loader!

  processed: (element, options) ->
    @loader
    .then (board) =>
      @board = board
      WinJS.Binding.processAll(element, @model = WinJS.Binding.as(
        board: board
        lists: @lists
        backgroundPositionX: 0
      ))

      board.labels.forEach (label) =>
        @labels[label.id] = createLabel(label)

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
        if action.type is "createLabel"
          @labels[action.data.label.id] or= createLabel(action.data.label)
        else if action.type is "commentCard"
          @_updateCardBadge(action.data.card.id, "comments", "+1")
        else if action.type is "deleteComment"
          @_updateCardBadge(action.data.card.id, "comments", "-1")
        else if action.type is "createCheckItem"
          if card = @cards[action.data.card.id]
            @_updateCheckListItem(card.checkListBadge, card.checkListBadge.checkItems + 1)
        else if action.type is "removeChecklistFromCard"
          if card = @cards[action.data.card.id]
            @_updateCheckListItem(card.checkListBadge, 0, 0)
        else if action.type is "convertToCardFromCheckItem"
          if card = @cards[action.data.cardSource.id]
            # FIXME: Here a complete refresh is required, cause we do not know if the checkItem was completed or not
            @_updateCheckListItem(card.checkListBadge, card.checkListBadge.checkItems - 1)
        else if action.type is "deleteCheckItem"
          if card = @cards[action.data.card.id]
            # A complete card that is deleted also reduces the checkItemsChecked of the list
            if action.data.checkItem.state is "complete"
              checkItemsChecked = card.checkListBadge.checkItemsChecked - 1
            @_updateCheckListItem(card.checkListBadge, card.checkListBadge.checkItems - 1, checkItemsChecked)
        else if action.type is "updateCheckItemStateOnCard"
          if card = @cards[action.data.card.id]
            checkItemsChecked = if action.data.checkItem.state is "incomplete"
              card.checkListBadge.checkItemsChecked - 1
            else
              card.checkListBadge.checkItemsChecked + 1
            @_updateCheckListItem(card.checkListBadge, undefined, checkItemsChecked)
        else if action.type is "updateLabel"
          if action.data.old?.name isnt undefined
            @labels[action.data.label.id].name = action.data.label.name
          if action.data.old?.color isnt undefined
            @labels[action.data.label.id].color = action.data.label.color
        else if action.type is "addLabelToCard" or action.type is "removeLabelFromCard"
          if card = @cards[action.data.card.id]
            label = @labels[action.data.label.id]
            unless label
              @labels[action.data.label.id] = label = createLabel(action.data.label)
            if action.type is "addLabelToCard"
              card.labels.push(label)
            else if (index = card.labels.indexOf(label)) isnt -1
              card.labels.splice(index, 1)
        else if action.type is "createCard"
          #FIXME: Does not send the labels and pos, even if created with them on the web UI
          if action.data.list
            if list = listById(@lists, action.data.list.id)
              @_addCardToList(list, action.data.card)
        else if action.type is "deleteCard"
          if card = @cards[action.data.card.id]
            @cards[action.data.card.id] = undefined
            if action.data.list
              if list = listById(@lists, action.data.list.id)
                list.cards.splice(list.cards.indexOf(card), 1)
        else if action.type is "updateList"
          if list = listById(@lists, action.data.list.id)
            if action.data.old
              if action.data.old.name isnt undefined
                list.header = action.data.list.name
        else if action.type is "updateCard"
          #TODO: Fetch the card from the server, if we did not know the card
          if card = @cards[action.data.card.id]
            if action.data.old
              changedProperty = Object.keys(action.data.old)[0]
              if changedProperty in ["name", "due"]
                card[changedProperty] = action.data.card[changedProperty]
                if changedProperty is "due"
                  @_updateCardBadge(action.data.card.id, "due", action.data.card[changedProperty])
              else if changedProperty is "closed"
                card.closed = action.data.card.closed
                if list = listById(@lists, action.data.list.id)
                  list.filteredCardsList.changeFilter()
              else if changedProperty is "desc"
                @_updateCardBadge(action.data.card.id, "description", !!action.data.card.desc)
              else if changedProperty is "pos"
                card.pos = action.data.card.pos
                oldListId = card.idList
                if oldListId is action.data.list.id # Moved in the same list
                  if list = listById(@lists, action.data.list.id)
                    if (index = list.cards.indexOf(card)) isnt -1
                      list.cards.notifyMutated(index)
                else # Moved from another list between items on a new list
                  card.idList = action.data.list.id
                  if oldList = listById(@lists, oldListId)
                    if (index = oldList.cards.indexOf(card)) isnt -1
                      oldList.cards.splice(index, 1)
                  if newList = listById(@lists, card.idList)
                    newList.cards.push(card)
              else if changedProperty is "idList" # Card moved to another list
                card.idList = action.data.card.idList
                if oldList = listById(@lists, action.data.old.idList)
                  if (index = oldList.cards.indexOf(card)) isnt -1
                    oldList.cards.splice(index, 1)
                if newList = listById(@lists, action.data.card.idList)
                  newList.cards.push(card)

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
      board.listsAsync()
      .then (lists) =>
        lists.forEach (list, index) =>
          section = if WinJS.Utilities.isPhone then new WinJS.UI.PivotItem() else new WinJS.UI.HubSection()
          section.header = list.name
          section.isHeaderStatic = true
          baseCardsList = new WinJS.Binding.List()
          section.filteredCardsList = baseCardsList.createFiltered (card) ->
            !card.closed
          cards = section.filteredCardsList.createSorted((a,b) -> a.pos - b.pos)
          section.cards = cards
          section.idList = list.id
          baseCardsList.addEventListener "itemmoved", (event) ->
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
            listView.itemDataSource = cards.dataSource
            listView.groupInfo =
              enableCellSpanning: true
              cellWidth:"250px"
              cellHeight:"50px"
            canEditPromise.then (result) ->
              listView.itemsReorderable = result
          @lists.push(section)
          trello.api.getPublicAsync("/lists/#{list.id}", cards: "open")
          .then (list) =>
            list.cards.forEach (card) =>
              @_addCardToList(section, card)

  unload: () ->
    @cards = null
    @labels = null
    document.body.style.backgroundImage = ""

  ready: (element, options) ->
    element.querySelector(".win-searchbox")?.addEventListener "querysubmitted", (event) =>
      trello.api.getPublicAsync("/search",
        query: event.detail.queryText
        partial: true
        idBoards : @options.id
      ).then (searchResults) ->
        return searchResults
