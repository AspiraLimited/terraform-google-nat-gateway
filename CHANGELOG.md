# Changelog

## 1.3.0 (tag A: no instance-template change)

- `stateful_internal_ip` (default `false`): stateful internal IP on the MIG (`delete_rule = NEVER`) and
  `instance_redistribution_type = NONE`. Apply (and verify the MIG's `statefulPolicy`) BEFORE moving to 1.4.0, so the
  recreate caused by the new template keeps the internal address.
