#
# This class can be used to configure the drbd service.
#
# It has been influenced by the camptocamp module as well as
# by an example created by Rackspace's cloudbuilders
#
class drbd(
  $service_enable   = true,
  $version          = $::drbd::params::version,
  $package_name     = $::drbd::params::package_name,
  $kmod_package_name = $::drbd::params::kmod_package_name,
  $manage_repo      = $::drbd::params::manage_repo,
  $protocol         = 'C',
) inherits ::drbd::params {
  include ::drbd::service

  validate_bool($service_enable)
  validate_bool($manage_repo)
  validate_re($protocol, '^A|B|C$')
  validate_re($version, '^8\.3|8\.4$', 'The drbd module supports versions 8.3 and 8.4 of DRBD only')

  if $manage_repo {
    case $::osfamily {
      'RedHat': {
        unless $::operatingsystem == 'Fedora' { require ::elrepo }
      }
      default: { }
    }
  }
  ensure_packages($package_name)

  if $kmod_package_name {
    ensure_packages($kmod_package_name)
    # ensure that the kernel module is loaded
    exec { 'modprobe drbd':
      path   => ['/bin/', '/sbin/'],
      unless => 'grep -qe \'^drbd \' /proc/modules',
      require => Package[$kmod_package_package_name],
    }
  }
  else {
    # ensure that the kernel module is loaded
    exec { 'modprobe drbd':
      path   => ['/bin/', '/sbin/'],
      unless => 'grep -qe \'^drbd \' /proc/modules',
    }
  }

  File {
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => Package[$package_name],
    notify  => Class['drbd::service'],
  }

  file { '/drbd':
    ensure => directory,
  }

  # this file just includes other files
  file { '/etc/drbd.conf':
    source  => 'puppet:///modules/drbd/drbd.conf',
  }

  file { '/etc/drbd.d/global_common.conf':
    content => template('drbd/global_common.conf.erb'),
  }

  # only allow files managed by puppet in this directory.
  file { '/etc/drbd.d':
    ensure  => directory,
    mode    => '0644',
    purge   => true,
    recurse => true,
    force   => true,
  }

}
