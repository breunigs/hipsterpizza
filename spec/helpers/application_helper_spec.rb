require 'spec_helper'

describe ApplicationHelper, :type => :helper do
  describe '#euro' do
    pending
  end

  describe '#euro_de' do
    pending
  end

  describe '#overwrite_order_confirm' do
    pending
  end

  describe '#has_nick?' do
    pending
  end

  describe '#tips?' do
    pending
  end

  describe '#nick_ids?' do
    pending
  end

  describe '#show_insta_order?' do
    pending
  end

  describe '#admin?' do
    it 'tests correctly for true' do
      expect(helper).to receive(:cookie_get).with(:is_admin).and_return('true')
      expect(helper.admin?).to eql true
    end

    it 'returns false for other values' do
      expect(helper).to receive(:cookie_get).with(:is_admin).and_return('1')
      expect(helper.admin?).to eql false
    end
  end

  describe '#my_order?' do
    pending
  end
end
