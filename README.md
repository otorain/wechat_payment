# WechatPayment
微信支付的 engine


## Convention
在使用该 Engine 之前，需要先建立`用户模型`，`商品模型`，`用户商品关联模型`，用户表需要有 open_id 字段,
商品表需要有 price 和 name 字段。假设`商品模型`为`Product`，则用户和商品之间的关联模型为`UserProduct`，
关联模型属于`user`和`product`。

## Getting Started
1. 在`Gemfile`中添加
   ```ruby
     gem 'wechat_payment'
   ```

2. 执行 `bundle install`

3. 初始化
   ```bash
   # rails g wechat_payment:install [GoodsModel] [UserModel]
   $ rails g wechat_payment:install Product User
   $ rails db:migrate
   ```

## 配置
打开 `config/initializers/wechat_payment.rb`，將里边的配置改成你自己的小程序配置

## 支付
用户模型具有`buy`方法，而商品模型有`sell`方法，用户购买商品或商品售出都会产生一张订单，
调用订单的`pay`方法则会向微信发起下单请求，并将处理后的结果返回，此时返回的是一个`ServiceResult`对象，
执行该对象的`as_json`方法，得到的就是小程序需要拉起支付的参数

```ruby
user = User.first

product = Product.first

# 微信要传一个用户调起支付的 ip: spbill_create_ip ，文档上写必传，但是传空、固定ip、不传都不会报错，
# 但是还是给他加上了，保存到用户模型的 last_spbill_create_ip 属性上，实际使用中可以
# 在控制器里边通过 request.remote_ip 获取请求的 ip
# 
# user.spbill_create_ip = request.remote_ip
client_ip = "45.12.112.31"  
user.spbill_create_ip = client_ip

order = user.buy(product)

result = order.pay 

# 返回给前端调起支付的数据
result.as_json
```

## 退款
调用订单的`refund`，参数是退款金额，默认全额退款，执行成功后会创建一张退款订单，此时退款订单状态为 pending，
并返回退款下单的结果(`SerivceResult`对象)，如果成功，触发用户商品关联模型的`refund_apply_success`，
失败则触发`refund_apply_failure`

```ruby
payment_order = User.first.payment_orders.last
result = payment_order.refund

if result.success?
   # do something on success
else
   # do something on failure
end
```

## 事件
当支付进行时，会产生一些相应的事件，事件会触发相应的钩子，如果有事先定义的话。钩子方法需定义在用户商品关联(如`UserProduct`)模型中，
且每个钩子接收一个参数 result ，事件和钩子的对应关系如下：

|        事件       |        钩子       |
|  :-------------- | :--------------- |
| 支付下单成功        | payment_apply_success |
| 支付下单失败        | payment_apply_failure |
| 支付成功(回调)      | payment_exec_success |
| 支付失败(回调)      | payment_exec_failure |
| 申请退款成功        | refund_apply_success |
| 申请退款失败        | refund_apply_failure |
| 退款成功(回调)      | refund_exec_success |
| 退款失败(回调)      | refund_exec_failure |

一个简单的事件处理的例子
```ruby
# app/model/user_product.rb
class UserProduct
   # result 结构见下文说明
  def payment_exec_success(result)
    update(state: :paid)
  end
end
```

每个钩子接收的参数结构可能不一样:

### payment_apply_success:
```ruby
{
   "return_code"=>"SUCCESS",
   "return_msg"=>"OK",
   "result_code"=>"SUCCESS",
   "mch_id"=>"12312412312",
   "appid"=>"wxc5acd06cc6a7ac12",
   "sub_mch_id"=>"1526921451",
   "sub_appid"=>"wxf89f912345823dcd",
   "nonce_str"=>"ZUN2rEf6ATgYU8Lr",
   "sign"=>"3A216DB61196CE2313CE21182D53FD1833F",
   "prepay_id"=>"wx2815535651598812181c452eb3f26b90000",
   "trade_type"=>"JSAPI"
}
```

###  payment_apply_failure:
```ruby
{
   "return_code"=>"SUCCESS",
   "return_msg"=>"OK",
   "result_code"=>"FAIL",
   "err_code_des"=>"该订单已支付",
   "err_code"=>"ORDERPAID",
   "mch_id"=>"12312412312",
   "appid"=>"wxc5acd06cc6a7ac12",
   "sub_mch_id"=>"1526921451",
   "sub_appid"=>"wxf89f912345823dcd",
   "nonce_str"=>"1jWLkg2YZjwnOozl",
   "sign"=>"3C210A1C9BD6CFDB7C37CCFCA1AAF9E274"
} 
```

### payment_exec_success:
```ruby
{
   "appid" => "wxc5acd06cc6a7ac12",
   "bank_type" => "CMB_CREDIT",
   "cash_fee" => "1",
   "fee_type" => "CNY",
   "is_subscribe" => "N",
   "mch_id" => "12312412312",
   "nonce_str" => "e42ad44489a1f4e6f8a09d1299cfa59f6",
   "openid" => "oef2nsaOcYcBYrNq1x9eUucKy7NQ",
   "out_trade_no" => "16267654023120174189",
   "result_code" => "SUCCESS",
   "return_code" => "SUCCESS",
   "sign" => "608972A854024030332360B1E79511B4",
   "sub_appid" => "wxf89f912345823dcd",
   "sub_is_subscribe" => "N",
   "sub_mch_id" => "1526921451",
   "sub_openid" => "oef2nsaOcYcBYrNq1x9eUucKy7NQ",
   "time_end" => "20210720151228",
   "total_fee" => "1",
   "trade_type" => "JSAPI",
   "transaction_id" => "4200001153233202137201270712453"
}
```

### payment_exec_failure:
TODO 待补充

### refund_apply_success:
```ruby
{
   "return_code"=>"SUCCESS",
   "return_msg"=>"OK",
   "appid"=>"wxc5acd06cc6a7ac12",
   "mch_id"=>"12312412312",
   "sub_mch_id"=>"1526921451",
   "nonce_str"=>"RsXVcs0GMg2p5NRD",
   "sign"=>"F10AB3929B900DE4E189CA93B12D9D7A",
   "result_code"=>"SUCCESS",
   "transaction_id"=>"420000119112202101210049902399",
   "out_trade_no"=>"1624867410141191608",
   "out_refund_no"=>"16248674504421685776",
   "refund_id"=>"50301108952025421210183695009",
   "refund_channel"=>"",
   "refund_fee"=>"1",
   "coupon_refund_fee"=>"0",
   "total_fee"=>"1",
   "cash_fee"=>"1",
   "coupon_refund_count"=>"0",
   "cash_refund_fee"=>"1"
}
```

### refund_apply_failure:
```ruby
{
   "return_code"=>"SUCCESS",
   "return_msg"=>"OK",
   "appid"=>"wxc5acd06cc6a7ac12",
   "mch_id"=>"12312412312",
   "sub_mch_id"=>"1526921451",
   "nonce_str"=>"gMDFilvaKanXW80W",
   "sign"=>"BA24E81B18B12AAC112DF9F84CA5E21",
   "result_code"=>"FAIL",
   "err_code"=>"INVALID_REQUEST",
   "err_code_des"=>"订单已全额退款"
}

```

### refund_exec_success:
```ruby
{
   "out_refund_no"=>"16421102919350974",
   "out_trade_no"=>"1626761001219492162",
   "refund_account"=>"REFUND_SOURCE_RECHARGE_FUNDS",
   "refund_fee"=>"1",
   "refund_id"=>"503014086722221012110826014924",
   "refund_recv_accout"=>"招商银行信用卡4012",
   "refund_request_source"=>"API",
   "refund_status"=>"SUCCESS",
   "settlement_refund_fee"=>"1",
   "settlement_total_fee"=>"1",
   "success_time"=>"2021-07-20 15:11:52",
   "total_fee"=>"1",
   "transaction_id"=>"42000011872021002028121998431"
}
```

### refund_exec_failure:
TODO 待补充


## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).