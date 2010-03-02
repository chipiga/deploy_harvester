Capistrano::Configuration.instance(true).load do
  set :passenger_path, "/usr/bin"
  namespace :passenger do
    desc "Restart Rails app running under Phusion Passenger by touching restart.txt"
    task :restart, :roles => :app do
      run "#{try_sudo} touch #{File.join(latest_release,'tmp','restart.txt')}"
    end
 
    desc "Inspect Phusion Passenger's memory usage"
    task :memory, :roles => :app do
      sudo "#{passenger_path}/passenger-memory-stats"
    end
        
    desc "Inspect Phusion Passenger's internal status"
    task :status, :roles => :app do
      sudo "#{passenger_path}/passenger-status"
    end
  end
  
  namespace :deploy do
    desc "Restarting passenger with restart.txt"
    task :restart, :roles => :app, :except => { :no_release => true } do
      passenger.restart
    end
  
    [:start, :stop].each do |t|
      desc "#{t} task is a no-op with passenger"
      task t, :roles => :app do ; end
    end
  end
end
