# frozen_string_literal: true

class PermissionSeederService
  attr_accessor :categories

  PERMISSION_SEED_DATA_FILE_PATH = Rails.root.join("config", "permissions.yml")

  def process
    data = load_permissions!

    data["categories"].each do |category|
      category["permissions"].each do |permission|
        record = Permission.find_or_initialize_by(name: permission["name"])
        record.category = category["name"]
        record.description = permission["description"]
        record.sequence = permission["sequence"]
        record.save
      end
    end
  end

  private

    def load_permissions!
      YAML.load_file(PERMISSION_SEED_DATA_FILE_PATH)
    end
end
