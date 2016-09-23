path = require 'path'
_ = require 'underscore-plus'
SingleFile = require './single-file'
{CompositeDisposable} = require 'atom'
{OmnibloxView, OmnibloxPart} = require '@omniblox/omniblox-common'

module.exports =

  config:
    triggerOnSave:
      type        : 'boolean'
      description : 'Watch will trigger on save.'
      default     : true
    locale:
      type        : 'string'
      description : 'Manufacturing locale'
      default     : 'local'
    externalTools:
      type: 'object'
      properties:
        stl:
          type: 'string'
          default: OmnibloxPart.defaultConfig().darwin[OmnibloxPart.STL]
          title: 'Tool for printing STL files'
        brd:
          type: 'string'
          default: OmnibloxPart.defaultConfig().darwin[OmnibloxPart.BRD]
          title: 'Tool for cutting BRD files'

  activate: ->
    @statusViewAttached = false
    @disposables = new CompositeDisposable
    @disposables.add atom.workspace.addOpener(openURI)

    atom.commands.add 'atom-workspace', 'maker-ide-atom:fabricate', =>
      filePath = atom.workspace.getActivePane().activeItem.file.path
      omnibloxParts[filePath].fabricate(@buildConfig().darwin)

  deactivate: ->
    @disposables.dispose()

  buildConfig: () ->
    config = {'darwin': {'.stl': atom.config.get('maker-ide-atom.externalTools.stl'), '.brd': atom.config.get('maker-ide-atom.externalTools.brd')}}
    return OmnibloxPart.resolveConfig(config);

# Files with extensions in OmnibloxPart.supportedFileTypes will be opened as geo
openURI = (uriToOpen) ->
  uriExtension = path.extname(uriToOpen).toLowerCase()
  if _.include(OmnibloxPart.supportedFileTypes, uriExtension)
    new SingleFile(uriToOpen)
