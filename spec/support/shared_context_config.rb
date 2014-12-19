RSpec.shared_context 'config' do
  before do
    silence_warnings { CONFIG = {} }
  end

  after(:all) do
    silence_warnings { CONFIG = { }.freeze }
  end
end
