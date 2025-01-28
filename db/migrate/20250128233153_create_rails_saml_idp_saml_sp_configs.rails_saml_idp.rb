# This migration comes from rails_saml_idp (originally 20250120165545)
class CreateRailsSamlIdpSamlSpConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :saml_sp_configs do |t|
      # For identification
      t.string :name
      t.string :display_name
      # SP attributes
      t.string :entity_id
      t.string :signing_certificate
      t.string :encryption_certificate
      t.boolean :sign_assertions
      t.boolean :sign_authn_request
      # IdP attributes
      t.string :certificate
      t.string :private_key
      t.string :pv_key_password
      t.string :relay_state
      t.string :name_id_attribute
      t.text :raw_metadata

      if connection.adapter_name.downcase.starts_with?('postgresql')
        # SP attributes
        t.text :name_id_formats, array: true, default: []
        t.jsonb :assertion_consumer_services, default: []
        t.jsonb :single_logout_services, default: {}
        # IdP attributes
        t.jsonb :contact_person, default: {}
        t.jsonb :saml_attributes, default: {}
      elsif connection.adapter_name.downcase.starts_with?('mysql')
        # SP attributes
        t.text :name_id_formats, array: true, default: []
        t.json :assertion_consumer_services, default: []
        t.json :single_logout_services, default: {}
        # IdP attributes
        t.json :contact_person, default: {}
        t.json :saml_attributes, default: {}
      else
        # SP attributes
        t.text :name_id_formats, default: '[]'
        t.text :assertion_consumer_services, default: '[]'
        t.text :single_logout_services, default: '{}'
        # IdP attributes
        t.text :contact_person, default: '{}'
        t.text :saml_attributes, default: '{}'
      end

      # Public UUID for SP
      if connection.adapter_name.downcase.starts_with?('mysql')
        t.string :uuid, null: false, default: -> { "UUID()" }
      elsif connection.adapter_name.downcase.starts_with?('postgresql')
        t.uuid :uuid, null: false, default: -> { "gen_random_uuid()" }
      else
        t.string :uuid, null: false
      end

      t.timestamps
    end

    add_index :saml_sp_configs, :name, unique: true
    add_index :saml_sp_configs, :entity_id, unique: true
  end
end
