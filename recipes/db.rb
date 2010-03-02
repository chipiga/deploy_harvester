require 'yaml'

namespace :db do
  namespace :create do
    desc "Create MySQL database and user for this environment using prompted values"
    task :database, :roles => :db, :only => { :primary => true } do
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
    end

    desc "Create database.yml in shared path with settings for all env"
    task :yaml do
      set(:db_user) { Capistrano::CLI.ui.ask "Enter #{environment} database username:" }
      set(:db_pass) { Capistrano::CLI.password_prompt "Enter #{environment} database password:" }
      set(:db_name) { Capistrano::CLI.ui.ask "Enter basic database name:" }
      set(:db_adapter) { Capistrano::CLI.ui.ask "Enter #{environment} database adapter:" }
      
      db_config = <<-CONFIG
base: &base
  adapter: #{db_adapter}
  host: localhost
  username: #{db_user}
  password: #{db_pass}

development:
  database: #{db_name}_development
  <<: *base

test:
  database: #{db_name}_test
  <<: *base

CONFIG

      stages.each do |s|
        db_config << <<-CONFIG
#{s}:
  database: #{db_name}_#{s}
  <<: *base

CONFIG
      end

      put db_config, "#{shared_path}/config/database.yml"
    end
  end

  namespace :backup do
    desc 'Dumps the database to db/#{environment}-data.sql on the remote server'
    task :dump, :roles => :db, :only => { :primary => true } do
      # get "#{latest_release}/config/database.yml", 'tmp/database.yml'
      # db_config = YAML.load_file('tmp/database.yml')[environment]
      # run_locally "rm tmp/database.yml"
      # cmd = ['mysqldump --default-character-set=latin1']
      # cmd << "--host='#{db_config['host']}'" unless db_config['host'].to_s.empty?
      # cmd << "--user='#{db_config['username'].to_s.empty? ? 'root' : db_config['username']}'"
      # cmd << "--password='#{db_config['password']}'" unless db_config['password'].to_s.empty?
      # cmd << "-r #{latest_release}/db/#{environment}-data.sql"
      # cmd << db_config['database']
      # cmd << "; bzip2 -f #{latest_release}/db/#{environment}-data.sql"
      # run cmd.flatten.join ' '
      run_rake "db:backup:dump"
    end

    desc 'Loads an existing database dump into the current environment database on the remote server'
    task :restore, :roles => :db, :only => { :primary => true } do
      # get "#{latest_release}/config/database.yml", 'tmp/database.yml'
      # db_config = YAML.load_file('tmp/database.yml')[environment]
      # run_locally "rm tmp/database.yml"
      # cmd = ["bzcat #{latest_release}/db/#{environment}-data.sql.bz2 | mysql"]
      # cmd << "--host='#{db_config['host']}'" unless db_config['host'].to_s.empty?
      # cmd << "--user='#{db_config['username'].to_s.empty? ? 'root' : db_config['username']}'"
      # cmd << "--password='#{db_config['password']}'" unless db_config['password'].to_s.empty?
      # cmd << db_config['database']
      # run cmd.flatten.join ' '
      # TODO?
    end
  
    desc 'Downloads db/#{environment}-data.sql from the remote environment to your local machine'
    task :download, :roles => :db, :only => { :primary => true } do
      get "#{latest_release}/db/#{environment}-data.sql.bz2", "db/#{environment}-data.sql.bz2"
    end

    desc 'Remove database dump file'
    task :cleanup, :roles => :db, :only => { :primary => true } do
      run "rm #{latest_release}/db/#{environment}-data.sql.bz2"
    end

    desc 'Dumps, downloads and then cleans up the remote db backup'
    task :runner do
      backup
      download
      cleanup
    end
  end
end

# before "deploy:migrate", "db:backup:dump"
# before "deploy:migrations", "deploy:web:disable"
# after  "deploy:migrations", "deploy:web:enable"

# Note the dependency this code creates on mysqldump and bzip2
depend :remote, :command, 'mysqldump'
depend :remote, :command, 'bzip2'
