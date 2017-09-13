desc "run tests"
task :test do
  Dir.glob './test/test_*.rb' do |f|
    p f
    require f
  end
end
