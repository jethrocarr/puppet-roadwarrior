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


# Usage

TBD.


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

