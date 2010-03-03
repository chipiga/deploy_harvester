# Domain
set :host, "192.168.1.1"
set :domain, "stage.app.com"
server host, :app, :web
role :db, host, :primary => true
# role :web, "stage.app.com"
# role :app, "stage.app.com"
# role :db,  "stage.app.com", :primary => true

#	Application
set :application, domain
set :deploy_to, "/application/rails/#{application}"
 
# GENERAL
set :user, "application"
set :use_sudo, false
# set :rails_env, stage
 
# Branch
# set :branch, 'staging'

# Recipes settings
set :local_ping_path, "http://#{domain}"
set :asset_directories, ['public/assets', 'public/uploads']

# Recipes hooks
after "deploy:update_code", "rails:symlink_db_config" # copy database.yml file to release path
after "deploy:restart", "tools:ping" # ping passenger to start the rails instance
after "deploy:update_code", "rails:sweep:cache" # clear cache after updating code
after 'deploy:setup', 'assets:directories:create'
after 'deploy:finalize_update', 'assets:directories:symlink'
after "deploy:update_code", "rails:force_env" # nginx passenger bug fix
