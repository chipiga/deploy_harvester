# require 'helpers'
require 'yaml'

Capistrano::Configuration.instance(true).load do
  namespace :db do
    namespace :mysql do
      desc "Create MySQL database and user for this environment using prompted values"
      task :setup, :roles => :db, :only => { :primary => true } do
        set(:db_admin_user) { Capistrano::CLI.ui.ask "Username with priviledged database access (to create db):" }
        set(:db_name) { Capistrano::CLI.ui.ask "Enter basic database name:" }
        set :db_name, "#{db_name}_#{environment}"
        set(:db_user) { Capistrano::CLI.ui.ask "Enter #{environment} database username:" }
        set(:db_pass) { Capistrano::CLI.password_prompt "Enter #{environment} database password:" }

        sql = "CREATE DATABASE #{db_name}; GRANT ALL PRIVILEGES ON #{db_name}.* TO #{db_user}@localhost IDENTIFIED BY '#{db_pass}';"

        run "mysql --user=#{db_admin_user} -p --execute=\"#{sql}\"" do |channel, stream, data|
          if data =~ /^Enter password:/
            pass = Capistrano::CLI.password_prompt "Enter database password for '#{db_admin_user}':"
            channel.send_data "#{pass}\n" 
          end
        end
      end # setup

      desc "Create database.yml in shared path with settings for all env"
      task :create_yaml do
        set(:db_user) { Capistrano::CLI.ui.ask "Enter #{environment} database username:" }
        set(:db_pass) { Capistrano::CLI.password_prompt "Enter #{environment} database password:" }
        set(:db_name) { Capistrano::CLI.ui.ask "Enter basic database name:" }
        
        db_config = %Q{base: &base
  adapter: mysql
  host: localhost
  username: #{db_user}
  password: #{db_pass}

development:
  database: #{db_name}_development
  <<: *base

test:
  database: #{db_name}_test
  <<: *base

}
        stages.each do |s|
          db_config << %Q{#{s}:
  database: #{db_name}_#{s}
  <<: *base

}
        end

        put db_config, "#{shared_path}/config/database.yml"
      end # create_yaml

      desc 'Dumps the database to db/#{environment}-data.sql on the remote server'
      task :backup, :roles => :db, :only => { :primary => true } do
        get "#{latest_release}/config/database.yml", 'tmp/database.yml'
        db_config = YAML.load_file('tmp/database.yml')[environment]
        run_locally "rm tmp/database.yml"
        cmd = ['mysqldump --default-character-set=latin1']
        cmd << "--host='#{db_config['host']}'" unless db_config['host'].to_s.empty?
        cmd << "--user='#{db_config['username'].to_s.empty? ? 'root' : db_config['username']}'"
        cmd << "--password='#{db_config['password']}'" unless db_config['password'].to_s.empty?
        cmd << "-r #{latest_release}/db/#{environment}-data.sql"
        cmd << db_config['database']
        cmd << "; bzip2 -f #{latest_release}/db/#{environment}-data.sql"
        run cmd.flatten.join ' '
      end # create

      desc 'Loads an existing database dump into the current environment database'
      task :restore, :roles => :db, :only => { :primary => true } do
        get "#{latest_release}/config/database.yml", 'tmp/database.yml'
        db_config = YAML.load_file('tmp/database.yml')[environment]
        run_locally "rm tmp/database.yml"
        cmd = ["bzcat #{latest_release}/db/#{environment}-data.sql.bz2 | mysql"]
        cmd << "--host='#{db_config['host']}'" unless db_config['host'].to_s.empty?
        cmd << "--user='#{db_config['username'].to_s.empty? ? 'root' : db_config['username']}'"
        cmd << "--password='#{db_config['password']}'" unless db_config['password'].to_s.empty?
        cmd << db_config['database']
        run cmd.flatten.join ' '
      end # load
      
      desc 'Downloads db/#{environment}-data.sql from the remote environment to your local machine'
      task :download, :roles => :db, :only => { :primary => true } do
        get "#{latest_release}/db/#{environment}-data.sql.bz2", "db/#{environment}-data.sql.bz2"
      end # download

      desc 'Cleans up data dump file'
      task :cleanup, :roles => :db, :only => { :primary => true } do
        run "rm #{latest_release}/db/#{environment}-data.sql.bz2"
      end # cleanup

      desc 'Dumps, downloads and then cleans up the production data dump'
      task :runner do
        db.mysql.backup
        db.mysql.download
        db.mysql.cleanup
      end # runner
    end # mysql namespace
  end # db namespace
end
