default['h2o']['install_method'] = 'source'
default['h2o']['version'] = '1.4.4'
default['h2o']['source']['url_base'] = 'https://github.com/h2o/h2o/archive'
default['h2o']['source']['extension'] = 'tar.gz'
default['h2o']['source']['prefix'] = '/usr/local'
default['h2o']['source']['default_enabled'] = true
default['h2o']['source']['upstart']['description'] = 'An optimized HTTP server'
default['h2o']['source']['upstart']['author_name'] = 'Anonymous'
default['h2o']['source']['upstart']['author_email'] = 'anonymous@example.com'

default['h2o']['required_os_packages']['source_code_build'] = %w(
build-essential
cmake
)
