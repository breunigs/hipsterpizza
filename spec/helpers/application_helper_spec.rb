require 'spec_helper'

describe ApplicationHelper, :type => :helper do
  describe '#euro' do
    it 'formats properly' do
      expect(helper.euro(1.1)).to eql '1.10€'
      expect(helper.euro(0)).to eql '0.00€'
      expect(helper.euro(1234)).to eql '1 234.00€'
    end
  end

  describe '#euro_de' do
    it 'formats properly' do
      expect(helper.euro_de(1.1)).to eql '1,10€'
      expect(helper.euro_de(0)).to eql '0,00€'
      expect(helper.euro_de(1234)).to eql '1 234,00€'
    end
  end

  describe '#overwrite_order_confirm' do
    it 'returns empty string if @order not present' do
      expect(helper.overwrite_order_confirm).to eql ''
    end

    it 'returns a non-empty string if @order exists' do
      helper.instance_variable_set('@order', 'I exist!')
      expect(helper.overwrite_order_confirm).not_to eql ''
    end
  end

  describe '#has_nick?' do
    it 'returns false if cookie not set' do
      helper.cookie_delete(:nick)
      expect(helper.has_nick?).to eql false
    end

    it 'returns false if cookie has blank nick' do
      helper.cookie_set(:nick, '')
      expect(helper.has_nick?).to eql false
    end

    it 'returns true if nick present in cookie' do
      helper.cookie_set(:nick, 'some text')
      expect(helper.has_nick?).to eql true
    end
  end

  describe '#tips?' do
    include_context 'config'

    it 'works when config setting is missing' do
      expect(helper.tips?).to eql false
    end

    it 'is true when a positive tip amount is specified' do
      CONFIG['tip_percent'] = 1
      expect(helper.tips?).to eql true
    end
  end

  describe '#nick_ids?' do
    include_context 'config'

    it 'works when config setting is missing' do
      expect(helper.nick_ids?).to eql false
    end

    it 'is true when the config setting is truthy' do
      CONFIG['show_nick_ids'] = 1
      expect(helper.nick_ids?).to eql true
    end
  end

  describe '#show_insta_order?' do
    it 'is false when an order exists' do
      helper.instance_variable_set('@order', 'I exist!')
      allow(helper).to receive(:has_nick?).and_return(true)

      expect(helper.show_insta_order?).to eql false
    end

    it 'is false when no nick is defined' do
      allow(helper).to receive(:has_nick?).and_return(false)

      expect(helper.show_insta_order?).to eql false
    end

    it 'is true when nick is defined and there’s no order yet' do
      helper.instance_variable_set('@order', 'I exist!')
      expect(helper.show_insta_order?).to eql false
    end
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
    let(:order) { Order.new(nick: 'derp') }

    it 'returns true when the stored nick matches the order’s nick' do
      helper.instance_variable_set('@order', order)
      cookie_set(:nick, order.nick)

      expect(helper.my_order?).to eql true
    end

    it 'returns false when missing nick' do
      helper.instance_variable_set('@order', order)
      cookie_delete(:nick)

      expect(helper.my_order?).to eql false
    end

    it 'returns false when missing order' do
      cookie_set(:nick, order.nick)

      expect(helper.my_order?).to eql false
    end
  end
end
