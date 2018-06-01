//= require knockout

// Fetch data hidden in the html
const paramsEl = document.querySelector('[data-params]');
const paramsData = JSON.parse(paramsEl.textContent);
const subjectsData = Reflect.ownKeys(paramsData.subjects || {})
  .filter((k) => paramsData.subjects[k]);

// Are there errors on page 2 and not on page 1?
const p1errs = document.querySelector('.page-1 .alert');
const p2errs = document.querySelector('.page-2 .alert');

console.debug("Params Data:", paramsData);

const subjects = ['Math', 'Science', 'Social Sciences', 'Humanities'];
const vm = {
  adoptions: ko.observable(paramsData.adoptions || {}),
  agree: ko.observable(paramsData.i_agree === "1"),
  bySubject: ko.observable({}),
  formPage: ko.observable(!p1errs && p2errs ? 2 : 1),
  howUsing: ko.observable(paramsData.using_openstax),
  howUsingBook: ko.observable(paramsData.how_using_book || {}),
  newsletter: ko.observable(paramsData.newsletter),
  numStudents: ko.observable(paramsData.num_students),
  numStudentsBook: ko.observable(paramsData.num_students_book || {}),
  subjects,
  adopted: ko.pureComputed(() => vm.howUsing() === 'Confirmed Adoption Won'),
  interested: ko.pureComputed(() => vm.howUsing() === 'Not using'),
  selectedBooks: ko.pureComputed(() => {
    const result = [];

    vm.subjects.forEach((s) => {
      if (vm.bySubject()[s]) {
        vm.bySubject()[s].forEach((b) => {
          if (b.checked()) {
            result.push(b);
          }
        });
      }
    });

    return result;
  }),
  nextPage(data, event) {
    const currentPage = event.target.parentNode;
    const invalid = currentPage.querySelector(':invalid');

    if (invalid) {
      // It is a submit button.
      // knockout does preventDefault by default. return true overrides that
      // the submit process will find the invalid field and pop up a bubble
      return true;
    }
    vm.formPage(vm.formPage() + 1);
  },
  prevPage() {
    vm.formPage(vm.formPage() - 1);
  },
  beforeSubmit(data, event) {
    const currentPage = event.target.parentNode;
    const invalid = currentPage.querySelector(':invalid');

    console.debug("Calling beforeSubmit", data);
    if (invalid) {
        console.debug("INVALID:", invalid);
        return false;
    }
    return true;
  }
};
ko.applyBindings(vm);


const booksPromise = fetch('https://openstax.org/api/books')
  .then((r) => r.json())
  .then((r) => r.books.filter((b) => b.salesforce_abbreviation));

booksPromise.then((books) => {
  const bySubject = {};
  const nameFor = (abbr) => `${abbr.replace(/\W+/g, '_').toLowerCase()}`

  books
    .filter((b) => b.salesforce_abbreviation)
    .map((book) => ({
      text: book.salesforce_name,
      abbreviation: nameFor(book.salesforce_abbreviation),
      name: `profile[subjects[${nameFor(book.salesforce_abbreviation)}]]`,
      value: '1',
      comingSoon: book.coming_soon,
      subject: book.subject,
      imageUrl: book.cover_url,
      checked: ko.observable(subjectsData.includes(nameFor(book.salesforce_abbreviation))),
      toggle() {
        this.checked(!this.checked());
      }
    }))
    .forEach((b) => {
      if (!(b.subject in bySubject)) {
        bySubject[b.subject] = [];
      }

      const alreadyHere = bySubject[b.subject].findIndex((b2) => b2.abbreviation === b.abbreviation);

      if (alreadyHere >= 0) {
        bySubject[b.subject][alreadyHere] = b;
      } else {
        bySubject[b.subject].push(b);
      }
    });
  vm.bySubject(bySubject);
});
