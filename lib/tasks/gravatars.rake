desc "Import avatars from a users gravatar url"

task :import_avatars => :environment do
  puts "Importing avatars from gravatar.com"
  User.get_gravatars
  puts "Avatars updated."
end