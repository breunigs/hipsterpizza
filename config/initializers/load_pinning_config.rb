# encoding: utf-8

path = "#{Rails.root}/config/pinning.yml"
if File.exist?(path)
  PINNING = YAML.load_file(path)
else
  PINNING = { }
end
