local config = import './config.libsonnet';
local context = import './context.libsonnet';
local feature = import './feature.libsonnet';
local lib = import './helpers.libsonnet';
local manifest = import './manifest.libsonnet';

// Feature
{
  type:: 'application',

  // create new manifest
  new(
    features=[],
    defaults={},
    profiles={},
    extensions=[],
    filter=function(ctx, config, props) true,
    map=function(ctx, config, props) config,
  ):: (
    self + {
      configs:: self.resolve(context.new(defaults), defaults),
      profiles:: {
        default: {},  // so we can render without a profile
      } + profiles,
      args:: {
        defaults: defaults,
        profiles: profiles,
        features: features,
        extensions: extensions,
        filter: filter,
        map: map,
      },
    } + {
      body: self.render(context.new(defaults, self.configs), defaults),
    }
  ),

  // render the config with resolved props
  render(
    ctx=context.new(self.args.defaults, self.configs),
    props=self.args.defaults
  ):: (
    local moreProps = std.mergePatch(self.args.defaults, props);
    local configs = self.resolve(ctx, props);

    // context with resolved manifests
    local resolvedCtx = ctx.extend(moreProps, configs);

    // apply extensions to the resolved configs
    local extended = lib.applyExtensions(
      self.extensions(resolvedCtx, moreProps),
      resolvedCtx,
      configs,
      moreProps
    );

    // context with extended configs
    local extendedCtx = ctx.extend(moreProps, extended);

    //render all resolved configs
    lib.renderConfigs(extendedCtx, extended, moreProps)
  ),

  // render with profile
  init(
    props=self.args.defaults,
    profile='default',
  ):: (
    // get the profile props
    local profileProps = if std.objectHas(self.profiles, profile) then (
      self.profiles[profile]
    )
    else (
      error 'profile "' + profile + '" not found'
    );

    // merge global defaults with profile defaults
    local defaultProps = std.mergePatch(self.args.defaults, profileProps);
    // merge defaults with provided values
    local moreProps = std.mergePatch(defaultProps, props);

    // render context with profile metadata
    local ctx = context.new(moreProps, self.configs, metadata={
      profile: profile,
    });

    self.render(ctx, moreProps)
  ),

  debug(
    props=self.args.defaults,
    profile='default',
  ):: (
    // get the profile props
    local profileProps = if std.objectHas(self.profiles, profile) then (
      self.profiles[profile]
    )
    else (
      error 'profile "' + profile + '" not found'
    );

    // merge global defaults with profile defaults
    local defaultProps = std.mergePatch(self.args.defaults, profileProps);
    // merge defaults with provided values
    local mergedProps = std.mergePatch(defaultProps, props);

    // render context with profile metadata
    local ctx = context.new(mergedProps, metadata={
      profile: profile,
    });

    local body = self.render(ctx, mergedProps);
    local profiles = self.profiles;
    local defaults = self.args.defaults;

    {
      _debug: {
        '[10] supplied profile at init': profile,
        '[11] supplied props at init': props,
        '[20] app defaults': defaults,
        '[21] app profiles': profiles,
        '[30] final render props': mergedProps,
      },
      body: body,
    }
  ),

  // resolve individual configs
  resolve(
    ctx=context.new(self.args.defaults, self.args.config),
    props=self.args.defaults
  ):: (
    local moreProps = std.mergePatch(self.args.defaults, props);

    local configs = std.filter(
      // support conditional configs by filtering out null configs
      function(config) std.type(config) != 'null',
      // map over the configs and apply the render functions
      std.map(
        function(config) (
          // allow conditional config rendering
          if std.isFunction(config) then (
            config(ctx, moreProps)
          )
          else (
            config
          )
        ),
        self.args.features
      )
    );

    // resolve all configs from different sources into a flat array
    local resolved = std.flattenArrays(
      std.map(
        function(source) (
          if lib.isResolvable(source) then (
            source.resolve(ctx, moreProps)
          )
          else (
            manifest.from(source).resolve(ctx, moreProps)
          )
        ),
        configs
      )
    );

    // apply custom filter and remove any empty configs
    local filtered = std.filter(
      function(config) (
        if std.length(std.objectFields(config)) > 0 then (
          self.args.filter(ctx, config, moreProps)
        )
        else (
          false
        )
      ),
      resolved
    );

    // apply custom map function the filtered configs
    lib.mapConfigs(self.args.map, filtered)
  ),

  //
  features(
    ctx=context.new(self.args.defaults, self.args.manifest),
    props=self.args.defaults
  ):: (
    local moreProps = std.mergePatch(self.args.defaults, props);

    std.filter(
      // allow conditional features by filtering out null extensions
      function(feature) std.type(feature) != 'null',
      std.map(
        function(feature) (
          // allow conditional extension rendering
          if std.isFunction(feature) then (
            feature(ctx, moreProps)
          )
          else (
            feature
          )
        ),
        self.args.features
      )
    )
  ),

  //
  extensions(
    ctx=context.new(self.args.defaults, self.configs),
    props=self.args.defaults
  ):: (
    local moreProps = std.mergePatch(self.args.defaults, props);

    std.filter(
      // allow conditional extensions by filtering out null extensions
      function(extension) std.type(extension) != 'null',
      std.map(
        function(extension) (
          // allow conditional extension rendering
          if std.isFunction(extension) then (
            extension(ctx, moreProps)
          )
          else (
            extension
          )
        ),
        self.args.extensions
      )
    )

    // resolve extensions from features
    + std.flattenArrays(
      std.map(
        function(feature) (
          if std.isObject(feature) && std.objectHasAll(feature, 'extensions') && std.isFunction(feature.extensions) then (
            feature.extensions(ctx, moreProps)
          )
          else (
            []
          )
        ),
        self.features(ctx, moreProps)
      )
    )
  ),

  // extend the manifest

  // extend the manifest
  extend(
    features=[],
    defaults={},
    profiles={},
    extensions=[],
    filter=function(ctx, config, props) true,
    map=function(ctx, config, props) config,
    schema=self.schema
  ):: (
    self.new(
      features=self.args.features + features,
      defaults=std.mergePatch(self.args.defaults, defaults),
      profiles=std.mergePatch(self.args.profiles, profiles),
      extensions=self.args.extensions + extensions,
      filter=function(ctx, config, props) (
        self.args.filter(ctx, config, props) && filter(ctx, config, props)
      ),
      map=function(ctx, config, props) (
        map(ctx, self.args.map(ctx, config, props), props)
      ),
    )
  ),

  // returns an extended manifest with a filter applied
  filter(fn):: (
    self.extend(filter=fn)
  ),

  // returns an extended manifest with a map function applied
  map(fn):: (
    self.extend(map=fn)
  ),

  // finds a configs in the manifest and returns the first result
  find(fn):: (
    local manifest = self.filter(fn);

    if std.length(manifest.configs) > 0 then (
      manifest.configs[0]
    )
  ),

  // get a specific config by path
  get(path, matcher=''):: (
    self.find(
      function(ctx, config, props) (
        lib.getPath(config.body, path) == matcher
      )
    )
  ),

  // get a specific config by kind and metadata name
  kget(kind, name=null):: (
    self.find(
      function(ctx, config, props) (
        if std.type(name) != 'null' then (
          config.body.kind == kind && config.body.metadata.name == name
        ) else (
          config.body.kind == kind
        )
      )
    )
  ),
}
