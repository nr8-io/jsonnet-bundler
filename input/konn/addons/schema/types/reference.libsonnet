local property = import './property.libsonnet';

function(
  id,
  required=null,
  requires=null,
  default=null,
) (
  property.new({
    '$ref': id,

    required: required,
    requires: requires,

    default: default,
  })
)
