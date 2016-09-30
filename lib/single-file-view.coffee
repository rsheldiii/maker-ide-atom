_ = require 'underscore-plus'
path = require 'path'
{$, ScrollView} = require 'atom-space-pen-views'
{Emitter, CompositeDisposable} = require 'atom'
{OmnibloxView, OmnibloxPart} = require '@omniblox/omniblox-common'

# View that renders the asset.
module.exports =
class SingleFileView extends ScrollView

  @content: ->
    @div class: 'maker-ide-single-file-view', tabindex: -1, =>
      @div class: 'maker-ide-container', =>
        @div id: 'maker-ide-container-cell'

  initialize: (@singleFile) ->

    super

    @divID = 'maker-ide-container-cell'
    @emitter = new Emitter
    @debug = true

  attached: ->
    @disposables = new CompositeDisposable
    @initThreeJs()
    @animate()

  onDidLoad: (callback) ->
    @emitter.on 'did-load', callback

  detached: ->
    @disposables.dispose()

  # Retrieves this view's pane.
  #
  # Returns a {Pane}.
  getPane: ->
    @parents('.pane')[0]


  animate: () ->
    return unless @isVisible()
    requestAnimationFrame => @animate
    @render()
    @omnibloxView.controls.update();

  render: (event) ->
    @omnibloxView.render()

  # TODO: Fix resizing
  initThreeJs: () ->
    # set up webGL view
    container = $('#' + @divID)
    @containerId = "#{@divID}-#{@singleFile.sceneID}"
    @omnibloxView = new (OmnibloxView)(@containerId, container, true, false, @debug)
    container.attr id: @containerId

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
    buttonID = "#{@containerId}-factory-button"
    $("<div id=\"#{buttonID}\" class=\"factory-button\"></div>").insertAfter(container)
    button = $("##{buttonID}")
    button[0].addEventListener 'click', () ->
      atom.commands.dispatch(atom.views.getView(atom.workspace), "maker-ide-atom:fabricate")

    return

  # using window means that model is offset from center by the width of the
  # tree view... but it lends itself to more consistent event behaviour ($().height()|.width() only trigger on window resize)
  onWindowResize: () ->
    @omnibloxView.setSize(window.innerWidth, window.innerHeight)
    @omnibloxView.render();
    return