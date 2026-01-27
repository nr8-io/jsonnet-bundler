local k = import '../../main.libsonnet';
local array = import './types/array.libsonnet';
local boolean = import './types/boolean.libsonnet';
local manifest = import './types/manifest.libsonnet';
local map = import './types/map.libsonnet';
local number = import './types/number.libsonnet';
local object = import './types/object.libsonnet';
local property = import './types/property.libsonnet';
local reference = import './types/reference.libsonnet';
local schema = import './types/schema.libsonnet';
local string = import './types/string.libsonnet';

{
  arr:: array,
  array:: array,
  bool:: boolean,
  boolean:: boolean,
  manifest:: manifest,
  map:: map,
  num:: number,
  number:: number,
  obj:: object,
  object:: object,
  property:: property.new,
  prop:: property.new,
  ref:: reference,
  reference:: reference,
  schema:: schema,
  str:: string,
  string:: string,
}
