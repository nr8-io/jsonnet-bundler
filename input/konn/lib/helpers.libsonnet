local context = import './context.libsonnet';
local util = import './util.libsonnet';

// apply extensions to configs with props
local applyExtensions = function(extensions, ctx, configs, props={}) (
  std.map(
    function(config) (
      std.foldl(
        function(target, extension) (
          extension.inject(
            ctx,
            target,
            props
          )
        ),
        extensions,
        config
      )
    ),
    configs,
  )
);

// get value from object by path using dot notation
local getPath = function(obj, path, defaultValue=null) (
  // magic to support values inside of []
  local sections = std.split(std.strReplace(std.strReplace('.' + path, '[', '%'), ']', '%'), '%');

  // slit dot notation if not inside of [...] sections
  local keys = std.filter(function(key) key != '', std.flatMap(function(part) (
    if std.startsWith(part, '.') then (
      std.split(part, '.')
    ) else (
      // remove ' and " if used in [...] sections
      [std.strReplace(std.strReplace(part, "'", ''), '"', '')]
    )
  ), sections));

  // get the nested value
  local get = function(o, k) (
    if std.length(k) == 0 then (
      o
    )
    else if std.isObject(o) && std.objectHas(o, k[0]) then (
      get(o[k[0]], std.slice(k, 1, null, null))
    )
    else (
      defaultValue
    )
  );

  get(obj, keys)
);

local setPath = function(obj, path, value=null) (
  // magic to support values inside of []
  local sections = std.split(std.strReplace(std.strReplace('.' + path, '[', '%'), ']', '%'), '%');

  // slit dot notation if not inside of [...] sections
  local keys = std.filter(function(key) key != '', std.flatMap(function(part) (
    if std.startsWith(part, '.') then (
      std.split(part, '.')
    ) else (
      // remove ' and " if used in [...] sections
      [std.strReplace(std.strReplace(part, "'", ''), '"', '')]
    )
  ), sections));

  local set = function(o, k, value) (
    if std.length(k) == 0 then (
      value
    )
    else if std.isObject(o) && std.objectHas(o, k[0]) then (
      o {
        [k[0]]: set(o[k[0]], std.slice(k, 1, null, null), value),
      }
    ) else (
      o {
        [k[0]]: set({}, std.slice(k, 1, null, null), value),
      }
    )
  );

  set(obj, keys, value)
);

// Test if a given target is a valid renderable object
local isRenderable = function(target) (
  std.isObject(target)
  && std.objectHasAll(target, 'render')
  && std.isFunction(target.render)
);


// Test if a given target has resolveConfigs method
local isResolvable = function(target) (
  std.isObject(target)
  && std.objectHasAll(target, 'resolve')
  && std.isFunction(target.resolve)
);

// Test if a give target is a config
local isConfig = function(target) (
  isRenderable(target)
  && std.objectHasAll(target, 'type')
  && target.type == 'config'
);

// Test if a give target is a config
local isManifest = function(target) (
  isRenderable(target)
  && std.objectHasAll(target, 'type')
  && target.type == 'manifest'
);


// map configs and extend them with supplied context and props props
local mapConfigs = function(fn, configs=[]) (
  std.map(
    function(config) (
      // extend config with the map function and props
      config.extend(function(ctx, data, props) (
        fn(ctx, data, props)
      ))
    ),
    configs
  )
);


local renderConfigs = function(ctx=context.new(), configs=[], props={}) (
  std.foldl(
    function(manifest, config)
      local rendered = config.render(ctx.extend(props, manifest), props);

      if rendered != null then (
        manifest + [rendered]  // add rendered config to manifest
      )
      else (
        manifest  // filter out empty renders
      ),
    configs,  // configs to render
    []  // initial manifest
  )
);

// render a target with a context and props
// mostly used for testing
local render = function(target, props={}) (
  if isRenderable(target) then (
    target.render(context.new(target.props, target.configs), props)
  ) else (
    target
  )
);

// merge props with target defaults and apply overrides
local resolveProps = function(target, props={}) (
  if std.objectHasAll(target, 'overrides') && std.isFunction(target.overrides) then (
    std.mergePatch(target.props, target.overrides(props))
  ) else (
    std.mergePatch(target.props, props)
  )
);

// exports
{
  applyExtensions:: applyExtensions,
  getPath:: getPath,
  setPath:: setPath,
  isConfig:: isConfig,
  isManifest:: isManifest,
  isRenderable:: isRenderable,
  isResolvable:: isResolvable,
  mapConfigs:: mapConfigs,
  renderConfigs:: renderConfigs,
  render:: render,
  resolveProps:: resolveProps,
}
