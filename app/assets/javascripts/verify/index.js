//= require knockout

const subjects = ['Math', 'Science', 'Social Sciences', 'Humanities'];
const vm = {
    formPage: ko.observable(1),
    subjects,
    bySubject: ko.observable({}),
    nextPage() {
        vm.formPage(vm.formPage() + 1);
    },
    prevPage() {
        vm.formPage(vm.formPage() - 1);
    }
};
ko.applyBindings(vm);


const booksPromise = fetch('https://openstax.org/api/books')
    .then((r) => r.json())
    .then((r) => r.books.filter((b) => b.salesforce_abbreviation));

booksPromise.then((books) => {
    const bySubject = {};

    books
    .map((book) => ({
        text: book.salesforce_name,
        name: `subjects[${book.salesforce_abbreviation.replace(/\W+/g, '_').toLowerCase()}]`,
        value: book.salesforce_abbreviation,
        comingSoon: book.coming_soon,
        subject: book.subject,
        imageUrl: book.cover_url,
        checked: ko.observable(false),
        toggle() {
            console.debug("TOggling", this);
            this.checked(!this.checked());
        }
    }))
    .forEach((b) => {
        if (!(b.subject in bySubject)) {
            bySubject[b.subject] = [];
        }

        bySubject[b.subject].push(b);
    });
    vm.bySubject(bySubject);
    console.debug("By subject now:", vm.bySubject());
});
