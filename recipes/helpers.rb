# Automatically sets the environment based on presence of 
# :stage (multistage gem), :rails_env, or RAILS_ENV variable; otherwise defaults to 'production'
def environment  
  if exists?(:stage)
    stage.to_s
  elsif exists?(:rails_env)
    rails_env.to_s
  elsif(ENV['RAILS_ENV'])
    ENV['RAILS_ENV'].to_s
  else
    "production"  
  end
end

# Run rake on the remote server(s), using the version of rake that has been
# specified (defaulting to whatever is in the path) and the correct RAILS_ENV
# (defaulting to production if not specified).  Pass in one or more tasks to
# run.  This always runs tasks against the latest release, so it's only valid
# to use after +update_code+ has been run.
def run_rake(*tasks)
  rake = fetch(:rake, 'rake')
  tasks.each do |task|
    run "cd #{latest_release}; #{rake} RAILS_ENV=#{environment} #{task}"
  end
end
