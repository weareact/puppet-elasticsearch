# == Define: elasticsearch_old::shield::role
#
# Manage shield roles.
#
# === Parameters
#
# [*privileges*]
#   A hash of permissions defined for the role. Valid privilege settings can
#   be found in the Shield documentation:
#   https://www.elastic.co/guide/en/shield/current/index.html
#   Value type is hash
#   Default value: {}
#
# [*mappings*]
#   A list of optional mappings defined for this role.
#   Value type is array
#   Default value: []
#
# === Examples
#
# # Creates and manages the role 'power_user' mapped to an LDAP group.
# elasticsearch_old::shield::role { 'power_user':
#   privileges => {
#     'cluster' => 'monitor',
#     'indices' => {
#       '*' => 'all',
#     },
#   },
#   mappings => [
#     "cn=users,dc=example,dc=com",
#   ],
# }
#
# === Authors
#
# * Tyler Langlois <mailto:tyler@elastic.co>
#
define elasticsearch_old::shield::role (
  $ensure     = 'present',
  $privileges = {},
  $mappings   = [],
) {
  validate_string($ensure)
  validate_hash($privileges)
  validate_array($mappings)
  validate_slength($name, 30, 1)

  if empty($privileges) or $ensure == 'absent' {
    $_role_ensure = 'absent'
  } else {
    $_role_ensure = $ensure
  }

  if empty($mappings) or $ensure == 'absent' {
    $_mapping_ensure = 'absent'
  } else {
    $_mapping_ensure = $ensure
  }

  elasticsearch_shield_role { $name :
    ensure     => $_role_ensure,
    privileges => $privileges,
  }

  elasticsearch_shield_role_mapping { $name :
    ensure   => $_mapping_ensure,
    mappings => $mappings,
  }
}
