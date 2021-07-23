class WechatPayment::InstallGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  class_option :user, type: :string, default: :user

  # 生成 initializer 文件
  def gen_initializer_file
    copy_file "initializer.rb", "config/initializers/wechat_payment.rb"
  end

  # 挂载 engine 到路由上
  def mount_payment_engine
    route %Q(mount WechatPayment::Engine => "/wechat_payment")
  end

  # 安装迁移文件
  def copy_migration
    Rake::Task["wechat_payment:install:migrations"].invoke
  end

  def add_concern_to_goods
    goods_model_head_one = "class #{goods_model_name} < ApplicationRecord"
    inject_into_file goods_model_file, after: goods_model_head_one do <<-GOODS_CONCERN

  include WechatPayment::Concern::Goods
#{def_custom_user_model}
    GOODS_CONCERN
    end
  end

  def add_concern_to_users
    user_model_head_one = "class #{user_model_name} < ApplicationRecord"
    inject_into_file user_model_file, after: user_model_head_one do <<-'USERS_CONCERN'

  include WechatPayment::Concern::User
    USERS_CONCERN
    end
  end

  def add_concern_to_user_goods
    user_goods_model_head_one = "class #{user_goods_model_name} < ApplicationRecord"
    inject_into_file user_goods_model_file, after: user_goods_model_head_one do <<-'USER_GOOD_CONCERN'

  include WechatPayment::Concern::UserGoods
    USER_GOOD_CONCERN
    end
  end

  private

  def goods_model_file
    "app/models/#{name.to_s.underscore}.rb"
  end

  def user_model_file
    "app/models/#{options[:user].to_s.underscore}.rb"
  end

  def user_goods_model_file
    "app/models/#{options[:user].to_s.underscore}_#{name.to_s.underscore}.rb"
  end

  def goods_model_name
    name.to_s.camelize
  end

  def user_model_name
    options[:user].to_s.camelize
  end

  def user_goods_model_name
    user_model_name + goods_model_name
  end

  def def_custom_user_model
    if user_model_name != 'User'
      <<-DEF
  self.user_model = "#{user_model_name}"
  self.user_ref_field = "#{user_model_name.underscore}"
  self.user_goods_model = "#{user_model_name}#{goods_model_name}"
      DEF
    end
  end
end
