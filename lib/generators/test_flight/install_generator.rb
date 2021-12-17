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

      def copy_model_file
        if Dir['app/models/*device.rb'].any?
          puts 'Device model has already been copied to your app'
        else
          copy_file 'models/device.rb', Rails.root.join('app/models/device.rb')
        end
      end

      def copy_device_associations
        unless File.readlines('app/models/user.rb').include?('has_many :devices')
          inject_into_file(
            'app/models/user.rb',
            "\n  has_many :devices, dependent: :destroy",
            after: 'belongs_to :organization'
          )
        end
      end

      def add_device_model_incineration
        inject_into_file(
          'app/models/concerns/incinerable_concern.rb',
          '"Device": {
            joins: :user,
            where: ["users.organization_id = ?", org_id]
          },
          ',
          before: '"User"'
        )
      end

      def copy_device_routes
        route_file = File.readlines('config/routes.rb').include?("  draw :api\n") ? 'config/routes/api.rb' : 'config/routes.rb'

        inject_into_file(
          route_file,
          "\n    resources :devices, only: [:create, :destroy]",
          after: 'namespace :v1 do'
        )
      end

      def copy_device_controller
        if Dir['app/controllers/api/v1/*devices_controller.rb'].any?
          puts 'Device controller has already been copied to your app'
        else
          copy_file 'controllers/devices_controller.rb', Rails.root.join('app/controllers/api/v1/devices_controller.rb')
        end
      end
    end
  end
end
