# The forms in this control are written with x-editable styling so that it looks
# similar to the other controls.

$(document).ready ->

  $('#add-an-email').click ->

    $(this).before """
      <span class="editable-container editable-inline new-email" style="">
        <div>
          <div class="editableform-loading" style="display: none;"></div>
          <form class="form-inline editableform" style="">
            <input type="hidden" name="contact_info[type]" value="EmailAddress">
            <div class="control-group form-group">
              <div>
                <div class="editable-input" style="position: relative;">
                  <input type="text" class="form-control input-sm" style="padding-right: 24px;" placeholder="Email" name="contact_info[value]"><span class="editable-clear-x"></span>
                </div><div class="editable-buttons"><button type="submit" class="btn btn-primary btn-sm editable-submit"><i class="glyphicon glyphicon-ok"></i></button><button type="button" class="btn btn-default btn-sm editable-cancel"><i class="glyphicon glyphicon-remove"></i></button>
                </div>
              </div>
              <div class="editable-error-block help-block" style="display: none;"></div>
            </div>
          </form>
        </div>
      </span>
      """

    $(this).prev().find('input[type=text]').focus()

    $(this).hide()



  $(document).on 'submit', '.new-email form', (e) ->

    e.preventDefault()

    new_email_path = "/contact_infos"

    form = $(this)
    container = form.closest('.editable-container')
    loading = form.prev()
    error_block = form.find('.editable-error-block')

    $.ajax
      type: "POST"
      url: new_email_path
      data: $(this).serialize()
      beforeSend: () ->
        form.hide()
        loading.show()
      success: (data) ->
        console.log data
        container.remove()
        template = $('#email-template').html()
        template = template.replace("EMAIL_VALUE", data.contact_info.value)
        $('.email:last').after template
        $('#add-an-email').show()
      error: (data) ->
        loading.hide()
        form.show()
        error_block.html data.responseText
        error_block.css("display", "block")
