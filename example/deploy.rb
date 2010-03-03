# =============================================================================
# STAGE SETTINGS
# =============================================================================
# set :stages, %w(production staging)
set :default_stage, "staging"
require 'capistrano/ext/multistage'

# =============================================================================
# GENERAL SETTINGS
# =============================================================================
# set :application,  "demo"
# set :deploy_to,  "/application/rails/#{application}"
set :deploy_via, :remote_cache
set :scm, :git
set :repository, "git@github.com:user/project.git"
set :git_enable_submodules, 1
# set :scm_verbose, true
# set :git_shallow_clone, 1
set :keep_releases, 3
 
# =============================================================================
# SSH OPTIONS
# =============================================================================
# ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "demo")]
ssh_options[:forward_agent] = true
default_run_options[:pty] = true

# =============================================================================
# RECIPE INCLUDES
# =============================================================================
# require 'rubygems'
# require 'cap_recipes/tasks/apache'
# require 'cap_recipes/tasks/passenger'
# require 'cap_recipes/tasks/rails'

# Custom user recipes
# $: << File.dirname(__FILE__)
# require 'deploy/recipes/nginx_config'
# require 'deploy/recipes/setup'
# require 'deploy/recipes/symlink'
