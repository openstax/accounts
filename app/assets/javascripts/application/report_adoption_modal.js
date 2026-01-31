(function() {
  function showReportAdoptionModal(event) {
    event.preventDefault();
    var $modal = $('#reportAdoptionModal');

    if ($modal.length) {
      $modal.modal('show');
    }
  }

  function getBookRowTemplateHtml() {
    var template = document.getElementById('report-adoption-book-template');
    return template ? template.innerHTML.trim() : '';
  }

  function addBookRow() {
    var templateHtml = getBookRowTemplateHtml();

    if (!templateHtml) {
      return;
    }

    var $row = $(templateHtml);
    $row.find('select').val('');
    $row.find('input[type="number"]').val('');
    $('[data-report-adoption-books]').append($row);
    applyDefaultSchoolYear($row);
    setRowLabels();
    updateRemoveButtons();
    updateSummaryMetrics();
  }

  function handleAddBookClick(event) {
    event.preventDefault();
    addBookRow();
  }

  function handleRemoveBookClick(event) {
    event.preventDefault();
    var $row = $(event.currentTarget).closest('[data-report-adoption-row]');
    var $rows = $('[data-report-adoption-row]');

    if ($rows.length <= 1) {
      $row.find('select').val('');
      $row.find('input[type="number"]').val('');
      updateSummaryMetrics();
      return;
    }

    $row.remove();
    setRowLabels();
    updateRemoveButtons();
    updateSummaryMetrics();
  }

  function updateRemoveButtons() {
    var $rows = $('[data-report-adoption-row]');
    var hideButtons = $rows.length <= 1;

    $rows.each(function(_, row) {
      var $button = $(row).find('[data-report-adoption-remove]');
      $button.toggleClass('is-hidden', hideButtons);
    });
  }

  function resetBookRows() {
    var $container = $('[data-report-adoption-books]');

    if (!$container.length) {
      return;
    }

    var $rows = $container.find('[data-report-adoption-row]');
    $rows.slice(1).remove();
    $rows = $container.find('[data-report-adoption-row]');
    $rows.find('select').val('');
    $rows.find('input[type="number"]').val('');
    applyDefaultSchoolYear($rows.first());
    setRowLabels();
    updateRemoveButtons();
    updateSummaryMetrics();
  }

  function getCurrentSchoolYear() {
    var $form = $('#report-adoption-form');
    return $form.data('current-school-year');
  }

  function applyDefaultSchoolYear($row) {
    if (!$row || !$row.length) {
      return;
    }

    var defaultYear = getCurrentSchoolYear();

    if (!defaultYear) {
      return;
    }

    $row.find('[data-report-adoption-school-year]').val(defaultYear);
  }

  function formatNumber(value) {
    if (Number.isNaN(value)) {
      return '—';
    }
    return value.toLocaleString ? value.toLocaleString() : String(value);
  }

  function updateTotalStudents() {
    var inputs = $('[data-report-adoption-students]');
    if (!inputs.length) {
      return;
    }

    var total = 0;
    var hasValue = false;

    inputs.each(function(_, input) {
      var numeric = parseInt(input.value, 10);
      if (!Number.isNaN(numeric)) {
        total += numeric;
        hasValue = true;
      }
    });

    var text = hasValue ? formatNumber(total) + ' students' : '—';
    $('[data-report-adoption-summary-value]').text(text);
    return hasValue ? total : null;
  }

  function updateBookCount() {
    var selects = $('[data-report-adoption-row] select[name="books[][name]"]');
    var count = 0;

    selects.each(function(_, select) {
      if (select.value && select.value.trim().length > 0) {
        count += 1;
      }
    });

    var display = count > 0 ? count : '—';
    $('[data-report-adoption-summary-subtext]').text('Across ' + display + ' books');
  }

  function updateSummaryMetrics() {
    updateTotalStudents();
    updateBookCount();
  }

  function setRowLabels() {
    var $rows = $('[data-report-adoption-row]');
    $rows.each(function(index, row) {
      var $label = $(row).find('[data-report-adoption-row-label]');
      if ($label.length) {
        $label.text('Adoption ' + (index + 1));
      }
    });
  }

  $(document).on('click', '[data-report-adoption-trigger]', showReportAdoptionModal);
  $(document).on('click', '[data-report-adoption-add]', handleAddBookClick);
  $(document).on('click', '[data-report-adoption-remove]', handleRemoveBookClick);

  $(document).on('input', '[data-report-adoption-students]', updateSummaryMetrics);
  $(document).on('change', '[data-report-adoption-row] select[name="books[][name]"]', updateSummaryMetrics);

  $(document).on('submit', '#report-adoption-form', function(event) {
    event.preventDefault();
  });

  $(document).on('show.bs.modal', '#reportAdoptionModal', function() {
    var form = document.getElementById('report-adoption-form');

    if (form) {
      form.reset();
    }

    resetBookRows();
    setRowLabels();
    updateSummaryMetrics();
  });

  // initialize on load
  setRowLabels();
  updateSummaryMetrics();
})();
