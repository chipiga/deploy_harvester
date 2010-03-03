set :local_ping_path, 'http://localhost'

namespace :tools do
  desc "Pings localhost to startup server"
  task :ping, :roles => :app do
    puts "Pinging the web server to start it"
    run "wget -O /dev/null #{local_ping_path} 2>/dev/null"
  end
  # after "deploy:restart", "tools:ping" # ping passenger to start the app instance
  
  desc <<-TEXT
    Remove the cached copy of the code. This can sometimes be helpful
    when, for example, you've changed the upstream location of a git
    submodule. Git doesn't seem to want to update its working copy with
    that information, so chances are the easiest thing to do is nuke the
    cached copy and start again.
  TEXT
  task :rm_cached_copy, :except => { :no_release => true } do
    cache = strategy.send(:repository_cache)
    run "[ -d #{cache} ] && rm -rf #{cache}"
  end
end
