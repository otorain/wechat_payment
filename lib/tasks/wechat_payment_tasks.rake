# desc "Explaining what the task does"
# task :wechat_payment do
#   # Task goes here
# end

desc "Install Wechat Payment Engine"
namespace :wechat_payment do
  task install: :environment do
    Rake::Task["wechat_payment:install:migrations"].invoke
    sh "rails g wechat_payment:initializer wechat_payment"
    sh "rails g wechat_payment:routes wechat_payment"
  end
end