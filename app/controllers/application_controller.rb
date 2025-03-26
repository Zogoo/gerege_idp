class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def current_company
    tenant_config =  Rails.application.config_for(:tenant)

    @current_company ||= if tenant_config.tenant_mode == 'single'
      Company.find_by!(name: tenant_config.dig(:admin_tenant, :name))
    elsif tenant_config.tenant_mode == 'multi'
      case tenant_config.tenant_type
      when 'subdomain'
        subdomain = request.subdomains(0).first&.downcase
        raise 'Invalid domain' if subdomain.blank?
        Company.find_by!(name: subdomain)
      when 'path'
        # TODO: Create dynamic routing or route generation
      end
    end
  end
end
