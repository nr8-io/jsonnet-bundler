local config = import './config.libsonnet';
local context = import './context.libsonnet';
local lib = import './helpers.libsonnet';
local util = import './util.libsonnet';

// Extension
{
  type:: 'extension',

  // create a new config
  new(
    render=function(ctx, config, props) config,  // extension render function
    props={},  // extension default props
    selector=function(ctx, config, props) true,  // selector function
    extends=config.new(),  // renderable config or manifest to extend
  ):: (
    local ctx = context.new(props);

    self + {
      body: self.render(ctx, props),
      props:: props,
      args:: {
        render: render,
        props: props,
        selector: selector,
        extends: extends,
      },
    }
  ),

  // render a preview of the extension using extends and props
  render(ctx=context.new(), props={}):: (
    local extends = self.args.extends;
    local render = self.args.render;

    if lib.isResolvable(extends) then (
      local extendsProps = lib.resolveProps(extends, props);
      local moreProps = std.mergePatch(extendsProps, props);
      local configs = extends.resolve(ctx, moreProps);
      local extended = lib.applyExtensions([self], ctx, configs, moreProps);

      lib.renderConfigs(ctx, extended, moreProps)
    )
    else if lib.isConfig(extends) then (
      local extendsProps = lib.resolveProps(extends, props);
      local moreProps = std.mergePatch(extendsProps, props);
      local config = extends.render(ctx, moreProps);

      render(ctx, config, moreProps)
    )
    else if std.isObject(extends) then (
      local moreProps = lib.resolveProps(self, props);

      render(ctx, extends, moreProps)
    ) else (
      local moreProps = lib.resolveProps(self, props);

      render(ctx, {}, props)
    )
  ),

  // test a target to see if it should be extended
  selector(ctx=context.new(), config=config.new(), props={}):: (
    self.args.selector(ctx, config, props)
  ),

  // inject the extension to a config
  inject(ctx=context.new(), config=config.new(), props={}):: (
    local render = self.args.render;
    local resolvedProps = lib.resolveProps(self, props);

    if self.selector(ctx, config, resolvedProps) then (
      config.extend(function(_, target, moreProps) (
        // render with extension context and props
        render(ctx, target, resolvedProps)
      ))
    ) else (
      config
    )
  ),

  // extend the extension
  extend(
    render=function(ctx, config, props) config,
    props={},
    selector=function(ctx, config, props) true,  // selector function
    extends=config.new(),  // renderable config or manifest to extend
    schema=self.schema,
  ):: (
    self.new(
      render=function(ctx, config, props) (
        local extension = self.render(ctx, props);

        render(ctx, extension, props)
      ),
      props=lib.resolveProps(self, props),
      selector=selector,
      extends=extends,
    )
  ),

  // resolve overrides
  overrides(props):: props,

  // override props with a function or object
  // overrides supersede the original and render props
  override(propsOrFunction):: (
    // original extension resolver
    local overrides = self.overrides;

    // override with function and parent props
    local overrideWith = function(props) (
      if std.isFunction(propsOrFunction) then (
        propsOrFunction(props)
      )
      else if std.isObject(propsOrFunction) then (
        propsOrFunction
      )
    );

    // supply overrides to be computed at render
    self {
      overrides(props):: std.mergePatch(overrides(props), overrideWith(props)),
    }
  ),

  // alias of override
  apply(propsOrFunction):: self.override(propsOrFunction),
  configure(propsOrFunction):: self.override(propsOrFunction),

}
