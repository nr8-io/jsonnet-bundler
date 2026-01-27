local t = import 'konn/addons/schema/types.libsonnet';
local k = import 'konn/main.libsonnet';

local bwSchema = t.schema(
  id='bitwarden-secrets',
  title='Bitwarden secrets',
  description='Creates a bitwarden external secret and a secret store for the vault',
  properties={
    secretStore: t.property('Secret store', 'The name of the secret store', default='bitwarden', required=true, minLength=1, oneOf=[t.string(), t.number()]),
    organizationId: t.string('Organization ID', 'The organization id of the bitwarden vault', format='uuid'),
    projectId: t.string('The project id of the bitwarden vault', format='uuid'),
    createSecrets: t.bool('If empty Secret should be created with empty keys', default=true),
    createSecretStore: t.bool('If a secret store should be created', default=true, requires=['organizationId', 'projectId']),
    secrets: t.map('secrets', 'map of secrets to create', items=t.object(properties={
      forceSync: t.string('Add force sync annotation', default='1'),
      forcePushSync: t.string('Add force sync annotation to the push secret', default='1'),
      refreshInterval: t.string('Optional refresh interval for the external secret, default is 1m, nullable', default='1m'),
      pushRefreshInterval: t.string('Optional refresh interval for the push secret, default is null'),
      createSecret: t.bool('Optional override for global createSecrets'),
      createPushSecret: t.bool('If a push secret should be created for this secret', default=true),
      keys: t.array(description='The keys to be synced with bitwarden secrets', examples=['[key1, key2, key3]'], items=t.string('key name'), required=true),
    })),
  }
);

local bwFeat = k.feature(
  [
    t.define(bwSchema),
  ],
);

local appSchema = t.schema(
  id='root',
  properties={
    extensions: t.object('extensions', 'Map of extensions to apply', properties={
      schema: t.bool('enable schema extension', default=false),
    }),
    bitwardenSecrets: t.ref('bitwarden-secrets'),
  },
  root=true
);

local app = k.app(
  [
    function(ctx, props) (import 'konn/addons/schema/main.libsonnet').apply({
      generate: props.generateSchema,
      schema: appSchema,
    }),

    {
      banana: true,
    },

    bwFeat,
  ],
  {
    generateSchema: false,
  }
);

app.init({ generateSchema: true })
