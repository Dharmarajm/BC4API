class AuthenticationController < ApplicationController
	skip_before_action :authenticate_request, only: %i[login finding_user]

   # POST /auth/login
	def login
		if params[:email].present?
			# @user = User.find_by_email(params[:email])
			@user = User.find_by("email ILIKE ?", "%#{params[:email]}%")
		    if @user && @user.password == params[:password]
		    # if @user&.authenticate(params[:password])
		    	if @user.active_status == true
		    		token = JsonWebToken.encode(user_id: @user.id)
				    user = User.select(:name, :email, :user_uid, :id, :role_id).find(@user.id)
				    render json: { token: token, message: 'Login Success', user: user }, status: :ok
				else
					render json: { error: 'Need to subscription' }
		    	end
		    else
		      render json: { error: 'Invalid credential' }, status: :unauthorized
		    end
		else
			render json: { error: 'Give the valid Email' }, status: :unauthorized
		end
	end

	def finding_user
		user_email = User.where(email: params[:email])
		if user_email.present?
			render json: user_email
		else
			render json: { error: 'Give the valid Email' }, status: :unauthorized
		end
	end

	private

	def login_params
	  params.permit(:email, :password)
	end
end
