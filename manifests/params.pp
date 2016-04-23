# Define all default parameters here. You should never fork the module and
# have to make changes here, instead use Hiera to override the params passed
# to the classes.

class roadwarrior::params {

  # TODO: This will be Debian specific
  # Define all the packages we need for StrongSwan and the plugins (in particular EAP-TLS).
  $packages_strongswan = ['strongswan', 'libstrongswan-standard-plugins', 'libstrongswan-extra-plugins', 'libcharon-extra-plugins']

  # TODO: This will (probably) be Debian specific
  # Define the name of the service.
  $service_strongswan = 'strongswan'

  # By default, we should manage the firewall. Ideally the user will be taking
  # advantage of puppetlabs/firewall to manage their ruleset, but if another
  # firewall module or technology is being used (eg AWS security groups) it's
  # easy enough to disable our management of the firewall.
  $manage_firewall_v4 = true
  $manage_firewall_v6 = true

  # Name the VPN based on the hostname by default. This name is then used to
  # populate all the certs that is generated, so pick a name you wish to keep,
  # since changing means re-generating all the client certs/config.
  $vpn_name = $::fqdn

  # Default IP range for the VPN clients to use
  $vpn_range = '10.10.10.0/24'

  # Route to push through to the clients
  $vpn_route = '192.168.0.0/16'

  # Debug logging - Enabled additional log information
  $debug_logging = true

  # Certificate Params.
  $cert_dir        = '/etc/ipsec.d'  # This shouldn't be changed unless to suit packaging differences on distros
  $cert_lifespan   = '3650'          # Expiry of the certs in days (3650 == 10 years)
}

# vi:smartindent:tabstop=2:shiftwidth=2:expandtab:
