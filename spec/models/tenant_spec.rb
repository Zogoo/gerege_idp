require 'rails_helper'

RSpec.describe Tenant, type: :model do
  it { should have_many(:users) }
end
