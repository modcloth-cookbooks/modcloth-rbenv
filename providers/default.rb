action :install do
  
  cookbook_file "#{rbenv_user_dir}/.bashrc" do
    owner new_resource.user
    mode '0744'
    source "bashrc"
    action :create
  end

  cookbook_file "#{rbenv_user_dir}/.bash_profile" do
    owner new_resource.user
    mode '0744'
    source "bash_profile"
    action :create
  end

  cookbook_file "/tmp/install_ruby.sh" do
    mode '0755'
    source "install_ruby.sh"
    action :create
  end

  git rbenv_dir do
    user new_resource.user
    repository "git://github.com/sstephenson/rbenv.git"
    action :sync
  end

  directory "#{rbenv_user_dir}/.rbenv/plugins" do
    owner new_resource.user
    action :create
  end

  git "#{rbenv_user_dir}/.rbenv/plugins/ruby-build" do
    user new_resource.user
    repository "git://github.com/sstephenson/ruby-build.git"
    action :sync
  end
  
  bash "installing ruby '#{new_resource.ruby}' for user '#{new_resource.user}'" do
    code <<-EOH
      /tmp/install_ruby.sh install #{new_resource.user} #{new_resource.ruby}
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