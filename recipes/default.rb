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

unless node['rbenv'].nil?
  search(:users, "id:#{node['rbenv']['users_query']}") do |u|
    rbenv_user = u['username'] ||= u['uid']
    rbenv_group = u['group'] ||= u['gid']
    rbenv_user_dir = "/home/#{rbenv_user}"
    rubies = u['ruby']
    rbenv_dir = "#{rbenv_user_dir}/.rbenv"

    bash "change permisions" do
      code <<-EOH
        chown -R #{rbenv_user}:#{rbenv_user} #{rbenv_user_dir}
      EOH
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

    git rbenv_dir do
      user rbenv_user
      repository "git://github.com/sstephenson/rbenv.git"
      action :sync
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
      extra_flags = ' export CFLAGS="-DBYTE_ORDER -DLITTLE_ENDIAN" ' if ruby == '1.9.3-p327'
      extra_flags = ' export CFLAGS="-march=native -O3 -pipe -fomit-frame-pointer" '
      extra_flags = ' export CFLAGS="-R -fPIC -march=native -O3 -pipe -fomit-frame-pointer" ' if %w(2.0.0-p195 2.0.0-p451).include?(ruby)

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
          export OS_VERSION=`uname -v`
          export ac_cv_func_dl_iterate_phdr=no
          export rb_cv_have_signbit=no
          #{extra_flags}
          source .bashrc

          if ( which ruby && ( ls #{rbenv_user_dir}/.rbenv/versions | grep #{ruby} ) ) &>/dev/null
            then echo "#{ruby} already installed!";
            echo > /tmp/ruby_installed
          elif [ -f $HOME/smartos-rbenv/#{rbenv_user}/#{ruby}.tar.gz ];
            then echo "copying #{ruby}  from LOCAL directory..." >> /tmp/copy && mkdir -p  $HOME/.rbenv/versions &&  \
            tar -xzf $HOME/smartos-rbenv/#{rbenv_user}/#{ruby}.tar.gz -C $HOME/.rbenv/versions
          else
            # make sure to create os/version folder for ruby
            [  -d $HOME/smartos-rbenv/#{rbenv_user} ] || echo "creating pkg directory..." && mkdir -p $HOME/smartos-rbenv/#{rbenv_user}
            echo "installing ruby #{ruby} from source..." && \
            rbenv install #{ruby} \
            rbenv install #{ruby} && echo "creating tar file" && cd .rbenv/versions/ && \
            mkdir -p $HOME/smartos-rbenv/#{rbenv_user} && \
            tar -czf $HOME/smartos-rbenv/#{rbenv_user}/#{ruby}.tar.gz #{ruby};
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
end
