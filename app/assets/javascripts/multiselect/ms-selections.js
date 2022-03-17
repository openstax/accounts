msSelectionsSpec = (
  function () {
    function VM ({ filter, selections, placeholder }) {
      this.filter = filter
      this.selections = selections
      this.placeholder = placeholder
      this.remove = (data) => {
        data.selected(false)
      }
    }

    return ({
      viewModel: VM,
      template: `
            <div class="selections">
                <input type="text" class="filter" data-bind="textInput: filter, attr: {placeholder: placeholder}">
                <!-- ko foreach: selections -->
                    <div class="box">
                        <span data-bind="text: label"></span>
                        <span role="button" class="put-away" data-bind="click: $parent.remove">
                            &times;
                        </span>
                    </div>
                <!-- /ko -->
            </div>
        `
    });
  }()
);
