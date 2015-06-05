# encoding: utf-8

# via https://stackoverflow.com/a/19445201/1684530
# license: CC-BY-SA 3.0

# Put this code in lib/validators/json_validator.rb
# Usage in your model:
#   validates :json_attribute, presence: true, json: true
#
# To have a detailed error use something like:
#   validates :json_attribute, presence: true, json: {message: :some_i18n_key}
# In your yaml use:
#   some_i18n_key: "detailed exception message: %{exception_message}"
class JsonValidator < ActiveModel::EachValidator
  def initialize(options)
    options.reverse_merge!(:message => :invalid)
    super(options)
  end

  def validate_each(record, attribute, value)
    return if not value.is_a?(String)
    value = value.strip
    ActiveSupport::JSON.decode(value)
  rescue MultiJson::LoadError => exception
    record.errors.add(attribute, options[:message], exception_message: exception.message)
  end
end
