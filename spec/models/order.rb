require 'spec_helper'

describe Order do
  let(:o) { FactoryGirl.build(:order) }

  it 'can be created' do
    expect(o.save).to eql true
    expect(o.uuid).not_to eql nil
  end

  describe '#json_parsed' do
    it 'decodes valid json string' do
      expect { o.json_parsed }.not_to raise_error
    end

    it 'raises errors for invalid json' do
      o.json = 'derp } '

      expect { o.json_parsed }.to raise_error
    end
  end

  describe '#sum' do
    it 'returns floats' do
      expect(o.sum).to be_kind_of Float
    end

    it 'calculates correctly' do
      expect(o.sum).to be_within(0.0001).of(7.35)
    end
  end

  describe '#sum_with_tip' do
    it 'returns floats' do
      expect(o.sum_with_tip).to be_kind_of Float
    end

    it 'rounds to 10 cents' do
      with_tip = CONFIG['tip_percent'].to_f / 100.0 + 1.0
      expect(o.sum_with_tip).to be_within(0.10).of(7.35*with_tip)
    end
  end

  describe '#date' do
    it 'returns “never” if basket not submitted' do
      expect(o.date).to eql I18n.t 'time.never'
    end

    it 'returns basket submit time if available' do
      time = Time.now
      o.basket.submitted = time

      expect(o.date).to eql time.strftime('%Y-%m-%d')
    end
  end

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
