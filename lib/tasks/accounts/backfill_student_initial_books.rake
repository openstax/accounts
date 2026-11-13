namespace :accounts do
  desc 'One-time backfill of Student__c.Initial_Book__c from signup redirects; never overwrites. DRY_RUN=true writes nothing'
  # rake accounts:backfill_student_initial_books
  # DRY_RUN=true rake accounts:backfill_student_initial_books
  task backfill_student_initial_books: :environment do
    dry_run = ActiveModel::Type::Boolean.new.cast(ENV['DRY_RUN']) || false
    stats = BackfillStudentInitialBooks.call(dry_run: dry_run)

    puts "#{dry_run ? 'DRY RUN, nothing written. ' : ''}Done:"
    puts "  candidates (linked students with a signup log): #{stats.candidates}"
    puts "  resolvable to a book:                            #{stats.resolvable}"
    puts "  already set or record missing:                   #{stats.already_set_or_missing}"
    puts "  updated:                                         #{stats.updated}"
    puts "  failures:                                        #{stats.failures}"

    if stats.by_book.any?
      names = OpenStax::Salesforce::Remote::Book.all.to_a.to_h { |book| [book.id, book.name] }
      puts dry_run ? 'Would write, by book:' : 'Written, by book:'
      stats.by_book.sort_by { |_, count| -count }.each do |book_id, count|
        puts "  #{names.fetch(book_id, book_id)}: #{count}"
      end
    end
  end
end
