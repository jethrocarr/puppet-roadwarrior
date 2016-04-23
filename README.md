# puppet-roadwarrior

WARNING: WORK IN PROGRESS, THERE IS NO GOD WILLING TO HELP YOU IF YOU USE THIS.

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
* Generate client certs


# Compatibility

Tested and confirmed on:

* Debian 8 [Server]
* iOS 9 [Client]


This module *should* work on any OS released in 2015-2016 onwards, but many
earlier OS releases didn't ship with IKEv2 VPN support. The following are
known minimum versions:

* MacOS - minimum of 10.11 (El Capitan)
* iOS - minimum of 9


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



# Client Configuration

Simply define each client you wish to use, in addition to the main `roadwarrior`
class above.

    roadwarrior::client { 'myiphone': }
    roadwarrior::client { 'bobiphone': }
    roadwarrior::client { 'androidftw': }

Generally you will not want to adjust any other params per client and leave
them on the defaults. This module will export out the certs in a range of
formats and sets up a mobile config file.


# Development

Contributions in the form of Pull Requests are always welcome. However please
keep in mind the goal of this module is to support road warrior style setups
rather than being a general all-purpose StrongSwan/IKEv2 VPN configuration
module.


# License

This module is licensed under the Apache License, Version 2.0 (the "License").
See the LICENSE or http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

