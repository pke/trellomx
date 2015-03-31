# Rename this to apiKeys.coffee afer checkout and fill in your values
# Don't stage your apiKeys.* files (they are .gitignored for all our safety)

# FIXME: use requirejs and export those and not put them in the global namespace
WinJS.Namespace.define "trello.apiKeys",
  apiKey: "YOUR API KEY HERE"
  # Not actually needed, we don't do OAuth at the moment
  apiSecret: "YOUR API SECRET HERE"
