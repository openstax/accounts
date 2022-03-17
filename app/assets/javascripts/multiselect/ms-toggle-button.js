msToggleButton = (
  function () {
    function VM ({ isOpen }) {
      return {
        isOpen,
        toggleOpen () {
          isOpen(!isOpen())
        }
      }
    }

    return ({
      viewModel: VM,
      template: `
            <button type="button" data-bind="click: toggleOpen">
                <!-- ko if: isOpen -->
                    <i class="fa fa-caret-up"></i>
                <!-- /ko -->
                <!-- ko ifnot: isOpen -->
                    <i class="fa fa-caret-down"></i>
                <!-- /ko -->
            </button>
        `
    });
  }()
);
