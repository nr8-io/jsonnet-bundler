local property = import './property.libsonnet';
local k = import 'konn/main.libsonnet';

function(
  id,
  options={},
  schema='https://json-schema.org/draft/2020-12/schema',
) (
  property.new(options {
    id: id,

    // add schema specific properties
    override: {
      '$id': 'konn:schema:' + id,
      '$schema': schema,
    },
  })
)
