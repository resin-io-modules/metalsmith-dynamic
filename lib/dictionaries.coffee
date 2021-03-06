fs = require('fs')
path = require('path')
_ = require('lodash')

Dicts = (dictionaries) ->
  if dictionaries instanceof Dicts
    return dictionaries

  if _.isString(dictionaries)
    return Dicts.fromDir(dictionaries)

  if this not instanceof Dicts
    return new Dicts(dictionaries)

  @_dicts = _.assign({}, dictionaries)
  @dictNames = _.keys(@_dicts)

  @_expandFKs()

  return

Dicts::_expandFKs = ->
  for name, dict of @_dicts
    for entry in dict
      for k, v of entry
        continue if k[0] isnt '$'
        parts = v.split('.')
        if parts.length isnt 2
          throw new Error("FK values must be formated as `$otherDict.ID`: #{k}: #{v}")
        [ otherDict, id ] = parts
        otherObj = this.getDetails(otherDict, id)
        if not otherObj?
          throw new Error("ID #{id} not found in dict #{otherDict}")
        entry[k] = otherObj

Dicts::getDict = (key) ->
  @_dicts[key] or throw new Error("Unknown key #{key}")

Dicts::getValues = (key) ->
  _.map @getDict(key), 'id'

Dicts::getDetails = (key, id) ->
  _.find @getDict(key), { id }

Dicts::getDefault = (key) ->
  _.first(@getDict(key))?.id

Dicts::getDefaults = ->
  result = {}
  for key in @dictNames
    result[key] = @getDefault(key)
  return result

KNOWN_EXTS = [
  'js'
  'coffee'
  'json'
]

Dicts.fromDir = (dir) ->
  if dir
    extsRe = new RegExp("\\.(#{KNOWN_EXTS.join('|')})$")
    files = fs.readdirSync(dir)
      .filter (file) -> file.match(extsRe)
      .map (file) ->
        ext = path.extname(file)
        return path.basename(file, ext)
  else
    files = []

  dicts = {}
  for file in files
    dicts["$#{file}"] = require("#{dir}/#{file}")

  return Dicts(dicts)

module.exports = Dicts
