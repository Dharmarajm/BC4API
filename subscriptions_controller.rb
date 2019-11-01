class SubscriptionsController < ApplicationController
  before_action :set_subscription, only: [:show, :update, :destroy]
  skip_before_action :authenticate_request, only: %i[app_amount apply_coupon make_payment]

  # GET /subscriptions
  def index
    @subscriptions = Subscription.all

    render json: @subscriptions
  end

  # GET /subscriptions/1
  def show
    render json: @subscription
  end


  # GET /app_amount for application amount from env 
  def app_amount
      amount = ENV["app_amount"]
      render json: amount
  end

  # GET subscriptions/apply_coupon for apply coupon api using discounted price
  def apply_coupon
    if params[:user_id].present? #params["original_amt"].present?
      data =  params[:offer_id].present? ? params[:offer_id] : 1
      percentage = Offer.find(data).percentage.to_f
      app_amount = ENV["app_amount"].to_f
      discount_price =  app_amount *  (percentage / 100) #params[:original_amt] * Offer.find(data).percentage
      pay_amount = app_amount - discount_price # pay_amount = params[:original_amt] - price
      render json: {amount: pay_amount}, status: :ok
    else
      render json: { error: "user_id should be given" }, status: :unauthorized
    end
  end

  # POST /subscriptions/make_payment for payment
  def make_payment
    payment_id = params[:payment_id]
    user_id = params[:user_id]
    offer_id = params[:offer_id]
    response = Subscription.make_payment(payment_id, user_id, offer_id)
    render json: response
  end

  # POST /subscriptions
  def create
    @subscription = Subscription.new(subscription_params)

    if @subscription.save
      render json: @subscription, status: :created, location: @subscription
    else
      render json: @subscription.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /subscriptions/1
  def update
    if @subscription.update(subscription_params)
      render json: @subscription
    else
      render json: @subscription.errors, status: :unprocessable_entity
    end
  end

  # DELETE /subscriptions/1
  def destroy
    @subscription.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def subscription_params
      params.require(:subscription).permit(:user_id, :start_date, :end_date, :razorpay_detail, :offer_id, :original_amt, :payment_status)
    end
end
