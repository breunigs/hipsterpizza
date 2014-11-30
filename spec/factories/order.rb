FactoryGirl.define do
  factory Order do
    nick 'Fake Test Nick'
    json [
      { price: 1.2,  prod: 'Nigiri Avocado',  extra: [] },
      { price: 6.15, prod: 'Croque Schinken', extra: ['Curry', 'ohne Salat'] }
    ].to_json

    basket
  end
end
