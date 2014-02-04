# encoding: utf-8

namespace :hipster do
  DEFAULT_PORT = 10002

  def run(command)
    puts "### Running: #{command}"
    system(command)
    puts
    puts
    unless $?.success?
      puts '### Last Command returned an error. Aborting'
      exit 1
    end
  end

  def bundle_install
    run('which bundle || gem install bundler')
    if Rails.env.production?
      run('bundle --deployment --without development test')
    else
      run('bundle install')
    end
  end

  desc 'Sets HipsterPizza up for development'
  task setup_development: [] do
    bundle_install
    puts
    puts '### Almost done! Execute “guard” next and you should be ready'
    puts '### to develop away :)'
  end

  desc 'Executes necessary steps to make HipsterPizza run in production'
  task setup_production: [] do
    bundle_install

    run('RAILS_ENV=production bundle exec rake assets:precompile')
    run('RAILS_ENV=production bundle exec rake db:migrate')

    puts '### Almost done! Run the following command to make HipsterPizza'
    puts "### available on port #{DEFAULT_PORT}. See the README.md file on how to"
    puts '### integrate this into your webserver'
    puts
    puts "RAILS_ENV=production bundle exec rails server -p #{DEFAULT_PORT} -b localhost --daemon"
    puts
    puts
  end

  desc 'Update HipsterPizza to latest git version'
  task update: :environment do
    run('git pull --all')
    bundle_install

    run('RAILS_ENV=production bundle exec rake assets:precompile') if Rails.env.production?

    pid = File.open('tmp/pids/server.pid', 'r').read.to_i rescue nil
    running = pid && pid > 0 && (Process.kill(0, pid) rescue nil)

    if running
      puts '### old server is running, determining which port it listens on…'
      port = `netstat --tcp --program --listening --wide --numeric-hosts --numeric-ports | grep #{pid}/ruby`
      port = port.match(/.*?:([0-9]+)/)[1].to_i rescue nil
      puts port ? "Found port to be #{port}" : "Didn’t find port, using default #{DEFAULT_PORT}"

      run("kill #{pid}")
      if (Process.kill(0, pid) rescue nil)
        # still running, kill harder
        run("kill -9 #{pid}")
      end
    end
    port ||= DEFAULT_PORT

    run("RAILS_ENV=#{Rails.env} bundle exec rake db:migrate")

    if running
      puts '### Restarting server…'
      run("RAILS_ENV=#{Rails.env} bundle exec rails server -p #{port} -b localhost --daemon")
    else
      puts '### Server wasn’t running before, not running it now'
      puts '### In order to start your server, execute:'
      puts "RAILS_ENV=#{Rails.env} bundle exec rails server -p #{port} -b localhost --daemon"

      if Rails.env.development?
        puts
        puts '### Since you’re running in development mode, either run'
        puts '### “guard” or simply wait until it picks up the changes.'
      end
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
