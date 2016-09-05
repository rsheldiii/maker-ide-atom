path = require 'path'
_ = require 'underscore-plus'
MakerIDE = require './maker-ide'
{CompositeDisposable} = require 'atom'

module.exports =

  activate: ->
    @statusViewAttached = false
    @disposables = new CompositeDisposable
    @disposables.add atom.workspace.addOpener(openURI)

    atom.commands.add 'atom-workspace', 'maker-ide-atom:make', ->
      filePath = atom.workspace.getActivePane().activeItem.file.path
      omnibloxParts[filePath].fabricate()

  deactivate: ->
    @disposables.dispose()

# Files with these extensions will be opened as geo
brdExtensions = ['.brd', '.stl']
openURI = (uriToOpen) ->
  uriExtension = path.extname(uriToOpen).toLowerCase()
  if _.include(brdExtensions, uriExtension)
    new MakerIDE(uriToOpen)
