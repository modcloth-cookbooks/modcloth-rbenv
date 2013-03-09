#
# Cookbook Name:: rbenv
# Recipe:: default
#
# Copyright 2012, ModCloth, Inc.
#
# All rights reserved - Do Not Redistribute
#

include_recipe "autofs::smartos"
default_ruby = node.rbenv.default_ruby

rbenv "rbenv admin #{default_ruby}" do
  user "admin"
  ruby "#{default_ruby}"
  action :install
end
