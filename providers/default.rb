action :install do
  cmd = "/tmp/install_ruby.sh install #{new_resource.user} #{new_resource.ruby}"

  execute "installing ruby '#{new_resource.ruby}' for user '#{new_resource.user}'" do
    command cmd
    only_if "ls /tmp/install_ruby.sh"
  end
end
 
action :remove do
  cmd = "/tmp/install_ruby.sh remove #{new_resource.user} #{new_resource.ruby}"
  
  execute "removing ruby '#{new_resource.ruby}' for user '#{new_resource.user}'" do
    command cmd
    only_if "ls /tmp/install_ruby.sh"
  end
end