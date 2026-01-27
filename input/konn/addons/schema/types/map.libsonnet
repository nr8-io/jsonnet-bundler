local object = import './object.libsonnet';
local property = import './property.libsonnet';

// alias for object, puts properties into additional properties
function(
  // defaults
  title=null,
  description=null,
  default=null,
  required=null,
  requires=null,
  example=null,
  examples=null,
  deprecated=null,

  // map type
  items={},

  // object
  minProperties=null,
  maxProperties=null,

  // composition
  allOf=null,
  anyOf=null,
  oneOf=null,
  not=null,

  // advanced overrides
  override=null,
) (
  property.new({
    type: 'object',

    title: title,
    description: description,
    default: default,
    required: required,
    requires: requires,
    example: example,
    examples: examples,
    deprecated: deprecated,

    additionalProperties: items,

    override: override,
  })

  // auto create a map example
  + (
    if std.type(examples) == 'null' && std.type(example) == 'null' then (
      {
        examples+: [{
          key: items.defaults(),
        }],
      }
    ) else (
      {}
    )
  )

  // transparent property forwarding to support defaults() for objects
  + (
    if items.type == 'object' then (
      {
        properties:: items.properties,
      }
    ) else (
      {}
    )
  )
)
