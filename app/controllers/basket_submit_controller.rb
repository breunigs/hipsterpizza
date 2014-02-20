class BasketSubmitController < ApplicationController
  include CookieHelper
  include ActionController::Live

  before_filter :find_basket

  def submit
    @basket.update_column(:submitted, Time.now)
    @cfg = load_fax_config
    provider = @cfg['order_by_fax'] ? @cfg['fax_provider'] : nil

    case provider
    when 'manual' then
      redirect_to pdf_basket_path(@basket.uid)
    when 'pdf24' then
      @cfg = load_fax_config
      stream('submit_fax_pdf24')
    else
      cookie_set(:replay, "basket #{get_replay_mode} #{@basket.uid}")
      cookie_set(:action, :submit_group_order)
      redirect_to_shop
    end
  end
end
