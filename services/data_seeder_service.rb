# frozen_string_literal: true

class DataSeederService
  def run!
    return unless allow?

    load_seed_data!
  end

  def load_seed_data!
    PermissionSeederService.new.process
  end

  private

    # When there are no Organization's and User's
    def allow?
      [Organization, User].map { |model| model.count == 0 }.all?
    end
end
