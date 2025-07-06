# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    admin_tenant = user.tenant
    return if admin_tenant.blank?

    cannot :read_all, Tenant
    cannot :manage, Tenant
    can :read, Tenant, id: admin_tenant.id
    can :read, User, id: user.id
  end
end
