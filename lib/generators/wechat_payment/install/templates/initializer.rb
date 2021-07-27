
WechatPayment.setup do |config|
  # 接收回调的域名
  config.host = "https://xxx.com"

  # 下面所有参数都需要改成你自己的小程序配置
  config.appid = "wxc5c26065c6123456"
  config.app_secret = "123456784aa91bb538867d3d2790b308"
  config.mch_id = "112241802"
  config.key = "123456723erivPO09irNNbh78u8udwFer"

  # 证书可以在微信支付后台获取到，路径是相对于项目根路径，如果需要退款的话，则必须要证书
  # config.cert_path = "config/apiclient_cert.p12"
  config.cert_path = nil

  config.sub_appid = "wx8f9f912623456789"
  config.sub_mch_id = "1234911291"
  config.sub_app_secret = "88888231e2f3a21152d163f61b99999"
end