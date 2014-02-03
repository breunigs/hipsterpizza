# encoding: utf-8

class Basket < ActiveRecord::Base
  has_many :orders

  scope :similar, ->(basket) { where(shop_url: basket.shop_url, sha_address: basket.sha_address) }
  scope :with_duration, -> { where.not(arrival: nil, submitted: nil) }

  validates :uid, presence: true, uniqueness: true
  validates :shop_name, presence: true
  validates :shop_url, presence: true,
    format: { with: %r{\A/}, message: "must start with /" }

  before_validation(on: :create) do
    create_uid
  end

  def arrived?
    !arrival.nil?
  end

  def duration
    return nil unless submitted? && arrived?
    dur = arrival - submitted
    return nil if dur < 0
    dur
  end

  def editable?
    submitted == nil && !cancelled?
  end

  def sum
    sum_orders(orders)
  end

  def sum_paid
    sum_orders(orders.paid)
  end

  def sum_unpaid
    sum_orders(orders.unpaid)
  end

  def json
    ActiveSupport::JSON.encode(orders.map(&:json_parsed).flatten)
  end

  def estimate
    similar = Basket.similar(self).with_duration
    durations = similar.map { |b| b.duration.to_f/b.sum rescue nil }.compact
    return nil, 0 if durations.empty?
    avg_per_euro = durations.sum.to_f / durations.size.to_f
    return (avg_per_euro * sum).round, durations.size
  end

  private

  def create_uid
    raise "Basket has already an UID"  if self.uid

    other = Basket.pluck(:uid)

    50.times do
      self.uid = SecureRandom.hex(3)
      break unless other.include?(self.uid)
    end

    # if we don’t find a unique ID after 50 tries, the basket creation
    # will fail on validation
  end

  def sum_orders(orders)
    orders.map { |o| o.amount }.sum
  end
end
