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

version       = node['h2o']['version']
extension     = node['h2o']['source']['extension']
prefix        = node['h2o']['source']['prefix']
source_prefix = "#{prefix}/src"
binary_prefix = "#{prefix}/bin"
etc_prefix    = "#{prefix}/etc"
etc_dir       = "#{etc_prefix}/h2o"
log_dir       = '/var/log/h2o'
run_dir       = '/var/run'
binary_path   = "#{binary_prefix}/h2o"

url = "#{node['h2o']['source']['url_base']}/v#{version}.#{extension}"

case node['h2o']['source']['extension']
when 'tar.gz' then
  extract_cmd = 'tar zxf'
when 'zip' then
  extract_cmd = 'unzip'
end

remote_file "#{source_prefix}/h2o-#{version}.#{extension}" do
  source url
  mode '0644'
  action :create_if_missing
end

bash 'build-and-install' do
  cwd source_prefix
  code <<-EOF
    #{extract_cmd} h2o-#{version}.#{extension}
    (cd h2o-#{version} && cmake -DWITH_BUNDLED_SSL=on .)
    (cd h2o-#{version} && make && make install)
  EOF
  not_if { ::File.exists?("#{binary_path}") }
end

directory 'config-directory' do
  path etc_dir
  owner 'root'
  group 'root'
  action :create
end

template 'default-config' do
  path "#{etc_dir}/h2o.conf"
  source 'h2o.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables (
    {
      source_path: source_prefix + "/h2o-#{version}",
      log_dir: log_dir,
      run_dir: run_dir,
    }
  )
  action :create_if_missing
  # notifies :reload, 'service[h2o]'
  only_if { node['h2o']['source']['default_enabled'] }
end

directory 'create-log-directory' do
  path log_dir
  owner 'root'
  group 'root'
  action :create
end

template 'init-daemon-file' do
  path "/etc/init/h2o.conf"
  source "upstart.erb"
  variables (
    {
      description:        node['h2o']['source']['upstart']['description'],
      author_name:        node['h2o']['source']['upstart']['author_name'],
      author_email:       node['h2o']['source']['upstart']['author_email'],
      binary_path:        "#{binary_path}",
      configuration_path: "#{etc_dir}/h2o.conf",
    }
  )
  action :create
end
