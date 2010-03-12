require 'ya2yaml'

namespace :db do
  desc "Dump a class to YML, give class name in square brackets, use rake -s for silent"
  task :dump_utf8 , [:clazz]  => :environment do  |t , args|
    clazz = eval(args.clazz)
    objects = {}
    clazz.find( :all ).each do |obj|
      attributes = obj.attributes
      attributes.delete("created_at")   
      attributes.delete("updated_at")   
      name = attributes["name"] 
      unless name
        name = args.clazz 
        name = name +   "_" + attributes["id"].to_s if attributes["id"]
      end
      name = name.gsub( " " , "_")
      objects[name] = attributes
    end
    puts objects.ya2yaml
  end
  
  namespace :backup do
    desc "Dumps the database for the current environment into db/environment-data.sql.bz2."
    task :dump => :environment do
      abc = ActiveRecord::Base.configurations[RAILS_ENV]
      case abc['adapter']
      when 'mysql'
        cmd = ['mysqldump --default-character-set=latin1']
        cmd << "--host='#{abc['host']}'" unless abc['host'].blank?
        cmd << "--user='#{abc['username'].blank? ? 'root' : abc['username']}'"
        cmd << "--password='#{abc['password']}'" unless abc['password'].blank?
        cmd << "-r #{RAILS_ROOT}/db/#{RAILS_ENV}-data.sql"
        cmd << abc['database']
        cmd << "; bzip2 -f #{RAILS_ROOT}/db/#{RAILS_ENV}-data.sql"
        sh cmd.flatten.join ' '
      else
        raise "Task not supported by '#{abc['adapter']}'."
      end
    end
 
    desc <<-TEXT
Loads an existing database dump into the current environment's database.
WARNING: this completely nukes the existing database! Use SOURCE_ENV to
specify which dump should be loaded. Defaults to 'production'."
TEXT
    task :restore => [ :environment, "db:drop", "db:create" ] do
      source_env = ENV['SOURCE_ENV'] || 'production'
 
      abc = ActiveRecord::Base.configurations[RAILS_ENV]
      case abc['adapter']
      when 'mysql'
        cmd = ["bzcat #{RAILS_ROOT}/db/#{source_env}-data.sql.bz2 | mysql"]
        cmd << "--host='#{abc['host']}'" unless abc['host'].blank?
        cmd << "--user='#{abc['username'].blank? ? 'root' : abc['username']}'"
        cmd << "--password='#{abc['password']}'" unless abc['password'].blank?
        cmd << abc['database']
        sh cmd.flatten.join ' '
      else
        raise "Task not supported by '#{abc['adapter']}'."
      end
    end
  end
end