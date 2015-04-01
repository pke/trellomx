
WinJS.UI.Pages.define "/pages/debug/webHooksPage.html",
  init: (element, @options = {}) ->
    @items = new WinJS.Binding.List()
    trello.api.getWebhooksAsync()
    .then (webhooks) =>
      @items.push.apply(@items, webhooks)
    return