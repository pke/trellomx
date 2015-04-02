
##
# check if there's a fully qualified key in the resourceMap
# if so, the concatenated key is returned, otherwise null
checkQualifiedKey = (key, modifier) ->
  qualifiedKey = "#{key}.#{modifier}"
  result = WinJS.Resources.getString(qualifiedKey)
  if result.empty then null else result.value


##
# translate a i18n key using the given params
translate = (key, params = {}) ->
  if Array.isArray(key)
    return key.map (key) -> translate(key, params)

  key = key.substr(1) if key[0] is ':'

  params = { count: params } if typeof params == 'number'
  if typeof params?['count'] != 'undefined'
    if params['count'] == 0
      translated = checkQualifiedKey(key, 'none')
    else if params['count'] == 1
      translated = checkQualifiedKey(key, 'one')
    else if params['count'] == 2
      translated = checkQualifiedKey(key, 'two') || checkQualifiedKey(key, 'many')
    else
      translated = checkQualifiedKey(key, 'many')

  unless translated
    result = WinJS.Resources.getString(key)
    if result.empty
      if params.default
        if Array.isArray(params.default)
          defaultKeys = params.default
          delete params.default # Do not send them to the recursive function
          defaultKeys.some (defaultKey) ->
            if defaultKey[0] is ':'
              text = translate(defaultKey.substr(1), params)
              if text isnt defaultKey
                translated = text
                return true
            else
              translated = defaultKey
              return true
        else
          translated = if params.default[0] is ':' then translate(params.default) else params.default
    else
      translated = result.value

  return key unless translated

  for param, value of params
    try
      regex = new RegExp("#\\{#{param}\\}", 'g')
      translated = translated.replace(regex, value)

  translated

WinJS.Namespace.define "i18n",
  translate: translate