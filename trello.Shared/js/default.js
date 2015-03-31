﻿// For an introduction to the Hub/Pivot template, see the following documentation:
// http://go.microsoft.com/fwlink/?LinkID=392285
(function () {
  "use strict";

  var activation = Windows.ApplicationModel.Activation;
  var app = WinJS.Application;
  var nav = WinJS.Navigation;
  var sched = WinJS.Utilities.Scheduler;
  var ui = WinJS.UI;

  if (WinJS.Utilities.isPhone) {
    WinJS.UI.Hub = WinJS.UI.Pivot;
    WinJS.UI.HubSection = WinJS.UI.PivotItem;
  }

  WinJS.Namespace.define("trello.app", {
    state: WinJS.Binding.define({
      boards: new WinJS.Binding.List()
    })
  });

  WinJS.Namespace.define("trello.binding", {
    url: WinJS.Binding.converter(function(value) {
      if (!value) {
        return "none";
      }
      return "url(" + value + ")";
    }),

    boardBackgroundImage: WinJS.Binding.converter(function(board) {
      if (!board || !board.prefs || !board.prefs.backgroundImageScaled) {
        return "none";
      }
      return "url(" + board.prefs.backgroundImageScaled[2].url + ")";
    }),
  });

  // TODO: How are settings handled on the phone?
  if (!WinJS.Utilities.isPhone) {

    WinJS.Application.onsettings = function(e) {
      e.detail.e.request.applicationCommands.append(Windows.UI.ApplicationSettings.SettingsCommand.accountsCommand);
      //i18n
      var command = new Windows.UI.ApplicationSettings.SettingsCommand("Privacy", "Privacy Policy", function(){
        Windows.System.Launcher.launchUriAsync(new Windows.Foundation.Uri("https://trello.com/privacy"))
      });
      e.detail.e.request.applicationCommands.append(command);
    }

    var accountSettingsPane = Windows.UI.ApplicationSettings.AccountsSettingsPane.getForCurrentView();
    accountSettingsPane.onaccountcommandsrequested = function(args) {
      var passwordVault = Windows.Security.Credentials.PasswordVault();
      var passwordCredentials = passwordVault.retrieveAll();
      var provider = Windows.Security.Credentials.WebAccountProvider("trello.com", "Trello", new Windows.Foundation.Uri("ms-appx:///images/logo.png"));
      var providerCommand = Windows.UI.ApplicationSettings.WebAccountProviderCommand(provider, function(){
          trello.api.authorizeAsync().done();
      });
      if (!passwordCredentials.size) {
        args.headerText = "Add your trello account here." //i18n
        args.webAccountProviderCommands.append(providerCommand);
      } else {
        args.headerText = "Manage your trello account here." //i18n
      }

      var accountInvokedhandled = function (command, args) {
        if (args.action === Windows.UI.ApplicationSettings.WebAccountAction.remove) {
          trello.api.logout()
          // The model should listen to logout itself, and refresh itself
          trello.app.model.refreshAsync()
        }
      }
      for (var i = 0; i < passwordCredentials.size; i++) {
        var cred = passwordCredentials.getAt(i);
        var account= Windows.Security.Credentials.WebAccount(provider, cred.userName, Windows.Security.Credentials.WebAccountState.connected);
        var command = Windows.UI.ApplicationSettings.WebAccountCommand(
              account,
              accountInvokedhandled,
              Windows.UI.ApplicationSettings.SupportedWebAccountActions.remove |  Windows.UI.ApplicationSettings.SupportedWebAccountActions.manage);
        args.webAccountCommands.append(command);
      }
    }
  }

    app.addEventListener("activated", function (args) {
        if (args.detail.kind === activation.ActivationKind.launch) {
            if (args.detail.previousExecutionState !== activation.ApplicationExecutionState.terminated) {
                // TODO: This application has been newly launched. Initialize
                // your application here.
            } else {
                // TODO: This application has been reactivated from suspension.
                // Restore application state here.
            }

            hookUpBackButtonGlobalEventHandlers();
            nav.history = app.sessionState.history || {};
            nav.history.current.initialPlaceholder = true;

            // Optimize the load of the application and while the splash screen is shown, execute high priority scheduled work.
            ui.disableAnimations();
            var p = ui.processAll().then(function () {
                return nav.navigate(nav.location || Application.navigator.home, nav.state);
            }).then(function () {
                return sched.requestDrain(sched.Priority.aboveNormal + 1);
            }).then(function () {
                ui.enableAnimations();
            });

            args.setPromise(p);
        }
    });

    app.oncheckpoint = function (args) {
        // TODO: This application is about to be suspended. Save any state
        // that needs to persist across suspensions here. If you need to
        // complete an asynchronous operation before your application is
        // suspended, call args.setPromise().
        app.sessionState.history = nav.history;
    };

    function hookUpBackButtonGlobalEventHandlers() {
        // Subscribes to global events on the window object
        window.addEventListener('keyup', backButtonGlobalKeyUpHandler, false)
    }

    // CONSTANTS
    var KEY_LEFT = "Left";
    var KEY_BROWSER_BACK = "BrowserBack";
    var MOUSE_BACK_BUTTON = 3;

    function backButtonGlobalKeyUpHandler(event) {
        // Navigates back when (alt + left) or BrowserBack keys are released.
        if ((event.key === KEY_LEFT && event.altKey && !event.shiftKey && !event.ctrlKey) || (event.key === KEY_BROWSER_BACK)) {
            nav.back();
        }
    }

    app.start();
})();
