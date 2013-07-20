#
# Cookbook Name:: rbenv
# Recipe:: default
#
# Copyright 2012, ModCloth, Inc.
#
# All rights reserved - Do Not Redistribute
#

include_recipe "autofs::smartos"
default_user = node.rbenv.default_user
default_ruby = node.rbenv.default_ruby

modcloth_rbenv "rbenv #{default_user} #{default_ruby}" do
  user "#{default_user}"
  ruby "#{default_ruby}"
  action :install
end
