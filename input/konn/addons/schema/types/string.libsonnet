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

  // string
  format=null,
  pattern=null,
  minLength=null,
  maxLength=null,

  // composition
  allOf=null,
  anyOf=null,
  oneOf=null,
  not=null,

  override=null,
) (
  property.new({
    type: 'string',
    title: title,
    description: description,
    default: default,
    required: required,
    requires: requires,
    example: example,
    examples: examples,
    deprecated: deprecated,

    format: format,
    pattern: pattern,
    minLength: minLength,
    maxLength: maxLength,

    allOf: allOf,
    anyOf: anyOf,
    oneOf: oneOf,
    not: not,

    override: override,
  })
)
