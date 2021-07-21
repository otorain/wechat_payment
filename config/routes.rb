WechatPayment::Engine.routes.draw do
  post "/callback/payment", to: "callback#payment"
  post "/callback/refund", to: "callback#refund"
end
