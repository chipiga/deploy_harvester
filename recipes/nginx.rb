set :nginx_init_path, "/etc/init.d/nginx"

namespace :nginx do
  desc "Stops the nginx web server"
  task :stop, :roles => :web do
    puts "Stopping the nginx server"
    sudo "#{nginx_init_path} stop"
  end
  
  # To force this work with passenger you should change /etc/init.d/ngninx start to the following:
  # start-stop-daemon --start --quiet --pidfile /usr/local/nginx/logs/$NAME.pid -b --exec $DAEMON 
  # Notice: the extra -b option to fork to background.
  # http://groups.google.com/group/phusion-passenger/browse_thread/thread/df950f6769925714 
  desc "Starts the nginx web server"
  task :start, :roles => :web do
    puts "Starting the nginx server"
    sudo "#{nginx_init_path} start"
  end

  desc "Restarts the nginx web server"
  task :restart, :roles => :web do
    puts "Restarting the nginx server"
    # sudo "#{nginx_init_path} restart"
    stop
    start
  end
end
