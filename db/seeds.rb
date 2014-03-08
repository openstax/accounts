# This file breaks up our seeds into separate files in the db/seeds directory, and
# calls them each in the specified order.  We do this so that each file can be 
# run separately in production as needed.  There's no great way to run arbitrary
# ruby code after migrations in production to update the 'seeded' state of the database.
#
# Putting seed data in migrations seems appealing in that we can repeatedly run
# db:migrate on production (and in fact have it baked into our deploy).  Old migrations
# aren't rerun so we get the desirable outcome of not duplicate seed records.
#
# However, tests don't run migrations. They just copy over the structure of the dev 
# database and load this seeds.rb file. So by separating out the seeding steps and 
# calling them all here, we have an easier way to run the selected seed steps
# manually on production.  
#
# Let's try to make the seed steps as idempotent as possible so we can run them
# multiple times if needed without negative effects (e.g. if there are problems 
# in the middle of one).

%w(

    001_fine_print_contracts.rb
  
).each do |filename|
  load "#{Rails.root.to_s}/db/seeds/#{filename}"
end

