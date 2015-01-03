require 'spec_helper'

RSpec.shared_examples 'uneditable_basket' do
  it 'does not have My Order dropdown' do
    render
    expect(rendered).not_to have_text I18n.t('basket.my_order.dropdown')
  end

  it 'does not have copy in order table' do
    render
    expect(rendered).not_to have_text I18n.t('button.copy_order.button')
  end

  it 'allows to toggle paid status' do
    render
    expect(rendered).to have_text I18n.t('button.toggle_paid.not_paid.button')
  end
end

RSpec.shared_examples 'submitted_basket' do
  it 'renders delivery estimate progress bar' do
    render
    expect(rendered).to render_template 'basket/_submitted_status'
  end
end

RSpec.describe 'basket/show', type: :view do
  let(:submitted_basket) { FactoryGirl.create(:basket_with_orders, submitted: Time.now) }
  let(:cancelled_basket) { FactoryGirl.create(:basket_with_orders, cancelled: true) }
  let(:arrived_basket) { FactoryGirl.create(:basket_with_orders, submitted: 10.minutes.ago, arrival: Time.now) }

  context 'basket has been submitted' do
    before do
      assign(:basket, submitted_basket)
      assign(:order, submitted_basket.orders.first)
    end

    it_behaves_like 'uneditable_basket'
    it_behaves_like 'submitted_basket'
  end

  context 'delivery has arrived' do
    before do
      assign(:basket, arrived_basket)
      assign(:order, arrived_basket.orders.first)
    end

    it_behaves_like 'uneditable_basket'
    it_behaves_like 'submitted_basket'
  end

  context 'basket has been cancelled' do
    before do
      assign(:basket, cancelled_basket)
      assign(:order, cancelled_basket.orders.first)
    end

    it_behaves_like 'uneditable_basket'

    it 'shows “was cancelled” message' do
      render
      expect(rendered).to have_text I18n.t('basket.cancelled.heading')
      expect(rendered).to have_text I18n.t('basket.cancelled.body')
    end
  end
end
