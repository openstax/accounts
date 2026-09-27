# One-time (rerunnable) cleanup for Student__c records pass 1 created before
# it excluded the Find Me A Home placeholder school (School::PLACEHOLDER_NAME):
# a student whose school_id already pointed at the placeholder got a
# Student__c pointing at that Account. Not part of the cron; see
# lib/tasks/accounts/remove_placeholder_school_students.rake.
class RemovePlaceholderSchoolStudents
  Stats = Struct.new(:deleted, :kept, :already_gone, :failed) do
    def initialize(*)
      super
      members.each { |member| self[member] ||= 0 }
    end
  end

  def self.call(dry_run: false)
    new(dry_run: dry_run).call
  end

  def initialize(dry_run: false)
    @dry_run = dry_run
  end

  def call
    stats = Stats.new

    affected_users.find_each do |user|
      process(user, stats)
    rescue StandardError => e
      stats.failed += 1
      Sentry.capture_exception(e, extra: { user_id: user.id })
    end

    Rails.logger.info("[RemovePlaceholderSchoolStudents] complete: #{stats.to_h}")
    stats
  end

  private

  attr_reader :dry_run

  def placeholder_school
    @placeholder_school ||= School.where('LOWER(name) = ?', School::PLACEHOLDER_NAME.downcase).first
  end

  def affected_users
    return User.none unless placeholder_school

    User.student
        .where(school_id: placeholder_school.id)
        .where.not(salesforce_student_id: nil)
  end

  def process(user, stats)
    student = OpenStax::Salesforce::Remote::Student.find(user.salesforce_student_id)

    if student.nil?
      stats.already_gone += 1
      clear_link(user)
      return
    end

    if student.school_id == placeholder_school.salesforce_id
      stats.deleted += 1
      unless dry_run
        student.destroy
        clear_link(user)
      end
    else
      stats.kept += 1
    end
  end

  def clear_link(user)
    return if dry_run

    user.update_columns(
      salesforce_student_id: nil,
      salesforce_student_pushed_at: nil,
      salesforce_student_last_seen_pushed_at: nil
    )
  end
end
