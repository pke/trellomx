# Rename this to apiKeys.coffee afer checkout and fill in your values
# Don't stage your apiKeys.* files (they are .gitignored for all our safety)

define [], ->
  trello:
    apiKey: "YOUR API KEY HERE"
    # Not actually needed, we don't do OAuth at the moment
    apiSecret: "YOUR API SECRET HERE"
  pubnub:
    publish_key: 'YOUR PUBLISH KEY HERE'
    subscribe_key: 'YOUR SUBSCRIBE KEY HERE'
