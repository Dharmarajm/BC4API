class EmergencyDetailsController < ApplicationController
  before_action :set_emergency_detail, only: [:show, :update, :destroy]

  # GET /emergency_details
  def index
    @emergency_details = EmergencyDetail.where(user_id: current_user.id)
    cg_ids = UserAssociation.where(patient_id: current_user.id).pluck(:caregiver_id)
    caregiver = User.where(id: cg_ids).where.not(email: nil, password: nil)
    render json: { emergency_detail: @emergency_details, emergency_contact_count: @emergency_details.to_a.count, caregivers: caregiver, caregiver_count: caregiver.to_a.count }
  end

  # GET /emergency_details/caregiver_delete
  def caregiver_delete
    if params[:cg_id].present?
      @user_association = UserAssociation.find_by(patient_id: current_user.id, caregiver_id: params[:cg_id])
      if @user_association.destroy
        render json: { message: 'Delete Successfully' }
      else
        render json: { message: 'Something went wrong' }, status: :unprocessable_entity
      end
    end
  end

  # GET /emergency_details/1
  def show
    render json: @emergency_detail
  end

  # POST /emergency_details
  def create
    if (current_user.role_id == 1)
      @emergency_detail = EmergencyDetail.new(contact_name: params[:contact_name], emergency_no: params[:emergency_no], user_type: params[:user_type], user_id: current_user.id)
      if @emergency_detail.save
        render json: @emergency_detail, status: :created, location: @emergency_detail
      else
        render json: @emergency_detail.errors, status: :unprocessable_entity        
      end
    end
  end

  # PATCH/PUT /emergency_details/1
  def update
  	if (current_user.role_id == 1)
  		if @emergency_detail.update(emergency_detail_params)
	      render json: @emergency_detail
	    else
	      render json: @emergency_detail.errors, status: :unprocessable_entity
	    end
  	end
  end

  # DELETE /emergency_details/1
  def destroy
  	if (current_user.role_id == 1)
  		if @emergency_detail.destroy
  			render json: { message: 'Delete Successfully' }
  		else
  			render json: @emergency_detail.errors, status: :unprocessable_entity
  		end
  	else
  		render json: { message: 'You are not allowed' }, status: :unauthorized
  	end
  end


  # def allergy_search
  #   allergy_search = AllergyList.search(params[:search]).pluck(:name)
  #   render json: allergy_search
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_emergency_detail
      @emergency_detail = EmergencyDetail.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def emergency_detail_params
      params.require(:emergency_detail).permit(:mediclaim_policy, :policy_issuer, :contact_name, :emergency_no, :user_type, :user_id)
    end
end
