
Organization = trello.model.define "Organization",
  readOnly: ["id"]
  properties:
    name:
      maximumLength: 16384
    displayName:
      minimumLength: 1
      validate: (value) ->
        value and value[0] != ' ' and value[value.length-1] != ' '
    desc:
      maximumLength: 16384
    website:
      format: /^https?:\/\//
      formatMessage: "The website URL must start with http:// or https://" #i18n

WinJS.Namespace.define "trello.app.model",
  Organization: Organization