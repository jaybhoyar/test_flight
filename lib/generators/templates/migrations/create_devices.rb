class CreateDevices < ActiveRecord::Migration[6.1]
  def change
    create_table :devices, id: :uuid do |t|
      t.string :device_token, null: false
      t.string :platform, null: false
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end