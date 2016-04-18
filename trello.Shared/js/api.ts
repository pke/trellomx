/// <reference path="../../typings/require.d.ts" />
/// <reference path="../../typings/winjs.d.ts" />
/// <reference path="../../typings/winrt.d.ts" />
interface TrelloApiOptions {
  appName: string;
  version?: number;
  apiKey: string;
  webhookCallbackUrl: string;
}
     
(function() {
  define(["apiKeys"], function(ApiKeys) {
    var TrelloAPI, passwordVault;
    
    passwordVault = new Windows.Security.Credentials.PasswordVault();
    
    
    TrelloAPI = WinJS.Class.define(function(options) {
      var cred, passwordCredentials;
      this.webhookCallbackUrl = options.webhookCallbackUrl;
      this.appName = options.appName;
      this.version = options.version || 1;
      this.apiKey = options.apiKey;
      this.apiRootUrl = "https://api.trello.com/" + this.version;
      this.authorizeUrl = "https://trello.com/" + this.version + "/authorize";
      passwordCredentials = passwordVault.retrieveAll();
      if (passwordCredentials.size && (cred = passwordCredentials.getAt(0))) {
        cred.retrievePassword();
        this.token = cred.password;
      }
    }, {
      loggedIn: {
        get: function() {
          return !!this.token;
        }
      },
      _requestPrivateAsync: function(method: string, path: string, params) {
        if (params == null) {
          params = {};
        }
        return (params.token ? WinJS.Promise.as(params.token) : this.authorizeAsync()).then((function(_this) {
          return function(token) {
            params["token"] || (params["token"] = _this.token);
            return _this._requestAsync(method, path, params);
          };
        })(this));
      },
      _toQueryString: function(params:any) : string {
        var queryParams;
        return queryParams = (Object.keys(params).map(function(key) {
          return key + "=" + (encodeURIComponent(params[key]));
        })).join("&");
      },
      _requestAsync: function(method:string, path:string, params:any) {
        var url;
        if (params == null) {
          params = {};
        }
        params["key"] = this.apiKey;
        if (this.token) {
          params["token"] || (params["token"] = this.token);
        }
        url = "" + this.apiRootUrl + path + "?" + (this._toQueryString(params));
        return WinJS.xhr({
          url: url,
          type: method
        }).then(function(result) {
          var e;
          try {
            return JSON.parse(result.responseText);
          } catch (_error) {
            e = _error;
            return WinJS.Promise.wrapError(new WinJS.ErrorFromName("TrelloApiError", "Could not parse response: " + e.message));
          }
        }, function(errorResponse) {
          return WinJS.Promise.wrapError(new WinJS.ErrorFromName("TrelloApiError", errorResponse.status + " " + errorResponse.statusText + ": " + errorResponse.responseText));
        }).then(null, function(error) {
          console.error("Could not " + method + " " + url + ": " + error.message);
          return WinJS.Promise.wrapError(new WinJS.ErrorFromName("TrelloApiError", "Error " + method + " " + path + ": " + error.message + " (" + url + ")"));
        });
      },
      getPublicAsync: function(path:string, params) {
        return this._requestAsync("GET", path, params);
      },
      getAsync: function(path:string, params) {
        return this._requestPrivateAsync("GET", path, params);
      },
      postAsync: function(path:string, params) {
        return this._requestPrivateAsync("POST", path, params);
      },
      putAsync: function(path:string, params) {
        return this._requestPrivateAsync("PUT", path, params);
      },
      deleteAsync: function(path:string, params) {
        return this._requestPrivateAsync("DELETE", path, params);
      },
      meAsync: function(options) {
        return this._me || (this._me = this.getAsync("/members/me", options).then((function(_this) {
          return function(me) {
            _this.watchAsync(me);
            _this._me = null;
            if (me.boards) {
              me.boards = me.boards.map(function(board) {
                return new trello.app.model.Board(board);
              }, _this);
            }
            return me;
          };
        })(this), (function(_this) {
          return function(error) {
            _this._me = null;
            return WinJS.Promise.wrapError(error);
          };
        })(this)));
      },
      logout: function() {
        passwordVault.remove(passwordVault.retrieveAll().getAt(0));
        this.token = this._me = null;
        return WinJS.Application.queueEvent({
          type: "trello/loggedout"
        });
      },
      getBoardAsync: function(id, params) {
        return this.getPublicAsync("/boards/" + id, params).then((function(_this) {
          return function(board) {
            board = new trello.app.model.Board(board);
            board.unwatch = _this.unwatch.bind(_this, board);
            return board;
          };
        })(this));
      },
      _webhooks: {},
      watchAsync: function(model) {
        var webhook, _base, _name;
        webhook = (_base = this._webhooks)[_name = model.id] || (_base[_name] = {});
        if (webhook.refCount) {
          webhook.refCount = webhook.refCount + 1;
          return WinJS.Promise.as(webhook);
        } else if (this.loggedIn) {
          return WinJS.Utilities.Scheduler.schedule(function() {
            return this.createWebhookAsync({
              description: model.name || model.fullName,
              idModel: model.id,
              callbackURL: this.webhookCallbackUrl + "/" + model.id
            }).then(function() {
              webhook.refCount = 1;
              return webhook;
            });
          }, WinJS.Utilities.Scheduler.Priority.idle, this);
        } else {
          return WinJS.Promise.as(webhook);
        }
      },
      unwatch: function(model) {
        var webhook;
        if (webhook = this._webhooks[model.id]) {
          if ((webhook.refCount = webhook.refCount - 1) === 0) {
            return delete this._webhooks[model.id];
          }
        }
      },
      createWebhookAsync: function(params) {
        return this.postAsync("/tokens/" + this.token + "/webhooks", params).then(null, function(error) {
          console.error("Could not create webhook for " + params.idModel + ":" + params.description);
        }).then(function() {
          return WinJS.Application.queueEvent({
            type: "trello/webhook/created",
            webhook: params
          });
        });
      },
      getWebhooksAsync: function() {
        return this.getAsync("/tokens/" + this.token + "/webhooks");
      },
      deleteWebhookAsync: function(id) {
        return this.deleteAsync("/tokens/" + this.token + "/webhooks/" + id);
      },
      deleteAllWebhooksAsync: function() {
        return this.getWebhooksAsync().then((function(_this) {
          return function(webhooks) {
            var next;
            next = WinJS.Promise.as();
            webhooks.forEach(function(webhook) {
              return next = next.then(function() {
                return _this.deleteWebhookAsync(webhook.id);
              }, function(error) {
                return console.error("Could not delete webhook " + webhook.id);
              });
            });
            return next;
          };
        })(this));
      },
      _onAuthenticated: function(result) {
        var token;
        if (result.responseStatus === Windows.Security.Authentication.Web.WebAuthenticationStatus.success) {
          token = result.responseData.replace(TrelloAPI._wabReturnUrl + "/token=", "");
          return this.getAsync("/members/me", {
            token: token
          }).then((function(_this) {
            return function(account) {
              var password;
              password = new Windows.Security.Credentials.PasswordCredential("trello", account.fullName, _this.token = token);
              passwordVault.add(password);
              WinJS.Application.queueEvent({
                type: "trello/loggedin"
              });
              return token;
            };
          })(this));
        } else if (result.responseStatus === Windows.Security.Authentication.Web.WebAuthenticationStatus.userCancel) {
          return WinJS.Promise.wrapError(new WinJS.ErrorFromName("Canceled"));
        } else {
          return WinJS.Promise.wrapError(new WinJS.ErrorFromName("trello", "Login error: " + result.responseErrorDetail));
        }
      },
      authorizeAsync: function(expiration) {
        var endUri, queryString, startUri;
        if (expiration == null) {
          expiration = "never";
        }
        if (this.token) {
          return WinJS.Promise.as(this.token);
        }
        queryString = this._toQueryString({
          callback_method: "fragment",
          return_url: TrelloAPI._wabReturnUrl,
          scope: "read,write,account",
          expiration: expiration,
          name: this.appName,
          key: this.apiKey
        });
        startUri = new Windows.Foundation.Uri(this.authorizeUrl + "?" + queryString);
        endUri = new Windows.Foundation.Uri(TrelloAPI._wabReturnUrl + "/token");
        if (Windows.Security.Authentication.Web.WebAuthenticationBroker.authenticateAndContinue) {
          return WinJS.Promise.as(Windows.Security.Authentication.Web.WebAuthenticationBroker.authenticateAndContinue(startUri, endUri, null, Windows.Security.Authentication.Web.WebAuthenticationOptions.none));
        }
        return this._authorizing || (this._authorizing = Windows.Security.Authentication.Web.WebAuthenticationBroker.authenticateAsync(Windows.Security.Authentication.Web.WebAuthenticationOptions.none, startUri, endUri).then(this._onAuthenticated.bind(this)).then(null, (function(_this) {
          return function(error) {
            _this._authorizing = null;
            return WinJS.Promise.wrapError(error);
          };
        })(this)));
      }
    }, {
      _wabReturnUrl: "https://trello.com"
    });
    WinJS.Namespace.define("trello", {
      api: new TrelloAPI({
        version: 1,
        appName: "Trello Windows App",
        apiKey: ApiKeys.trello.apiKey,
        apiSecret: ApiKeys.trello.apiSecret,
        webhookCallbackUrl: "http://pfcpille.no-ip.biz:1337"
      })
    });
  });

}).call(this);
