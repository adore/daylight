module Authentication

  def authenticate
    token = params[:auth_token] || auth_token

    # Vault throws an error on unknown tokens
    if token.blank? || (Vault[token].nil? rescue true)
      render status: :unauthorized, text: "Missing or unknown auth_token"
    end
  end

  private
    def auth_token
      if request.authorization
        ActionController::HttpAuthentication::Basic.user_name_and_password(request).last
      end
    end
end
