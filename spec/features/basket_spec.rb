# encoding: utf-8

require 'spec_helper'

describe 'Basket' do
  submit_link = I18n.t('button.submit_group_order.first_time.text')

  before do
    @basket = basket_create
  end

  it 'can be created' do
    expect(page).to have_content I18n.t('basket.share.heading')
    expect(page).to have_content basket_path(@basket)

    click_on I18n.t('basket.share.basket_link')
    expect(page).to have_link I18n.t('basket.new_order_button.link')
    expect(page).to have_link I18n.t('nav.admin.admin')
  end

  it 'can be cancelled' do
    visit basket_path(@basket)
    click_on I18n.t('nav.admin.admin')
    click_link I18n.t('button.cancel.do')

    expect(page).to have_content I18n.t('basket.controller.group_order.cancelled')
    open_admin_menu
    expect(page).to have_link I18n.t('button.cancel.undo')
    expect(page).not_to have_link submit_link

    click_link I18n.t('button.cancel.undo')

    open_admin_menu
    expect(page).to have_link submit_link
  end

  it 'is submittable' do
    visit basket_path(@basket)
    order_create

    open_admin_menu(submit_link)
    wait_for_progress_done

    within('#bestellform') do
      expect(page).to have_content 'Chicken Curry'
      expect(page).to have_field 'Nachname'

      fill_in 'Nachname', with: 'Tést 123'
      # don’t care, only need to blur Nachname field
      fill_in 'Vorname', with: 'asd'
    end

    click_on I18n.t('modes.basket_submit.cancel.button')
    expect(page).to have_content I18n.t('basket.controller.reopened')
    expect(page).to have_link I18n.t('nav.admin.admin')

    open_admin_menu(submit_link)
    wait_for_progress_done
    expect(find_field('Nachname').value).to eq 'Tést 123'
  end

  it 'doesn’t show any edit or destroy links after submit' do
    visit basket_path(@basket)
    order_create
    open_admin_menu(submit_link)
    visit basket_path(@basket)

    def check_links
      expect(page).not_to have_link I18n.t('basket.my_order.dropdown')
      click_on I18n.t('order_table.menu')
      expect(page).not_to have_content(I18n.t('button.copy_order.button'))
      # close menu again in order to not interfere with other clicks
      find('body').click
    end

    check_links

    click_delivery_arrived_button

    check_links
  end

  it 'allows users to become admins' do
    # we’re on the share basket page
    click_on I18n.t('basket.share.basket_link')
    basket_url = current_url
    expect(page).to have_link I18n.t('nav.admin.admin')

    Capybara.reset_sessions!
    visit basket_url
    expect(page).not_to have_link I18n.t('nav.admin.admin')

    click_on I18n.t('other')
    click_on I18n.t('nav.main.other.become_admin.link')

    expect(page).to have_link I18n.t('nav.admin.admin')
  end

  it 'doesn’t show admin menu to users' do
    visit_basket_as_new_user
    expect(page).not_to have_content I18n.t('nav.admin.admin')
  end

  it 'shows a delivery time estimate' do
    visit basket_path(@basket)
    order_create

    open_admin_menu(submit_link)
    visit basket_path(@basket)

    expect(page).to have_content I18n.t('basket.submitted_status.submitted')

    click_delivery_arrived_button
    reload
    wait_until_content I18n.t('basket.submitted_status.arrived')
    # actually this would be basket.submitted_status.bar.done, but since the
    # string includes a variable, manually match it here
    expect(page).to have_content 'NOM NOM NOM!'

    # second basket, should be able to print an estimate now
    basket_with_order_create

    open_admin_menu(submit_link)
    visit basket_path(@basket)
    expect(page).to have_content I18n.t('basket.submitted_status.estimate')
  end

  it 'sets correct submit time' do
    visit basket_path(@basket)
    open_admin_menu(submit_link)
    click_on I18n.t('modes.basket_submit.update_time.button')
    expect(page).to have_content 'less than a minute ago'
  end

  it 'can render a pdf' do
    visit basket_path(@basket)
    order_create

    open_admin_menu(I18n.t('nav.admin.render_pdf'))
    expect(page.html).to start_with('%PDF-1')
    # This is always true due to a bug in Rails. See
    # https://github.com/rails/rails/pull/14000
    expect(page.status_code).to eql(200)
  end

  private

  def click_delivery_arrived_button
    page.driver.js_prompt_input = Time.now
    page.driver.accept_js_prompts!
    click_on I18n.t('button.delivery_arrived.button')
  end
end
