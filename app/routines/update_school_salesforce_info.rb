# Thin shim around Salesforce::SyncSchools. Kept so cron entries and any
# rake/console callers continue to work without changes.
class UpdateSchoolSalesforceInfo
  # Re-export constants for existing specs/code that referenced them.
  BATCH_SIZE = Salesforce::SyncSchools::BATCH_SIZE
  SF_TO_DB_CACHE_COLUMNS_MAP = Salesforce::SyncSchools::SF_TO_DB_CACHE_COLUMNS_MAP

  def self.call
    Salesforce::SyncSchools.call
  end
end
