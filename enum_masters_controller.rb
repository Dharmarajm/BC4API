require 'will_paginate/array'
class EnumMastersController < ApplicationController
  before_action :set_enum_master, only: [:show, :update, :destroy]

  # GET /enum_masters
  def index
    if params[:category_name].present?
        page_count = params[:per_page].present? ? params[:per_page]  : "7"
        page = params[:page].present? ? params[:page] : "1"
        filters = {"per_page" => page_count, "page" => page} 
        if params[:search].present?
          @enum_masters = EnumMaster.where(category_name: params[:category_name]).search_by_name(params[:search]).with_pg_search_highlight.pluck(:name)
          render json: @enum_masters
        else
          enum = EnumMaster.where(category_name: params[:category_name]).pluck(:name).uniq
          @enum_masters = enum.paginate(:page => page, :per_page => page_count)
          render json: { enum_masters: @enum_masters, filters: filters, count: @enum_masters.count }
      end
    else
      @enum_masters = EnumMaster.all
      render json: @enum_masters, status: :ok
      # category_name = EnumMaster.pluck(:category_name).uniq
      # render json: { "message": 'Category Name should be given', Category: category_name }, status: :unauthorized
    end 
  end

  # GET /enum_masters/1
  def show
    render json: @enum_master
  end

  # POST /enum_masters
  def create
    @enum_master = EnumMaster.new(enum_master_params)
    if @enum_master.save
      render json: @enum_master, status: :created, location: @enum_master
    else
      render json: @enum_master.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /enum_masters/1
  def update
    if @enum_master.update(enum_master_params)
      render json: @enum_master
    else
      render json: @enum_master.errors, status: :unprocessable_entity
    end
  end

  # DELETE /enum_masters/1
  def destroy
    @enum_master.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_enum_master
      @enum_master = EnumMaster.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def enum_master_params
      params.require(:enum_master).permit(:name, :category_name)
    end
end
