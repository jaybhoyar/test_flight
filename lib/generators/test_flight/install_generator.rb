# frozen_string_literal: true

require 'rails/generators/base'
require 'rails/generators/migration'
require 'rails/generators/active_record'

module TestFlight
  module Generators

    class DeviceTableGenerator < Rails::Generators::Base

      include Rails::Generators::Migration
      extend ActiveRecord::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)

      def self.next_migration_number(path)
        ActiveRecord::Generators::Base.next_migration_number(path)
      end

      def copy_migration_file
        if migration_file_exists?('create_devices')
          puts "Migration create_devices is already present in your app."
        else 
          add_create_devices_migration('create_devices')
        end
      end

      private
        def migration_file_exists?(template)
          migration_dir = File.expand_path('db/migrate')
          self.class.migration_exists?(migration_dir, "migrations/#{template}.rb")
        end

        def add_create_devices_migration(template)
          migration_template "migrations/#{template}.rb", "db/migrate/#{template}.rb"
        end
    end
  end
end
