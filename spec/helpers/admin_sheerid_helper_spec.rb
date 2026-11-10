require 'rails_helper'

describe AdminSheeridHelper, type: :helper do
  describe '#sheerid_step_badge' do
    def badge_for(step, error_ids: [])
      verification = FactoryBot.build(:sheerid_verification,
                                      current_step: step, error_ids: error_ids)
      helper.sheerid_step_badge(verification)
    end

    def label(style, text)
      %(<span class="label label-#{style}">#{text}</span>)
    end

    it 'maps the SheerID steps to a label and a style' do
      expect(badge_for(SheeridVerification::VERIFIED)).to eq label('success', 'Verified')
      expect(badge_for(SheeridVerification::REJECTED)).to eq label('danger', 'Rejected')
      expect(badge_for(SheeridVerification::PENDING))
        .to eq label('warning', 'Pending document review')
      expect(badge_for(SheeridVerification::ERROR)).to eq label('danger', 'Error')
    end

    it 'calls an expired error Expired' do
      badge = badge_for(SheeridVerification::ERROR,
                        error_ids: [SheeridVerification::EXPIRED_ERROR_ID])
      expect(badge).to eq label('danger', 'Expired')
    end

    it 'shows an unmapped step as-is' do
      expect(badge_for('somethingNew')).to eq label('default', 'somethingNew')
    end
  end

  describe '#sheerid_activity_event_types' do
    it 'includes the school-match and faculty-status ladder events, not just sheerid_' do
      expect(helper.sheerid_activity_event_types).to include(
        'sheerid_webhook_pending', 'fv_success_by_sheerid',
        'school_added_to_user_from_sheerid_webhook', 'faculty_status_advanced',
        'faculty_status_downgrade_refused', 'user_not_viable_for_sheerid'
      )
      expect(helper.sheerid_activity_event_types).not_to include('sign_in_successful')
    end
  end

  describe '#sheerid_event_name' do
    it 'spells SheerID properly' do
      log = SecurityLog.new(event_type: :sheerid_webhook_received)
      expect(helper.sheerid_event_name(log)).to eq 'SheerID webhook received'
    end
  end

  describe '#sheerid_event_details' do
    it 'returns nil when nothing but the verification id or blanks is present' do
      expect(helper.sheerid_event_details({})).to be_nil
      expect(helper.sheerid_event_details('verification_id' => 'abc', 'error_ids' => [])).to be_nil
    end

    it 'renders labelled pairs and collapses a school hash to its name' do
      html = helper.sheerid_event_details(
        'verification_id' => 'abc',
        'current_step' => 'docUpload',
        'school' => { 'id' => 1, 'name' => 'Rice' }
      )
      expect(html).to include('current step: </span>docUpload')
      expect(html).to include('school: </span>Rice')
      expect(html).not_to include('abc')
    end
  end
end
