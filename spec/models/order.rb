# encoding: utf-8

require 'spec_helper'

describe Order do
  let(:o) { Order.new }

  describe '#nick_id' do
    it 'handles nicks without any valid characters' do
      o.nick = 'ᗰ∀Ⲭ'
      expect(o.nick_id).to eql '~~~'
    end

    it 'handles empty nicks' do
      o.nick = ''
      expect(o.nick_id).to eql '~~~'
    end

    it 'ignores diacritics' do
      o.nick = 'ÖáǺ'
      expect(o.nick_id).to eql 'OAA'
    end
  end
end
