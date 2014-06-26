class BasketSubmitController < ApplicationController
  include CookieHelper
  include ActionController::Live

  before_filter :require_basket, only: :submit
  before_filter :load_config

  def submit
    @basket.update_attribute(:submitted, Time.now)
    provider = @cfg['order_by_fax'] ? @cfg['fax_provider'] : nil

    case provider
    when 'manual' then
      redirect_to pdf_basket_path(@basket.uid)
    when 'pdf24' then
      stream('submit_fax_pdf24')
    else
      cookie_set(:replay, "basket #{replay_mode} #{@basket.uid}")
      cookie_set(:mode, :pizzade_basket_submit)
      redirect_to_shop
    end
  end

  def test
    stream('test')
  end

  private

  def load_config
    @cfg = load_fax_config
  end
end
