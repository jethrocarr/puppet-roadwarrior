# Generate V4 UUIDs as used in iOS mobile config files
# See: https://en.wikipedia.org/wiki/Universally_unique_identifier#Version_4_.28random.29

module Puppet::Parser::Functions
  newfunction(:roadwarrior_uuid, :type => :rvalue) do |args|
    # We let Ruby's stdlib do all the work :-)
    return SecureRandom.uuid
  end
end

# vim: set ts=2 sw=2 et :
# encoding: utf-8
