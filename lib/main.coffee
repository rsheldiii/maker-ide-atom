path = require 'path'
_ = require 'underscore-plus'
MakerIDE = require './maker-ide'
{CompositeDisposable} = require 'atom'
{OmnibloxView, OmnibloxPart} = require '@omniblox/omniblox-common'

module.exports =

  config:
    externalTools:
      type: 'object'
      properties:
        stl:
          type: 'string'
          default: '/Applications/Cura.app/Contents/MacOS/Cura'
          title: 'Tool for printing STL files'
        brd:
          type: 'string'
          default: '/Applications/Otherplan.app/Contents/MacOS/Otherplan'
          title: 'Tool for cutting BRD files'

  activate: ->
    @statusViewAttached = false
    @disposables = new CompositeDisposable
    @disposables.add atom.workspace.addOpener(openURI)

    atom.commands.add 'atom-workspace', 'maker-ide-atom:make', =>
      filePath = atom.workspace.getActivePane().activeItem.file.path
      omnibloxParts[filePath].fabricate(@buildConfig())

  deactivate: ->
    @disposables.dispose()

  buildConfig: () ->
    return {'.stl': atom.config.get('maker-ide-atom.externalTools.stl'), '.brd': atom.config.get('maker-ide-atom.externalTools.brd')}

# Files with extensions in OmnibloxPart.supportedFileTypes will be opened as geo
openURI = (uriToOpen) ->
  uriExtension = path.extname(uriToOpen).toLowerCase()
  if _.include(OmnibloxPart.supportedFileTypes, uriExtension)
    new MakerIDE(uriToOpen)
