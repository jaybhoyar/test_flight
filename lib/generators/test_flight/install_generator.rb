# frozen_string_literal: true

require 'rails/generators/base'
require 'rails/generators/migration'
require 'rails/generators/active_record'

module TestFlight
  module Generators

    class InstallGenerator < Rails::Generators::Base

      include Rails::Generators::Migration
      extend ActiveRecord::Generators::Migration

      source_root File.expand_path('../../templates', __FILE__)

      def self.next_migration_number(path)
        ActiveRecord::Generators::Base.next_migration_number(path)
      end

      def copy_migration_file
        if Dir['db/migrate/*create_devices.rb'].any?
          puts 'Migration create_devices has already been copied to your app'
        else
          migration_template 'migrations/create_devices.rb', Rails.root.join('db/migrate/create_devices.rb')
        end
      end 
    end
  end
end
