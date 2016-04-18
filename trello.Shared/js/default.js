/// <reference path="../../typings/require.d.ts"/>
/// <reference path="../../typings/winjs.d.ts"/>
/// <reference path="../../typings/winrt.d.ts"/>

(function () {
  "use strict";

  WinJS.validation = true;
  WinJS.Binding.optimizeBindingReferences = true;

  require.isBrowser = false;
  require.config({
    baseUrl: "/js",
    paths: {
        lib: '../lib'
    }
  });

  var activation = Windows.ApplicationModel.Activation;
  var app = WinJS.Application;
  var nav = WinJS.Navigation;
  var sched = WinJS.Utilities.Scheduler;
  var ui = WinJS.UI;

  if (WinJS.Utilities.isPhone) {
    WinJS.UI.Hub = WinJS.UI.Pivot;
    WinJS.UI.HubSection = WinJS.UI.PivotItem;

    /*var speechRecognizer = new Windows.Media.SpeechRecognition.SpeechRecognizer();
    var uri = new Windows.Foundation.Uri("ms-appx:///speech.grxml");
    var storageFile = Windows.Storage.StorageFile.getFileFromApplicationUriAsync(uri)
    .then(function (srgs) {
      var grammarfileConstraint = new Windows.Media.SpeechRecognition.SpeechRecognitionGrammarFileConstraint(srgs, "createCommands");
      speechRecognizer.constraints.append(grammarfileConstraint);
      speechRecognizer.compileConstraintsAsync();
    }).then(function () {
      var listen = function() {
        speechRecognizer.recognizeAsync()
        .then(function (result) {
          console.info(result.text);
        }, function (error) {
          console.error("Speech: " + error.message);
        }).then(function () {
          WinJS.Promise.timeout().then(listen);
        });
      };
      listen();
    });*/
  };

  WinJS.Namespace.define("trello.binding", {
    CardLayout: WinJS.Class.define(function (options) {
      this._site = null;
      this._surface = null;
    },
    {
      // This sets up any state and CSS layout on the surface of the custom layout
      initialize: function (site) {
        this._site = site;
        this._surface = this._site.surface;

        // Add a CSS class to control the surface level layout
        WinJS.Utilities.addClass(this._surface, "cardLayout");

        return WinJS.UI.Orientation.vertical;
      },

      // Reset the layout to its initial state
      uninitialize: function () {
        WinJS.Utilities.removeClass(this._surface, "cardLayout");
        this._site = null;
        this._surface = null;
      },

      hittest: function () {

      }
    }),

    displayBlockIf: WinJS.Binding.converter(function(value) {
      if (!value) {
        return "none";
      } else {
        return "block";
      }
    }),

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
      if (board.prefs.backgroundImageScaled.length > 2) {
        return "url(" + board.prefs.backgroundImageScaled[2].url + ")";
      } else {
        return "url(" + board.prefs.backgroundImageScaled[0].url + ")";
      }
    }),

    permissionLevel: WinJS.Binding.converter(function(permissionLevel) {
      return i18n.translate("board.permissionLevel." + permissionLevel)
    }),

    badgeUpdate: WinJS.Binding.initializer(function (s, sp, d, dp) {
      s.bind(sp[0], function(value, oldValue) {
        if (oldValue === undefined) return;
        WinJS.UI.Animation.updateBadge(d);
      });
      return WinJS.Binding.defaultBind(s, sp, d, dp);
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
        args.headerText = "Add your trello account here."; //i18n
        args.webAccountProviderCommands.append(providerCommand);
      } else {
        args.headerText = "Manage your trello account here."; //i18n
      }

      var accountInvokedhandled = function (command, args) {
        if (args.action === Windows.UI.ApplicationSettings.WebAccountAction.remove) {
          trello.api.logout()
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
        if (args.detail.kind === activation.ActivationKind.webAuthenticationBrokerContinuation) {
          require(["api"], function(api) {
            trello.api._onAuthenticated(args.detail.webAuthenticationResult);
          });
        } else if (args.detail.kind === activation.ActivationKind.launch) {
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
                return new WinJS.Promise(function(c,e,p) {
                  require(["api", "lib/page", "pubnub"], function (api, page, pubnub) {
                    // Those cannot be used in Win HTML Apps, causes SecurityException with "about:" URLs
                    page.Context.prototype.pushState = page.Context.prototype.save = function () { }
                    WinJS.Namespace.define("trello", {
                      show: function (path) {
                        page.show(path);
                      }
                    });
                    page("about:what(.*)", function(context) {
                      //WinJS.Navigation.navigate("/pages/aboutPage.html", context.params)
                    });
                    page("/", function(context) {
                      WinJS.Navigation.navigate("/pages/homePage.html", context.params)
                    });
                    page("/boards/:id", function(context) {
                      WinJS.Navigation.navigate("/pages/boardPage.html", context.params)
                    });
                    page("/cards/:card", function (context) {
                      WinJS.Navigation.navigate("/pages/cardPage.html", context.params)
                    });
                    page(function(context) {
                      WinJS.Navigation.navigate("/pages/404.html", context.params)
                    });
                    page.start({dispatch:false, click:false});
                    c.apply(this, arguments);
                  }, e);
                });
            }).then(function () {
              if (args.detail.arguments) {
                trello.show(args.detail.arguments);
              } else {
                return nav.navigate(nav.location || Application.navigator.home, nav.state);
              }
            }).then(function() {
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
