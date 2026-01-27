local property = import './property.libsonnet';

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

  // object
  properties={},
  patternProperties=null,
  additionalProperties=null,
  unevaluatedProperties=null,
  propertyNames=null,
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

    properties: properties,
    patternProperties: patternProperties,
    additionalProperties: additionalProperties,
    unevaluatedProperties: unevaluatedProperties,
    propertyNames: propertyNames,
    minProperties: minProperties,
    maxProperties: maxProperties,

    allOf: allOf,
    anyOf: anyOf,
    oneOf: oneOf,
    not: not,

    override: override,
  })
)
