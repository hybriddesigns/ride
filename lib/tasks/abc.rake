namespace :events do
  desc "Rake task to test whenever"
  task :fetch => :environment do
    @drivers=Driver.all
    @drivers.each do |x|
    	puts x.name
    end
    puts " "
  end
end

