#
# Cookbook Name:: h2o
# Recipe:: default
#
# Copyright 2015, Kenji Akiyama
#
# All rights reserved - Do Not Redistribute
#

case node['h2o']['install_method']
when 'source' then
  include_recipe 'h2o::source'
end
