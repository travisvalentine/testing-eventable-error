class User < Model
  attrs :id, :email, :api_token, :active, :approved, :profile_id,
        :latitude, :longitude, :updated_at, :unread_question_count,
        :current_location

end