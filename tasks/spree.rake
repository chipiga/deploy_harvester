namespace :spree do
  desc "Disable SSL in production environment"
  task :disable_ssl => :environment do
    Spree::Config.set(:allow_ssl_in_production => false)
  end
  
  desc "Rebuild Spree taxons and recreate permalinks"
  task :rebuild_taxons => :environment do
    Taxon.rebuild!
    Taxon.all.each{|t| t.send(:set_permalink); t.save}
  end
end
