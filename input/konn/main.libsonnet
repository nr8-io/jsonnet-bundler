local app = import './lib/app.libsonnet';
local config = import './lib/config.libsonnet';
local context = import './lib/context.libsonnet';
local extension = import './lib/extension.libsonnet';
local feature = import './lib/feature.libsonnet';
local helpers = import './lib/helpers.libsonnet';
local manifest = import './lib/manifest.libsonnet';
local util = import './lib/util.libsonnet';

{
  // util functions
  onlyIf:: util.onlyIf,
  onlyIfArr:: util.onlyIfArr,
  onlyIfHas:: util.onlyIfHas,
  onlyIfHasArr:: util.onlyIfHasArr,
  parseToBool:: util.parseToBool,

  // templating helpers
  yaml:: util.yaml,
  json:: util.json,
  template:: util.template,

  // config helpers
  is:: util.is,  // kind check

  // debugging helpersR
  trace:: util.trace,

  // get/set helpers
  get:: helpers.getPath,
  set:: helpers.setPath,
  patch:: std.mergePatch,

  // lib functions
  isConfig:: helpers.isConfig,
  isManifest:: helpers.isManifest,
  isResolvable:: helpers.isResolvable,
  isRenderable:: helpers.isRenderable,

  // manifest helpers
  fromYaml:: manifest.fromYaml,
  fromJson:: manifest.fromJson,

  // render
  render:: helpers.renderConfigs,

  // lib exports
  lib:: {
    app: app,
    config: config,
    context: context,
    extension: extension,
    feature: feature,
    manifest: manifest,
  },

  app(
    features=[],
    defaults={},
    profiles={},
    extensions=[],
    filter=function(ctx, config, props) true,
    map=function(ctx, config, props) config,
  ):: (
    app.new(
      features=features,
      defaults=defaults,
      profiles=profiles,
      extensions=extensions,
      filter=filter,
      map=map
    )
  ),

  feature(
    configs=[],
    props={},
    extensions=[],
    filter=function(ctx, config, props) true,
    map=function(ctx, config, props) config,
  ):: (
    feature.new(
      configs=configs,
      props=props,
      extensions=extensions,
      filter=filter,
      map=map
    )
  ),

  manifest(
    source=function(ctx, props) [],
    props={},
    filter=function(ctx, config, props) true,
    map=function(ctx, config, props) config,
  ):: (
    manifest.from(
      source=source,
      props=props,
      filter=filter,
      map=map
    )
  ),

  config(
    source=function(ctx, props) {},
    props={}
  ):: (
    config.from(
      source=source,
      props=props
    )
  ),

  extension(
    render=function(ctx, config, props) config,  // extension render function
    props={},  // extension default props
    selector=function(ctx, config, props) true,  // selector function
    extends=config.new(),  // renderable config or manifest to extend
  ):: (
    extension.new(
      render=render,
      props=props,
      selector=selector,
      extends=extends
    )
  ),
}
