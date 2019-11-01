class UsersController < ApplicationController
  before_action :set_user, only: [:show, :update, :destroy]
  skip_before_action :authenticate_request, only: %i[patient_register user_uid caregiver_register identify_user verification_code password_updation user_details list ] 


  def index
    if params[:page].present? && params[:per_page].present?
      @users = User.all.paginate(:page => params[:page], :per_page => params[:per_page])
    else
      @users = User.all
    end
    render json: @users
  end

  def users_count
    if (current_user.role_id == 3)
      user_count = User.all.count
      render json: user_count
    else
      render json: { error: 'You are not allowed' }, status: :unprocessable_entity
    end
  end

  # GET /list
    def list 
      #if (current_user.role_id == 3)  
              model_fields = User.attribute_names
              data = params[:data].present? ? params[:data] : model_fields
              page_count = params[:per_page].present? ? params[:per_page]  : "10"
              page = params[:page].present? ? params[:page] : "1"
              sort = params[:sort].present? && model_fields.include?(params["sort"]) ? params[:sort] : "name"
              order_types = ["asc", "desc", "ASC", "DESC"]
              order_by = params[:order].present? && order_types.include?(params["order"]) ? params[:order] : "ASC" 
              filters = {"data" =>data,"per_page"=> page_count,"page"=> page,"sort"=>sort,"order"=>order_by} 
        if params[:role_id].present?
              @user = User.select(data).where(role_id: params[:role_id]).order(sort => order_by).paginate(:page => page, :per_page => page_count)
        elsif params[:id].present?
              @user = User.where(id: params[:id]).includes(:active_subscriptions)
        else
              @user =  User.select(data).where.not(id: 1, email: "admin@gmail.com").includes(:active_subscriptions).order(sort=> order_by).paginate(:page => page, :per_page => page_count)
               # @user =  User.select(data).where.not(id: 1, email: "admin@gmail.com").includes(:subscriptions).order(sort=> order_by).paginate(:page => page, :per_page => page_count)
        end
        user_count = User.all.count
        render :json => { :users => @user.as_json(:include => :active_subscriptions), filters: filters, count: user_count }#,each_serializer: UserSerializer, status: :ok
      #else
       # render json: { error: 'You are not allowed' }, status: :unprocessable_entity
      #end
    end

  # GET /users/email_validation
    def email_validation
      email = params[:email]
      status = EmailDetected.exist?(email)  
      if (status[:status] == true)
        render json: { status: true }
      else
        render json: { status: false, "error": "Please Give valid Email" }
      end
    end


  # POST /users (for creating new users)
    def patient_register
        @patient = User.new(name: params[:user][:name], email: params[:user][:email], password: params[:user][:password], mobile_no: params[:user][:mobile_no], address: params[:user][:address], country: params[:user][:country], role_id: params[:user][:role_id])
        if @patient.save
          if (@patient.role_id == 1)
            @patient.update(user_uid: rand(36**8).to_s(36).upcase) #SecureRandom.base64(6) #for generate the user_uid
          end
             user_uid = @patient.user_uid
             User.qr_image(user_uid)
          if params[:caregiver].present?
              @caregiver = User.find_by(mobile_no: params[:caregiver][:mobile_no])
            if @caregiver.present?
              @user_association = UserAssociation.create(patient_id: @patient.id, caregiver_id: @caregiver.id)
            else
              @caregiver = User.create(name: params[:caregiver][:name], mobile_no: params[:caregiver][:mobile_no], role_id: params[:caregiver][:role_id])
              @user_association = UserAssociation.create(patient_id: @patient.id, caregiver_id: @caregiver.id)
            end
          end
          UserMailer.welcome_user(@patient).deliver_now
          render json: {patient: @patient, caregiver: @caregiver, user_association: @user_association}, status: :ok
        else
          render json: { "error": "Mobile number or Email has been already taken" }, status: :unprocessable_entity
        end
    end
 

  # PATCH/PUT /users/1
    def update
        #user_params = user_params.select!{|x| User.attribute_names.index(x)}
     	  if @user.update(user_params)
          render json: { "message": "Updated Successfully" } 
        else
          render json: @user.errors.messages
        end
    end

  # POST /users/profile_picture (for uploade & changing profile picture)
    def profile_picture
      pic = params[:user_picture]
      @user = current_user
        if @user.update(user_picture: pic)
          render json: { "message": "Profile Picture Updated Successfully" }, status: :ok
        else
          render json: @user.errors.messages
        end
    end


  # GET /users/picture_show (for view the profile picture)
    def picture_show
      path =current_user.user_picture.path.present? ? current_user.user_picture.path.gsub("/home/altius/Uma/project/BC4_api/public/","http://192.168.1.238:4020/") : nil #{}"http://192.168.1.238:4020/uploads/notfount_image.jpg"
      user = User.select(:name, :email, :user_uid, :mobile_no, :id).find(current_user.id)
      cg_id = UserAssociation.where(patient_id: current_user.id).pluck(:caregiver_id) != [] ? UserAssociation.where(patient_id: current_user.id).pluck(:caregiver_id) : nil
      caregiver = User.where(id: cg_id)
      pat_id = UserAssociation.where(caregiver_id: current_user.id).pluck(:patient_id) != [] ? UserAssociation.where(caregiver_id: current_user.id).pluck(:patient_id) : nil
      patient = User.where(id: pat_id)
      render json: {profile_pic: path, user_info: user, caregiver: caregiver, patient: patient }, status: :ok
    end


  # GET /users/patient_list
    def patient_list
      pat_id = UserAssociation.where(caregiver_id: current_user.id).pluck(:patient_id) != [] ? UserAssociation.where(caregiver_id: current_user.id).pluck(:patient_id) : nil
      patient = User.where(id: pat_id)
      nick_name = UserAssociation.find_by(patient_id: pat_id, caregiver_id: current_user.id)
      render json: {patient: patient, nick_name: nick_name}, status: :ok
    end


    def show
      @user = User.find(params[:id]) 
    end

  # DELETE /users/1
    def destroy
        if (current_user.role_id == 3)
            if @user.destroy
                render json:{"info": "Deleted Successfully"}, status: :ok
            else
             render json: { error: 'The User not found' }, status: :unprocessable_entity
            end
        else
          render json: { error: 'You are not allowed' }, status: :unprocessable_entity
        end
    end


  # GET /users/user_uid
    def user_uid
      if (params[:user_uid] != nil)
        @pu_id = User.find_by(user_uid: params[:user_uid])
        if @pu_id.present?
          cg_ids = UserAssociation.where(patient_id: @pu_id.id).pluck(:caregiver_id) != [] ? UserAssociation.where(patient_id: @pu_id.id).pluck(:caregiver_id) : nil
          caregivers = User.where(id: cg_ids).where.not(email: nil, password: nil)
          if (caregivers.count < 2)
            caregiver = User.where(id: cg_ids).select(:name, :email, :mobile_no, :id)
            render json: { caregiver: caregiver }, status: :ok 
          else
            render json: { message: "The patient already have two caregivers" }, status: :unprocessable_entity
          end
        else
          render json: { message: 'false' }, status: :unauthorized
        end
      else
        render json: { error: 'User UID is missing' }, status: :unauthorized
      end
      # if (params[:user_uid] != nil)
      #     @pu_id = User.find_by(user_uid: params[:user_uid])
      #     if @pu_id.present?
      #       cg_id = UserAssociation.where(patient_id: @pu_id.id).pluck(:caregiver_id) != [] ? UserAssociation.where(patient_id: @pu_id.id).pluck(:caregiver_id) : nil
      #       caregiver = User.where(id: cg_id).select(:name, :email, :mobile_no, :id)
      #       render json: { caregiver: caregiver }
      #     else
      #       render json: { message: 'false' }, status: :unauthorized
      #     end
      # else
      #   render json: { error: 'User UID is missing' }, status: :unauthorized
      # end
    end


  # POST /users (for create the caregiver)
    def caregiver_register
      if (params[:user_uid] != nil)
        @pu_id = User.find_by(user_uid: params[:user_uid])
        if @pu_id.present?
          cg_ids = UserAssociation.where(patient_id: @pu_id.id).pluck(:caregiver_id) != [] ? UserAssociation.where(patient_id: @pu_id.id).pluck(:caregiver_id) : nil
          caregivers = User.where(id: cg_ids).where.not(email: nil, password: nil)
          if (caregivers.count < 2)
            pay_status = @pu_id.active_status
            if (pay_status == true)
              mob_no = User.find_by(mobile_no: params[:mobile_no], role_id: params[:role_id])
              if mob_no.present?
                @cg = mob_no.update(name: params[:name], email: params[:email], password: params[:password], active_status: true)
                @cg = mob_no
                  user_association = UserAssociation.find_by(patient_id: @pu_id.id, caregiver_id: @cg.id)
                  if user_association.present?
                    user_association = user_association.update(patient_id: @pu_id.id, caregiver_id: @cg.id)
                  end
                UserMailer.welcome_user(@cg).deliver_now
              else
                @cg = User.new(name: params[:name], email: params[:email], mobile_no: params[:mobile_no], password: params[:password], role_id: params[:role_id], active_status: true)
                if @cg.save
                  user_association = UserAssociation.create(patient_id: @pu_id.id, caregiver_id: @cg.id)  
                  UserMailer.welcome_user(@cg).deliver_now
                  render json: {cg: @cg, user_association: user_association}, status: :ok
                else
                  render json: { error: 'Mobile number or Email has been already taken' }, status: :unprocessable_entity
                end
              end
            else
              render json: { error: 'your patient needs to Subscription' }, status: :unauthorized
            end
          else
            render json: { message: "The patient already have two caregivers" }, status: :unprocessable_entity
          end
        else
          render json: { error: 'UID not valid' }, status: :unauthorized
        end
      end

      # if (params[:user_uid] != nil)
      #   @pu_id = User.find_by(user_uid: params[:user_uid])
      #   if @pu_id.present?
      #     pay_status = @pu_id.active_status
      #     if pay_status == true
      #       mob_no = User.find_by(mobile_no: params[:mobile_no], role_id: params[:role_id])
      #       if mob_no.present?
      #         @cg = mob_no.update(name: params[:name], email: params[:email], password: params[:password], active_status: true)
      #         @cg = mob_no
      #          user_association = UserAssociation.find_by(patient_id: @pu_id.id, caregiver_id: @cg.id)
      #           if user_association.present?
      #             user_association = user_association.update(patient_id: @pu_id.id, caregiver_id: @cg.id)
      #           end
      #         UserMailer.welcome_user(@cg).deliver_now
      #       else
      #         @cg = User.new(name: params[:name], email: params[:email], mobile_no: params[:mobile_no], password: params[:password], role_id: params[:role_id], active_status: true)
      #         if @cg.save
      #           user_association = UserAssociation.create(patient_id: @pu_id.id, caregiver_id: @cg.id)  
      #           UserMailer.welcome_user(@cg).deliver_now
      #           render json: {cg: @cg, user_association: user_association}, status: :ok
      #         else
      #           render json: { error: 'Mobile number or Email has been already taken' }, status: :unprocessable_entity
      #         end
      #       end
      #     else
      #       render json: { error: 'your patient needs to Subscription' }, status: :unauthorized
      #     end
      #   else
      #     render json: { error: 'UID not valid' }, status: :unauthorized        
      #   end
      # end
    end

  # POST /users/add_patient
    def add_patient
      if (current_user.role_id == 2)
        if (params[:user_uid] != nil)
          @uid = User.find_by(user_uid: params[:user_uid])
          if @uid.present?
            cg_ids = UserAssociation.where(patient_id: @uid.id).pluck(:caregiver_id) != [] ? UserAssociation.where(patient_id: @uid.id).pluck(:caregiver_id) : nil
            caregivers = User.where(id: cg_ids).where.not(email: nil, password: nil)
            if (caregivers.count <2)
              cuser = UserAssociation.find_by(patient_id: @uid.id, caregiver_id: current_user.id)
              if cuser.present?
                user_association_update = UserAssociation.find(cuser.id).update(patient_id: @uid.id, caregiver_id: current_user.id, nick_name: params[:nick_name])
                @user_association = UserAssociation.find(cuser.id)
              else
                @user_association = UserAssociation.create(patient_id: @uid.id, caregiver_id: current_user.id, nick_name: params[:nick_name])
              end
              patient_name = @user_association.nick_name
              render json: {patient_name: patient_name, patient_detail: @uid}, status: :ok #, assocation: @user_association
            else
              render json: { message: "The patient already have two caregivers" }, status: :unprocessable_entity
            end
          else
            render json: { error: 'UID not valid' }, status: :unauthorized
          end
        end
      else
        render json: { error: 'You are not a caregiver' }, status: :unauthorized
      end

      # if (current_user.role_id == 2)
      #   if (params[:user_uid] != nil)
      #     @uid = User.find_by(user_uid: params[:user_uid])
      #     # patient_name = params[:patient_name].present? ? params[:patient_name] : @uid.name
      #     if @uid.present?
      #       cuser = UserAssociation.find_by(patient_id: @uid.id, caregiver_id: current_user.id)
      #       if cuser.present?
      #         @user_association = UserAssociation.find(cuser.id).update(patient_id: @uid.id, caregiver_id: current_user.id, nick_name: params[:nick_name])
      #       else
      #         @user_association = UserAssociation.create(patient_id: @uid.id, caregiver_id: current_user.id, nick_name: params[:nick_name])
      #       end
      #         patient_name = @user_association.nick_name
      #         render json: {patient_name: patient_name, patient_detail: @uid}, status: :ok #, assocation: @user_association
      #     else
      #       render json: { error: 'UID not valid' }, status: :unauthorized  
      #     end 
      #   end
      # else
      #   render json: { error: 'You are not a caregiver' }, status: :unauthorized
      # end

    end

  # GET users/patient_delete
  def patient_delete
      if params[:patient_id].present?
        @user_association = UserAssociation.find_by(patient_id: params[:patient_id], caregiver_id: current_user.id)
        if @user_association.destroy
          render json: { message: ' Deleted Successfully' }
        else
          render json: { error: 'something went wrong' }
        end
      end
  end


  # GET users/identify_user (for identify the user based on given email)
    def identify_user
      user_email = params[:email]
      response = User.identify_user(user_email)
      render json: response
    end


  # GET users/verification_code (for verify the verification code)
    def verification_code
      user_id = params[:user_id]
      verification_code = params[:verification_code]
      response = User.verify_code(user_id, verification_code)
      render json: response
    end

  # POST users/password_updation (for update the new password)
    def password_updation
      user_id = params[:user_id]
      password = params[:password]
      if password.present?
        @password = User.find(params[:user_id]).update(password: params[:password])
        render json: @password, status: :ok
      else
        render json: { error: 'password can not be nil' }, status: :unauthorized
      end     
    end

  # GET users/user_details (to give the user details for QR code)
    def user_details
      if (params[:user_uid] != nil)
        user = User.select(:name, :blood_group, :age, :id, :user_picture).find_by(user_uid: params[:user_uid])
        path = user.user_picture.path.present? ? user.user_picture.path.gsub("/home/altius/Uma/project/BC4_api/public", "http://192.168.1.238:4020/") :nil
        contacts = EmergencyDetail.where(user_id: user.id)
        health_detail = HealthDetail.find_by(user_id: user.id, name: "health")
        policy_details = HealthDetail.find_by(user_id: user.id, name: "policy")
        render json: { user: user, profile_picture: path, contacts: contacts, health_detail: health_detail, policy_details: policy_details }, status: :ok
      else
        render json: { "error": "Give the user UID" }, status: :unprocessable_entity
      end
    end

  # GET users/preview 
    def preview
      user = User.select(:name, :blood_group, :age, :id).find(current_user.id)
      path = current_user.user_picture.path.present? ? current_user.user_picture.path.gsub("/home/altius/Uma/project/BC4_api/public/","http://192.168.1.238:4020/") : nil
      contacts = EmergencyDetail.where(user_id: user.id)
      health_detail = HealthDetail.find_by(user_id: user.id, name: "health")
      policy_details = HealthDetail.find_by(user_id: user.id, name: "policy")
      render json: { user: user, profile_picture: path, contacts: contacts, health_detail: health_detail, policy_details: policy_details }, status: :ok
    end

  private

    def set_user
  	  @user = User.find(params[:id])
    end

    def user_params
  	  params.require(:user).permit!#(:name, :email, :password, :mobile_no, :address, :country, :blood_group, :age, :public_uid, :role_id)
    end

    # def upload_params
    #   params.require(:upload).permit(:user_picture)
    # end
    
    # def caregiver_params
    #   params.require(:user).permit!#(:name, :email, :password, :mobile_no, :address, :country, :blood_group, :age, :public_uid, :user_picture, :role_id)
    # end


    # def define_order(attribute)
    #    attribute.start_with?("-") ? :desc : :asc
    # end

end