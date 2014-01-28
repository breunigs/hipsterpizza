module BasketHelper
  def admin?
    @basket && @basket.uid == cookie_get(:basket).to_s
  end
end
