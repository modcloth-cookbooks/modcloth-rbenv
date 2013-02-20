#
# Cookbook Name:: rbenv
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# traverse users in data bag and see if they set a ruby attribute
# (or some other query) and install rubies

include_recipe "autofs::smartos"

search(:users, node['rbenv']['users_query']) do |u|
  rbenv_user = u['username'] ||= u['id']
  rbenv_group = u['group']
  rbenv_user_dir = "/home/#{rbenv_user}"
  rubies = u['ruby']
  rbenv_dir = "#{rbenv_user_dir}/.rbenv"

  bash "change permisions" do
    code <<-EOH
       chown -R #{rbenv_user}:#{rbenv_group} #{rbenv_user_dir}
    EOH
  end

  git rbenv_dir do
    user rbenv_user
    repository "git://github.com/sstephenson/rbenv.git"
    action :sync
  end

  cookbook_file "#{rbenv_user_dir}/.bashrc" do
    owner rbenv_user
    mode '0744'
    source "bashrc"
    action :create
  end

  cookbook_file "#{rbenv_user_dir}/.bash_profile" do
    owner rbenv_user
    mode '0744'
    source "bash_profile"
    action :create
  end

  directory "#{rbenv_user_dir}/.rbenv/plugins" do
    owner rbenv_user
    action :create
  end

  git "#{rbenv_user_dir}/.rbenv/plugins/ruby-build" do
    user rbenv_user
    repository "git://github.com/sstephenson/ruby-build.git"
    action :sync
  end

  rubies.each do |ruby|
    # Fix me a hash would be better  
    extra_flags =" export CFLAGS='-DBYTE_ORDER -DLITTLE_ENDIAN' \
                   export ac_cv_func_dl_iterate_phdr=no \
                   export rb_cv_have_signbit=no " if ruby.eql?("1.9.3-p327")
    
    bash "installing ruby #{ruby}" do
      user rbenv_user
      cwd rbenv_user_dir
      code <<-EOH
        export HOME=#{rbenv_user_dir}
        export TMPDIR=#{rbenv_user_dir}
        export PREFIX=#{rbenv_user_dir}/.rbenv/versions/#{ruby}
        export CONFIGURE_OPTS='--with-opt-dir=/opt/local'
        # ruby compile flags to link correctly for smartos
        export LDFLAGS="-R/opt/local -L/opt/local/lib "
        export FILER="/net/filer/export/ModCloth/shared02/installations/rbenv"
        export OS_VERSION=`uname -v`
        #{extra_flags}
        source .bashrc
                
        if [ -d $HOME/.rbenv/versions/#{ruby} ]; then
          echo "ruby #{ruby} already installed..."
        elif [ -f $FILER/$OS_VERSION/#{rbenv_user}/#{ruby}.tar.gz ]; then
          echo "installing ruby #{ruby} from filer..."
          mkdir -p $HOME/.rbenv/versions
          tar -xzf $FILER/$OS_VERSION/#{rbenv_user}/#{ruby}.tar.gz -C $HOME/.rbenv/versions
        else
          if [ ! -d $FILER/$OS_VERSION/#{rbenv_user} ]; then
            echo "creating pkg directory..."
            mkdir -p $FILER/$OS_VERSION/#{rbenv_user}
          fi
          echo "installing ruby #{ruby} from source..."
          rbenv install #{ruby}
          echo "putting ruby #{ruby} on the filer for safe keeping..."
          cd .rbenv/versions/
          mkdir -p $FILER/$OS_VERSION/#{rbenv_user}
          tar -czf $FILER/$OS_VERSION/#{rbenv_user}/#{ruby}.tar.gz #{ruby}
        fi
        
        rbenv rehash
        rbenv global #{ruby}
        
        if rbenv which bundle; then
          echo 'bundler already installed'
        else
          gem install bundler
        fi
        
        rbenv rehash
      EOH
    end
  end
end
