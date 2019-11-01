class ReportTypesController < ApplicationController
  before_action :set_report_type, only: [:show, :update, :destroy]

  # GET /report_types
  def index
    if params[:term].present?
      @report_types = ReportType.search_by_name(params[:term]).with_pg_search_highlight.pluck(:name)
      render json: @report_types
    else
      render json: false
    end
  end

  # GET /report_types/1
  def show
    render json: @report_type
  end

  # POST /report_types
  def create
    @report_type = ReportType.new(report_type_params)

    if @report_type.save
      render json: @report_type, status: :created, location: @report_type
    else
      render json: @report_type.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /report_types/1
  def update
    if @report_type.update(report_type_params)
      render json: @report_type
    else
      render json: @report_type.errors, status: :unprocessable_entity
    end
  end

  # DELETE /report_types/1
  def destroy
    @report_type.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_report_type
      @report_type = ReportType.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def report_type_params
      params.require(:report_type).permit(:name)
    end
end
