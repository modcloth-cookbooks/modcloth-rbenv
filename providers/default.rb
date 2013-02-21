action :install do
  
  cookbook_file "/home/#{new_resource.user}/.bashrc" do
    owner new_resource.user
    mode '0744'
    source "user/bashrc"
    action :create
  end

  cookbook_file "/home/#{new_resource.user}/.bash_profile" do
    owner new_resource.user
    mode '0744'
    source "user/bash_profile"
    action :create
  end

  cookbook_file "/tmp/install_ruby.sh" do
    mode '0755'
    source "install_ruby.sh"
    action :create
  end

  git "/home/#{new_resource.user}" do
    user new_resource.user
    repository "git://github.com/sstephenson/rbenv.git"
    action :sync
  end

  directory "/home/#{new_resource.user}/.rbenv/plugins" do
    owner new_resource.user
    action :create
  end

  git "/home/#{new_resource.user}/.rbenv/plugins/ruby-build" do
    user new_resource.user
    repository "git://github.com/sstephenson/ruby-build.git"
    action :sync
  end
  
  bash "installing ruby '#{new_resource.ruby}' for user '#{new_resource.user}'" do
    user new_resource.user
    code <<-EOH
      cd ~

      ACTION=$1
      USER=$2
      RUBY=$3

      HOME="/home/${USER}"
      TMPDIR="${HOME}"
      PREFIX="${HOME}/.rbenv/versions/${RUBY}"
      CONFIGURE_OPTS="--with-opt-dir=/opt/local"
      LDFLAGS="-R/opt/local -L/opt/local/lib "

      FILER="/net/filer/export/ModCloth/shared02/installations/rbenv"
      OS_VERSION=`uname -v`

      source .bashrc

      if [ -d $HOME/.rbenv/versions/${RUBY} ]; then
        echo "ruby #{ruby} already installed..."
      elif [ -f $FILER/$OS_VERSION/${USER}/${RUBY}.tar.gz ]; then
        echo "installing ruby ${RUBY} from filer..."
        mkdir -p $HOME/.rbenv/versions
        tar -xzf $FILER/$OS_VERSION/${USER}/${RUBY}.tar.gz -C $HOME/.rbenv/versions
      else
          if [ ! -d $FILER/$OS_VERSION/${USER} ]; then
            echo "creating pkg directory..."
            mkdir -p $FILER/$OS_VERSION/#{rbenv_user}
          fi
        echo "installing ruby ${RUBY} from source..."
        rbenv install ${RUBY}
        echo "putting ruby ${RUBY} on the filer for safe keeping..."
        cd .rbenv/versions/
        mkdir -p $FILER/$OS_VERSION/${USER}
        tar -czf $FILER/$OS_VERSION/${USER}/${RUBY}.tar.gz ${RUBY}
      fi

      rbenv rehash
      rbenv global ${RUBY}

      if rbenv which bundle; then
        echo 'bundler already installed'
      else
        gem install bundler
      fi

      rbenv rehash
    EOH
  end
  
  bash "change permissions" do
    code <<-EOH
       chown -R #{new_resource.user}:#{new_resource.user} /home/#{new_resource.user}
    EOH
  end
  
end
 
action :remove do

  bash "removing ruby '#{new_resource.ruby}' for user '#{new_resource.user}'" do
    code <<-EOH
      /tmp/install_ruby.sh remove #{new_resource.user} #{new_resource.ruby}
    EOH
  end

  bash "change permissions" do
    code <<-EOH
       chown -R #{new_resource.user}:#{new_resource.user} /home/#{new_resource.user}
    EOH
  end

end