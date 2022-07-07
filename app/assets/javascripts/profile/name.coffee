# Modified from /vendor/packages/x-editable/address.js

class OX.Profile.Name

  @editable: (el, attribs) ->
    el.editable(
      value: attribs,
      success: (response) -> $(@).html(response.full_name)
      validate: (attrs) ->
        if not attrs.first_name and not attrs.last_name
          OX.I18n.name.first_last_name_blank
        else if not attrs.first_name
          OX.I18n.name.first_name_blank
        else if not attrs.last_name
          OX.I18n.name.last_name_blank
    )

  @defaults = $.extend({}, $.fn.editabletypes.abstractinput.defaults,
    tpl: () -> """
       <div><input type="text" name="title" class="form-control input-sm" placeholder="#{OX.I18n.name.title}"></div>
       <div><input type="text" name="first_name" class="form-control input-sm" placeholder="#{OX.I18n.name.first_name}"></div>
       <div><input type="text" name="last_name" class="form-control input-sm" placeholder="#{OX.I18n.name.last_name}"></div>
       <div><input type="text" name="suffix" class="form-control input-sm" placeholder="#{OX.I18n.name.suffix}"></div>
    """
    inputclass: ''

  )

  constructor: (options) ->
    # We defer evaluating template until construction, as otherwise it would try
    # to read values if OX.I18n before its initialisation.
    defaults = OX.Profile.Name.defaults
    defaults = $.extend(defaults, {
      tpl: defaults.tpl(),
    })
    this.init('profile_name', options, OX.Profile.Name.defaults)


$.fn.editabletypes.profile_name = OX.Profile.Name
$.fn.editableutils.inherit(OX.Profile.Name, $.fn.editabletypes.abstractinput)
$.extend(OX.Profile.Name.prototype, {
  render: ->
    this.$input = this.$tpl.find('input')

  value2html: ->

  value2str: (value) ->
    str = ''
    if value
      for k of value
        str = str + k + ':' + value[k] + ';'
    str

  value2input: (value) ->
    return unless value
    this.$input.filter('[name="title"]').val value.title
    this.$input.filter('[name="first_name"]').val value.first_name
    this.$input.filter('[name="last_name"]').val value.last_name
    this.$input.filter('[name="suffix"]').val value.suffix

  input2value: ->
    {
      title: this.$input.filter('[name="title"]').val()
      first_name: this.$input.filter('[name="first_name"]').val()
      last_name: this.$input.filter('[name="last_name"]').val()
      suffix: this.$input.filter('[name="suffix"]').val()
    }

  activate: ->
    this.$input.filter('[name="first_name"]').focus()

  autosubmit: ->
    this.$input.keydown (e) ->
      $(this).closest('form').submit() if e.which is 13

})
