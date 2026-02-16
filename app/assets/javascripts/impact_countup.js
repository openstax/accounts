(function() {
  function shouldReduceMotion() {
    return window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  }

  function formatValue(value, format) {
    if (format === 'currency') {
      if (value < 10000) {
        var roundedHundreds = Math.round(value / 100) * 100;
        return currencyFormatter.format(roundedHundreds);
      }

      var roundedThousands = Math.round(value / 1000) * 1000;
      var units = [
        { threshold: 1e12, suffix: 'T' },
        { threshold: 1e9, suffix: 'B' },
        { threshold: 1e6, suffix: 'M' },
        { threshold: 1e3, suffix: 'K' }
      ];

      var suffix = '';
      var divisor = 1;

      for (var i = 0; i < units.length; i += 1) {
        if (roundedThousands >= units[i].threshold) {
          suffix = units[i].suffix;
          divisor = units[i].threshold;
          break;
        }
      }

      var shortened = Math.round(roundedThousands / divisor);
      return '$' + shortened + suffix;
    }

    return integerFormatter.format(Math.round(value));
  }

  var integerFormatter = new Intl.NumberFormat(undefined, { maximumFractionDigits: 0 });
  var currencyFormatter = new Intl.NumberFormat(undefined, {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0
  });

  function animateValue(element, target, format) {
    var duration = 600;
    var start = null;

    function step(timestamp) {
      if (!start) start = timestamp;
      var progress = Math.min((timestamp - start) / duration, 1);
      var eased = 1 - Math.pow(1 - progress, 3);
      var current = Math.round(target * eased);
      element.textContent = formatValue(current, format);
      if (progress < 1) {
        window.requestAnimationFrame(step);
      }
    }

    window.requestAnimationFrame(step);
  }

  function initCountUp() {
    if (shouldReduceMotion()) {
      return;
    }

    var elements = document.querySelectorAll('[data-countup-target]');
    elements.forEach(function(element) {
      var target = parseFloat(element.getAttribute('data-countup-target'));
      var format = element.getAttribute('data-countup-format') || 'integer';
      if (Number.isNaN(target)) {
        return;
      }
      animateValue(element, target, format);
    });
  }

  document.addEventListener('DOMContentLoaded', initCountUp);
})();
