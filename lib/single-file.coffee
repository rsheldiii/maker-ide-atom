path = require 'path'
fs = require 'fs-plus'
{File, CompositeDisposable} = require 'atom'

# Editor model for an maker files
module.exports =
class SingleFile
  atom.deserializers.add(this)

  @deserialize: ({filePath}) ->
    if fs.isFileSync(filePath)
      new SingleFile(filePath)
    else
      console.warn "Could not deserialize Maker IDE for path '#{filePath}' because that file no longer exists"

  constructor: (filePath, @sceneID) ->
    @file = new File(filePath)
    @subscriptions = new CompositeDisposable() 

  serialize: ->
    {filePath: @getPath(), deserializer: @constructor.name}

  getViewClass: ->
    require './single-file-view'

  destroy: ->
    @subscriptions.dispose()

  getTitle: ->
    if filePath = @getPath()
      path.basename(filePath)
    else
      'untitled'

  # Retrieves the URI of the file.
  #
  # Returns a {String}.
  getURI: -> @getPath()


  # Retrieves the absolute path to the file.
  #
  # Returns a {String} path.
  getPath: -> @file.getPath()

  # Compares two {MakerID}s to determine equality.
  #
  # Equality is based on the condition that the two URIs are the same.
  #
  # Returns a {Boolean}.
  isEqual: (other) ->
    other instanceof SingleFile and @getURI() is other.getURI()
