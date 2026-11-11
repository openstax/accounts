require 'rails_helper'

RSpec.describe ProfileHelper, type: :helper do
  describe '#email_entry' do
    it 'escapes the address rather than rendering it as markup' do
      html = helper.email_entry(value: '<img src=x onerror=alert(1)>@x.edu', id: 1,
                                is_verified: true, is_searchable: false)

      expect(html).not_to include('<img')
      expect(html).to include('&lt;img src=x onerror=alert(1)&gt;@x.edu')
    end
  end
end
