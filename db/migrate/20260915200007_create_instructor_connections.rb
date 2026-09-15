class CreateInstructorConnections < ActiveRecord::Migration[6.1]
  def change
    create_table :instructor_connections do |t|
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :instructor, foreign_key: { to_table: :users }
      t.references :school, foreign_key: true

      # Snapshot fields — always populated (from the matched instructor/school
      # when present, or the student's free text when not) so the claim is
      # readable even if the matched records are later renamed or deleted.
      t.string :instructor_name, null: false
      t.string :school_name, null: false
      t.string :course
      t.string :term
      t.string :instructor_email

      # Student-attested claims start (and, for now, stay) unverified: no
      # Salesforce push, no impact counting. See InstructorConnection::STATUSES.
      t.string :status, null: false, default: 'unverified'

      t.timestamps
    end

    add_index :instructor_connections, [:student_id, :instructor_id]
    add_index :instructor_connections, :status
  end
end
