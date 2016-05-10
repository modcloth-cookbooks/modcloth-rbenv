search(:users, "id:#{node['rbenv']['users_query']}") do |u|
    rbenv_user = u['username'] ||= u['uid']

    cookbook_file "/home/#{rbenv_user}/.bash_env_vars" do
      owner rbenv_user
      mode '0744'
      source 'bash_env_vars'
      action :create
    end

    execute "add extra environment variables to .profile" do
      command "echo >> /home/#{rbenv_user}/.bashrc && echo '[ -f ~/.bash_env_vars ] && source ~/.bash_env_vars' >> /home/#{rbenv_user}/.bashrc"
      not_if { system "grep -q bash_env_vars /home/#{rbenv_user}/.bashrc" }
    end
end
