class EventTypeListsController < ApplicationController
  before_action :set_event_type_list, only: [:show, :update, :destroy]

  # GET /event_type_lists
  def index
    @event_type_lists = EventTypeList.all

    render json: @event_type_lists
  end

  # GET /event_type_lists/1
  def show
    render json: @event_type_list
  end

  # POST /event_type_lists
  def create
    @event_type_list = EventTypeList.new(event_type_list_params)

    if @event_type_list.save
      render json: @event_type_list, status: :created, location: @event_type_list
    else
      render json: @event_type_list.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /event_type_lists/1
  def update
    if @event_type_list.update(event_type_list_params)
      render json: @event_type_list
    else
      render json: @event_type_list.errors, status: :unprocessable_entity
    end
  end

  # DELETE /event_type_lists/1
  def destroy
    @event_type_list.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event_type_list
      @event_type_list = EventTypeList.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def event_type_list_params
      params.require(:event_type_list).permit(:name)
    end
end
