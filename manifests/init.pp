# This class sets up the base RoadWarrior VPN configuration. See the README for
# more information and usage examples.

class roadwarrior (
  $packages_strongswan  = $roadwarrior::params::packages_strongswan,
  $service_strongswan   = $roadwarrior::params::service_strongswan,
  $manage_firewall_v4   = $roadwarrior::params::manage_firewall_v4,
  $manage_firewall_v6   = $roadwarrior::params::manage_firewall_v6,
  $vpn_name             = $roadwarrior::params::vpn_name,
  $vpn_range            = $roadwarrior::params::vpn_range,
  $vpn_route            = $roadwarrior::params::vpn_route,
  $debug_logging        = $roadwarrior::params::debug_logging,
) inherits ::roadwarrior::params {


  # Ensure resources is brilliant witchcraft, we can install all the StrongSwan
  # dependencies in a single run and avoid double-definitions if they're already
  # defined elsewhere.
  ensure_resource('package', [$packages_strongswan], {
    'ensure' => 'installed',
    'before' => [ Service[$service_strongswan], File['/etc/ipsec.conf'] ]
  })

  # We need to define the service and make sure it's set to launch at startup.
  service { $service_strongswan:
    ensure => running,
    enable => true,
  }


  # StrongSwan IPSec subsystem configuration. Most of the logic that we
  # need to configure goes here.
  file { '/etc/ipsec.conf':
    ensure  => file,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('roadwarrior/ipsec.conf.erb'),
    notify  => Service[$service_strongswan]
  }


  # Charon Configuration File
  # TODO: Adjustments to Charon config for timeouts, etc?


  # Configure firewalling and packet forwarding if appropiate
  if ($manage_firewall_v4 or $manage_firewall_v6) {
    include ::roadwarrior::firewall
  }


}

# vi:smartindent:tabstop=2:shiftwidth=2:expandtab:
