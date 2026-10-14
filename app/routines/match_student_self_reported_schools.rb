# One-time (rerunnable) backfill resolving students' typed-but-unmatched
# self_reported_school against Schools, so the nightly PushUserActivityToSalesforce
# (which only ever creates a Student__c for users with a school_id) has something
# to push for them. Not part of the cron; see
# lib/tasks/accounts/match_student_self_reported_schools.rake.
class MatchStudentSelfReportedSchools
  Stats = Struct.new(:names, :matched_names, :unmatched_names, :students_matched) do
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

    self_reported_names.each do |name|
      stats.names += 1

      school = School.match_self_reported(name)
      unless school
        stats.unmatched_names += 1
        next
      end

      stats.matched_names += 1
      stats.students_matched += update_students(name, school.id)
    end

    Rails.logger.info("[MatchStudentSelfReportedSchools] complete: #{stats.to_h}")
    stats
  end

  private

  attr_reader :dry_run

  def scope
    User.student.where(school_id: nil).where.not(self_reported_school: [nil, ''])
  end

  def self_reported_names
    scope.distinct.pluck(:self_reported_school)
  end

  # One update_all per distinct name: every student who typed the same string
  # resolves to the same School, so there's no reason to match per student.
  def update_students(name, school_id)
    students = scope.where(self_reported_school: name)
    return students.count if dry_run

    students.update_all(school_id: school_id)
  end
end
