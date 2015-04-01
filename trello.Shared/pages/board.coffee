# 4d5ea62fd76aa1136000000c - trello dev
# 545a4dcabd3b29a164b303b3  - JObs
# 54c93f6f836da7c4865460d2 - Agile Board

PUBNUB_demo = PUBNUB.init(
  publish_key: 'pub-c-0b20bfbc-2c49-4f20-82ac-659d8ebb490c'
  subscribe_key: 'sub-c-f3c0a50c-d79f-11e4-9532-0619f8945a4f'
)

WinJS.UI.Pages.define "/pages/board.html",
  title: "Loading..." #i18n

  init: (element, @options = {}) ->
    @lists = new WinJS.Binding.List()
    id = @options
    if typeof @options is 'string'
      @options = {}
      @options["id"] = id

    # HACK: use a default board if none given
    # Remove this and display a proper page error message
    @options["id"] or= "54c93f6f836da7c4865460d2" or "545a4dcabd3b29a164b303b3" or "4d5ea62fd76aa1136000000c"
    window.console.debug(@options.id)
    @loader = trello.api.getPublicAsync("/boards/#{@options.id}",
      lists: "open"
      fields: "all"
    )

  processed: (element, options) ->
    WinJS.Binding.processAll(element, @)
    .then =>
      @loader
    .then (board) =>
      @title = board.name
      if trello.api.loggedIn
        trello.api.createWebhookAsync(
          description: board.name
          idModel: board.id
          #HACK: Hardcoded hostname:port
          #See pubnubserver/README.md for details
          #In the final version the host should be pubnub
          callbackURL: "http://pfcpille.no-ip.biz:1337/#{board.id}"
        ).then () =>
          PUBNUB_demo.subscribe(
            channel: board.id
            message: (m) =>
              if m.action.type is "updateCard"
                @lists.some (list) ->
                  if list.listId is m.action.data.list.id
                    list.cards.some (card) ->
                      if card.id is m.action.data.card.id
                        card.pos = m.action.data.card.pos
                        list.cards.notifyMutated(list.cards.indexOf(card))
                        return true
                    return true
              console.log(m)
          )
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
        fragment.style.backgroundColor = board.prefs.backgroundColor
      board.lists.forEach (list, index) =>
        section = if WinJS.Utilities.isPhone then new WinJS.UI.PivotItem() else new WinJS.UI.HubSection()
        section.header = list.name
        section.isHeaderStatic = true
        cards = new WinJS.Binding.List(null, binding:true)
        section.cards = cards
        section.listId = list.id
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
