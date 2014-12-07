require 'spec_helper'

RSpec.describe 'nav/_main', type: :view do
  before do
    assign(:basket, FactoryGirl.build_stubbed(:basket))
  end

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

    it 'displays disable admin link' do
      render
      expect(rendered).to have_link I18n.t('nav.main.other.unbecome_admin')
    end

    it 'displays admin menu' do
      render
      expect(rendered).to have_link I18n.t('nav.admin.admin')
    end
  end

end
