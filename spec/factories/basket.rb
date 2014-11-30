FactoryGirl.define do
  factory Basket do
    shop_name  'HipsterPizza Fake Shop'
    shop_url '/hipster/fake'

    factory :basket_with_orders do
      after(:create) do |basket|
        create_list(:order, 2, basket: basket)
      end
    end
  end
end
