# Nightly push of students' picked schools to Salesforce Student__c records
# (Name = accounts UUID, School__c = school's Salesforce Account id).
# Pseudonymous by design: no name or email is ever sent.
class PushStudentSchoolsToSalesforce
  BATCH_SIZE = 250

  def self.call
    new.call
  end

  def call
    return unless Settings::Salesforce.push_students_enabled

    User.student
        .where.not(school_id: nil)
        .where(salesforce_student_pushed_at: nil)
        .preload(:school)
        .find_each(batch_size: BATCH_SIZE) do |user|
      push(user)
    end
  end

  private

  def push(user)
    sf_school_id = user.school&.salesforce_id
    return if sf_school_id.blank?

    student = OpenStax::Salesforce::Remote::Student.where(name: user.uuid).first

    if student.nil?
      OpenStax::Salesforce::Remote::Student.new(
        name: user.uuid, school_id: sf_school_id
      ).save!
    elsif student.school_id.blank?
      # Never overwrite a school set by the Assignable pipeline:
      # an LMS-derived school beats a signup-form pick.
      student.school_id = sf_school_id
      student.save!
    end

    user.update_column(:salesforce_student_pushed_at, Time.current)
  rescue StandardError => e
    Sentry.capture_exception(e)
  end
end
