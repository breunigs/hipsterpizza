FactoryGirl.define do
  factory SavedOrder do
    name 'ẞÄV¢D Ö®D¢®'
    nick 'Fake Test Nick'
    json [
      { price: 1.2,  prod: 'Nigiri Avocado',  extra: [] },
      { price: 6.15, prod: 'Croque Schinken', extra: ['Curry', 'ohne Salat'] }
    ].to_json

    shop_url { FactoryGirl.build(:basket).shop_url }
  end
end
