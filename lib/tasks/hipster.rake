# encoding: utf-8

namespace :hipster do
  DEFAULT_PORT = 10002

  def run(command)
    puts "### Running: #{command}"
    system(command + ' 2>&1')
    puts
    puts
    unless $?.success?
      puts '### Last Command returned an error. Aborting'
      exit 1
    end
  end

  def bundle_install
    run('which bundle || gem install bundler')
    run('./bin/bundle --deployment --without development test')
  end

  desc 'Executes necessary steps to make HipsterPizza run in production'
  task setup_production: [] do
    bundle_install

    run('RAILS_ENV=production ./bin/rake assets:precompile')
    run('RAILS_ENV=production ./bin/rake db:create db:migrate')

    puts '### Almost done! Run the following command to make HipsterPizza'
    puts "### available on port #{DEFAULT_PORT}. See the README.md file on how to"
    puts '### integrate this into your webserver'
    puts
    puts "RAILS_ENV=production ./bin/rails server -p #{DEFAULT_PORT} -b localhost --daemon"
    puts
    puts
  end

  desc 'Update HipsterPizza to latest version'
  task update: :environment do
    run('git checkout master')
    run('git pull')
    bundle_install

    run('RAILS_ENV=production ./bin/rake assets:precompile')

    pid = File.open('tmp/pids/server.pid', 'r').read.to_i rescue nil
    running = pid && pid > 0 && (Process.kill(0, pid) rescue nil)

    port ||= DEFAULT_PORT

    run("RAILS_ENV=production ./bin/rake db:migrate")

    if running
      puts '### Restarting server…'
      run("kill -2 #{pid}")
    else
      puts '### Server wasn’t running before, not running it now'
      puts '### In order to start your server, execute:'
      puts "RAILS_ENV=production ./bin/rails server -p #{port} -b localhost --daemon"
    end
  end


  desc 'Cleans out old baskets and orders.'
  task purge_old: :environment do
    # note: use 9 months here, even though views/main/privacy.html says
    # one year to allow the data to be purged from backups and the like.
    puts 'Deleting old baskets…'
    Basket.destroy_all(['created_at < ?', 9.months.ago])
    puts 'Deleting any left over orders…'
    Order.delete_all(['created_at < ?', 9.months.ago])
  end

end
