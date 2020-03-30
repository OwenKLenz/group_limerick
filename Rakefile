desc "Delete all gamefiles from data directory"
task :reset do
  Dir.glob("*.yml", base: File.expand_path("../test_dir", __FILE__)) do |file|
    path = File.expand_path(file, "data/")
    binding.pry
    FileUtils.remove(path)
  end
end