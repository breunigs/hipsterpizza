require 'spec_helper'

describe Basket, type: :model do
  let(:basket) { FactoryGirl.build(:basket) }
  let(:basket_with_orders) { FactoryGirl.create(:basket_with_orders) }
  let(:order) { FactoryGirl.build(:order) }

  it 'can be created' do
    expect(basket.save).to be true
    expect(basket.uid).not_to be nil
    expect(basket.uid).not_to be 'new'
  end

  describe '#full_path' do
    it 'starts with /' do
      expect(basket.full_path).to start_with '/'
    end

    it 'includes URL parameters saved on Basket creation' do
      basket.shop_url_params = '?is_test=1&more_test=2'
      path = basket.full_path

      expect(path).to include 'is_test=1'
      expect(path).to include 'more_test=2'
      expect(path.count('?')).to eql 1
    end

    it 'includes parameters given to the function' do
      basket.shop_url_params = '?is_test=1&more_test=2'
      path = basket.full_path(passed: 1, more_passed: 2)

      expect(path).to include 'passed=1'
      expect(path).to include 'more_passed=2'
      expect(path).to include 'is_test=1'
      expect(path).to include 'more_test=2'
      expect(path.count('?')).to eql 1
    end
  end

  describe '#shop_url_params_hash' do
    it 'returns an empty hash if none set' do
      basket.shop_url_params = nil
      expect(basket.shop_url_params_hash).to eql({})
    end

    it 'parses the query string properly' do
      basket.shop_url_params = '?some=1&params=2'
      expect(basket.shop_url_params_hash).to include('some' => '1', 'params' => '2')
    end
  end

  describe '#arrived?' do
    it 'is true, when arrival date is set' do
      basket.arrival = Time.now
      expect(basket.arrived?).to eql true
    end

    it 'is false, when arrival date not set' do
      basket.arrival = nil
      expect(basket.arrived?).to eql false
    end
  end

  describe '#duration' do
    before do
      t = Time.now
      basket.submitted = t
      basket.arrival = t + 5.minutes
    end

    it 'is nil when not submitted' do
      basket.submitted = nil
      expect(basket.duration).to be_nil
    end

    it 'is nil when not arrived' do
      basket.arrival = nil
      expect(basket.duration).to be_nil
    end

    it 'is nil when duration would be negative' do
      basket.arrival, basket.submitted = basket.submitted, basket.arrival
      expect(basket.duration).to be_nil
    end

    it 'returns time difference between submission and arrival' do
      expect(basket.duration).to eql 5.minutes.to_f
    end
  end

  describe '#duration_per_euro' do
    it 'calculates properly' do
      expect(basket).to receive(:sum).twice.and_return 13.37
      expect(basket).to receive(:duration).and_return 5.minutes

      # i.e. each euro took roughly 22 seconds
      expect(basket.duration_per_euro).to be_within(1).of(22)
    end

    it 'handles 0 sum orders' do
      expect(basket).to receive(:sum).and_return 0
      expect(basket.duration_per_euro).to be_nil
    end
  end

  describe '#editable?' do
    it 'is true when neither submitted nor cancelled' do
      basket.submitted = nil
      basket.cancelled = false
      expect(basket.editable?).to eql true
    end

    it 'is false after submission' do
      basket.submitted = Time.now
      expect(basket.editable?).to eql false
    end

    it 'is false after cancellation' do
      basket.cancelled = true
      expect(basket.editable?).to eql false
    end
  end

  describe '#sum' do
    it 'is the sum of all its orders' do
      expect(basket.sum).to be_within(0.001).of(0.0)
      # basket_with_orders has the same order, two times
      expect(basket_with_orders.sum).to be_within(0.001).of(order.sum * 2)
    end
  end

  describe '#sum_paid' do
    it 'is the sum of all its paid orders' do
      expect(basket.sum_paid).to be_within(0.001).of(0.0)

      basket_with_orders.orders.first.toggle(:paid).save!
      expect(basket_with_orders.sum_paid).to be_within(0.001).of(order.sum)
    end
  end

  describe '#sum_unpaid' do
    it 'is the sum of all its paid orders' do
      expect(basket.sum_unpaid).to be_within(0.001).of(0.0)
      expect(basket_with_orders.sum_unpaid).to be_within(0.001).of(order.sum * 2)
    end
  end

  describe '#json' do
    pending
  end

  describe '#estimate' do
    pending
  end

  describe '#fax_filename' do
    before { basket.save }

    it 'includes updated_at timestamp' do
      expect(basket.fax_filename).to include(basket.updated_at.strftime('%H-%M'))
    end

    it 'includes uid' do
      expect(basket.fax_filename).to include(basket.uid)
    end

    it 'ends with .pdf' do
      expect(basket.fax_filename).to end_with('.pdf')
    end
  end

  describe '#clock_running?' do
    it 'is false when not submitted' do
      basket.submitted = nil
      expect(basket.clock_running?).to eql false
    end

    it 'is false once arrived' do
      basket.submitted = Time.now
      basket.arrival = Time.now
      expect(basket.clock_running?).to eql false
    end

    it 'is true if submitted but not arrived' do
      basket.submitted = Time.now
      basket.arrival = nil
      expect(basket.clock_running?).to eql true
    end
  end

  describe '#shop_name_short' do
    it 'cuts off everything after a comma' do
      basket.shop_name = 'Shöp, In The Street 123, 12312 Some City'
      expect(basket.shop_name_short).to eql 'Shöp'
    end

    it 'strips the shop name' do
      basket.shop_name = ' Shöp   , In The Street 123, 12312 Some City'
      expect(basket.shop_name_short).to eql 'Shöp'
    end

    it 'handles shops without commas' do
      basket.shop_name = ' Shöp'
      expect(basket.shop_name_short).to eql 'Shöp'
    end
  end
end




