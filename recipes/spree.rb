namespace :spree do
  desc 'Bootstrap EMPTY spree database with default data'
  task :bootstrap, :roles => :db, :only => { :primary => true } do
    run "cd #{latest_release} && " +
      "echo -e 'no' | rake RAILS_ENV=#{environment} db:bootstrap --trace"
  end
  
  desc 'Disable SSL when it is not possible through web interface'
  task :disable_ssl, :roles => :db, :only => { :primary => true } do
    run_rake 'spree:disable_ssl'
  end
  
  desc 'Performs clean spree install'
  task :install do
    deploy.setup
    deploy.update_code
    db.create.database
    db.create.yaml
    spree.bootstrap
    spree.disable_ssl
    deploy.symlink
    deploy.restart
  end
end
