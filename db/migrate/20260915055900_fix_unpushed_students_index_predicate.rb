class FixUnpushedStudentsIndexPredicate < ActiveRecord::Migration[6.1]
  # Intentionally empty. This only re-cut index_users_unpushed_students_with_school
  # with a role predicate, and 20260915060000 drops that index outright for
  # index_users_unlinked_students_with_school. Databases that already ran the
  # original are unaffected -- it stays in schema_migrations and never re-runs.
  def change; end
end
