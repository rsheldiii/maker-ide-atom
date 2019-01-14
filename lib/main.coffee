path = require 'path'
url  = require 'url'
_ = require 'underscore-plus'
SingleFile = require './single-file'
EditorPreviewView = require './editor-preview-view'
{CompositeDisposable, Disposable, Emitter} = require 'atom'
{OmnibloxView, OmnibloxPart, OmnibloxCompositor, OmnibloxFabricator} = require 'omniblox-common'

# string-hash
hash = (str) ->
  hashNum = 5381
  i = str.length

  while(i)
    hashNum = (hashNum * 33) ^ str.charCodeAt(--i)
  hashNum >>> 0

# Mouse tracking In Editor
# closestTextEditor = (target) ->
#   target?.closest?('atom-text-editor')?.getModel()

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
      default     : path.join(process.env.HOME || process.env.USERPROFILE, OmnibloxPart.defaultConfig().darwin['workingDir'].slice(1))
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
        svg:
          type: 'string'
          default: OmnibloxPart.defaultConfig().darwin['apps'][OmnibloxPart.SVG]
          title: 'Tool for cutting BRD files'


  editorPreviewView: null


  activate: ->
    @emitter = new Emitter
    @statusViewAttached = false
    @disposables = new CompositeDisposable
    @disposables.add atom.workspace.addOpener(openURI)

    @disposables.add atom.commands.add 'atom-workspace', 'maker-ide-atom:toggle': =>  @toggle()

    # @observeMouse()

  deactivate: ->
    @disposables.dispose()

  # Mouse tracking In Editor
  # core of mousing tracking in text-editor
  # TODO: Implement
  # observeMouse: ->
  #   locationStack = []
  #   handleCapture = (event) ->
  #     editor = atom.workspace.getActiveTextEditor()
  #     return unless editor?
  #     return unless editor.getPath().match(/omniblox.js$/)
  #     console.log(editor.getCursorBufferPosition())
  #
  #   handleBubble = (event) =>
  #     if closestTextEditor(event.target)?.getURI()
  #       setTimeout =>
  #         @checkLocationChange(location) if location = locationStack.pop()
  #       , 100
  #
  #   workspaceElement = atom.views.getView(atom.workspace)
  #   workspaceElement.addEventListener('mousedown', handleCapture, true)
  #   workspaceElement.addEventListener('mousedown', handleBubble, false)
  #
  #   @disposables.add new Disposable ->
  #     workspaceElement.removeEventListener('mousedown', handleCapture, true)
  #     workspaceElement.removeEventListener('mousedown', handleBubble, false)
  #
  # checkLocationChange: (oldLocation) ->
  #   editor = atom.workspace.getActiveTextEditor()
  #   return unless editor
  #
  #   if editor.element.hasFocus() and (editor.getURI() is oldLocation.URI)
  #     # Move within same buffer.
  #     newLocation = new Location(oldLocation.type, editor)
  #     @emitter.emit('did-change-location', {oldLocation, newLocation})
  #   else
  #     @emitter.emit('did-unfocus', {oldLocation})

  toggle: ->

    editor = atom.workspace.getActiveTextEditor()
    return unless editor && OmnibloxPart.previewFile(editor.getPath())

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

# Files with extensions in OmnibloxPart.renderededFileTypes will be opened as geo
openURI = (uriToOpen) ->
  try
    {protocol, host, pathname} = url.parse(uriToOpen)
  catch error
    return

  sceneID = "#{Date.now()}-#{hash(path.basename(uriToOpen, path.extname(uriToOpen)))}"

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
  if _.include(OmnibloxPart.renderedFileTypes, uriExtension)
    new SingleFile(uriToOpen, sceneID)
