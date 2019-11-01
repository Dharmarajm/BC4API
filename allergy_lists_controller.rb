class AllergyListsController < ApplicationController
  before_action :set_allergy_list, only: [:show, :update, :destroy]

  # GET /allergy_lists
  def index
  	if params[:term].present?
  		@allergy_lists = AllergyList.search_by_name(params[:term]).with_pg_search_highlight.pluck(:name)
      render json: @allergy_lists 		
  	else
        render json: false
    end 
  end

  # GET /allergy_lists/1
  def show
    render json: @allergy_list
  end

  # POST /allergy_lists
  def create
    if (current_user.role_id == 1)
      @allergy_list = AllergyList.new(allergy_list_params)

      if @allergy_list.save
        render json: @allergy_list, status: :created, location: @allergy_list
      else
        render json: @allergy_list.errors, status: :unprocessable_entity
      end
    end
  end

  # PATCH/PUT /allergy_lists/1
  def update
    if @allergy_list.update(allergy_list_params)
      render json: @allergy_list
    else
      render json: @allergy_list.errors, status: :unprocessable_entity
    end
  end

  # DELETE /allergy_lists/1
  def destroy
    @allergy_list.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_allergy_list
      @allergy_list = AllergyList.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def allergy_list_params
      params.require(:allergy_list).permit(:name)
    end
end
