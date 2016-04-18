/// <reference path="../../../typings/require.d.ts" />
/// <reference path="../../../typings/winjs.d.ts" />
/// <reference path="../../../typings/winrt.d.ts" />
define(function() {
  var MessageDialog, UICommand, dialogVisible, pendingDialogs, showPendingDialogs;
  MessageDialog = Windows.UI.Popups.MessageDialog;
  UICommand = Windows.UI.Popups.UICommand;
  pendingDialogs = [];
  dialogVisible = false;
  showPendingDialogs = function() {
    var pendingDialog;
    if (dialogVisible || !pendingDialogs.length) {
      return;
    }
    dialogVisible = true;
    pendingDialog = pendingDialogs.shift();
    return pendingDialog.dialog.showAsync().done(function() {
      pendingDialog.completed.apply(this, arguments);
      dialogVisible = false;
      return showPendingDialogs();
    });
  };
  return function(content:string, title:string) {
    var addButton, dialog;
    dialog = new MessageDialog(content, title);
    addButton = function(dialog:Windows.UI.Popups.MessageDialog, label:string, handler:()=>any, object:any) {
      var command;
      dialog.commands.append(command = new UICommand(label, handler, object));
      if (!object) {
        command.id = dialog.commands.length - 1;
      }
    };
    return {
      button: function(label:string, handler:() => any, object:any) {
        addButton(dialog, label, handler, object);
        return this;
      },
      cancelButton: function(label:string, handler:() => any, object:any) {
        dialog.cancelCommandIndex = dialog.commands.length;
        addButton(dialog, label, handler, object);
        return this;
      },
      defaultButton: function(label:string, handler:() => any, object:any) {
        dialog.defaultCommandIndex = dialog.commands.length;
        addButton(dialog, label, handler, object);
        return this;
      },
      title: function(title:string) {
        dialog.title = title;
        return this;
      },
      content: function(content:string) {
        dialog.content = content;
        return this;
      },
      cancelCommandIndex: function() : number {
        return dialog.cancelCommandIndex;
      },
      defaultCommandIndex: function() : number {
        return dialog.defaultCommandIndex;
      },
      showAsync: function() {
        return new WinJS.Promise(function(c, p) {
          pendingDialogs.push({
            dialog: dialog,
            completed: c
          });
          return showPendingDialogs();
        });
      }
    };
  };
});
