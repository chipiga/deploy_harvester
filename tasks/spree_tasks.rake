namespace :spree do
  desc "Disable SSL in production environment"
  task :disable_ssl => :environment do
    Spree::Config.set(:allow_ssl_in_production => false)
  end
end
