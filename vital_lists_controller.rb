class VitalListsController < ApplicationController
  before_action :set_vital_list, only: [:show, :update, :destroy]

  # GET /vital_lists
  def index
    if params[:term].present?
      @vital_lists = VitalList.search_by_name(params[:term]).with_pg_search_highlight.pluck(:name)
      render json: @vital_lists
    else
      render json: false
    end
  end

  # GET /vital_lists/1
  def show
    render json: @vital_list
  end

  # POST /vital_lists
  def create
    if (current_user.role_id == 1)
      @vital_list = VitalList.new(vital_list_params)

      if @vital_list.save
        render json: @vital_list, status: :created, location: @vital_list
      else
        render json: @vital_list.errors, status: :unprocessable_entity
      end
    end
  end

  # PATCH/PUT /vital_lists/1
  def update
    if @vital_list.update(vital_list_params)
      render json: @vital_list
    else
      render json: @vital_list.errors, status: :unprocessable_entity
    end
  end

  # DELETE /vital_lists/1
  def destroy
    @vital_list.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vital_list
      @vital_list = VitalList.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def vital_list_params
      params.require(:vital_list).permit(:name)
    end
end
