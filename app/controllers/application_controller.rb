class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def current_tenant
    tenant_config =  Rails.application.config_for(:tenant)

    @current_tenant ||= if tenant_config.tenant_mode == "single"
      Tenant.find_or_create_by(name: tenant_config.dig(:admin_tenant, :name))
    elsif tenant_config.multi_tenant_mode?
      case tenant_config.tenant_type
      when "subdomain"
        subdomain = request.subdomains(0).first&.downcase
        raise "Invalid domain" if subdomain.blank?
        Tenant.find_by!(name: subdomain)
      when "path"
        # TODO: Create dynamic routing or route generation
      end
    end
  end

  def after_sign_in_path_for(resource, default_path = nil)
    stored_location_for(resource) || default_path || users_my_page_path || root_path
  end
end
