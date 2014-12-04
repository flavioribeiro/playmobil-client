namespace :capture do
  desc "Open client capture screen"
  task open_client: :environment do
    Client.run
  end

end
