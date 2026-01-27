// trace function for debugging
local trace = function(target, message='', return=function() null) (
  // enable return value override
  local returnValue = if std.isFunction(return) then (
    target
  ) else (
    return
  );

  std.trace(message + ' ' + std.manifestJson(target), returnValue)
);

// Conditional patch with default value
// default is an empty object
local onlyIf = function(test, patch, default={}) (
  if std.isBoolean(test) && test then (
    patch
  ) else (
    default
  )
);

// Conditional patch with default value,
// same as onlyIf but default is an empty array for convenience
local onlyIfArr = function(test, patch, default=[]) (
  onlyIf(test, patch, default)
);

local onlyIfHas = function(obj, key, patch, default={}) (
  onlyIf(std.objectHas(obj, key), patch, default)
);

local onlyIfHasArr = function(obj, key, patch, default=[]) (
  onlyIf(std.objectHas(obj, key), patch, default)
);

// Used for importing string documents with templating and includes
// Automatically removes lines where props were null to keep formatting
local template = function(str, props={}) (
  local nullable = std.mapWithKey(
    function(key, prop) (
      if prop == null then '%(null)s' else prop
    ),
    props
  );

  // split into lines for filtering
  local lines = std.split(str % nullable, '\n');

  std.lines(
    std.filter(
      function(line) (
        std.length(std.findSubstr('%(null)s', line)) == 0
      ),
      lines
    )
  )
);

// Parse yaml from string with templating
// Passes flattened params to the template
local yaml = function(str, props={}, single=true, template=true) (
  local parsed = if std.length(std.objectFields(props)) > 0 && template then (
    std.parseYaml(str % props)
  ) else (
    std.parseYaml(str)
  );

  // normalize to array
  local documents = std.filter(function(val) val != null, if std.isArray(parsed) then (
    parsed
  ) else (
    [parsed]
  ));

  // allow returning single document
  if single && std.length(documents) == 1 then documents[0] else documents
);

local json = function(str, props={}, single=true, template=true) (
  local parsed = if std.length(std.objectFields(props)) > 0 && template then (
    std.parseJson(str % props)
  ) else (
    std.parseJson(str)
  );

  // normalize to array
  local documents = std.filter(function(val) val != null, if std.isArray(parsed) then (
    parsed
  ) else (
    [parsed]
  ));

  // allow returning single document
  if single && std.length(documents) == 1 then documents[0] else documents
);

local is = function(body, kind, name=null) (
  local kinds = if std.isArray(kind) then kind else [kind];

  if std.isObject(body) then (
    if std.type(name) != 'null' then (
      local names = if std.isArray(name) then name else [name];

      // before accessing self.body.kind checks self.body for kind
      std.objectHas(body, 'kind') &&
      std.count(kinds, body.kind) > 0 &&
      // before accessing name checks if body.metadata exists
      std.count(names, body.metadata.name) > 0
    ) else (
      // makes sure body has kind in it
      std.objectHas(body, 'kind') && std.count(kinds, body.kind) > 0
    )
  ) else (
    false
  )
);

// parse value to boolean
local parseToBool(input) =
  if std.type(input) == 'boolean' then input
  else if std.isNumber(input) then input != 0
  else if std.member(['true', '1', 'y', 'yes', 'on', 'Y', 'YES', 'ON'], std.toString(input)) then true
  else if std.member(['false', '0', 'n', 'no', 'off', 'N', 'NO', 'OFF'], std.toString(input)) then false
  else error 'Invalid boolean string';

{
  // conditional helpers
  onlyIf:: onlyIf,
  onlyIfArr:: onlyIfArr,
  onlyIfHas:: onlyIfHas,
  onlyIfHasArr:: onlyIfHasArr,

  // config helper
  is:: is,

  // templating helpers
  template:: template,
  yaml:: yaml,
  json:: json,

  // utils
  parseToBool:: parseToBool,

  // debugging helpers
  trace:: trace,
}
