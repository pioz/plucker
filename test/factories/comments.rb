# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    text { Faker::Lorem.sentence }
    association :author
    association :post
  end
end
