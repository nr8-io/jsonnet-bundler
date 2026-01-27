local types = import './types.libsonnet';
local k = import 'konn/main.libsonnet';

// default schema generation feature flag key
local defaultSchemaKey = '[konn.nr8.io/generate-json-schema]';

// feature flag helper to recursively generate all schemas included in features flags
local flag = function(props={}, path, schemaKey=defaultSchemaKey)
  k.get(props, path, false) || k.get(props, schemaKey, false);

types {
  // create a konn schema feature to be used in applications
  create:: function(id, spec, schemaKey=defaultSchemaKey) (
    local schema = types.schema(id, spec);

    // root schema feature with generation extension
    {
      schema: schema,  // schema preview
      generate:: function(enabled=false, filter=true) k.feature(
        [
          // create and annotate the root schema
          function(ctx, props) (
            types.manifest(schema, root=true)
          ),
        ],
        extensions=[
          function(ctx, props) (import './extensions/generate-json-schema.libsonnet').configure({
            schema: schema,
            filter: filter,
            enabled: enabled || k.get(props, schemaKey, false),
          }),
        ]
      ),
      manifest:: function(root=false) (
        types.manifest(schema, root=root)
      ),
      defaults:: schema.defaults,
      property:: schema.property,
    }
  ),
  // helper to create from json string
  fromJson:: function(id, json) (
    self.create(id, k.json(json))
  ),
  // helper to create from yaml string
  fromYaml:: function(id, str) (
    self.create(id, k.yaml(str))
  ),
  // feature flag helper
  flag:: flag,
}
