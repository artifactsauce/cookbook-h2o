#
# Cookbook Name:: h2o
# Recipe:: source
#
# Copyright 2015, Kenji Akiyama
#
# All rights reserved - Do Not Redistribute
#

node['h2o']['required_os_packages']['source_code_build'].each do |p|
  package p
end

version      = node['h2o']['version']
extension    = node['h2o']['source']['extension']
install_path = "/usr/local/bin/h2o"

url = "#{node['h2o']['source']['url_base']}/v#{version}.#{extension}"

remote_file "#{Chef::Config[:file_cache_path]}/h2o-#{version}.#{extension}" do
  source url
  mode '0644'
  action :create_if_missing
end

bash 'build-and-install' do
  cwd Chef::Config[:file_cache_path]
  code <<-EOF
    tar zxf h2o-#{version}.#{extension}
    (cd h2o-#{version} && cmake -DWITH_BUNDLED_SSL=on .)
    (cd h2o-#{version} && make && make install)
  EOF
  not_if { ::File.exists?(install_path) }
end
