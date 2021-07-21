# WechatPayment
微信支付的 engine

## 使用
```ruby
user = User.first

product = Product.first

# 微信要传一个用户调起支付的 ip: spbill_create_ip ，文档上写必传，但是传空、固定ip、不传都不会报错，
# 但是还是给他加上了，保存到用户模型的 last_spbill_create_ip 属性上，实际使用中可以
# 在控制器里边通过 request.remote_ip 获取请求的 ip
client_ip = "45.12.112.31"  
user.spbill_create_ip = client_ip

order = user.buy(product)

result = order.pay 

# 返回给前端调起支付的数据
result[:js_payload]
```

## 约定
如无特殊说明

- 用户模型为`User`。
- 商品模型和用户商品关联模型自行创建, 商品表需要有 price 和 name 字段。
- 假设商品模型为`Product`，则用户和商品之间的关联模型为`UserProduct`，中间表属于`user`和`product`。

## 安装

1. 在`Gemfile`中添加

   ```ruby
   gem 'wechat_payment'
   ```

2. 执行 `bundle install`

3. 安装
   ```bash
   $ rails g wechat_payment:install
   $ rails db:migrate
   ```
   
4. 往用户表中添加`open_id`，string 类型，如果已有字段则不需要，open_id 需自行维护
   
5. 在用户表中引入 `WechatPayment::Concern::User`
    ```ruby
    # app/model/user.rb
    class User
      include WechatPayment::Concern::User
    end
   ```
6. 在商品模型中引入`WechatPayment::Concern::Goods`，并在用户商品关联模型中引入`WechatPayment::Concern::UserGoods`，这里假设商品模型是`Product`:
   ```ruby
   # app/model/product.rb
   class Product
     include WechatPayment::Concern::Goods
   end
   
   # app/model/user_product.rb
   class UserProduct
     include WechatPayment::Concern::UserGoods
   end
   ```

## 配置
打开 `config/initializers/wechat_payment.rb`，將里边的配置改成你自己的小程序配置


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

一个简单的例子
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
   "appid"=>"wxc5f26065c6471234",
   "sub_mch_id"=>"1525911234",
   "sub_appid"=>"wxf89f912345823dcd",
   "nonce_str"=>"ZUN2rEf6ATgYU8Lr",
   "sign"=>"3A216DB61196CEC63CE282D53FD1833F",
   "prepay_id"=>"wx281553565159884f81c452eb3f26b90000",
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
 "mch_id"=>"1363241802",
 "appid"=>"wxc5f26065c6471bcf",
 "sub_mch_id"=>"1525918291",
 "sub_appid"=>"wxf89f9547da823dcd",
 "nonce_str"=>"1jWLkg2YZjwnOozl",
 "sign"=>"3C80A1C9BD6CFDB7C37CCFCEAAF9E274"
} 
```
### payment_exec_success:
```ruby

{
  "appid" => "wxc5f26065c6471bcf",
  "bank_type" => "CMB_CREDIT",
  "cash_fee" => "1",
  "fee_type" => "CNY",
  "is_subscribe" => "N",
  "mch_id" => "1363241802",
  "nonce_str" => "e4ad44489a1f4e6f8a09d1299cfa59f6",
  "openid" => "omf2nv3OgYXBYrNqdx9eUucKy7NQ",
  "out_trade_no" => "1626765407380174189",
  "result_code" => "SUCCESS",
  "return_code" => "SUCCESS",
  "sign" => "608972A8540240303D0560B1E79511B4",
  "sub_appid" => "wxf89f9547da823dcd",
  "sub_is_subscribe" => "N",
  "sub_mch_id" => "1525918291",
  "sub_openid" => "ogT7J5YddGnll-ippRvJq62Nv8W0",
  "time_end" => "20210720151728",
  "total_fee" => "1",
  "trade_type" => "JSAPI",
  "transaction_id" => "4200001148202107205270712453"
}
```

### payment_exec_failure:
TODO 待补充

### refund_apply_success:
```ruby
{
  "return_code"=>"SUCCESS",
  "return_msg"=>"OK",
  "appid"=>"wxc5f2606121234cf",
  "mch_id"=>"1363241234",
  "sub_mch_id"=>"1525912341",
  "nonce_str"=>"RsXVcs0GMg2p5NRD",
  "sign"=>"F10AB3929B900DE4E189CA93B73D9D7A",
  "result_code"=>"SUCCESS",
  "transaction_id"=>"4200001199202106280049902399",
  "out_trade_no"=>"1624867410475591608",
  "out_refund_no"=>"1624867450917685776",
  "refund_id"=>"50301108952021062810183695009",
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
  "appid"=>"wxc5f26065c6471bcf",
  "mch_id"=>"1363241802",
  "sub_mch_id"=>"1525918291",
  "nonce_str"=>"gMDFilvaKanXW80W",
  "sign"=>"BA24E81B18B63ACAF112DF9F84CA5E21",
  "result_code"=>"FAIL",
  "err_code"=>"INVALID_REQUEST",
  "err_code_des"=>"订单已全额退款"
}

```

### refund_exec_success:
```ruby
{
  "out_refund_no"=>"1626765103919350974",
  "out_trade_no"=>"1626765007719492162",
  "refund_account"=>"REFUND_SOURCE_RECHARGE_FUNDS",
  "refund_fee"=>"1",
  "refund_id"=>"50301408672021072010826014924",
  "refund_recv_accout"=>"招商银行信用卡4003",
  "refund_request_source"=>"API",
  "refund_status"=>"SUCCESS",
  "settlement_refund_fee"=>"1",
  "settlement_total_fee"=>"1",
  "success_time"=>"2021-07-20 15:11:52",
  "total_fee"=>"1",
  "transaction_id"=>"4200001187202107202028998431"
}
```

### refund_exec_failure:
TODO 待补充

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).