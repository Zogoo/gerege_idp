# frozen_string_literal: true

RailsSamlIdp.configure do |config|
  config.base_url = "http://localhost:3000"
  config.sign_in_url = "/users/sign_in"
  config.relay_state_url = "/home"
  config.session_validation_hook = ->(session) { true }
  config.saml_config_finder = lambda do
    SamlSpConfig.find_by(uuid: params.require(:uuid))
  end
  config.saml_user_finder = lambda do
    User = Struct.new(:name_id_attribute, :email, keyword_init: true)
    User.new(
      name_id_attribute: "email",
      email: "user@example.com"
    )
  end
end
