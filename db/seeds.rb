# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Clear existing data (optional)
puts "Cleaning database..."
Tenant.destroy_all
User.destroy_all

# Create companies
puts "Creating companies..."
5.times do
  FactoryBot.create(:tenant)
end

# Default tenant settings
FactoryBot.create(:tenant, name: 'example')

# Create users with associated companies
puts "Creating users..."
Tenant.all.each do |tenant|
  # Create 3 users per tenant
  3.times do
    FactoryBot.create(:user, tenant: tenant)
  end
end

puts "Seed data created successfully!"
puts "Created #{Tenant.count} tenants"
puts "Created #{User.count} users"
