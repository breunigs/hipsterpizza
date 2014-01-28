# encoding: utf-8

class Basket < ActiveRecord::Base
  has_many :orders


  validates :uid, presence: true, uniqueness: true
  validates :shop_name, presence: true
  validates :shop_url, presence: true,
    format: { with: %r{\A/}, message: "must start with /" }

  before_validation(on: :create) do
    create_uid
  end

  def editable?
    submitted == nil && !cancelled?
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
end
