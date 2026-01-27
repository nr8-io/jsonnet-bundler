local property = import './property.libsonnet';

function(
  // defaults
  title=null,
  description=null,
  default=null,
  required=null,
  requires=null,
  deprecated=null,

  override=null,
) (
  property.new({
    type: 'boolean',
    title: title,
    description: description,
    default: default,
    required: required,
    requires: requires,
    deprecated: deprecated,

    override: override,
  })
)
