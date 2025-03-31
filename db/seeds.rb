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
Company.destroy_all
User.destroy_all

# Create companies
puts "Creating companies..."
5.times do
  FactoryBot.create(:company)
end

# Default tenant settings
FactoryBot.create(:company, name: 'example')

# Create users with associated companies
puts "Creating users..."
Company.all.each do |company|
  # Create 3 users per company
  3.times do
    FactoryBot.create(:user, company: company)
  end
end

puts "Seed data created successfully!"
puts "Created #{Company.count} companies"
puts "Created #{User.count} users"
