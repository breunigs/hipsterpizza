require 'spec_helper'

describe OrderController, type: :controller do
  let(:basket) { FactoryGirl.create(:basket_with_orders) }
  let(:order) { basket.orders.first }

  def get_with_params(resource)
    get resource, basket_id: basket.uid, order_id: order.uuid
  end

  def post_with_params(resource)
    get resource, basket_id: basket.uid, order_id: order.uuid
  end

  describe '#new' do
    it 'redirects to shop' do
      get :new, basket_id: basket.uid
      # TODO: clean up once "redirect_to_shop" does not include pizza.de
      # specific parameters
      expect(response.redirect_url).to include basket.full_path
    end

    it 'sets mode cookie' do
      get :new, basket_id: basket.uid
      expect(cookies['_hipsterpizza_mode']).to include 'order_new'
    end
  end

  describe '#edit' do
    it 'sets mode cookie' do
      get_with_params :edit
      expect(cookies['_hipsterpizza_mode']).to include 'order_edit'
    end

    it 'sets replay cookie' do
      get_with_params :edit
      expect(cookies['_hipsterpizza_replay']).to eql "order nocheck #{order.uuid}"
    end

    it 'redirects to shop' do
      get_with_params :edit
      # TODO: clean up once "redirect_to_shop" does not include pizza.de
      # specific parameters
      expect(response.redirect_url).to include basket.full_path
    end

  end

  describe '#save' do
    it 'creates a saved order' do
      expect {
        post_with_params :save
      }.to change { SavedOrder.count }.by(1)
    end

    it 'stores nick in saved order if available' do
      cookies['_hipsterpizza_nick'] = 'Derpina'
      post_with_params :save
      expect(SavedOrder.first.nick).to eql 'Derpina'
    end

    it 'instructs JS to disable the button' do
      post_with_params :save
      expect(JSON.parse(response.body)).to include("disable" => true)
    end

    it 'creates a saved order with matching JSON' do
      post_with_params :save
      expect(SavedOrder.first.json).to eql order.json
    end

    it 'reports an error if JSON is invalid' do
      order.json = ' { incorrect'
      order.save(validate: false)
      post_with_params :save
      expect(JSON.parse(response.body)).to include("error")
    end
  end

  # def update
  #   old_pay     = @order.paid? ? @order.sum : 0
  #   old_pay_tip = @order.paid? ? @order.sum_with_tip : 0

  #   @order.json = params[:json]

  #   if @order.save
  #     pay = @order.sum - old_pay
  #     pay_tip = @order.sum_with_tip - old_pay_tip

  #     handle_price_difference(pay, pay_tip)
  #   else
  #     flash_error_msgs(@order)
  #   end

  #   redirect_to @basket
  # end

  # def create
  #   @order = Order.new(params.permit(:nick, :json))
  #   @order.basket_id = @basket.id

  #   if @order.save
  #     price = render_to_string 'order/_price', layout: false
  #     flash[:info] = t('order.controller.create', price: price).html_safe
  #   else
  #     flash_error_msgs(@order)
  #   end
  #   redirect_to @basket
  # end

  # def toggle_paid
  #   @order.toggle(:paid).save
  #   if request.xhr?
  #     return render json: {}
  #   else
  #     key = "order.controller.toggle_paid.#{@order.paid? ? 'is' : 'not'}_paid"
  #     flash[:info] = t(key, nick: @order.nick.possessive)
  #     return redirect_to @basket
  #   end
  # end

  # def destroy
  #   unless view_context.my_order? || view_context.admin?
  #     flash[:warn] = I18n.t('order.controller.destroy.admin_required')
  #     return redirect_to @basket
  #   end

  #   i18n_key = view_context.my_order? ? 'my_order' : 'other_order'
  #   flash[:info] = I18n.t("order.controller.destroy.#{i18n_key}")

  #   if @order.paid?
  #     price = render_to_string 'order/_price', layout: false
  #     flash[:info] << ' ' << I18n.t('order.controller.money.take', price: price)
  #   end

  #   @order.destroy!
  #   redirect_to @basket
  # end

  # def copy
  #   if @order.updated_at > 1.hour.ago && replay_mode == 'insta'
  #     params[:json] = @order.json
  #     params[:nick] = @nick
  #     return create
  #   else
  #     cookie_set(:replay, "order #{replay_mode} #{@order.uuid}")
  #     cookie_set(:mode, :pizzade_order_new)
  #     redirect_to_shop
  #   end
  # end

  # private

  # def ensure_basket_editable
  #   if @basket.cancelled?
  #     flash[:error] = I18n.t('order.controller.cancelled')
  #     redirect_to @basket
  #   elsif @basket.submitted?
  #     prefix = 'order.controller.already_submitted'
  #     flash[:error] = I18n.t("#{prefix}.main")
  #     flash[:error] << I18n.t("#{prefix}.has_order", order: @order) if @order
  #     redirect_to @basket
  #   end
  # end

  # def flash_error_msgs(order)
  #   return if order.errors.none?
  #   msgs = errors_to_fake_list(order)
  #   flash[:error] = I18n.t('order.controller.failure', msgs: msgs)
  # end

  # def handle_price_difference(pay, pay_tip)
  #   i18n_key = if pay == 0
  #     'no_change'
  #   elsif pay < 0
  #     'take'
  #   else
  #     @order.update_attribute(:paid, false)
  #     'give'
  #   end

  #   fake = OpenStruct.new(sum: pay, sum_with_tip: pay_tip)
  #   price = render_to_string 'order/_price', layout: false, order: fake

  #   flash[:info] = I18n.t('order.controller.update') << ' '
  #   flash[:info] << I18n.t("order.controller.money.#{i18n_key}", price: price)
  # end

  # def require_order
  #   @order = Order.friendly.find(params[:order_id]) rescue nil
  #   return if @order
  #   flash[:error] = t('order.controller.invalid_uuid')
  #   redirect_to @basket
  # end
end
