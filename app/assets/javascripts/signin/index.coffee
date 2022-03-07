$(document).ready( ->
  card = $('.ox-card.login')

  onHelpClick = (ev) =>
    ev.preventDefault()
    card.find('.login-help').slideToggle('fast')

  card.find('a.trouble').click(onHelpClick) if card.length
)
