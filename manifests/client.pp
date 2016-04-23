# Use this defined type to setup each VPN client. Puppet will generate the
# required SSL certs/keys and export them in a suitable form for distribution
# along with an iOS compatible .mobileconfig file for easy import on iOS

define roadwarrior::client (
    $vpn_client              = $name,
    $ondemand_connect        = false,
    $ondemand_ssid_excludes  = undef,
    $vpn_name                = $::roadwarrior::vpn_name,
    $cert_dir                = $::roadwarrior::cert_dir,
    $cert_lifespan           = $::roadwarrior::cert_lifespan,
    $cert_password           = $::roadwarrior::cert_password,
  ) {

  # The base class must be included first because it is used by parameter defaults
  require ::roadwarrior

  #if ! defined(Class['roadwarrior']) {
  #  fail('You must include the roadwarrior base class before defining any clients')
  #}
 
  # Handy hack - set the path for all Execs
  Exec {
    path => '/bin:/sbin:/usr/bin:/usr/sbin',
  }

  # Generate V4 UUIDs for .mobileconfig files
  # TODO - Would this be better in the template itself?
  $uuid_payload_pkcs12    = roadwarrior_uuid()
  $uuid_payload_vpnconfig = roadwarrior_uuid()
  $uuid_payload_cacert    = roadwarrior_uuid()
  $uuid_payload_id        = roadwarrior_uuid()
  $uuid_payload_uuid      = roadwarrior_uuid()


  ## Generate the client key/cert

  # Using the CA cert built by the main class, build a client cert and key that we can use on their device.
  exec { 'generate_client_key':
    command  => "ipsec pki --gen --type rsa --size 2048 --outform pem > ${cert_dir}/private/client_${vpn_client}Key.pem",
    creates  => "${cert_dir}/private/client_${vpn_client}Key.pem",
  } ->

  exec { 'generate_client_cert':
    command => "ipsec pki --pub --in ${cert_dir}/private/client_${vpn_client}Key.pem --type rsa | ipsec pki --issue --lifetime ${cert_lifespan} --cacert ${cert_dir}/cacerts/strongswanCert.pem --cakey ${cert_dir}/private/strongswanKey.pem --dn \"C=NZ, O=roadwarrior, CN=${vpn_client}@${vpn_name}\" --san ${vpn_client}@${vpn_name} --outform pem > ${cert_dir}/certs/client_${vpn_client}Cert.pem",
    creates => "${cert_dir}/certs/client_${vpn_client}Cert.pem",
    # TODO: Probably don't need to reload for new certs?
    #notify  => Service[$service_strongswan], # Make sure the server is restarted with the right cert (if needed)
  } ->



  ## Copy & generate distributable versions

  # Setup a dist directory per client
  file { "${cert_dir}/dist/${vpn_client}/":
    ensure => 'directory',
    mode   => '0600',
    owner  => 'root',
    group  => 'root',
  } ->

  # Copy the certs/key to the dist directory for easy packaging/distribution
  exec { 'dist_client_cert':
    command => "cp ${cert_dir}/certs/client_${vpn_client}Cert.pem ${cert_dir}/dist/${vpn_client}/${vpn_client}Cert.pem",
    creates => "${cert_dir}/dist/${vpn_client}/${vpn_client}Cert.pem"
  } ->

  exec { 'dist_client_key':
    command => "cp ${cert_dir}/private/client_${vpn_client}Key.pem ${cert_dir}/dist/${vpn_client}/${vpn_client}Key.pem",
    creates => "${cert_dir}/dist/${vpn_client}/${vpn_client}Key.pem"
  } ->

  # Whilst not needed by StrongSwan itself, generate a PKCS12 (.p12) file with the
  # combined cert and key, using $cert_password as the container password.
  exec { 'generate_client_pkcs12':
    command => "openssl pkcs12 -export -inkey ${cert_dir}/private/client_${vpn_client}Key.pem -in ${cert_dir}/certs/client_${vpn_client}Cert.pem -name \"${vpn_client}\" -certfile ${cert_dir}/cacerts/strongswanCert.pem -caname \"${vpn_name} CA\" -password \"pass:${cert_password}\" -out ${cert_dir}/dist/${vpn_client}/${vpn_client}.p12",
    creates => "${cert_dir}/dist/${vpn_client}/${vpn_client}.p12",
  } ->


  # Generate iOS mobileconfig. This is a bit tricky - we want to take this template and
  # populate it on disk, however we also need to copy the data from the certs into this
  # configuration.
  #
  # Hence we use Puppet file/template to generate the file with all the VPN
  # specific configuration and endpoints, but leave placeholders for the cert data which
  # we then populate with Exec.
  #
  # All this means that the mobileconfig won't regenerate if the template changes - you'll
  # have to rm -f the file on disk if you want to generate all new mobile configs for your
  # environment.

  # Generate template file (minus certs)
  file { "${cert_dir}/dist/${vpn_client}/ios-${vpn_client}.mobileconfig":
    ensure  => 'file',
    mode    => '0600',
    owner   => 'root',
    group   => 'root',
    replace => false,  # first generation, sticks
    content =>  template('roadwarrior/ios.mobileconfig.erb'),
  } ->


  # We use awk to do some evil where we read in the certs, turn to base64 (using
  # base64 command from coreutils) and replace the placeholders in the mobile
  # config file. We use sponge (from moreutils) to buffer whilst we write to avoid
  # the annoying mv file2 file1 dance.

  # Insert CA cert
  exec { 'insert_ca_cert':
    command => "awk '/%%CERT_CA_DER%%/ { system ( \"base64 ${cert_dir}/cacerts/strongswanCert.der\" ) } !/%%CERT_CA_DER%%/ { print; }' ${cert_dir}/dist/${vpn_client}/ios-${vpn_client}.mobileconfig | sponge ${cert_dir}/dist/${vpn_client}/ios-${vpn_client}.mobileconfig",
    onlyif  => "grep -q '%%CERT_CA_DER%%' ${cert_dir}/dist/${vpn_client}/ios-${vpn_client}.mobileconfig",
  } ->

  # PKCS12 (Client cert + key)
  exec { 'insert_pkcs12':
    command => "awk '/%%CERT_PKCS12%%/ { system ( \"base64 ${cert_dir}/dist/${vpn_client}/${vpn_client}.p12\" ) } !/%%CERT_PKCS12%%/ { print; }' ${cert_dir}/dist/${vpn_client}/ios-${vpn_client}.mobileconfig | sponge ${cert_dir}/dist/${vpn_client}/ios-${vpn_client}.mobileconfig",
    onlyif  => "grep -q '%%CERT_PKCS12%%' ${cert_dir}/dist/${vpn_client}/ios-${vpn_client}.mobileconfig",
  }


}

# vi:smartindent:tabstop=2:shiftwidth=2:expandtab:
