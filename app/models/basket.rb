# encoding: utf-8

class Basket < ActiveRecord::Base
  has_many :orders, dependent: :destroy

  scope :similar, ->(basket) { where(shop_url: basket.shop_url, sha_address: basket.sha_address) }
  scope :with_duration, -> { where.not(arrival: nil, submitted: nil) }

  validates :uid, presence: true, uniqueness: true
  validates :shop_name, presence: true
  validates :shop_url, presence: true,
    format: { with: %r{\A/}, message: "must start with /" }
  validates :fax_number, allow_blank: true,
    format: { with: %r{\A\+[0-9]+}, message: "must start with a plus sign and otherwise only contain numbers." }

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

  def duration_per_euro
    return nil if sum == 0
    duration.to_f/sum
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
    dur_per_euro = similar.map { |b| b.duration_per_euro }.compact
    return nil, 0 if dur_per_euro.empty?

    avg = dur_per_euro.sum.to_f / dur_per_euro.size.to_f
    return (avg * sum).round, dur_per_euro.size
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
