msFilteredResultsSpec = (
  function () {
    function VM (props) {
      Object.assign(this, props)
      const vm = this
      const results = ko.pureComputed(function () {
        return vm.options().map((opt) => Object.assign({}, opt, {
          groups: opt.groups || []
        }))
      })
      const groups = ko.pureComputed(function () {
        const s = new Set(results().map((opt) => opt.groups).reduce((a, b) => a.concat(b), []))

        return Array.from(s.values()).filter((v) => typeof v !== 'undefined').sort()
      })

      this.filteredResults = ko.pureComputed(function () {
        return results().filter(
          (opt) => opt.label.toLowerCase().includes(vm.filter().toLowerCase())
        )
      })
      this.filteredGroups = ko.pureComputed(function () {
        return groups()
          .map((g) => {
            const filterMatches = g.toLowerCase().includes(vm.filter().toLowerCase())

            return {
              name: g,
              results: (filterMatches ? results() : vm.filteredResults()).filter(
                (r) => r.groups.includes(g)
              )
            }
          })
          .filter(
            (g) => g.results.length > 0
          )
      })
      this.groupedResults = ko.pureComputed(function () {
        return groups().length > 0
      })
    }

    return ({
      viewModel: VM,
      template: `
        <div class="filtered-results">
            <!-- ko if: groupedResults -->
                <!-- ko foreach: filteredGroups -->
                    <div class="group-heading" data-bind="text:name"></div>
                    <div class="results" data-bind="foreach: results">
                        <div class="result" data-bind="text: $data.label, click: $parents[1].onClick, css: {selected: $data.selected}"></div>
                    </div>
                <!-- /ko -->
            <!-- /ko -->
            <!-- ko ifnot: groupedResults -->
                <div class="results" data-bind="foreach: filteredResults">
                    <div class="result" data-bind="text: $data.label, click: $parent.onClick, css: {selected: $data.selected}"></div>
                </div>
            <!-- /ko -->
        </div>
        `
    });
  } ()
)
