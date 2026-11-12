// "Step N of M" is rendered as text by newflow_login_signup_card; draw the
// progress track under it. The fill sits at N/M and CSS animates it in from
// (N-1)/M, so with no JS, or under reduced motion, the page is simply the text.
document.addEventListener('DOMContentLoaded', function () {
  var counters = document.querySelectorAll('.step-counter');

  Array.prototype.forEach.call(counters, function (counter) {
    if (counter.querySelector('.step-progress')) { return; }

    var match = (counter.textContent || '').match(/(\d+)\D+(\d+)/);
    if (!match) { return; }

    var current = parseInt(match[1], 10);
    var total = parseInt(match[2], 10);
    if (!total || current < 1 || current > total) { return; }

    var track = document.createElement('div');
    track.className = 'step-progress';
    track.setAttribute('aria-hidden', 'true');

    var fill = document.createElement('div');
    fill.className = 'step-progress__fill';
    fill.style.width = (current / total * 100) + '%';
    fill.style.setProperty('--step-from', String((current - 1) / current));

    track.appendChild(fill);
    counter.appendChild(track);
  });
});
