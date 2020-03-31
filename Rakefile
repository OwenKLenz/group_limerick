desc "Delete all gamefiles from data directory"
task :reset do
  Dir.glob("*.yml", base: File.expand_path("../data", __FILE__)) do |file|
    path = File.expand_path(file, "data/")
    FileUtils.remove(path)
  end
end

desc "Run tests"
task :test do
  system 'bundle exec ruby test/group_limerick_test.rb'
end