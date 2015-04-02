# The base Trello model

# The ctor accepts an object literal
TrelloModel = WinJS.Class.define (properties = {}) ->
  unless typeof properties is "object"
    throw new WinJS.ErrorFromName("TrelloModelError", "ctor properties must be an object")
  @_initObservable()
  for own property of properties
    @addProperty(property, properties[property])
  return

WinJS.Class.mix(TrelloModel, WinJS.Binding.mixin)

define = (className, options) ->
  throw new WinJS.ErrorFromName("TrelloModelError", "A className must be given") unless className

  endPointName = className.toLowerCase() + "s" # do proper pluralization here?
  return Model = WinJS.Class.derive TrelloModel, (properties) ->
    TrelloModel.apply(@, arguments)
    @clazz = options
    @_dirty = false
    return
  ,
    setProperty: (name, newValue) ->
      if options.properties[name]
        oldValue = WinJS.Binding.unwrap(@)[name]
        # if undefined this is called from the ctor
        if oldValue isnt undefined and oldValue isnt newValue
          @changedProperties or= {}
          # Save the old value in the changed properties array
          @changedProperties[name] = @[name]
          @dirty = true
      TrelloModel.prototype.setProperty.apply(@, arguments)

    className: get: -> className

    dirty:
      get: -> @_dirty
      set: (value) ->
        if !(@_dirty = value)
          @changedProperties = {}

    isNew: get: -> !@id

    apiArgs: (what = "all") ->
      properties = if what is "all" then options.properties else @changedProperties
      result = {}
      Object.keys(properties).forEach((property) ->
        # when "all" is used "undefined" properties are not saved
        # cause they should only be undefined when the object was newly created.
        # null is a valid value though.
        # in "changed" mode they are saved as "null"
        value = @[property]
        return if what is "all" and value is undefined
        result[property] = if value is undefined then null else value
      , this)
      result

    # @return true if model could be saved
    saveAsync: () ->
      if @isNew
        result = trello.api.postAsync("/#{endPointName}", @apiArgs("all"))
      else if @dirty
        result = trello.api.putAsync("/#{endPointName}/#{@id}", @apiArgs("changed"))
      else
        result = WinJS.Promise.as({})
      result.then (updated) =>
        Object.keys(updated).forEach((property) ->
          @[property] = updated[property]
        , this)
        @dirty = false

    destroyAsync: () ->
      trello.api.deleteAsync("/#{endPointName}/#{id}")
  ,
    # Instantiates a new model, saves it and returns it
    createAsync: (properties) ->
      model = new Model(properties)
      model.saveAsync()
      .then () ->
        model

    findAllAsync: () ->
      trello.api.getAsync("/members/me/#{endPointName}")
      .then (items) ->
        items.map (item) -> new Model(item)


WinJS.Namespace.define "trello.model",
  define: define