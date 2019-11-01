class HealthDetailsController < ApplicationController
	before_action :set_health_detail, only: [:show, :update, :destroy]

	# GET /health_details
	def index
		@health_details = HealthDetail.where(name: "health", user_id: current_user.id)
	    render json: { health_detail: @health_details }
	end

	# GET /health_details/1
	def show
	  render json: @health_detail
	end

	# POST /health_details
	def create
		if (current_user.role_id == 1)
			data = HealthDetail.find_by(name: "health", user_id: current_user.id)
			if data.present?
				@health_detail = HealthDetail.find_by(name: "health", user_id: current_user.id).update(attribute_name_value: params[:attribute_name_value])
				health = HealthDetail.find_by(name: "health", user_id: current_user.id)
				render json: health, status: :ok
			else
				@health_detail = HealthDetail.new(name: "health", attribute_name_value: params[:attribute_name_value], user_id: current_user.id)
				if @health_detail.save
					render json: @health_detail, status: :created, location: @health_detail
				else
					render json: @health_detail.errors, status: :unprocessable_entity
				end	
			end
		end
	end

	# GET /health_details/about (For My emergency about screen)
	def about
	  user = User.select(:name, :blood_group, :age, :id, :user_uid).find(current_user.id)
	  policies = HealthDetail.where(name: "policy", user_id: current_user.id).uniq
	  qrcode_image = "http://192.168.1.238:4020/qrcode/#{current_user.id}.png"
	  render json: { user_info: user, policies: policies, qrcode_image: qrcode_image }	
	end

	# POST /health_details/about_update  (For About screen update)
	def about_update
		if (current_user.role_id == 1)
			user_update = User.find(current_user.id).update(blood_group: params[:user][:blood_group], age: params[:user][:age])
			user = User.select(:blood_group, :age, :id).find(current_user.id)
			data = HealthDetail.find_by(user_id: current_user.id, name: "policy")
	    	if data.present?
				policy = HealthDetail.find_by(user_id: current_user.id, name: "policy").update(name: "policy", attribute_name_value: params[:policy][:attribute_name_value])
			else
				policy = HealthDetail.create(name: "policy", attribute_name_value: params[:policy][:attribute_name_value], user_id: current_user.id)				
			end
			policies = HealthDetail.find_by(name: "policy", user_id: current_user.id)
		end
		render json: { user: user, update: user_update, policy: policy, policies: policies }
	end


	# PATCH/PUT /health_details/1
	def update
		if (current_user.role_id == 1)
			if @health_detail.update(health_detail_params)
	  		  render json: @health_detail
	  		else
	    	  render json: @health_detail.errors, status: :unprocessable_entity
	  		end
		end
	end

	# DELETE /health_details/1
	def destroy
	  @health_detail.destroy
	end

	


	private
	  # Use callbacks to share common setup or constraints between actions.
	  def set_health_detail
	    @health_detail = HealthDetail.find(params[:id])
	  end

	  # Only allow a trusted parameter "white list" through.
	  def health_detail_params
	    params.require(:health_detail).permit!#(:name, :user_id, { attribute_name_value: [] })
	  end
end
