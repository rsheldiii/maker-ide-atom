path                  = require 'path'
{CompositeDisposable, Disposable} = require 'atom'
{$, $$$, ScrollView}  = require 'atom-space-pen-views'
_                     = require 'underscore-plus'
{OmnibloxView, OmnibloxPart, OmnibloxCompositor} = require 'omniblox-common'

# TODO: refactor to use the same class arrangement as single-file

module.exports =
class EditorPreviewView extends ScrollView
  atom.deserializers.add(this)

  editorSub           : null
  onDidChangeTitle    : -> new Disposable()
  onDidChangeModified : -> new Disposable()

  @deserialize: (state) ->
    new EditorPreviewView(sceneId: state.sceneId, editorId: state.editorId, filePath: state.filePath)

  @content: ->
    @div id: 'maker-ide-container-pane', class: 'maker-ide-view', tabindex: -1, =>
      @div class: 'maker-ide-container', =>
        @div id: 'maker-ide-container-cell'

  attached: () ->
    @initThreeJs()

  destroy: ->
    @compositor.clearScene()
    @disposables.dispose()

  onDidLoad: (callback) ->
    @emitter.on 'did-load', callback

  constructor: ({@sceneId, @editorId, filePath}) ->
    super

    @divID = 'maker-ide-container-cell'
    @paneDivID = 'maker-ide-container-pane'

    if @editorId?
      @resolveEditor(@editorId)
    else
      if atom.workspace?
        @subscribeToFilePath(filePath)
      else
        atom.packages.onDidActivatePackage =>
          @subscribeToFilePath(filePath)

    @debug = true
    return

  serialize: ->
    deserializer : 'EditorPreviewView'
    filePath     : @getPath()
    editorId     : @editorId
    sceneId      : @sceneId

  subscribeToFilePath: (filePath) ->
    @trigger 'title-changed'
    @handleEvents()
    @renderManifest()

  resolveEditor: (editorId) ->
    resolve = =>
      @editor = @editorForId(editorId)

      if @editor?
        @trigger 'title-changed' if @editor?
        @handleEvents()
      else
        # The editor this preview was created for has been closed so close
        # this preview since a preview cannot be rendered without an editor
        @parents('.pane').view()?.destroyItem(this)

    if atom.workspace?
      resolve()
    else
      # @subscribe atom.packages.once 'activated', =>
      atom.packages.onDidActivatePackage =>
        resolve()

  editorForId: (editorId) ->
    for editor in atom.workspace.getTextEditors()
      return editor if editor.id?.toString() is editorId.toString()
    null

  handleEvents: =>

    changeHandler = =>
      @renderManifest()
      pane = atom.workspace.paneForURI(@getURI())
      if pane? and pane isnt atom.workspace.getActivePane()
        pane.activateItem(this)

    @disposables = new CompositeDisposable
    if @editor?
      if not atom.config.get("maker-ide-atom.triggerOnSave")
        @disposables.add @editor.onDidChange _.debounce(changeHandler, 700)
      else
        @disposables.add @editor.onDidSave changeHandler
      @disposables.add @editor.onDidChangePath => @trigger 'title-changed'

  renderManifest: () ->
    if @editor?
      @renderScript()

  renderScript: () ->
    if not atom.config.get("maker-ide-atom.triggerOnSave") then @editor.save()
    scriptPath = @getPath()

    # reset scene
    @compositor.clearScene()
    @updatePane()

    if OmnibloxPart.isOmnibloxFile(scriptPath)
      console.log('render omniblox file...')
      @compositor.process(@editor)
    else if OmnibloxPart.isJscadFile(scriptPath)
      console.log('render jscad file...')
      OmnibloxPart.loadFileIntoScene(scriptPath, @compositor.view)

    return


  getTitle: ->
    if @editor?
      "#{@editor.getTitle()} Preview"
    else
      "Omniblox Preview"

  getURI: ->
    "maker-ide-atom://editor/#{@editorId}"

  getPath: ->
    if @editor?
      @editor.getPath()

  initThreeJs: () ->
    # set up webGL view
    canvasContainer = $('#' + @divID)
    canvasContainerID = "#{@divID}-#{@sceneId}"
    @omnibloxView = new (OmnibloxView)(canvasContainerID, canvasContainer, false, true, true, @debug)
    canvasContainer.attr id: canvasContainerID

    paneDiv = $('#' + @paneDivID)
    newPaneDivID = "#{@paneDivID}-#{@sceneId}"
    paneDiv.attr id: newPaneDivID

    # set up refresh events
    @omnibloxView.controls.addEventListener 'change', () =>
      pane = atom.workspace.getActivePane()
      activeItem = pane.getActiveItem()
      return if activeItem.undefined?

      @omnibloxView.render()
      return

    pane = atom.workspace.getActivePane()
    pane.onDidChangeFlexScale () =>
      @updatePane()
      return

    $(window).resize () =>
      @updatePane()
      return

    window.addEventListener 'resize', @onWindowResize(), false

    # TODO: kinda janky
    root = path.parse(path.parse(@editor.getURI()).dir).dir
    @compositor = new OmnibloxCompositor(@editor.getText(), @omnibloxView, root)

    return

  updatePane: () ->
    div = $("##{@paneDivID}-#{@sceneId}")[0]
    if div?
      @omnibloxView.setSize(div.clientWidth, div.clientHeight)
      @omnibloxView.render();
    return

  onWindowResize: () ->
    @omnibloxView.setSize(window.innerWidth, window.innerHeight)
    @omnibloxView.render();
    return
