
Organization = trello.model.define
  className: "Organization"
  properties:
    name: {}
    displayName: {}
    desc: {}
    website: {}
  validations:
    atSave: ->
      @validateLength("displayName", minimum: 1)
      @validate("displayName", (value) -> value and value[0] != ' ' and value[value.length-1] != ' ')
      @validateLength("name,desc", maximum: 16384)
      @validateFormat("website", /^https?:\/\//, "The website URL must start with http:// or https://") #i18n
    atCreate: ->

WinJS.Namespace.define "trello.app.model",
  Organization: Organization