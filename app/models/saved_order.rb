class SavedOrder < ActiveRecord::Base
  extend FriendlyId
  friendly_id :uuid

  validates :json, presence: true, json: true
  validates :nick, presence: true
  validates :shop_url, presence: true,
    format: { with: %r{\A/}, message: "must start with /" }

  scope :sorted, -> { order('lower(name) asc') }

  before_validation(on: :create) do
    create_uuid
  end

  def self.exists?(nick, order)
    SavedOrder.where(nick: nick, json: order.json, shop_url: order.basket.shop_url).exists?
  end


  def json_parsed
    ActiveSupport::JSON.decode(json)
  end

  private

  def create_uuid
    raise 'Order has already an UUID' if self.uuid
    self.uuid = SecureRandom.uuid
  end
end
