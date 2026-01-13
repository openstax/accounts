require 'rails_helper'

describe Settings::Recaptcha, type: :lib do
  describe '.disabled?' do
    it 'returns the value from Settings::Db.store.disable_recaptcha' do
      Settings::Db.store.disable_recaptcha = false
      expect(Settings::Recaptcha.disabled?).to eq(false)

      Settings::Db.store.disable_recaptcha = true
      expect(Settings::Recaptcha.disabled?).to eq(true)
    end
  end

  describe '.disabled=' do
    it 'sets the disable_recaptcha value in Settings::Db.store' do
      Settings::Recaptcha.disabled = true
      expect(Settings::Db.store.disable_recaptcha).to eq(true)

      Settings::Recaptcha.disabled = false
      expect(Settings::Db.store.disable_recaptcha).to eq(false)
    end
  end

  describe '.enabled?' do
    it 'returns the opposite of disabled?' do
      Settings::Db.store.disable_recaptcha = false
      expect(Settings::Recaptcha.enabled?).to eq(true)

      Settings::Db.store.disable_recaptcha = true
      expect(Settings::Recaptcha.enabled?).to eq(false)
    end
  end
end
