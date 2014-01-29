# encoding: utf-8

class Order < ActiveRecord::Base
  belongs_to :basket

  validates :uuid, presence: true, uniqueness: true
  validates :json, presence: true, json: true
  validates :nick, presence: true
  validates :basket_id, presence: true

  scope :paid, -> { where(paid: true) }
  scope :unpaid, -> { where(paid: false) }
  scope :sorted, -> { order(nick: :asc) }


  before_validation(on: :create) do
    create_uuid
  end

  def json_parsed
    ActiveSupport::JSON.decode(json)
  end

  def amount
    json_parsed.map { |i| i['price'] }.inject(0, :+)
  end

  def amount_with_tip
    # TODO: make configurable
    tip_percent = 5
    a = amount
    # round to nearest 10 cents
    round_tip = (a * 10 * tip_percent/100.0).round / 10.0
    a + round_tip
  end



  private
  def create_uuid
    raise 'Order has already an UUID'  if self.uuid
    other = Order.pluck(:uuid)
    2.times do
      self.uuid = SecureRandom.uuid
      break unless other.include?(self.uuid)
    end
  end
end
