Rails.application.routes.draw do
  mount WechatPayment::Engine => "/wechat_payment"
end
