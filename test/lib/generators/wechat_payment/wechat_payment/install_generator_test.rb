require "test_helper"
require "generators/wechat_payment/install/install_generator"

module WechatPayment
  class WechatPayment::InstallGeneratorTest < Rails::Generators::TestCase
    tests WechatPayment::InstallGenerator
    destination Rails.root.join('tmp/generators')
    setup :prepare_destination

    # test "generator runs without errors" do
    #   assert_nothing_raised do
    #     run_generator ["arguments"]
    #   end
    # end
  end
end
