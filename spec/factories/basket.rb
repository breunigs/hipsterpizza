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

  factory :real_basket_pizzade, class: Basket do
    shop_name 'Indian Curry, Berlin, Brüsseler Str. 17'
    shop_url '/indian-curry-berlin-bruesseler-str-17'
    shop_fax '+490000000000'
    shop_url_params '?lgs=102261&ed=540936'

    after(:create) do |basket|
      # this order has the following special modes:
      # – bottle deposit
      # – forced extras in menu
      # – item from sub-category
      # – items without popup
      # – same item twice
      # It misses the following mode:
      # – optional additional ingredients
      create(:order, basket: basket, json: '[{"price":32,"prod":"Raja-Platte für 2 Personen","extra":["Mango-Sekt 0,2 l","Mango-Sekt 0,2 l","Mangofrüchte","Mix Tandoori","Mulligatawny","Murgh Makhni","Mutton Sabzi","Tandoori Chicken Salad"]},{"price":4.9,"prod":"Amazonas","extra":[]},{"price":6.9,"prod":"Mix Sabzi","extra":[]},{"price":6.9,"prod":"Mix Sabzi","extra":[]},{"price":30,"prod":"Punjabi-Platte für 2 Personen","extra":["Chicken Korma","Gulab Jamun","Lamm Saagwala","Mix Sabzi","Sekt 0,2 l","Sekt 0,2 l","Tamatar Shorba"]},{"price":2.45,"prod":"Coca Cola, 0,5 l","extra":[]},{"price":0.15,"prod":"Pfand","extra":[]}]')
    end
  end
end
