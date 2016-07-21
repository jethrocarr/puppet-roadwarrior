# Use thisin order to iterate over
class roadwarrior::clients (
  $args = {},
  $defaults = {}
) {
  create_resources( roadwarrior::client, $args, $defaults )
}
