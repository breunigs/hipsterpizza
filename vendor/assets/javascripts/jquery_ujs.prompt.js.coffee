# encoding: utf-8

# taken from https://gist.github.com/korny/5487129
# license unknown

# Usage: link_to …, prompt: { message: 'Some message', default: 'default value', param: 'name of parameter' }
# The prompt will ask for "message" and use "default" as the default value.
# Unless user selects cancel, "param"=<new value> will be sent to the given path.
# Optionally, you can just use `prompt: "message"`.

$.rails.prompt = (message, defaultValue) ->
  window.prompt message, defaultValue

$.rails.handlePrompt = (element) ->
  config = element.data 'prompt'
  message = config.message || config
  defaultValue = config.default
  param = config.param || 'value'
  return true unless message

  if $.rails.fire element, 'prompt'
    value = $.rails.prompt message, defaultValue
    callback = $.rails.fire element, 'prompt:complete', [value]

  params = element.data('params') || {}
  params[param] = value
  element.data 'params', params

  value && callback

allowAction = $.rails.allowAction
$.rails.allowAction = (element) ->
  if element.data 'prompt'
    if !element.attr 'disabled'
      $.rails.handlePrompt element
  else
    allowAction element
