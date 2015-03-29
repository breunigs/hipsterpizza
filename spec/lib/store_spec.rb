require 'spec_helper'

describe Store do
  let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

  let(:store) do
    s = Store.new('https://www.yrden.de')
    allow(s).to receive(:backend).and_return(memory_store)
    s
  end

  let(:env) do
    {
      'REQUEST_URI' => '',
      'PATH_INFO' => '',
      'rack.input' => StringIO.new(''),
      'action_dispatch.cookies' => ActionDispatch::Cookies::CookieJar.new({})
    }
  end

  describe '#fetch' do
    pending
  end

  describe '#guess_expiry' do
    pending
  end

  describe '#third_party_login?' do
    let(:cookies) { env['action_dispatch.cookies'] }

    it 'defaults to false' do
      expect(store.send(:third_party_login?, env)).to eql false
    end

    it 'detects pizza.de login cookie' do
      cookies['pizza_de_login'] = 'gimme dat discount'
      expect(store.send(:third_party_login?, env)).to eql true
    end

    it 'detects pizza.de "logged out" cookie' do
      cookies['pizza_de_login'] = 'invalid&1'
      expect(store.send(:third_party_login?, env)).to eql false
    end
  end

  describe '#key' do
    it 'depends on query params (uses REQUEST_URI)' do
      env['REQUEST_URI'] = 'http://yrden.de?derp=ON'
      key1 = store.send(:key, env)

      env['REQUEST_URI'] = 'http://yrden.de?derp=OFF'
      key2 = store.send(:key, env)

      expect(key1).not_to eql key2
    end

    it 'depends on the input headers' do
      env['REQUEST_URI'] = StringIO.new('Header: 123')
      key1 = store.send(:key, env)

      env['REQUEST_URI'] = StringIO.new('Header: asd')
      key2 = store.send(:key, env)

      expect(key1).not_to eql key2
    end
  end

  describe '#cache_buster_param?' do

    it 'recognizes pizza.de style cache busting' do
      env['REQUEST_URI'] = 'http://pizza.de/_shop/shopinit_json?version=v8&kndDomain=1&store=1234&_=1421588829585'
      expect(store.send(:cache_buster_param?, env)).to eql true
    end

    it 'recognizes stadtsalat.de style cache busting' do
      env['REQUEST_URI'] = 'https://d2rzcb39z1r56i.cloudfront.net/assets/views/index.html?bust=1426870304'
      expect(store.send(:cache_buster_param?, env)).to eql true
    end

    it 'allows normal URLs' do
      env['REQUEST_URI'] = 'http://pizza.de/_shop/shopinit_json'
      expect(store.send(:cache_buster_param?, env)).to eql false
    end
  end
end
