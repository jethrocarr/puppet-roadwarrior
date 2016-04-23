# puppet-roadwarrior

The year is 2016. Giant clouds rule the internet. Microsoft supports linux. Yet
in this strange new world, not all is well. Your home network is still stuck
behind an IPv4 NAT gateway. And your apps still haven't all figured out how to
do secure HTTPS encrypted connections yet.

But wait! There in the distance... a savior emerges! The Road Warror VPN!

This module sets up a StrongSwan-based IKEv2 VPN suitable for use with the
native IKEv2 VPN client available on devices like iOS and Android, as well as
traditional operating systems like Windows, MacOS and GNU/Linux.

It intentionally tries not to do everything for everyone, the module is smart
in some areas (eg automatic generation of keys/certs) but dumb in other areas
(eg limited configurability to keep things simple for users).

If you're wanting the simpliest possible way to configure a VPN for your iOS
or Android device this is the module for you. If you want a module that exposes
every possible StrongSwan option, it's not.


# Features

* Extremely simple configuration.
* IKEv2 using StrongSwan.
* Certificate-based authentication with automatic setup of CA & certs.
* Generates client certs for you
* Generates `.mobileconfig` files for easy import on iOS devices.


# Compatibility

Tested and confirmed on:

* Debian 8 [Server]
* Ubuntu 16.04 [Server]
* iOS 9.3.1 [Client]
* MacOS X 10.11.4 [Client]


The VPN *should* work on any OS released in 2015-2016 onwards, but many
earlier OS releases didn't ship with IKEv2 VPN support. The following are
known minimum versions for working clients:

* iOS 9+
* MacOS X 10.11 (El Capitan)




# Usage

The following is an example of a basic configuration that sets up the firewall
rules, defines the VPN name and both the IP range to use for the clients as well
as the IP range to route back to the client devices.

    class { 'roadwarrior':
       manage_firewall_v4 => true,
       manage_firewall_v6 => true,
       vpn_name           => 'vpn.example.com',
       vpn_range          => '10.10.10.0/24',
       vpn_route          => '192.168.0.0/16',
     }

It is recommended that you consider backing up the `/etc/ipsec.d` directory. If
replacing/autoscaling the server running your roadwarror VPN, you will want to
populate the directory with the same data across the fleet, otherwises certs would
be re-generated.

You will want to make sure your server can be reached by the clients on UDP port
500 and UDP port 4500. If you use the managed firewall, this will be configured
for you with iptables (using puppetlabs/firewall module).

Currently all traffic will egress your VPN server with an IP from the `vpn_range`
defined above without any masqurading (NAT), so it's important that the
destination servers on your network know how to route back to the VPN range via
the server. (TODO: add a NAT option to this module?)

Refer to `manifests/params.pp` for the full list of configurable options and what
they mean.


# Client Configuration

## General Configuration

Simply define each client you wish to use, in addition to the main `roadwarrior`
class above.

    roadwarrior::client { 'myiphone': }
    roadwarrior::client { 'bobiphone': }
    roadwarrior::client { 'androidftw': }

This module will export out the certs in a range of formats and sets up a mobile
config file.

Most of the params you won't need to set, however the following two are useful.
By default the iOS configuration will be "connect on request" only, however you
can adjust to ensure the VPN always automatically establishes a connection

    roadwarrior::client { 'examplephone':
      ondemand_connect       => false,
      ondemand_ssid_excludes => undef,
    }

For example, to generate configuration for iOS that will always reconnect unless
you are on WiFi network "home" or "bach" which presumably don't require the VPN.

    roadwarrior::client { 'examplephone':
      ondemand_connect       => true,
      ondemand_ssid_excludes => ['home', 'bach'],
    }

The module will build and collect certs and configuration for your clients in
`/etc/ipsec.d/dist/`, for example:

    find /etc/ipsec.d/dist/
    /etc/ipsec.d/dist/
    /etc/ipsec.d/dist/examplephone
    /etc/ipsec.d/dist/examplephone/CACert.der
    /etc/ipsec.d/dist/examplephone/CACert.pem
    /etc/ipsec.d/dist/examplephone/ios-examplephone.mobileconfig
    /etc/ipsec.d/dist/examplephone/examplephone.p12
    /etc/ipsec.d/dist/examplephone/examplephoneCert.pem
    /etc/ipsec.d/dist/examplephone/examplephoneKey.pem


The purpose of these various files are:

* `ios-examplephone.mobileconfig` - A "ready to import" configuration for iOS
  devices that includes the CA and PKCS12 certs, along with all the config
  that you might want.

* `examplephone.p12` - A PCKS/P12 file that includes the client's cert and key
   capable of being imported to most devices for configuring. If your device
   can't import, try renaming from `.p12` to `.pfx` and see if that helps. The
   default password on this file is `password`.

* `examplephone(Cert|Key).pem` - PEM format client cert and key. Try these if
   your device refuses to import the .p12 file above.

* `CACert.(pem|der)` - The CA certificate. Many devices will want this to
   validate the authenticity of your VPN endpoint. If your device can't import
   the PEM, try the DER file.


## iOS Clients

To configure iOS clients (version 9+) email the `.mobileconfig` file that has
been generated to the phone. Note that Apple Mail and the stock Mail app handle
this properly, but third party clients (on sender or reciever) possibly may fail
to set the weird content types needed by iOS. Sharing via iCloud drive doesn't
seem to work properly (unable to import from iCloud on iOS end).

From the mail client, tap and import the file and follow the prompts to import
the certificate. Once complete, there will now be a VPN you can turn on/off in
the settings screen.

If ondemand has been enabled, the VPN should automatically connect if all
conditions are appropiate.


## MacOS Clients

The MacOS process is a bit fiddly, make sure you carefully follow the instructions,
especially in regard to trusting the certs. Also ensure you are on MacOS 10.11
(El Capitan) or later.

1. Import the `.p12` file generated for the client (eg "examplephone.p12"). Find
   the newly imported cert inside keychain access and make it as "Always Trusted".

2. Import the `CACert.pem` file generate for the client. Go into Keychain Access
   and find the CA under "Certificates". Now mark it as "Always Trusted".

3. These first two steps are CRITICAL, if either the client cert or CA cert are not
   trusted, the VPN will fail to connect without any visible message. Sometimes it
   can be hard to find where the certs are in Keychain access, recommend using the
   search box to search based on the vpn name (eg "vpn.example.com").

4. Access `System Preferences -> Network` and add a new VPN interface, making sure to
   select IKEv2 specifically.

5. Populate `Server Address` and `Remote ID` with the VPN Name you're using and
   set the local ID to `client@vpnname` where client is the name of the client
   resource defined (eg "examplephone" and vpnname is the main `vpn_name`
   defined for the `roadwarrior` class.

6. Under `Authentication Settings` select certificate authentication using the 
   one we imported before.

7. Establish your first connection and enjoy!




# Development

Contributions in the form of Pull Requests (or beer donations) are always
welcome. However please keep in mind the goal of this module is to support
road warrior style setups rather than being a general all-purpose
StrongSwan/IKEv2 VPN configuration module.


# License

This module is licensed under the Apache License, Version 2.0 (the "License").
See the LICENSE or http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

