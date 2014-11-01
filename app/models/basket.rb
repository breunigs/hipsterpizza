# encoding: utf-8

class Basket < ActiveRecord::Base
  extend FriendlyId
  friendly_id :uid

  has_many :orders, dependent: :destroy

  scope :similar, ->(basket) { where(shop_url: basket.shop_url, sha_address: basket.sha_address).where.not(id: basket.id) }
  scope :with_duration, -> { where.not(arrival: nil, submitted: nil) }
  scope :editable, -> { where(submitted: nil, cancelled: false) }

  validates :uid, presence: true, uniqueness: true
  validates :shop_name, presence: true
  validates :shop_url, presence: true,
    format: { with: %r{\A/}, message: "must start with /" }
  validates :shop_fax, allow_blank: true,
    format: { with: %r{\A\+[0-9]+}, message: "must start with a plus sign and otherwise only contain numbers." }
  validates :shop_url_params, allow_blank: true,
    format: { with: %r{\A\?}, message: "must start with a question mark." }

  validate :pinned_shop_url
  def pinned_shop_url
    return unless PINNING['shop_url']
    return if shop_url == PINNING['shop_url']
    errors.add(:shop_url, 'Shop differs from the pinned one. Contact the admin.')
  end

  validate :pinned_single_basket_mode
  def pinned_single_basket_mode
    return unless PINNING['single_basket_mode']
    other = Basket.find_editable(self.id)
    return unless other
    errors.add(:id, "There’s already a basket with UID=#{other.uid}, can’t create a new one until the other is sumbitted or cancelled.")
  end

  before_validation(on: :create) do
    create_uid
  end

  # returns the complete URL, i.e. canonical URL plus any additional query
  # parameters present when originally creating the basket. Adds arguments as
  # extra params.
  def full_url(*extra_params)
    query = shop_url_params_hash.merge(extra_params.first).to_param
    shop_url + '?' + query
  end

  def shop_url_params_hash
    return {} if shop_url_params.blank?
    Rack::Utils.parse_nested_query(shop_url_params[1..-1])
  end

  def self.find_editable(exclude = nil)
    self.editable.where.not(id: exclude).order(created_at: :desc).first
  end

  def self.find_recent_submitted(max_time_ago = 12.hours.ago)
    self.where('submitted > ?', max_time_ago).order(submitted: :desc).first
  end

  def self.cancel_all_editable
    self.editable.each { |b| b.update_attribute(:cancelled, true) }
  end

  def self.find_basket_for_single_mode
    return nil unless PINNING['single_basket_mode']

    # is there an editable basket we can forward the user to?
    @basket = find_editable
    return @basket if @basket

    # is there a recently submitted basket in the timeout range?
    after = (PINNING['single_basket_timeout'] || 720).minutes.ago
    @basket = self.find_recent_submitted(after)
    return @basket if @basket
    nil
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
    dur_per_euro = similar.map(&:duration_per_euro).compact
    return nil, 0 if dur_per_euro.empty?

    avg = dur_per_euro.sum.to_f / dur_per_euro.size.to_f
    return (avg * sum).round, dur_per_euro.size
  end

  def fax_filename
    name = updated_at.strftime('%Y-%m-%d_%H-%M')
    name << '_hipster_fax_'
    name << uid
    name << '.pdf'
    name
  end

  def clock_running?
    submitted? && !arrived?
  end

  def shop_name_short
    shop_name.split(',', 2).first
  end

  private

  def create_uid
    raise "Basket has already an UID"  if self.uid

    other = Basket.pluck(:uid)

    50.times do
      self.uid = (0...3).map { (65 + 32 + rand(26)).chr }.join
      next if self.uid == 'new'
      break unless other.include?(self.uid)
    end

    # if we don’t find a unique ID after 50 tries, the basket creation
    # will fail on validation
  end

  def sum_orders(orders)
    orders.map(&:sum).sum
  end
end
