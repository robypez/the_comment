# ERROR MSG BUILDER
@error_text_builder = (errors) ->
  error_msgs = ''
  for error in errors
    error_msgs += "<p><b>#{ error }</b></p>"
  error_msgs

# FORM CLEANER
@clear_comment_form = ->
  $('.error_notifier', '#new_comment, .comments_tree').hide()
  $("input[name='comment[title]']").val('')
  $("textarea[name='comment[raw_content]']").val('')

# NOTIFIER
@comments_error_notifier = (form, text) ->
  form.children('.error_notifier').empty().hide().append(text).show()

# JUST HELPER
@unixsec = (t) -> Math.round(t.getTime() / 1000)

# HIGHTLIGHT ANCHOR
@highlight_anchor = ->
  hash = document.location.hash
  if hash.match('#comment_')
    $(hash).addClass 'highlighted'

$ ->
  window.tolerance_time_start = unixsec(new Date)

  comment_forms  = "#new_comment, .reply_comments_form"
  tolerance_time = $('[data-comments-tolarance-time]').first().data('comments-tolarance-time')

  # Button Click => AJAX Before Send
  submits = '#new_comment input[type=submit], .reply_comments_form input[type=submit]'
  $(document).on 'click', submits, (e) ->
    button    = $ e.target
    form      = button.parents('form').first()
    time_diff = unixsec(new Date) - window.tolerance_time_start

    if tolerance_time && (time_diff < tolerance_time)
      delta  = tolerance_time - time_diff
      error_msgs = error_text_builder(["Please wait #{delta} secs"])
      comments_error_notifier(form, error_msgs)
      return false

    $('.tolerance_time').val time_diff
    button.prop 'disabled', true
    true

  # AJAX ERROR
  $(document).on 'ajax:error', comment_forms, (request, response, status) ->
    form = $ @
    $('input[type=submit]', form).prop 'disabled', false
    error_msgs = error_text_builder(["Server Error: #{response.status}"])
    comments_error_notifier(form, error_msgs)

  # COMMENT FORMS => SUCCESS
  $(document).on 'ajax:success', comment_forms, (request, response, status) ->
    form = $ @
    $('input[type=submit]', form).prop 'disabled', false

    if typeof(response) is 'string'
      anchor = $(response).find('.comment').attr('id')
      clear_comment_form()
      form.hide()
      $('.parent_id').val('')
      $('#new_comment').fadeIn()
      tree = form.parent().siblings('.nested_set')
      tree = $('ol.comments_tree') if tree.length is 0
      tree.append(response)
      document.location.hash = anchor
    else
      error_msgs = error_text_builder(response.errors)
      comments_error_notifier(form, error_msgs)

  # NEW ROOT BUTTON
  $(document).on 'click', '#new_root_comment', ->
    $('.reply_comments_form').hide()
    $('.parent_id').val('')
    $('#new_comment').fadeIn()
    false

  # REPLY BUTTON
  $(document).on 'click', '.reply_link', ->
    link    = $ @
    comment = link.parent().parent().parent()
  
    $(comment_forms).hide()
    form = $('#new_comment').clone().removeAttr('id').addClass('reply_comments_form')

    comment_id = comment.data('comment-id')
    $('.parent_id', form).val comment_id

    comment.siblings('.form_holder').html(form)
    form.fadeIn()
    false

  # CONTROLS
  ctrls = $('.controls')
  
  ctrls.on 'ajax:success', '.to_published', (request, response, status) ->
    link = $ @
    link.parents('.comment').first().removeClass('draft deleted').addClass('published')

  ctrls.on 'ajax:success', '.to_draft', (request, response, status) ->
    link = $ @
    link.parents('.comment').first().removeClass('published deleted').addClass('draft')

  ctrls.on 'ajax:success', '.to_spam, .to_deleted', (request, response, status) ->
    $(@).parents('li').first().hide()

  # INPLACE EDIT
  inplace_forms = '.comments_list .form form'
  $(document).on 'ajax:success', inplace_forms, (request, response, status) ->
    form = $ @
    item = form.parents('.item')
    item.children('.body').html(response).show()
    item.children('.form').hide()

  # FOR MANAGE SECTION
  list = $('.comments_list')

  list.on 'click', '.controls a.view', ->
    form = $(@).parents('div.form')
    body = form.siblings('.body')  
    body.show()
    form.hide()
    false

  list.on 'click', '.controls a.edit', ->
    body = $(@).parents('div.body')
    form = body.siblings('.form')
    body.hide()
    form.show()
    false

$ ->
  # ANCHOR HIGHLIGHT
  highlight_anchor()

  $(window).on 'hashchange', ->
    $('.comment.highlighted').removeClass 'highlighted'
    highlight_anchor()