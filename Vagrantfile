# -*- mode: ruby -*-
# vi: set ft=ruby :

#######################################################################################
#
# Utility code
#

require 'json'

class Hash
  def merge_recursively!(b)
    merge!(b) {|key, my_item, b_item| my_item.merge_recursively!(b_item) }
  end

  def merge_and_log!(*other_jsons)
    other_jsons.each do |other_json|
      merge_recursively!(other_json)
    end
    puts "The '#{ENV['provisioner_selection']}' provisioner will run with this JSON:\n#{JSON.pretty_generate(self)}"
  end
end

#
#######################################################################################
#
# In this section we construct bits of JSON that will be used by various 
# provisioning steps.
#

class ConfigJson

  # The following JSON will be given to OpsWorks as the stack custom JSON; OpsWorks
  # will pass it to chef on each life cycle event, so below we make sure we do the
  # same for this block

  def self.opsworks_stack_custom_json
    {
      :opsworks => {  
        :rails_stack => {
          # Have to specify :name here so guaranteed set before deploy::rails_stack attrs
          :name => 'nginx_unicorn' 
        }
      },
      # Used to put DB and other provider certificates on the server
      :ssl_certificates => {
        :db_provider => {
          :key => "-----BEGIN CERTIFICATE-----
blah
blah2
-----END CERTIFICATE-----",
          :crt => "bar",
          :ca => "blah"
        }
      },
      :papertrail => {
        :remote_port => ENV['PAPERTRAIL_PORT']
      },
      # To uncomment NR config you need to provide a real license key
      # :newrelic => {
      #   :server_monitoring => {
      #     :license => 'blah',
      #     :ssl => true
      #   }
      # },
      :deploy => {
        :accounts => {
          :auto_bundle_on_deploy => true,
          :database => {
            :database => "dev_db", 
            :host => 'localhost', 
            :password => 'password', 
            :reconnect => true, 
            :username => "dev_db_user",
            # Use the below params in production when have real values for ssl_certificates above
            # :sslca => 'db_provider.ca',
            # :sslcert => 'db_provider.crt',
            # :sslkey => 'db_provider.key'
          }, 
          :delete_cached_copy => false,
          :secret_settings => {
            :beta_username => 'beta',
            :beta_password => 'beta',
          },
          :ssl_support_with_generated_cert => true,
          :symlink_before_migrate => {
            :'config/database.yml' => "config/database_ssl.yml", 
            :'config/memcached.yml' => "config/memcached.yml",
            :'config/secret_settings.yml' => "config/secret_settings.yml"
          }
        },
      }
    }
  end

  # The following JSON is what comes from the GUI side of the OpsWorks configuration
  # which OpsWorks must merge in for the chef run on the deploy life cycle event.

  def self.opsworks_deploy_json
    {
      :deploy => {
        :accounts => {
          :application => "accounts", 
          :application_type => "rails", 
          :document_root => "public", 
          :domains => [
            :"accounts.openstax.org", 
            :"accounts"
          ], 
          :migrate => true, 
          :rails_env => "production", 
          :scm => {
            :password => nil, 
            :repository => '/vagrant/.git', # use in development
            # :repository => "git://github.com/openstax/accounts.git", # use to mimic production
            :revision => nil, 
            :scm_type => "git", 
            :ssh_key => ""#, 
            # :user => "deploy",
            # :group => 'www-data'
          }, 
          :ssl_certificate => nil, 
          :ssl_certificate_ca => nil, 
          :ssl_certificate_key => nil, 
          :ssl_support => false, 
          :symlinks => {
            :log => "log", 
            :pids => "tmp/pids", 
            :system => "public/system"
          }
        },
      }  
    }
  end

  def self.vagrant_only_json
    {
      :instance_role => "vagrant"
    }
  end

end

#
#######################################################################################
#
# Custom commands and the code to support them
#

class WrappedProvisionCommand
  def self.with_provisioner_selection_of(provisioner_selection)
    klass = Class.new(Vagrant.plugin(2, :command)) do
      cattr_accessor :provisioner_selection
      def execute
        IO.popen("export provisioner_selection=#{provisioner_selection}; vagrant provision; unset provisioner_selection").each do |line|
          puts line
        end
      end
    end
    klass.provisioner_selection = provisioner_selection
    klass
  end
end

class Deploy < Vagrant.plugin("2")
  name "Deploy"
  command "deploy" do; WrappedProvisionCommand.with_provisioner_selection_of('deploy'); end
end

class Undeploy < Vagrant.plugin("2")
  name "Undeploy"
  command "undeploy" do; WrappedProvisionCommand.with_provisioner_selection_of('undeploy'); end
end

class ShowStackJson < Vagrant.plugin("2")
  name "ShowStackJson"
  command "show-stack-json" do; puts "Stack JSON:\n#{JSON.pretty_generate(ConfigJson.opsworks_stack_custom_json)}"; end
end

#
#######################################################################################
#
# Setup some developer specific environment stuff.  Do using a dot file so that
# the developer doesn't need to remember to set these in each terminal where vagrant
# is run
#
# Example .vagrant_setup.json:
#
#    {
#      "environment_variables": {
#        "OPENSTAX_COOKBOOKS_PATH": "~myHomeDir/repoDir",
#        "PAPERTRAIL_PORT": "23xxx"
#      }  
#    }
#

setup_file = ::File.join(::File.dirname(__FILE__), '.vagrant_setup.json')
if ::File.exists?(setup_file)
  json = JSON.parse(File.read(setup_file))
  json["environment_variables"].each do |name, value|
    ENV[name] = value
  end
end

#
#######################################################################################
#
# The "normal" Vagrant configuration
#

Vagrant.configure("2") do |config|
  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  config.vm.network :forwarded_port, guest: 3000, host: 3000
  config.vm.network :forwarded_port, guest: 80, host: 8080
  config.vm.network :forwarded_port, guest: 443, host: 8081

  # AWS uses an older version of Chef, and the nginx recipes in particular aren't updated
  # so here we specify the latest version of Chef 10.  Actually, turns out AWS actually 
  # uses a private fork of 0.9.15.5 (yuck), but we couldn't find that in that in a repository
  #
  #    http://stackoverflow.com/a/16401714/1664216
  #    http://stackoverflow.com/a/14782607/1664216
  #
  # Here are two chef versions that can be used.  9.18 is good for simulating behavior close
  # to AWS' fork, but it has some weird permissions problem when checking out from github, a
  # a problem which is not present in 10.18.2 nor in the real OpsWorks run
  #
  #   gem install chef --version 10.18.2 --no-rdoc --no-ri --conservative;
  #   gem install chef -v 0.9.18 --no-rdoc --no-ri --conservative;
  #
  config.vm.provision :shell, :inline => <<-cmds 
    apt-get install -y build-essential;
    gem install net-ssh -v 2.2.2 --no-ri --no-rdoc;
    gem install net-ssh-gateway -v 1.1.0 --ignore-dependencies --no-ri --no-rdoc;
    gem install net-ssh-multi -v 1.1.0 --ignore-dependencies --no-ri --no-rdoc;
    gem install chef --version 10.18.2 --no-rdoc --no-ri --conservative;
    gem install bundler --no-rdoc --no-ri --conservative;
  cmds

  ENV['provisioner_selection'] ||= 'setup'
  puts "Provisioning selection is now '#{ENV['provisioner_selection']}'"

  

  
  if ENV['provisioner_selection'] == 'setup'
    config.vm.provision :chef_solo do |chef|
      chef.add_recipe('openstax_accounts::rails_web_server_setup')
      chef.add_recipe('openstax_accounts::rails_web_server_deploy')
      chef.add_recipe('openstax_accounts::rails_web_server_configure')
      chef.log_level = :debug

      chef.json.merge_and_log!(ConfigJson.opsworks_stack_custom_json,
                               ConfigJson.opsworks_deploy_json,
                               ConfigJson.vagrant_only_json)
    end
  end

  if ENV['provisioner_selection'] == 'deploy'
    config.vm.provision :chef_solo do |chef|
      ["openstax_common", 
       "openstax_accounts", 
       "aws", 
       "nginx", 
       "openstax_accounts::rails_web_server_deploy"].each do |recipe|
        chef.add_recipe(recipe)
      end
      chef.log_level = :debug

      chef.json.merge_and_log!(ConfigJson.opsworks_stack_custom_json,
                               ConfigJson.opsworks_deploy_json,
                               ConfigJson.vagrant_only_json)
    end
  end

end
