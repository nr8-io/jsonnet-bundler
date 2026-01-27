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

  // array
  contains=null,
  items=null,
  maxContains=null,
  maxItems=null,
  minContains=null,
  minItems=null,
  prefixItems=null,
  unevaluatedItems=null,
  uniqueItems=null,

  // composition
  allOf=null,
  anyOf=null,
  oneOf=null,
  not=null,

  // advanced overrides
  override=null,
) (
  property.new({
    type: 'array',
    title: title,
    description: description,
    default: default,
    required: required,
    requires: requires,
    example: example,
    examples: examples,
    deprecated: deprecated,

    contains: contains,
    items: items,
    maxContains: maxContains,
    maxItems: maxItems,
    minContains: minContains,
    minItems: minItems,
    prefixItems: prefixItems,
    unevaluatedItems: unevaluatedItems,
    uniqueItems: uniqueItems,

    allOf: allOf,
    anyOf: anyOf,
    oneOf: oneOf,
    not: not,

    override: override,
  })
)
