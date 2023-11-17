# frozen_string_literal: true

require_relative 'plucker/version'
require 'active_record'

# :nodoc:
module Plucker
  # :nodoc:
  def self.included(base)
    base.extend(ClassMethods)
  end

  # :nodoc:
  module ClassMethods
    # Plucker allows projecting a query into a specifically defined struct for
    # the query. It takes an array of values to be selected from the database
    # as arguments. Each element of the array can be specified in 3 different
    # ways depending on the requirements: as a Symbol, as a String, or as a
    # Hash. When using a symbol, the column with the corresponding name to
    # the symbol from the 'from' table of the query is selected, and the
    # struct field will have that name:
    #
    #   Post.plucker(:title).last
    #   #<struct title="How to make pizza">
    #
    # When using the symbol `:all`, it is interpreted as a 'SELECT *'
    # statement, selecting all columns from the specified table:
    #
    #   Post.plucker(:all).last
    #   #<struct id=1, title="How to make pizza", author_id=1, created_at=Sat, 21 Oct 2023 14:24:08 UTC +00:00, updated_at=Sat, 21 Oct 2023 14:24:08 UTC +00:00>
    #
    # When using a string value, the name of the struct field will be
    # generated using the `parameterize` function with an underscore as the
    # separator:
    #
    #   Post.joins(:comments).plucker('posts.title', 'COUNT(comments.id)').last
    #   #<struct posts_title="How to make pizza", count_comments_id=34>
    #
    # When using a Hash, it operates similarly to the String case, except that
    # the name of the struct field will be the same as the key of the Hash:
    #
    #   Post.joins(:comments).plucker(:title, comments_count: 'COUNT(comments.id)').last
    #   #<struct title="How to make pizza", comments_count=34>
    #
    # Plucker also takes an optional block, which is passed to the struct
    # definition:
    #
    #   posts = Post.plucker(:title) do
    #     def slug
    #       self.title.parameterize
    #     end
    #   end
    #   #<struct title="How to make pizza">
    #   posts.first.slug
    #   # 'how-to-make-pizza'
    #
    def plucker(*args, &block)
      scope = current_scope || self.all
      scope_table_name = scope.table.name
      columns = []
      alias_names = []
      args.each do |value|
        case value
        when Symbol
          if value.in?(%i[all *])
            scope_table_name.classify.constantize.columns.map do |column|
              columns << column.name
              alias_names << column.name.to_sym
            end
          else
            columns << value.to_s
            alias_names << value
          end
        when String
          table_name, column_name = value.split('.')
          if column_name == '*'
            table_name.classify.constantize.columns.map do |column|
              columns << column.name
              alias_names << "#{table_name}_#{column.name}".parameterize(separator: '_').to_sym
            end
          else
            columns << Arel.sql(value)
            alias_names << value.parameterize(separator: '_').to_sym
          end
        when Hash
          value.map do |k, v|
            columns << Arel.sql(v.to_s)
            alias_names << k.to_sym
          end
        else
          raise "Invalid plucker argument: '#{value.inspect}'"
        end
      end

      struct = Struct.new(*alias_names) do
        class_eval(&block) if block
      end
      scope.pluck(*columns).map do |record|
        struct.new(*record)
      end
    end
  end
end

ActiveRecord::Base.include(Plucker)
