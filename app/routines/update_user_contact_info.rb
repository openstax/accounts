# Thin shim around Salesforce::SyncContacts. Kept so cron entries and any
# rake/console callers continue to work without changes.
# See docs/superpowers/specs/2026-05-20-salesforce-sync-design.md.
class UpdateUserContactInfo
  def self.call
    Salesforce::SyncContacts.call
  end

  # Backwards compatibility for tests/callers that referenced the old class's
  # exception.
  UnknownFacultyVerifiedError = Salesforce::ResolveFacultyStatus::UnknownFacultyVerifiedError
end
