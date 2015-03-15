class Pinning
  def self.single_basket_mode?
    PINNING['single_basket_mode']
  end

  def self.provider
    PINNING['provider']
  end

  def self.shop_url(provider = nil)
    return unless PINNING['shop_url']

    without_question_mark = PINNING['shop_url_params'].to_s.sub(/\A\?/, '')
    query = Rack::Utils.parse_nested_query(without_question_mark)
    query = query.merge(provider.new_parameters) if provider

    "#{PINNING['shop_url']}?#{query.to_param}"
  end

  PINNABLE_PARAMETERS = %w(provider shop_name shop_url shop_fax shop_url_params)

  def self.all_pinned?
    PINNABLE_PARAMETERS.none? { |f| PINNING[f].blank? }
  end

  def self.merge_pinned!(params = {})
    PINNABLE_PARAMETERS.each do |f|
      next if PINNING[f].blank?
      params[f] = PINNING[f]
    end
    params
  end
end
