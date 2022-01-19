
class PaymentOrdersController < ApplicationController
  def index
    @payment_orders = WechatPayment::PaymentOrder.by_state(params[:state])

    render json: @payment_orders
  end

end