# require 'helpers'

Capistrano::Configuration.instance(true).load do
  set :local_ping_path, 'http://localhost'
 
  namespace :rails do
    # ===============================================================
    # UTILITY TASKS
    # ===============================================================
    desc "Symlinks the shared/config/database yaml to release/config/"
    task :symlink_db_config, :roles => :app do
      puts "Copying database configuration to release path"
      try_sudo "rm #{release_path}/config/database.yml -f"
      try_sudo "ln -s #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    end
    after "deploy:update_code", "rails:symlink_db_config" # copy database.yml file to release path

    desc "Repair permissions to allow user to perform all actions"
    task :repair_permissions, :roles => :app do
      puts "Applying correct permissions to allow for proper command execution"
      try_sudo "chmod -R 744 #{current_path}/log #{current_path}/tmp"
      try_sudo "chown -R #{user}:#{user} #{current_path}"
      try_sudo "chown -R #{user}:#{user} #{current_path}/tmp"
    end
    # after "deploy:restart", "rails:repair_permissions" # fix the permissions to work properly

    desc "Displays the log from the server locally"
    task :tail, :roles => :app do
      stream "tail -f #{shared_path}/log/#{environment}.log"
    end
 
    desc "Pings localhost to startup server"
    task :ping, :roles => :app do
      puts "Pinging the web server to start it"
      run "wget -O /dev/null #{local_ping_path} 2>/dev/null"
    end
    after "deploy:restart", "rails:ping" # ping passenger to start the rails instance
    
    # Because of nginx passenger bug - it just ignores rails_env
    # http://groups.google.com/group/phusion-passenger/browse_thread/thread/f91cd54bd379ad26/0a510133a080daac
    desc "Force application use current environment"
    task :force_env, :roles => :app do
      puts "Hardcode RAILS_ENV in config/environment.rb"
      out = []
      File.open(File.join '.', 'config', 'environment.rb').each_line do |s|
        if s.include? "ENV['RAILS_ENV']"
          out << "ENV['RAILS_ENV'] = '#{environment}' if defined? PhusionPassenger\n"
        else
          out << s
        end
      end
      put out.join(''), "#{latest_release}/config/environment.rb"
    end
    # after "deploy:update_code", "rails:force_env"

    # ===============================================================
    # MAINTENANCE TASKS
    # ===============================================================
    namespace :sweep do
      desc "Clear file-based fragment and action caching"
      task :log, :roles => :app  do
        puts "Sweeping all the log files"
        run "cd #{current_path} && #{sudo} rake log:clear RAILS_ENV=#{environment}"
      end
      after "deploy:update_code", "rails:sweep:cache" # clear cache after updating code
      
      desc "Clear file-based fragment and action caching"
      task :cache, :roles => :app do
        puts "Sweeping the fragment and action cache stores"
        run "cd #{release_path} && #{sudo} rake tmp:cache:clear RAILS_ENV=#{environment}"
      end
    end
  end
end
