class CreateTenants < ActiveRecord::Migration[8.0]
  def change
    create_table :tenants do |t|
      t.string :name
      t.string :address
      t.string :web
      t.string :tenant_mode
      t.string :tenant_type

      t.timestamps
    end
  end
end
