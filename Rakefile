desc "default task"
task default: :test

desc "run tests"
task :test do
  Dir.glob './test/test_*.rb' do |f|
    p f
    require f
  end
end

desc "set coverage "
task :set_cov_env do
  ENV['COVERAGE'] = '1'
end

desc "test and generate coverage"
task :cov => [:set_cov_env, :test]
