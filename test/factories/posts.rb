# frozen_string_literal: true

FactoryBot.define do
  factory :post do
    title { Faker::Lorem.sentence }
    body  { Faker::Lorem.paragraph }
    association :author
  end
end
