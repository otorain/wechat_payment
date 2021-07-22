class WechatPayment::RoutesGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  def mount_wechat_payment
    route %Q(mount WechatPayment::Engine => "/wechat_payment")
  end
end
