_ = require 'underscore-plus'
path = require 'path'
{$, ScrollView} = require 'atom-space-pen-views'
{Emitter, CompositeDisposable} = require 'atom'
{OmnibloxView, OmnibloxPart} = require '@omniblox/omniblox-common'

# View that renders the asset.
module.exports =
class SingleFileView extends ScrollView

  # @content: ->
  #   @div class: 'maker-ide-single-file-view', tabindex: -1, =>
  #     @div class: 'maker-ide-container', =>
  #       @div id: 'maker-ide-container-cell'

  @content: ->
    @div id: 'maker-ide-container-pane', class: 'maker-ide-view', tabindex: -1, =>
      @div class: 'maker-ide-container', =>
        @div id: 'maker-ide-container-cell'

  initialize: (@singleFile) ->

    super

    @divID = 'maker-ide-container-cell'
    @paneDivID = 'maker-ide-container-pane'

    @emitter = new Emitter
    @debug = true

  attached: ->
    @disposables = new CompositeDisposable
    @initThreeJs()

  onDidLoad: (callback) ->
    @emitter.on 'did-load', callback

  detached: ->
    @disposables.dispose()

  # Retrieves this view's pane.
  #
  # Returns a {Pane}.
  getPane: ->
    @parents('.pane')[0]

  # TODO: Fix resizing
  initThreeJs: () ->
    # set up webGL view
    debugger
    canvasContainer = $('#' + @divID)
    canvasContainerID = "#{@divID}-#{@singleFile.sceneID}"
    @omnibloxView = new (OmnibloxView)(canvasContainerID, canvasContainer, true, false, @debug)
    canvasContainer.attr("id", canvasContainerID)

    paneDiv = $('#' + @paneDivID)
    newPaneDivID = "#{@paneDivID}-#{@singleFile.sceneID}"
    paneDiv.attr("id", newPaneDivID)

    # set up refresh events
    @omnibloxView.controls.addEventListener 'change', () =>
      pane = atom.workspace.getActivePane()
      activeItem = pane.getActiveItem()
      return if activeItem.undefined?

      @omnibloxView.render()
      return

    OmnibloxPart.loadFileIntoScene(@singleFile.getURI(), @omnibloxView)

    # sort out div size
    @onWindowResize()
    $(window).resize(() => @onWindowResize())

    window.scene = @renderer

    # insert factory button
    buttonID = "#{canvasContainerID}-factory-button"
    $("<div id=\"#{buttonID}\" class=\"factory-button\"></div>").insertAfter(canvasContainer)
    button = $("##{buttonID}")
    button[0].addEventListener 'click', () ->
      atom.commands.dispatch(atom.views.getView(atom.workspace), "maker-ide-atom:fabricate-single-file")

    return

  onWindowResize: () ->
    div = $("##{@paneDivID}-#{@singleFile.sceneID}")[0]
    if div?
      @omnibloxView.setSize(div.clientWidth, div.clientHeight)
      @omnibloxView.render();
    return
