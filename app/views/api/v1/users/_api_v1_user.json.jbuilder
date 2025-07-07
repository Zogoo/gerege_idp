json.extract! api_v1_user, :id, :email, :provider, :uid, :name, :image, :created_at, :updated_at
json.url api_v1_user_url(api_v1_user, format: :json)
