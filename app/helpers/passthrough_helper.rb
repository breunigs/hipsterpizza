# encoding: utf-8

module PassthroughHelper
  def get_replay_details
    c = cookie_get(:replay).split(" ", 3)
    return nil, nil, nil if c.size < 3
    obj = case c[0]
      when 'order'      then Order.where(uuid: c[2]).first
      when 'savedorder' then SavedOrder.where(uuid: c[2]).first
      when 'basket'     then Basket.where(uid: c[2]).first
      else nil
    end

    json = obj ? obj.json : nil
    sum = obj.respond_to?(:sum) ? obj.sum : 0.0

    return c[1], json, sum
  end
end
