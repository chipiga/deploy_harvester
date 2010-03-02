Capistrano::Configuration.instance(true).load do
  desc <<-TEXT
  Clone the deployment environment to your current environment. This will back
  up the current database and any assets from the production environment, copy
  them locally and load them. WARNING: This will totally and utterly destroy the
  current data contents of your local environment. Don't do this unless you're
  paying attention!
  TEXT
  task :replicate, :roles => [ :db ], :only => { :primary => true } do
    source_env = environment
    target_env = ENV['TARGET_ENV'] || 'development'

    find_and_execute_task("db:mysql:backup")
    find_and_execute_task("db:mysql:download")
    find_and_execute_task("assets:backup")
    find_and_execute_task("assets:download")

    db_config = YAML.load_file('config/database.yml')[target_env]
    cmd = ["bzcat db/#{source_env}-data.sql.bz2 | mysql"]
    cmd << "--host='#{db_config['host']}'" unless db_config['host'].to_s.empty?
    cmd << "--user='#{db_config['username'].to_s.empty? ? 'root' : db_config['username']}'"
    cmd << "--password='#{db_config['password']}'" unless db_config['password'].to_s.empty?
    cmd << db_config['database']
    run_locally cmd.flatten.join ' '

    unless asset_directories.empty?
      asset_directories.each do |dir|
        run_locally "rm -rf #{dir}"
      end
      run_locally "tar jxf #{source_env}-assets.tar.bz2"
    end
  end

  depend :local, :command, "bzcat"
  depend :local, :command, "tar"
  depend :local, :command, "mysql"
end
