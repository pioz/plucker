# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'plucker'

require 'active_record'
require 'database_cleaner/active_record'
require 'byebug'
require 'faker'
require 'factory_bot'
require 'minitest/autorun'

DatabaseCleaner.strategy = :transaction
FactoryBot.find_definitions

module Minitest
  class Test
    include FactoryBot::Syntax::Methods

    def before_setup
      DatabaseCleaner.start
    end

    def after_teardown
      DatabaseCleaner.clean
    end
  end
end

# Setup ActiveRecord with in memory sqlite3 database

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Author < ApplicationRecord
end

class Post < ApplicationRecord
  belongs_to :author
  has_many :comments, dependent: :destroy
end

class Comment < ApplicationRecord
  belongs_to :author
  belongs_to :post
end

# Migrate database

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define do
    create_table(:authors) do |t|
      t.string :name, null: false
      t.timestamps
    end

    create_table(:posts) do |t|
      t.references :author, null: false, foreign_key: true
      t.string :title
      t.text :body
      t.timestamps
    end

    create_table(:comments) do |t|
      t.references :author, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.text :text
      t.timestamps
    end
  end
end
