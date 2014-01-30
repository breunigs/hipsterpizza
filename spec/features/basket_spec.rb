# encoding: utf-8

require 'spec_helper'

describe 'Basket', js: true do
  subject { page }

  #~　let!(:reviewer) { FactoryGirl.create(:reviewer) }
  #~　before { sign_in reviewer, true }

  it 'allows to create basket for some shop' do
    visit root_path
    click_link 'Create New Basket'


  end

  #~　it "should show outdated reviews with the updated filter" do
    #~　rev = FactoryGirl.create(:review)
    #~　rev.user = reviewer
    #~　rev.updated_at = rev.question.content_changed_at - 100000
    #~　rev.created_at = rev.question.content_changed_at - 100000
    #~　rev.save!
#~　
    #~　visit review_filter_path(:updated)
    #~　page.should have_content(rev.question.parent.title, visible: true)
    #~　page.should have_link(rev.question.ident, visible: false)
  #~　end
end
