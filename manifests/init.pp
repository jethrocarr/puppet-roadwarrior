# This class sets up the base RoadWarrior VPN configuration. See the README for
# more information and usage examples.

class roadwarrior (
  $packages_strongswan  = $::roadwarrior::params::packages_strongswan,
  $service_strongswan   = $::roadwarrior::params::service_strongswan,
  $manage_firewall_v4   = $::roadwarrior::params::manage_firewall_v4,
  $manage_firewall_v6   = $::roadwarrior::params::manage_firewall_v6,
  $vpn_name             = $::roadwarrior::params::vpn_name,
  $vpn_range_v4         = $::roadwarrior::params::vpn_range_v4,
  $vpn_route_v4         = $::roadwarrior::params::vpn_route_v4,
  $debug_logging        = $::roadwarrior::params::debug_logging,
  $cert_dir             = $::roadwarrior::params::cert_dir,
  $cert_lifespan        = $::roadwarrior::params::cert_lifespan,
  $cert_password        = $::roadwarrior::params::cert_password,
) inherits ::roadwarrior::params {

  # Compat checks
  if ($::operatingsystem != "Debian" and $::operatingsystem != "Ubuntu") {
    fail("Sorry, only Debian or Ubuntu distributions are supported by the roadwarrior module at this time. PRs welcome")
  }

  # Ensure resources is brilliant witchcraft, we can install all the StrongSwan
  # dependencies in a single run and avoid double-definitions if they're already
  # defined elsewhere.
  ensure_resource('package', [$packages_strongswan], {
    'ensure' => 'installed',
    'before' => [ Service[$service_strongswan], File['/etc/ipsec.conf'], File['/etc/ipsec.secrets'] ]
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

  # As we are doing cert authentication, the secrets file simply needs the
  # private key of the VPN host listed.
  file { '/etc/ipsec.secrets':
    ensure  => file,
    mode    => '0600',
    owner   => 'root',
    group   => 'root',
    content => template('roadwarrior/ipsec.secrets.erb'),
    notify  => Service[$service_strongswan]
  }

  # Charon Configuration File
  # TODO: Adjustments to Charon config for timeouts, etc?


  # Configure firewalling and packet forwarding if appropiate
  if ($manage_firewall_v4 or $manage_firewall_v6) {
    include ::roadwarrior::firewall
  }


  # Handy hack - set the path for all Execs
  Exec {
    path => '/bin:/sbin:/usr/bin:/usr/sbin',
   }

  # Check if the VPN name differs from the CA cert. If so, the admin has probably
  # messed with $vpn_name and now it doens't reflect reality.
  # TODO: write this validation

  # Generate CA key & cert
  exec { 'generate_ca_key':
    command  => "ipsec pki --gen --type rsa --size 4096 --outform pem > ${cert_dir}/private/strongswanKey.pem",
    creates  => "${cert_dir}/private/strongswanKey.pem",
    require  => File['/etc/ipsec.conf'], # Used to pull in all packages
  } ->

  exec { 'generate_ca_cert':
    command => "ipsec pki --self --ca lifetime ${cert_lifespan} --in ${cert_dir}/private/strongswanKey.pem --digest sha256 --type rsa --dn \"C=NZ, O=roadwarrior, CN=${vpn_name} CA\" --outform pem > ${cert_dir}/cacerts/strongswanCert.pem",
    creates  => "${cert_dir}/cacerts/strongswanCert.pem",
  } ->

  # Generate VPN host key & cert
  exec { 'generate_host_key':
    command  => "ipsec pki --gen --type rsa --size 2048 --outform pem > ${cert_dir}/private/vpnHostKey.pem",
    creates  => "${cert_dir}/private/vpnHostKey.pem",
  } ->

  exec { 'generate_host_cert':
    command => "ipsec pki --pub --in ${cert_dir}/private/vpnHostKey.pem --type rsa | ipsec pki --issue --digest sha256 --lifetime ${cert_lifespan} --cacert ${cert_dir}/cacerts/strongswanCert.pem --cakey ${cert_dir}/private/strongswanKey.pem --dn \"C=NZ, O=roadwarrior, CN=${vpn_name}\" --san ${vpn_name} --flag serverAuth --flag ikeIntermediate --outform pem > ${cert_dir}/certs/vpnHostCert.pem",
    creates => "${cert_dir}/certs/vpnHostCert.pem",
    notify  => Service[$service_strongswan], # Make sure the server is restarted with the right cert (if needed)
  } ->

  # Export the CA cert to DER format as well. StrongSwan doesn't need it, but it's useful
  # when generating the client packages as some take DER rather than PEM.
  exec { 'generate_host_cert_der':
    command  => "openssl x509 -in ${cert_dir}/cacerts/strongswanCert.pem -out ${cert_dir}/cacerts/strongswanCert.der -outform DER",
    creates  => "${cert_dir}/cacerts/strongswanCert.der",
  }

  # Create a directory for the distributable packages
  file { "${cert_dir}/dist":
    ensure  => directory,
    mode    => '0600',
    owner   => 'root',
    group   => 'root',
    require => File['/etc/ipsec.conf'],
  }

}

# vi:smartindent:tabstop=2:shiftwidth=2:expandtab:
