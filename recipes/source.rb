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
binary_path   = "#{binary_prefix}/h2o"

etc_dir       = node['h2o']['etc_dir']
log_dir       = node['h2o']['log_dir']
run_dir       = node['h2o']['run_dir']

url = "#{node['h2o']['source']['url_base']}/v#{version}.#{extension}"

cmake_options = []
if node['h2o']['source']['enabled_modules']['mruby'] then
  cmake_options << '-DWITH_MRUBY=on'
end
if node['h2o']['source']['enabled_modules']['ssl'] then
  cmake_options << '-DWITH_BUNDLED_SSL=on'
end

cmake_cmd = cmake_options.unshift('cmake').push('.').join(' ')

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
    (cd h2o-#{version} && #{cmake_cmd})
    (cd h2o-#{version} && make && make install)
  EOF
  not_if {
    ::File.exists?("#{binary_path}") &&
      /h2o version #{version}/.match(`#{binary_path} --version`)
  }
end

directory 'create-config-directory' do
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
  path "/etc/init.d/h2o"
  source "initd.erb"
  mode '0755'
  variables (
    {
      binary_path:        "#{binary_path}",
      configuration_path: "#{etc_dir}/h2o.conf",
      pid_path: "#{run_dir}/h2o.pid",
    }
  )
  action :create
end

execute 'update-rc.d' do
  command "/usr/sbin/update-rc.d h2o defaults"
end

directory 'create-certification-directory' do
  path "#{etc_dir}/ssl"
  mode '0600'
end

execute 'create-certifications' do
  cwd "#{etc_dir}/ssl"
  command "sudo openssl req -new -x509 -sha256 -days 365 -newkey rsa:2048 -nodes -subj \"/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com\" -out server.crt -keyout server.key"
  only_if {
    node['h2o']['source']['default_enabled'] ||
      !::File.exists?("#{etc_dir}/ssl/server.key")
  }
end
