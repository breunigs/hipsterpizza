RSpec.shared_context 'pinning' do
  before do
    silence_warnings { PINNING = { } }
  end

  after(:all) do
    silence_warnings { PINNING = { }.freeze }
  end
end
