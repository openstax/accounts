require 'rails_helper'

describe InitialBookResolver, type: :routine do
  let(:book_remote) { OpenStax::Salesforce::Remote::Book }
  let(:salesforce_books) do
    [
      double(id: 'a0B000000000001', name: 'Psychology', osc_url: 'https://openstax.org/details/books/psychology'),
      double(id: 'a0B000000000002', name: 'Chemistry', osc_url: 'https://openstax.org/details/books/chemistry-2e'),
      double(id: 'a0B000000000003', name: 'Calculus', osc_url: 'https://openstax.org/details/books/calculus-volume-1'),
      double(id: 'a0B000000000004', name: 'Calculus Volume 1', osc_url: 'https://openstax.org/details/books/calculus-volume-1'),
      double(id: 'a0B000000000005', name: 'Astronomy', osc_url: nil)
    ]
  end
  let(:cms_slugs) do
    {
      'psychology-2e' => 'Psychology',
      'psychology' => 'Psychology',
      'calculus-volume-1' => 'Calculus Volume 1',
      'astronomy-2e' => 'Astronomy',
      'ghost-book' => 'Not In Salesforce'
    }
  end

  before do
    allow(book_remote).to receive(:all).and_return(instance_double(ActiveForce::ActiveQuery, to_a: salesforce_books))
    allow_any_instance_of(FetchBookData).to receive(:abbreviations_by_slug).and_return(cms_slugs)
  end

  def resolve(redirect)
    described_class.new.book_id_for_redirect(redirect)
  end

  it 'resolves an edition-suffixed slug through the CMS abbreviation' do
    expect(resolve('https://openstax.org/books/psychology-2e/pages/1-introduction')).to eq 'a0B000000000001'
  end

  it 'resolves a retired first-edition slug through the CMS' do
    expect(resolve('https://openstax.org/books/psychology/pages/1-introduction')).to eq 'a0B000000000001'
  end

  it 'resolves a book with no OSC URL through the CMS' do
    expect(resolve('https://openstax.org/books/astronomy-2e/pages/1')).to eq 'a0B000000000005'
  end

  it 'resolves a slug only Salesforce knows through the OSC URL' do
    expect(resolve('https://openstax.org/books/chemistry-2e/pages/1')).to eq 'a0B000000000002'
  end

  it 'lets the CMS settle a slug shared by two Book__c rows' do
    expect(resolve('https://openstax.org/details/books/calculus-volume-1')).to eq 'a0B000000000004'
  end

  it 'accepts the details/books URL form' do
    expect(resolve('https://openstax.org/details/books/psychology-2e')).to eq 'a0B000000000001'
  end

  it 'returns nil for an unknown slug, an abbreviation with no Book__c, a non-book URL or no redirect' do
    expect(resolve('https://openstax.org/books/underwater-basket-weaving/pages/1')).to be_nil
    expect(resolve('https://openstax.org/books/ghost-book/pages/1')).to be_nil
    expect(resolve('https://openstax.org/foo')).to be_nil
    expect(resolve(nil)).to be_nil
  end

  it 'builds the map once per instance' do
    resolver = described_class.new
    2.times { resolver.book_id_for_redirect('https://openstax.org/books/psychology-2e/pages/1') }

    expect(book_remote).to have_received(:all).once
  end

  context 'when the CMS returns nothing' do
    let(:cms_slugs) { {} }

    before { allow(Sentry).to receive(:capture_message) }

    it 'falls back to the OSC URLs and reports once' do
      resolver = described_class.new
      2.times do
        expect(resolver.book_id_for_redirect('https://openstax.org/books/chemistry-2e/pages/1')).to eq 'a0B000000000002'
      end
      expect(resolver.book_id_for_redirect('https://openstax.org/books/psychology-2e/pages/1')).to be_nil

      expect(Sentry).to have_received(:capture_message).once
    end
  end

  context 'when the CMS lookup raises' do
    before do
      allow_any_instance_of(FetchBookData).to receive(:abbreviations_by_slug).and_raise(StandardError)
      allow(Sentry).to receive(:capture_exception)
      allow(Sentry).to receive(:capture_message)
    end

    it 'does not raise and falls back to the OSC URLs' do
      expect(resolve('https://openstax.org/books/chemistry-2e/pages/1')).to eq 'a0B000000000002'
      expect(Sentry).to have_received(:capture_exception)
    end
  end

  describe '#book_id_for' do
    let(:user) { FactoryBot.create :user, role: :student }

    it 'uses the earliest student_signed_up log' do
      FactoryBot.create :security_log, user: user, event_type: :student_signed_up,
        event_data: { 'redirect' => 'https://openstax.org/books/psychology-2e/pages/1' }
      FactoryBot.create :security_log, user: user, event_type: :student_signed_up,
        event_data: { 'redirect' => 'https://openstax.org/books/chemistry-2e/pages/1' },
        created_at: 10.minutes.from_now

      expect(described_class.new.book_id_for(user)).to eq 'a0B000000000001'
    end

    it 'returns nil with no signup log' do
      expect(described_class.new.book_id_for(user)).to be_nil
    end
  end
end
