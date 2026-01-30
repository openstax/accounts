class InferExternalIdRoles
  def self.call
    new.call
  end

  def call
    ExternalId.unknown_role.preload(:user).find_in_batches do |batch|
      ActiveRecord::Base.transaction do
        batch.each do |external_id|
          external_id.role = external_id.user.no_faculty_info? ? :student : :instructor
        end

        ExternalId.import(
          batch,
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: [:role]
          },
          validate: false
        )
      end
    end
  end
end
