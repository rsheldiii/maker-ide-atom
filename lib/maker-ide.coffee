path = require 'path'
fs = require 'fs-plus'
{File, CompositeDisposable} = require 'atom'

# Editor model for an maker files
module.exports =
class MakerIDE
  atom.deserializers.add(this)

  @deserialize: ({filePath}) ->
    if fs.isFileSync(filePath)
      new MakerIDE(filePath)
    else
      console.warn "Could not deserialize Maker IDE for path '#{filePath}' because that file no longer exists"

  constructor: (filePath) ->
    @file = new File(filePath)
    @subscriptions = new CompositeDisposable()
    @sceneID = "#{Date.now()}-#{path.basename(filePath, path.extname(filePath))}"

  serialize: ->
    {filePath: @getPath(), deserializer: @constructor.name}

  getViewClass: ->
    require './maker-ide-view'

  destroy: ->
    @subscriptions.dispose()

  getTitle: ->
    if filePath = @getPath()
      path.basename(filePath)
    else
      'untitled'

  # Retrieves the URI of the brd file.
  #
  # Returns a {String}.
  getURI: -> @getPath()


  # Retrieves the absolute path to the brd file.
  #
  # Returns a {String} path.
  getPath: -> @file.getPath()

  # Compares two {brdEditor}s to determine equality.
  #
  # Equality is based on the condition that the two URIs are the same.
  #
  # Returns a {Boolean}.
  isEqual: (other) ->
    other instanceof MakerIDE and @getURI() is other.getURI()
