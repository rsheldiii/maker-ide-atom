path                  = require 'path'
{CompositeDisposable, Disposable} = require 'atom'
{$, $$$, ScrollView}  = require 'atom-space-pen-views'
_                     = require 'underscore-plus'
{OmnibloxView, OmnibloxPart} = require '@omniblox/omniblox-common'

# TODO: refactor to use the same class arrangement as single-file

module.exports =
class EditorPreviewView extends ScrollView
  atom.deserializers.add(this)

  editorSub           : null
  onDidChangeTitle    : -> new Disposable()
  onDidChangeModified : -> new Disposable()

  @deserialize: (state) ->
    new EditorPreviewView(state)

  # @content: ->
  #   @div class: 'omniblox native-key-bindings', tabindex: -1, =>
  #     @div class: 'omniblox-container', =>
  #       @div id: 'omniblox-container-cell'

  @content: ->
    @div class: 'maker-ide-view', tabindex: -1, =>
      @div class: 'maker-ide-container', =>
        @div id: 'maker-ide-container-cell'

  attached: () ->
    @initThreeJs()
    @animate()

  constructor: ({@sceneId, @editorId, filePath}) ->
    super

    @divID = 'maker-ide-container-cell'
    if @editorId?
      @resolveEditor(@editorId)
    else
      if atom.workspace?
        @subscribeToFilePath(filePath)
      else
        atom.packages.onDidActivatePackage =>
          @subscribeToFilePath(filePath)

    return

  serialize: ->
    deserializer : 'EditorPreviewView'
    filePath     : @getPath()
    editorId     : @editorId
    sceneId      : @sceneId

  destroy: ->
    # @unsubscribe()
    @editorSub.dispose()

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

    @editorSub = new CompositeDisposable

    if @editor?
      if not atom.config.get("maker-ide-atom.triggerOnSave")
        @editorSub.add @editor.onDidChange _.debounce(changeHandler, 700)
      else
        @editorSub.add @editor.onDidSave changeHandler
      @editorSub.add @editor.onDidChangePath => @trigger 'title-changed'

  renderManifest: () ->
    if @editor?
      @renderAssembly()

  renderAssembly: () ->
    if not atom.config.get("maker-ide-atom.triggerOnSave") then @editor.save()
    console.log('foo')
    # reset scene
    # @omnibloxView.clearScene()
    # @updatePane()
    #
    # @compositor.process(@editor.getText());

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

  animate: () ->
    requestAnimationFrame => @animate
    @render()
    @omnibloxView.controls.update();

  render: (event) ->
    @omnibloxView.render()

  initThreeJs: () ->
    # set up webGL view
    container = $('#' + @divID)
    containerId = "#{@divID}-#{@sceneId}"
    @omnibloxView = new (OmnibloxView)(containerId, container)
    container.attr id: containerId

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
    root = path.parse(path.parse(@editor.getPath()).dir).dir
    # @compositor = new OmnibloxCompositor(@editor.getText(), @omnibloxView, "local", root)

    return

  updatePane: () ->
    div = $("##{@divID}-#{@sceneId}")[0]
    @omnibloxView.setSize(div.clientWidth, div.clientHeight)
    @omnibloxView.render();
    return

  onWindowResize: () ->
    @omnibloxView.setSize(window.innerWidth, window.innerHeight)
    @omnibloxView.render();
    return
