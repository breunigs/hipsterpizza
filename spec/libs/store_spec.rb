require 'spec_helper'

describe Store do
  let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

  let(:store) do
    s = Store.new('https://www.yrden.de')
    allow(s).to receive(:backend).and_return(memory_store)
  end

  describe '#fetch' do
    pending
  end

  describe '#guess_expiry' do
    pending
  end
end
