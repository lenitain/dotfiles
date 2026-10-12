# Trim pure prompt: pay only for fields we display.
# `_pure_set_default` (vendor) never overwrites non-empty values, so these
# persist regardless of conf.d load order. Edit here to re-enable a feature.

set -U pure_enable_aws_profile false
set -U pure_enable_container_detection false
set -U pure_enable_virtualenv false
