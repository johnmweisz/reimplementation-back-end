class CleanupStaleOidcRequestsJob < ApplicationJob
  queue_as :default

  # Deletes OidcRequest rows that are older than the 5-minute validity window,
  # meaning they were never consumed during the SSO callback flow.
  STALE_AFTER = 5.minutes

  def perform
    OidcRequest.where("created_at < ?", STALE_AFTER.ago).delete_all
  end
end