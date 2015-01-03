require 'spec_helper'

describe BasketController, type: :controller do
  let(:basket) { FactoryGirl.create(:basket) }
  let(:order) do
    o = FactoryGirl.build(:order)
    o.basket = basket
    o.save
    o
  end

  describe '#new' do
    context 'pinning' do
      include_context 'pinning'

      it 'redirects to existing, editable basket' do
        PINNING['single_basket_mode'] = true
        expect(basket.editable?).to eql true

        get :new

        expect(response).to redirect_to basket
      end

      it 'directly creates new basket if all needed fields are pinned' do
        PINNING['shop_name'] = 'Pinned Shop'
        PINNING['shop_url'] = '/hipster/pinned_shop/fake'
        PINNING['shop_fax'] = '+490000000000000'

        get :new
        basket = Basket.first

        expect(basket).not_to be_nil
        expect(response).to redirect_to share_basket_path(basket)
      end

      it 'redirects to pinned shop URL' do
        PINNING['shop_url'] = '/hipster/pinned_shop/fake'
        get :new
        expect(response.redirect_url).to include '/hipster/pinned_shop/fake'
      end
    end

    it 'redirects to Pizza.de root path' do
      get :new
      expect(response).to redirect_to root_service_path(:pizzade)
    end

    it 'sets correct mode cookie' do
      get :new
      expect(cookies['_hipsterpizza_mode']).to eql 'pizzade_basket_new'
    end

  end

  describe '#create' do
    let(:params) { FactoryGirl.attributes_for(:basket) }

    it 'creates new basket' do
      post :create, params
      expect(Basket.first).not_to be_nil
    end

    it 'sets admin cookie' do
      post :create, params
      expect(cookies['_hipsterpizza_is_admin']).to eql 'true'
    end

    it 'redirects to share page' do
      post :create, params
      expect(response).to redirect_to share_basket_path(Basket.first)
    end

    it 'complains about missing fields' do
      post :create
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to root_path
    end

    context 'pinning' do
      include_context 'pinning'

      it 'skips share page in single basket mode' do
        PINNING['single_basket_mode'] = true
        post :create, params
        expect(response).to redirect_to basket_path(Basket.first)
      end
    end
  end

  describe '#show' do
    it 'finds order if present' do
      cookies['_hipsterpizza_nick'] = order.nick
      get :show, id: basket.uid
      expect(assigns(:order)).to eq(order)
    end

    it 'renders basket overview' do
      get :show, id: basket.uid
      expect(response).to render_template :show
    end

    it 'renders a SVG QR Code' do
      get :show, id: basket.uid, format: 'svg'
      expect(response.body).to include '<svg'
      expect(response.body).to include '<?xml'
    end

    it 'renders only when updating on XHR' do
      xhr :get, :show, id: basket.uid
      expect(response.status).to eql 200

      xhr :get, :show, id: basket.uid, ts_basket: Time.now.to_i
      expect(response.status).to eql 204
    end
  end

  describe '#unsubmit' do
    it 'requires admin rights' do
      get :unsubmit, id: basket.uid
      expect(flash[:error]).to be_present
      expect(response).to redirect_to basket
    end

    context 'as admin' do
      include_context 'admin'

      it 'redirects back to basket' do
        get :unsubmit, id: basket.uid
        expect(response).to redirect_to basket
      end

      it 'resets the basket’s submitted time' do
        basket.submitted = Time.now
        basket.save

        get :unsubmit, id: basket.uid

        basket.reload
        expect(basket.submitted?).to eq false
      end

      it 'shows an info message' do
        get :unsubmit, id: basket.uid
        expect(flash[:info]).to be_present
      end
    end
  end

  describe '#set_submit_time' do
    it 'requires admin rights' do
      post :set_submit_time, id: basket.uid
      expect(flash[:error]).to be_present
      expect(response).to redirect_to basket
    end

    context 'as admin' do
      include_context 'admin'

      it 'updates submitted timestamp' do
        post :set_submit_time, id: basket.uid

        basket.reload
        expect(basket.submitted).not_to be_nil
      end

      it 'accepts and stores SHA addresses' do
        post :set_submit_time, id: basket.uid, sha_address: 'sha123'

        basket.reload
        expect(basket.sha_address).to eql 'sha123'
      end
    end
  end

  describe '#delivery_arrived' do
    let(:time) { Time.now }

    it 'updates arrival time' do
      xhr :patch, :delivery_arrived, id: basket.uid, arrival: time
      basket.reload
      expect(basket.arrival.to_i).to eql time.to_i
    end

    it 'instructs JS to reload page' do
      xhr :patch, :delivery_arrived, id: basket.uid, arrival: time
      expect(response.body).to include('reload')
    end

    it 'sets arrival time to “now” if time string is invalid' do
      old = Time.now
      xhr :patch, :delivery_arrived, id: basket.uid, arrival: "timely wimely"

      basket.reload
      expect(basket.arrival.to_i).to be_between(old.to_i, Time.now.to_i)
    end

    it 'shows an error if time string is invalid' do
      xhr :patch, :delivery_arrived, id: basket.uid, arrival: "timely wimely"

      expect(flash[:error]).to be_present
    end
  end

  describe '#share' do
    it 'renders' do
      get :share, id: basket.uid
      expect(response).to render_template :share
      expect(response.status).to eql 200
    end
  end

  describe '#toggle_cancelled' do
    it 'requires admin rights' do
      patch :toggle_cancelled, id: basket.uid
      expect(flash[:error]).to be_present
      expect(response).to redirect_to basket
    end

    context 'as admin' do
      include_context 'admin'

      it 'redirects to basket' do
        patch :toggle_cancelled, id: basket.uid
        expect(response).to redirect_to basket
      end

      it 'shows an error if status could not be toggled' do
        allow_any_instance_of(Basket).to receive(:save).and_return(false)
        patch :toggle_cancelled, id: basket.uid
        expect(flash[:error]).to be_present
      end

      context 'not canceled' do
        it 'shows a warning on canceling' do
          patch :toggle_cancelled, id: basket.uid
          expect(flash[:warn]).to be_present
        end

        it 'updates the basket to be canceled' do
          patch :toggle_cancelled, id: basket.uid
          basket.reload
          expect(basket.cancelled?).to eql true
        end
      end

      context 'already cancelled' do
        before do
          basket.cancelled = true
          basket.save
        end

         it 'shows a success message on re-enabling' do
          patch :toggle_cancelled, id: basket.uid
          expect(flash[:success]).to be_present
        end

        it 'updates the basket to not be canceled anymore' do
          patch :toggle_cancelled, id: basket.uid
          basket.reload
          expect(basket.cancelled?).to eql false
        end
      end
    end
  end

  describe '#pdf' do
    before { get :pdf, id: basket.uid }

    it 'renders' do
      expect(response.status).to eql 200
    end

    it 'sets correct content type' do
      expect(response.headers['Content-Type']).to eql 'application/pdf'
    end

    it 'appears to be a PDF' do
      expect(response.body).to start_with '%PDF-1.'
    end
  end

  describe '#find_changes' do
    before(:all) do
      BC = BasketController.new
      @basket = Basket.new
      BC.instance_variable_set(:@basket, @basket)
    end

    before do
      @basket.updated_at = Time.now
      BC.params = {}
    end

    it 'reports newer @basket timestamp as change' do
      BC.params = { ts_basket: (Time.now - 1.minute).to_i }
      BC.send(:find_changes)
      expect(BC.instance_variable_get(:@basket_changed)).to be true
    end

    it 'doesn’t report equal @basket timestamp as change' do
      BC.params = { ts_basket: @basket.updated_at.to_i }
      BC.send(:find_changes)
      expect(BC.instance_variable_get(:@basket_changed)).to be false
    end

    it 'doesn’t report older @basket timestamp as change' do
      BC.params = { ts_basket: (Time.now + 1.minute).to_i }
      BC.send(:find_changes)
      expect(BC.instance_variable_get(:@basket_changed)).to be false
    end

    it 'reports deleted @order as change' do
      BC.params = { ts_order: Time.now.to_i }
      BC.send(:find_changes)
      expect(BC.instance_variable_get(:@order_changed)).to be true
    end

    context 'with @order' do
      before(:all) do
        @order = Order.new
        BC.instance_variable_set(:@order, @order)
      end

      before do
        @order.updated_at = Time.now
      end

      it 'reports new @order as change' do
        BC.send(:find_changes)
        expect(BC.instance_variable_get(:@order_changed)).to be true
      end

      it 'doesn’t report older @order timestamp as change' do
        BC.params = { ts_order: (Time.now + 1.minute).to_i }
        BC.send(:find_changes)
        expect(BC.instance_variable_get(:@order_changed)).to be false
      end
    end
  end
end
