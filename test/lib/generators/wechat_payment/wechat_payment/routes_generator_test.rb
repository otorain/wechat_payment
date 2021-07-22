require "test_helper"
require "generators/wechat_payment/routes/routes_generator"

module WechatPayment
  class WechatPayment::RoutesGeneratorTest < Rails::Generators::TestCase
    tests WechatPayment::RoutesGenerator
    destination Rails.root.join('tmp/generators')
    setup :prepare_destination

    # test "generator runs without errors" do
    #   assert_nothing_raised do
    #     run_generator ["arguments"]
    #   end
    # end
  end
end
