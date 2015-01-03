require 'spec_helper'

RSpec.describe 'nav/_main', type: :view do
  let(:basket) { FactoryGirl.create(:basket) }

  before { assign(:basket, basket) }

  context 'not admin' do
    it 'displays become admin link' do
      render
      expect(rendered).to have_link I18n.t('nav.main.other.become_admin.link')
    end

    it 'does not display admin menu' do
      render
      text = Regexp.quote I18n.t('nav.admin.admin')
      expect(rendered).not_to have_link(/^#{text}$/)
    end
  end

  context 'admin' do
    before { allow(view).to receive(:admin?).and_return(true) }
    before { allow(view).to receive(:params).and_return({controller: 'basket'}) }

    it 'displays disable admin link' do
      render
      expect(rendered).to have_link I18n.t('nav.main.other.unbecome_admin')
    end

    it 'displays admin menu' do
      render
      expect(rendered).to have_link I18n.t('nav.admin.admin')
    end

    it 'has cancel link' do
      render
      expect(rendered).to have_link I18n.t('button.cancel.do')
    end

    it 'has submit link' do
      render
      expect(rendered).to have_link I18n.t('button.submit_group_order.first_time.text')
    end

    context 'cancelled basket' do
      before do
        basket.cancelled = true
        basket.save
        assign(:basket, basket)
      end

      it 'has un-cancel link' do
        render
        expect(rendered).to have_link I18n.t('button.cancel.undo')
      end

      it 'does not have submit link' do
        render
        expect(rendered).not_to have_link I18n.t('button.submit_group_order.first_time.text')
      end

    end
  end

end
