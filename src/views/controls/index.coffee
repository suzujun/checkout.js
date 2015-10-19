_ = require('underscore')

crowdcontrol = require 'crowdcontrol'
Events = crowdcontrol.Events
InputView = crowdcontrol.view.form.InputView

helpers = crowdcontrol.view.form.helpers
helpers.defaultTagName = 'crowdstart-input'

class Input extends InputView
  tag: 'crowdstart-input'
  html: require '../../../templates/control/input.jade'
  js:(opts)->
    @model = if opts.input then opts.input.model else @model

Input.register()

# views
class Static extends Input
  tag: 'crowdstart-static'
  html: '<span>{ model.value }</span>'

Static.register()

class Checkbox extends Input
  tag: 'crowdstart-checkbox'
  html: require '../../../templates/control/checkbox.jade'
  change: (event) ->
    value = event.target.checked
    if value != @model.value
      @obs.trigger Events.Input.Change, @model.name, value
      @model.value = value
      @update()

Checkbox.register()

class Select extends Input
  tag: 'crowdstart-select'
  html: require '../../../templates/control/select.jade'
  tags: false

  lastValueSet: null

  events:
    "#{Events.Input.Set}": (name, value) ->
      if name == @model.name && value?
        @clearError()
        @model.value = value
        # whole page needs to be updated for side effects
        riot.update()

  options: ()->
    return @selectOptions

  changed: false
  change: (event) ->
    value = $(event.target).val()
    if value != @model.value
      @obs.trigger Events.Input.Change, @model.name, value
      @model.value = value
      @changed = true
      @update()

  isCustom: (o)->
    options = o
    if !options?
      options = @options()

    for name, value of options
      if _.isObject value
        if !@isCustom value
          return false

      else if name == @model.value
        return false

    return true

  initSelect: ($select)->
    $select.select2(
      tags: @tags
      placeholder: @model.placeholder
      minimumResultsForSearch: Infinity
    ).change((event)=>@change(event))

  js:(opts)->
    super

    @selectOptions = opts.options

    @on 'update', ()=>
      $select = $(@root).find('select')
      if $select[0]?
        if !@initialized
          requestAnimationFrame ()=>
            @initSelect($select)
            @initialized = true
            @changed = true
        else if @changed
          requestAnimationFrame ()=>
            # this bypasses caching of select option names
            # no other way to force select2 to flush cache
            if @isCustom()
              $select.select('destroy')
              @initSelect($select)
            $select.select2('val', @model.value)
            @changed = false
      else
        requestAnimationFrame ()=>
          @update()

    @on 'unmount', ()=>
      $select = $(@root).find('select')

Select.register()

class QuantitySelect extends Select
  tag: 'crowdstart-quantity-select'
  options: ()->
    return {
      0: 0
      1: 1
      2: 2
      3: 3
      4: 4
      5: 5
      6: 6
      7: 7
      8: 8
      9: 9
    }

QuantitySelect.register()

# tag registration
helpers.registerTag (inputCfg)->
  return inputCfg.hints.input
, 'crowdstart-input'

helpers.registerTag (inputCfg)->
  return inputCfg.hints.static
, 'crowdstart-static'

helpers.registerTag (inputCfg)->
  return inputCfg.hints.checkbox
, 'crowdstart-checkbox'

helpers.registerTag (inputCfg)->
  return inputCfg.hints.select
, 'crowdstart-select'

helpers.registerTag (inputCfg)->
  return inputCfg.hints['quantity-select']
, 'crowdstart-quantity-select'

helpers.registerValidator ((inputCfg) -> return inputCfg.hints.required)
, (model, name)->
  value = model[name]
  if _.isNumber(value)
    return value

  value = value?.trim()
  throw new Error "Required" if !value? || value == ''

  return value

helpers.registerValidator ((inputCfg) -> return inputCfg.hints.terms)
, (model, name)->
  value = model[name]
  if !value
    throw new Error 'Please read and agree to the terms and conditions.'
  return value