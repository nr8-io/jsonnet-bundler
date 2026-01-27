local k = import 'konn/main.libsonnet';

k.extension(
  function(ctx, target, props) (
    if k.is(target, 'JsonSchema') then (
      if props.enabled && k.get(target, 'metadata.annotations[konn.nr8.io/json-schema]') == 'root' then (
        // get all schemas in the manifest except this one to add to defs
        local defs = ctx.filter(function(target) target.is('JsonSchema') && target.get('metadata.annotations[konn.nr8.io/json-schema]') != 'root');

        target {
          spec+: {
            '$defs'+: {
              [x.metadata.name]: x.spec
              for x in k.render(ctx, defs, props)
            },
          },
        }
      ) else if props.filter == false then (
        target  // disable schema filtering (on by default)
      ) else (
        null  // all json schemas are filtered out by default
      )
    ) else if !props.enabled then (
      target  // if not generating include regular configs
    ) else (
      null  // if generating filter out regular configs
    )
  ),
  {
    filter: true,
    enabled: false,
  }
)
