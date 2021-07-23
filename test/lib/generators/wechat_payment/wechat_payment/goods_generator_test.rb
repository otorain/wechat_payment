require "test_helper"
require "generators/wechat_payment/goods/goods_generator"

module WechatPayment
  class WechatPayment::GoodsGeneratorTest < Rails::Generators::TestCase
    tests WechatPayment::GoodsGenerator
    destination Rails.root.join('tmp/generators')
    setup :prepare_destination

    # test "generator runs without errors" do
    #   assert_nothing_raised do
    #     run_generator ["arguments"]
    #   end
    # end
  end
end
