# The "Finish setting up" link is a plain page navigation, so there is no
# server-side request afterwards to hang a PostHog capture on -- fire it here
# instead, guarded the same way editable_error.coffee guards its own capture
# call (window.posthog may not have loaded, e.g. if the person has an ad
# blocker or hasn't consented to analytics).
$ ->
  $('.profile-nudge-banner__finish').on 'click', ->
    window.posthog?.capture('educator_profile_nudge_banner_clicked')
