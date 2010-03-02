namespace :spree do
  desc 'Bootstrap EMPTY spree database with default data'
  task :bootstrap, :roles => :db, :only => { :primary => true } do
    run "cd #{deploy_to}/#{current_dir} && " +
      "echo -e 'no' | rake RAILS_ENV=#{environment} db:bootstrap --trace"
  end
  
  desc 'Disable SSL when it is not possible through web interface'
  task :disable_ssl, :roles => :db, :only => { :primary => true } do
    run_rake 'spree:disable_ssl'
  end
end
