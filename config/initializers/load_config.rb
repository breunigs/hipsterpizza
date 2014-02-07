# encoding: utf-8

path = "#{Rails.root}/config/pinning.yml"
if File.exist?(path)
  PINNING = YAML.load_file(path).freeze
else
  PINNING = { }.freeze
end

# the fax.yml file is reloaded on each access, to make it easy to change
# stuff on the fly before submitting.
def load_fax_config
  path = "#{Rails.root}/config/fax.yml"
  return { } unless File.exist?(path)
  YAML.load_file(path).freeze
end
