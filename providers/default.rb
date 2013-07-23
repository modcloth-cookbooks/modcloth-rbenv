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

  git "/home/#{new_resource.user}/.rbenv" do
    user new_resource.user
    repository "git://github.com/sstephenson/rbenv.git"
    action :sync
  end

  directory "/home/#{new_resource.user}/.rbenv/plugins" do
    owner new_resource.user
    action :create
    only_if "ls /home/#{new_resource.user}/.rbenv"
  end

  git "/home/#{new_resource.user}/.rbenv/plugins/ruby-build" do
    user new_resource.user
    repository "git://github.com/sstephenson/ruby-build.git"
    action :sync
  end
  
  bash "installing ruby '#{new_resource.ruby}' for user '#{new_resource.user}'" do
    code <<-EOH
      export USER="#{new_resource.user}"
      export RUBY="#{new_resource.ruby}"
      
      export FILER="/net/filer/export/ModCloth/shared02/installations/rbenv"
      export OS_VERSION=`uname -v`
      
      if [ -d /home/${USER}/.rbenv/versions/${RUBY} ]; then
        echo "ruby ${RUBY} already installed..."
      elif [ -f $FILER/$OS_VERSION/${USER}/${RUBY}.tar.gz ]; then
        echo "installing ruby ${RUBY} from filer..."
        mkdir -p /home/${USER}/.rbenv/versions
        tar -xzf $FILER/$OS_VERSION/${USER}/${RUBY}.tar.gz -C /home/${USER}/.rbenv/versions
      else
        echo "installing ruby ${RUBY} from source..."
        su - ${USER} -c "source .bashrc && rbenv install ${RUBY}"
      fi
      
      if [ ! -f $FILER/$OS_VERSION/${USER}/${RUBY}.tar.gz ]; then
        if [ ! -d $FILER/$OS_VERSION/${USER} ]; then
          echo "creating pkg directory..."
          mkdir -p $FILER/$OS_VERSION/${USER}
        fi
        echo "putting ruby ${RUBY} on the filer for safe keeping..."
        cd /home/${USER}/.rbenv/versions/
        tar -czf $FILER/$OS_VERSION/${USER}/${RUBY}.tar.gz ${RUBY}
      fi
      
      su - ${USER} -c "source .bashrc && rbenv rehash"
      su - ${USER} -c "source .bashrc && rbenv global ${RUBY}"
      
      if su - ${USER} -c "source .bashrc && which bundle"; then
        echo 'bundler already installed'
      else
        echo 'installing bundler...'
        su - ${USER} -c "source .bashrc && gem install bundler"
      fi
      
      su - ${USER} -c "source .bashrc && rbenv rehash"
    EOH
    only_if "ls /home/#{new_resource.user}/.bashrc"
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
      echo "blah"
    EOH
  end

  bash "change permissions" do
    code <<-EOH
       chown -R #{new_resource.user}:#{new_resource.user} /home/#{new_resource.user}
    EOH
  end

end
