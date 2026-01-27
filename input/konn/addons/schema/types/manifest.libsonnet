local k = import 'konn/main.libsonnet';

// create a konn config and render as a kubernetes compatible CRD with auto filter to be used in $defs
function(spec={}, root=false) (
  local schema = {
    apiVersion: 'konn.nr8.io/v1alpha1',
    kind: 'JsonSchema',
    metadata+: {
      name: spec['$id'],
    },
    spec: spec,
  };

  //
  k.manifest(
    function(ctx, props) [
      if root then (
        schema {
          metadata+: {
            annotations+: {
              'konn.nr8.io/json-schema': 'root',
            },
          },
        }
      ) else (
        schema
      ),
    ],
    // filter out schemas unless the schema feature is included
    filter=function(ctx, target, props) (
      ctx.has('metadata.annotations[konn.nr8.io/json-schema]', 'root') || root
    )
  )
)
