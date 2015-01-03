require 'spec_helper'

RSpec.describe 'basket/_submitted_status', type: :view do
  context 'basket has been submitted' do
    before(:all) do
      b = FactoryGirl.create(:basket_with_orders, submitted: Time.now)
      assign(:basket, b)
    end

    it 'shows basket has been submitted' do
      render
      expect(rendered).to have_text I18n.t('basket.submitted_status.submitted')
    end

    it 'shows that it can’t estimate' do
      render
      expect(rendered).to have_text I18n.t('basket.submitted_status.no_estimate')
    end

    it 'shows an estimate if data is available' do
      allow_any_instance_of(Basket).to receive(:estimate).and_return([120, 5])
      render
      expect(rendered).to have_text I18n.t('basket.submitted_status.estimate')
      expect(rendered).to have_text I18n.t('basket.submitted_status.bar.togo', minutes: 120/60)
    end
  end

end
