require 'fileutils'
require 'open-uri'
require 'json'
require File.expand_path(File.dirname(__FILE__) + '/misc/test_support')

include FileUtils

def create_app_dir(source, startup_file, dir_name)
  app_root = "/home/app/#{dir_name}"
  rm_rf(app_root)
  mkdir(app_root)
  cp("/system/internal/test/misc/#{source}", "#{app_root}/#{startup_file}")
  mkdir("#{app_root}/public")
  mkdir("#{app_root}/tmp")
  chown_R('app', 'app', app_root)
  app_root
end

def create_app_dirs
  app_dirs = []
  app_dirs << create_app_dir('ruby_test_app.rb', 'config.ru', 'ruby_test_app')
  app_dirs << create_app_dir('python_test_app.py', 'passenger_wsgi.py', 'python_test_app')
  app_dirs << create_app_dir('nodejs_test_app.js', 'app.js', 'nodejs_test_app')
  app_dirs
end

def list_passenger_instances
  output = `passenger-config list-instances --json`
  if $?.exitstatus != 0
    abort "The command 'passenger-config list-instances --json' failed"
  end
  JSON.parse(output)
end

def passenger_instance_fully_initialized?(instance)
  !instance['core_pid'].nil?
end

shared_examples_for 'Hello world Ruby application' do
  it 'works' do
    if RUBY_VERSION >= '2.5'
      URI.open('http://passenger.test/', 'rb') do |io|
        expect(io.read).to eql("Hello Ruby\n")
      end
    else
      open('http://passenger.test/', 'rb') do |io|
        expect(io.read).to eql("Hello Ruby\n")
      end
    end
  end
end

shared_examples_for 'Hello world Python application' do
  it 'works' do
    if RUBY_VERSION >= '2.5'
      URI.open('http://1.passenger.test/', 'rb') do |io|
        expect(io.read).to eql("Hello Python\n")
      end
    else
      open('http://1.passenger.test/', 'rb') do |io|
        expect(io.read).to eql("Hello Python\n")
      end
    end
  end
end

shared_examples_for 'Hello world Node.js application' do
  it 'works' do
    if RUBY_VERSION >= '2.5'
      URI.open('http://2.passenger.test/', 'rb') do |io|
        expect(io.read).to eql("Hello Node.js\n")
      end
    else
      open('http://2.passenger.test/', 'rb') do |io|
        expect(io.read).to eql("Hello Node.js\n")
      end
    end
  end
end

describe "The system's Apache with Passenger enabled" do
  before :all do
    @app_dirs = create_app_dirs
    cp('/system/internal/test/apache/vhost.conf', '/etc/apache2/sites-enabled/001-testapp.conf')
    chmod(0644, '/etc/apache2/sites-enabled/001-testapp.conf')
    sh('service apache2 start')
    eventually do
      ping_tcp_socket('127.0.0.1', 80)
    end

    # Apache restarts all modules during startup, so
    # we can briefly end up with two Passenger instances.
    # Wait until the first instance is gone.

    # Wait until at least one Passenger instance exists.
    eventually do
      list_passenger_instances.size >= 1
    end
    # Allow some time for Apache to restart Passenger during startup.
    sleep 1
    # Wait until exactly one *fully initialized* Passenger instance
    # exists.
    eventually do
      instances = list_passenger_instances
      instances.size == 1 &&
        passenger_instance_fully_initialized?(instances[0])
    end
  end

  after :each do |t|
    if t.exception
      sh('cat /var/log/apache2/error.log')
    end
  end

  after :all do
    sh('service apache2 stop')
    eventually do
      !ping_tcp_socket('127.0.0.1', 80)
    end
    @app_dirs.each do |path|
      rm_rf(path)
    end
    rm('/etc/apache2/sites-enabled/001-testapp.conf')
  end

  before :each do
    sh('passenger-config restart-app / --ignore-app-not-running')
  end

  describe 'Ruby support' do
    include_examples 'Hello world Ruby application'
  end

  describe 'Python support' do
    include_examples 'Hello world Python application'
  end

  describe 'Node.js support' do
    include_examples 'Hello world Node.js application'
  end
end

describe "The system's Nginx with Passenger enabled" do
  before :all do
    @app_dirs = create_app_dirs
    cp('/system/internal/test/nginx/vhost.conf', '/etc/nginx/sites-enabled/001-testapp.conf')
    chmod(0644, '/etc/nginx/sites-enabled/001-testapp.conf')
    sh("sed -i 's|# include /etc/nginx/passenger.conf|include /etc/nginx/passenger.conf|' /etc/nginx/nginx.conf")
    sh('service nginx start')
    eventually do
      ping_tcp_socket('127.0.0.1', 80)
    end

    # Wait until exactly one *fully initialized* Passenger instance
    # exists.
    eventually do
      instances = list_passenger_instances
      instances.size == 1 &&
        passenger_instance_fully_initialized?(instances[0])
    end
  end

  after :each do |t|
    if t.exception
      sh('cat /var/log/nginx/error.log')
    end
  end

  after :all do
    sh('service nginx stop')
    eventually do
      !ping_tcp_socket('127.0.0.1', 80)
    end
    @app_dirs.each do |path|
      rm_rf(path)
    end
    rm('/etc/nginx/sites-enabled/001-testapp.conf')
    sh("sed -i 's|\tinclude /etc/nginx/passenger.conf|\t# include /etc/nginx/passenger.conf|' /etc/nginx/nginx.conf")
  end

  describe 'Ruby support' do
    include_examples 'Hello world Ruby application'
  end

  describe 'Python support' do
    include_examples 'Hello world Python application'
  end

  describe 'Node.js support' do
    include_examples 'Hello world Node.js application'
  end
end
