define ->
  MessageDialog = Windows.UI.Popups.MessageDialog
  UICommand = Windows.UI.Popups.UICommand

  # inspired by
  # http://stackoverflow.com/questions/13652413/what-is-the-alternative-to-alert-in-metro-apps/
  pendingDialogs = []
  dialogVisible = false

  showPendingDialogs = () ->
    return if dialogVisible or !pendingDialogs.length
    dialogVisible = true
    pendingDialog = pendingDialogs.shift()
    pendingDialog.dialog.showAsync().done () ->
      pendingDialog.completed.apply(@, arguments)
      dialogVisible = false
      showPendingDialogs()

  (content, title) ->
    dialog = new MessageDialog(content, title)

    addButton = (dialog, label, handler, object) ->
      dialog.commands.append(command = new UICommand(label, handler, object))
      unless object
        command.id = dialog.commands.length - 1
      return

    button: (label, handler, object) ->
      addButton(dialog, label, handler, object)
      @

    cancelButton: (label, handler, object) ->
      dialog.cancelCommandIndex = dialog.commands.length
      addButton(dialog, label, handler, object)
      @

    defaultButton: (label, handler, object) ->
      dialog.defaultCommandIndex = dialog.commands.length
      addButton(dialog, label, handler, object)
      @

    title: (title) ->
      dialog.title = title
      @

    content: (content) ->
      dialog.content = content
      @

    cancelCommandIndex: ->
      dialog.cancelCommandIndex

    defaultCommandIndex: ->
      dialog.defaultCommandIndex

    showAsync: ->
      new WinJS.Promise (c,p) ->
        pendingDialogs.push(
          dialog: dialog
          completed: c
          )
        showPendingDialogs()