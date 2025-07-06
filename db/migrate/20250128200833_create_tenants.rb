class CreateTenants < ActiveRecord::Migration[8.0]
  def change
    create_table :tenants do |t|
      t.string :name
      t.string :address
      t.string :web

      t.timestamps
    end
  end
end
