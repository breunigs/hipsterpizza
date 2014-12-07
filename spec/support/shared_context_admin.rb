RSpec.shared_context 'admin' do
  before do
    cookies['_hipsterpizza_is_admin'] = true.to_s
  end
end
