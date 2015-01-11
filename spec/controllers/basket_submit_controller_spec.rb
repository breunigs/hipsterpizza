require 'spec_helper'

RSpec.shared_examples 'sets_submit_time' do
  it 'sets submitted time' do
    expect(basket.submitted).to be_nil
    patch :submit, id: basket.uid
    basket.reload
    expect(basket.submitted).not_to be_nil
  end
end

describe BasketSubmitController, type: :controller do
  let(:basket) { FactoryGirl.create(:basket) }

  describe '#submit' do
    context '“manual” provider' do
      before do
        cfg = { 'order_by_fax' => true, 'fax_provider' => 'manual' }
        allow(controller).to receive(:fax_config).and_return(cfg)
      end

      include_examples 'sets_submit_time'

      it 'redirects to PDF' do
        patch :submit, id: basket.uid
        expect(response).to redirect_to pdf_basket_path
      end
    end

    context '“pdf24” provider' do
      before do
        cfg = {
          'order_by_fax' => true,
          'fax_provider' => 'pdf24',
          'pdf24_mail' => 'fake',
          'pdf24_pass' => 'fake'
        }
        # allow(controller).to receive(:fax_config).and_return(cfg)
        # make @fax_config available to the templates
        controller.instance_variable_set(:@fax_config, cfg)
      end

      # Not testing the time setting because the thread may get stuck:
      # https://github.com/rails/rails/issues/10989
      # include_examples 'sets_submit_time'

      it 'fails at login stage' do
        patch :submit, id: basket.uid
        expect(response.body).to have_text 'Logging In 1/2 ✗'
        expect(response.body).to have_text 'Return To Basket'
      end
    end

    context 'using shop’s web interface' do
      before { allow(controller).to receive(:fax_config).and_return({}) }

      it 'sets correct cookies' do
        patch :submit, id: basket.uid
        expect(cookies['_hipsterpizza_replay']).to eql "basket check #{basket.uid}"
        expect(cookies['_hipsterpizza_mode']).to eql 'pizzade_basket_submit'
      end

      it 'redirects to shop' do
        patch :submit, id: basket.uid
        # TODO: clean up once "redirect_to_shop" does not include pizza.de
        # specific parameters
        expect(response.redirect_url).to include basket.full_path
      end
    end
  end
end
