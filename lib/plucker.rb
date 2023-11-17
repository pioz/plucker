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
    # Plucker allows projecting records extracted from a query into an array
    # of specifically defined Ruby structs for the occasion. It is an
    # enchanted `pluck`. It takes a list of values you want to extract and
    # throws them into a custom array of Ruby struct.
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
