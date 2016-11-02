path = require 'path'
url  = require 'url'
_ = require 'underscore-plus'
SingleFile = require './single-file'
EditorPreviewView = require './editor-preview-view'
{CompositeDisposable} = require 'atom'
{OmnibloxView, OmnibloxPart, OmnibloxCompositor, OmnibloxFabricator} = require '@omniblox/omniblox-common'

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
    workingDir:
      type        : 'string'
      description : 'Working Directory'
      default     : path.join(process.env.HOME, OmnibloxPart.defaultConfig().darwin['workingDir'] .slice(1))
    externalTools:
      type: 'object'
      properties:
        stl:
          type: 'string'
          default: OmnibloxPart.defaultConfig().darwin['apps'][OmnibloxPart.STL]
          title: 'Tool for printing STL files'
        brd:
          type: 'string'
          default: OmnibloxPart.defaultConfig().darwin['apps'][OmnibloxPart.BRD]
          title: 'Tool for cutting BRD files'

  editorPreviewView: null

  activate: ->
    @statusViewAttached = false
    @disposables = new CompositeDisposable
    @disposables.add atom.workspace.addOpener(openURI)

    @disposables.add atom.commands.add 'atom-workspace', 'maker-ide-atom:toggle': =>  @toggle()
    @disposables.add atom.commands.add 'atom-workspace', 'maker-ide-atom:fabricate-single-file': =>  @makeSingleFile()
    @disposables.add atom.commands.add 'atom-workspace', 'maker-ide-atom:fabricate-product': =>  @makeProduct()

  deactivate: ->
    @disposables.dispose()

  buildConfig: () ->
    config = {'darwin': {'apps': {'.stl': atom.config.get('maker-ide-atom.externalTools.stl'), '.brd': atom.config.get('maker-ide-atom.externalTools.brd')}, 'workingDir': atom.config.get('maker-ide-atom.workingDir')}}
    return OmnibloxPart.resolveConfig(config);

  toggle: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    return unless editor.getPath().match(/omniblox.js$/)

    uri = "maker-ide-atom://editor/#{editor.id}"

    previewPane = atom.workspace.paneForURI(uri)
    if previewPane
      previewPane.destroyItem(previewPane.itemForURI(uri))
      return

    previousActivePane = atom.workspace.getActivePane()
    atom.workspace.open(uri, {split: 'right', searchAllPanes: true}).done (editorPreviewView) ->
      if editorPreviewView instanceof EditorPreviewView
        editorPreviewView.renderManifest()
        previousActivePane.activate()


  makeSingleFile: ->
    filePath = atom.workspace.getActivePane().activeItem.file.path
    config = @buildConfig().darwin
    OmnibloxFabricator.fabricateSingleFile(path.extname(filePath), [filePath], config)


  makeProduct: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?
    return unless editor.getPath().match(/omniblox.js$/)

    root = path.parse(path.parse(editor.getURI()).dir).dir
    config = @buildConfig().darwin
    OmnibloxFabricator.fabricateProduct(editor.getText(), root, config)



# Files with extensions in OmnibloxPart.supportedFileTypes will be opened as geo
openURI = (uriToOpen) ->
  try
    {protocol, host, pathname} = url.parse(uriToOpen)
  catch error
    return

  sceneID = "#{Date.now()}-#{path.basename(uriToOpen, path.extname(uriToOpen))}"

  if protocol is 'maker-ide-atom:'
    openEditorPreview(uriToOpen, host, pathname, sceneID)
  else
    openSingleFileView(uriToOpen, sceneID)


openEditorPreview = (uriToOpen, host, pathname, sceneID) ->
  try
    pathname = decodeURI(pathname) if pathname
  catch error
    return

  if host is 'editor'
    new EditorPreviewView(sceneId: sceneID, editorId: pathname.substring(1))
  else
    new EditorPreviewView(sceneId: sceneID, filePath: pathname)


openSingleFileView = (uriToOpen, sceneID) ->
  uriExtension = path.extname(uriToOpen).toLowerCase()
  if _.include(OmnibloxPart.supportedFileTypes, uriExtension)
    new SingleFile(uriToOpen, sceneID)
