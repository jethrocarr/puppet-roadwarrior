# Use this defined type to setup each VPN client. Puppet will generate the
# required SSL certs/keys and export them in a suitable form for distribution
# along with an iOS compatible .mobileconfig file for easy import on iOS

define roadwarrior::client (
    $vpn_client    = $name,
    $vpn_name      = $::roadwarrior::vpn_name,
    $cert_dir      = $::roadwarrior::cert_dir,
    $cert_lifespan = $::roadwarrior::cert_lifespan,
    $cert_password = $::roadwarrior::cert_password,

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
    command => "openssl pkcs12 -export -inkey ${cert_dir}/private/client_${vpn_client}Key.pem -in ${cert_dir}/certs/client_${vpn_client}Cert.pem -name \"${vpn_client}\" -certfile ${cert_dir}/cacerts/strongswanCert.pem -caname \"${vpn_name} CA\" -password \"pass:${cert_password}\" -out ${cert_dir}/dist/${vpn_client}.p12",
    creates => "${cert_dir}/dist/${vpn_client}/${vpn_client}.p12",
  }


  # Generate iOS mobileconfig
  # TODO: Write this


}

# vi:smartindent:tabstop=2:shiftwidth=2:expandtab:
