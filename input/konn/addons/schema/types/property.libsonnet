// private key
local pkey = function(key) (
  '#' + key
);

// property option
local option = function(props={}, key, types=false, private=false) (
  local type = if std.objectHas(props, 'type') then props.type else 'object';

  if !std.objectHas(props, key) || props[key] == null then (
    {}
  ) else if std.isArray(types) && !std.contains(types, type) then (
    {}
  ) else if private then (
    {
      [pkey(key)]:: props[key],
    }
  ) else (
    {
      [key]: props[key],
    }
  )
);

local property = {
  // default type is object
  [pkey('type')]:: 'object',

  // requirement tracking
  [pkey('requires')]:: null,  // used for requiredFor, if true, the property is required
  [pkey('required')]:: null,

  // create a new property definition
  new(options={}):: (
    local type = if std.objectHas(options, 'type') then options.type else if std.objectHas(options, '$ref') then 'ref' else 'object';

    self

    // private type key to support nested json/yaml parsing
    + { [pkey('type')]: type }

    + option(options, 'title')
    + option(options, 'description')
    + option(options, 'default')

    // private, used by parent schema for evaluating sub-schemas
    // https://json-schema.org/understanding-json-schema/reference/object#required
    + option(options, 'required', private=true)
    + option(options, 'requires', private=true)

    // annotations
    + option(options, 'examples')
    + option(options, 'deprecated')

    // string
    + option(options, 'format', ['string'])
    + option(options, 'pattern', ['string'])
    + option(options, 'minLength', ['string'])
    + option(options, 'maxLength', ['string'])

    // numbers
    + option(options, 'multipleOf', ['number'])
    + option(options, 'minimum', ['number'])
    + option(options, 'exclusiveMinimum', ['number'])
    + option(options, 'maximum', ['number'])
    + option(options, 'exclusiveMaximum', ['number'])

    // special types
    + option(options, 'enum')
    + option(options, 'const')

    // array
    + option(options, 'contains', ['array'])
    + option(options, 'items', ['array'])
    + option(options, 'maxContains', ['array'])
    + option(options, 'maxItems', ['array'])
    + option(options, 'minContains', ['array'])
    + option(options, 'minItems', ['array'])
    + option(options, 'prefixItems', ['array'])
    + option(options, 'unevaluatedItems', ['array'])
    + option(options, 'uniqueItems', ['array'])

    // object
    + option(options, 'additionalProperties', ['object'])
    + option(options, 'unevaluatedProperties', ['object'])
    + option(options, 'propertyNames', ['object'])
    + option(options, 'minProperties', ['object'])
    + option(options, 'maxProperties', ['object'])

    // composition
    + option(options, 'allOf')
    + option(options, 'anyOf')
    + option(options, 'oneOf')
    + option(options, 'not')

    + (
      if std.contains(['array', 'boolean', 'number', 'object', 'string'], type) then (
        {
          type: type,
        }
      ) else (
        {}
      )
    )

    // add $ref for ref type
    + (
      if std.objectHas(options, '$ref') then (
        {
          '$ref': '#/$defs/konn:schema:' + options['$ref'],
        }
      ) else (
        {}
      )
    )

    + (  // add object properties if supplied
      if type == 'object' && std.objectHas(options, 'properties') then (
        // add properties & dependent requirements
        {
          properties: {
            [x]: if !std.objectHasAll(options.properties[x], pkey('type')) then (
              property.new(options.properties[x])  // recursively create property from plain objects
            ) else (
              options.properties[x]
            )
            for x in std.objectFields(options.properties)
            if options.properties != null
          },
        }

        + (
          local dependentRequired = {
            [x]+: options.properties[x][pkey('requires')]
            for x in std.objectFields(options.properties)
            if std.objectHas(options.properties[x], pkey('requires')) && std.isArray(options.properties[x][pkey('requires')])
          };

          if std.length(dependentRequired) > 0 then (
            { dependentRequired+: dependentRequired }
          ) else (
            {}
          )
        )

        // add required array if any properties are flagged as required
        + (
          local requiredList = [
            x
            for x in std.objectFields(options.properties)
            if std.objectHas(options.properties[x], pkey('required')) && options.properties[x][pkey('required')] == true
          ];

          if std.length(requiredList) > 0 then (
            { required+: requiredList }
          ) else (
            {}
          )
        )
      ) else (
        {}
      )
    )

    + (  // add object properties if supplied
      if type == 'object' && std.objectHas(options, 'patternProperties') && options.patternProperties != null then (
        // add properties & dependent requirements
        {
          patternProperties: {
            [x]: options.patternProperties[x]
            for x in std.objectFields(options.patternProperties)
            if options.patternProperties != null
          },
        }
      ) else (
        {}
      )
    )


    + (
      if std.objectHas(options, 'examples') && std.type(options.examples) != 'null' then (
        {
          examples+: [options.examples],
        }
      ) else (
        {}
      )
    )

    + (  // advanced overrides
      if std.objectHas(options, 'override') && options.override != null && std.isObject(options.override) then (
        options.override
      ) else (
        {}
      )
    )
  ),

  // access object property by key
  property(key=null):: (
    local type = self.type;

    if type == 'object' && std.objectHas(self.properties, key) then (
      self.properties[key]
    ) else (
      null
    )
  ),

  // gets the default value for the property, used for filling defaults
  defaults(recursive=false, depth=0):: (
    local type = if std.objectHas(self, 'type') then self.type else 'object';

    if (type == 'object' && recursive == false && depth == 0) || type == 'object' && recursive == true then (
      local properties = if std.objectHasAll(self, 'properties') then self.properties else {};
      local default = if std.objectHas(self, 'default') then self.default else {};

      std.mergePatch(default, {
        [x]: properties[x].defaults(recursive, depth + 1)
        for x in std.objectFields(properties)
      })
    ) else if std.objectHas(self, 'default') then (
      self.default
    ) else if type == 'object' then (
      {}
    ) else if type == 'array' then (
      []
    ) else (
      null
    )
  ),

};

property
