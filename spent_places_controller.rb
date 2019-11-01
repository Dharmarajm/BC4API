class SpentPlacesController < ApplicationController
  before_action :set_spent_place, only: [:show, :update, :destroy]

  # GET /spent_places
  def index
    if params[:term].present?
      @spent_places = SpentPlace.search_by_name(params[:term]).with_pg_search_highlight.pluck(:name)
      render json: @spent_places
    else
      render json: false      
    end
  end

  # GET /spent_places/1
  def show
    render json: @spent_place
  end

  # POST /spent_places
  def create
    if (current_user.role_id == 1)
      @spent_place = SpentPlace.new(spent_place_params)

      if @spent_place.save
        render json: @spent_place, status: :created, location: @spent_place
      else
        render json: @spent_place.errors, status: :unprocessable_entity
      end
    end
  end

  # PATCH/PUT /spent_places/1
  def update
    if @spent_place.update(spent_place_params)
      render json: @spent_place
    else
      render json: @spent_place.errors, status: :unprocessable_entity
    end
  end

  # DELETE /spent_places/1
  def destroy
    @spent_place.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_spent_place
      @spent_place = SpentPlace.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def spent_place_params
      params.require(:spent_place).permit(:name)
    end
end
