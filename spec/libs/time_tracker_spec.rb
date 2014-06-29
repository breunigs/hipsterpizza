# encoding: utf-8

require 'spec_helper'

describe TimeTracker do
  def tt
    TimeTracker.new(@basket)
  end

  before do
    class TestBasket < Basket
      def estimate
        # estimate in seconds, number of samples
        return 120, 5
      end
    end
    @basket = TestBasket.new
    @basket.submitted = Time.now - 5.minutes
  end

  describe '#overdue?' do
    it 'is false, if there’s still time left' do
      @basket.submitted = Time.now - 1.minutes
      expect(tt.overdue?).to be_false
    end

    it 'is true, if it’s taken longer than the estimate' do
      expect(tt.overdue?).to be_true
    end

    it 'is true, if it’s taken longer than the estimate, even after arrival' do
      @basket.arrival = Time.now
      expect(tt.overdue?).to be_true
    end
  end

  describe '#overdue_percent' do
    it 'is 0.0 if not overdue' do
      @basket.submitted = Time.now - 1.minutes
      expect(tt.overdue_percent).to eql(0.0)
    end

    it 'returns overdue percentage where overdue+estimate==100%' do
      # estimate = 2
      # overdue = 3
      # expected percentage = 3/(2+3)*100
      # check for approximate value only, since Time.now introduces variations
      expect(tt.overdue_percent).to be_within(0.1).of(60)
    end
  end

  describe '#now_percent' do
    it 'reports passed percentage to estimated delivery when not arrived' do
      @basket.submitted = Time.now - 1.minutes
      # estimate = 2
      # time passed = 1
      # time to go = 1
      # expected percentage: 50
      expect(tt.now_percent).to be_within(0.1).of(50)
    end

    it 'reports 100% if arrived and “now” is greater than other dates' do
      # submitted = 5 mins ago
      # estimate = 3 mins ago
      @basket.arrival = Time.now - 2.minutes
      expect(tt.now_percent).to be_within(0.1).of(100)
    end

    it 'reports % of estimate if arrived and ”now” is smaller than estimate' do
      @basket.submitted = Time.now - 1.minutes
      @basket.arrival = Time.now - 30.seconds
      # estimate: Time.now + 1.minutes
      # delivery took 30 seconds, but expected were 120. Expect 25%.
      expect(tt.now_percent).to be_within(0.1).of(25)
    end
  end

  describe '#togo_minutes' do
    it 'returns a question mark if overdue' do
      expect(tt.togo_minutes).to eql('?')
    end

    it 'returns time left in minutes if not overdue' do
      @basket.submitted = Time.now - 1.minutes
      expect(tt.togo_minutes).to eql(1)
    end
  end
end
