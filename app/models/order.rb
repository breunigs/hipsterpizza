# encoding: utf-8

class Order < ActiveRecord::Base
  belongs_to :basket

  validates :uuid, presence: true, uniqueness: true
  validates :json, presence: true, json: true
  validates :nick, presence: true
  validates :basket_id, presence: true


  before_validation(on: :create) do
    create_uuid
  end

  private
  def create_uuid
    raise "Order has already an UUID"  if self.uuid
    other = Order.pluck(:uuid)
    2.times do
      self.uuid = SecureRandom.uuid
      break unless other.include?(self.uuid)
    end
  end
end
