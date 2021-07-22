class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  def create_initializer_file
    copy_file "initializer.rb", "config/initializers/wechat_payment.rb"
  end
end
