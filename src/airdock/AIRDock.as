package airdock
{
	import airdock.config.ContainerConfig;
	import airdock.config.DockConfig;
	import airdock.config.PanelConfig;
	import airdock.enums.CrossDockingPolicy;
	import airdock.enums.PanelContainerSide;
	import airdock.enums.PanelContainerState;
	import airdock.events.DockEvent;
	import airdock.events.PanelContainerEvent;
	import airdock.events.PanelContainerStateEvent;
	import airdock.events.PanelPropertyChangeEvent;
	import airdock.interfaces.docking.IContainer;
	import airdock.interfaces.docking.ICustomizableDocker;
	import airdock.interfaces.docking.IDockFormat;
	import airdock.interfaces.docking.IDockTarget;
	import airdock.interfaces.docking.IPanel;
	import airdock.interfaces.docking.ITreeResolver;
	import airdock.interfaces.factories.IContainerFactory;
	import airdock.interfaces.factories.IPanelFactory;
	import airdock.interfaces.factories.IPanelListFactory;
	import airdock.interfaces.ui.IDockHelper;
	import airdock.interfaces.ui.IPanelList;
	import airdock.interfaces.ui.IResizer;
	import airdock.util.IPair;
	import airdock.util.LazyPair;
	import airdock.util.StaticPair;
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardTransferMode;
	import flash.desktop.NativeDragActions;
	import flash.desktop.NativeDragManager;
	import flash.desktop.NativeDragOptions;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.EventPhase;
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;
	import flash.events.NativeDragEvent;
	import flash.events.NativeWindowBoundsEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	/**
	 * Dispatched whenever a panel is either added to a container, or when it is removed from its container.
	 * @eventType	airdock.events.PanelContainerStateEvent.VISIBILITY_TOGGLED
	 */
	[Event(name = "pcPanelVisibilityToggled", type = "airdock.events.PanelContainerStateEvent")]
	
	/**
	 * Dispatched whenever a panel is moved to its parked container (docked), or when it is moved into another container which is not its own parked container (integrated).
	 */
	[Event(name = "pcPanelStateToggled", type = "airdock.events.PanelContainerStateEvent")]
	
	/**
	 * Implementation of ICustomizableDocker (and by extension, IBasicDocker) which manages the main docking panels mechanism.
	 * 
	 * @author	Gimmick
	 * @see	airdock.interfaces.docking.IBasicDocker
	 * @see	airdock.interfaces.docking.ICustomizableDocker
	 */
	public final class AIRDock implements ICustomizableDocker
	{
		private const cl_allowedDragActions:NativeDragOptions = new NativeDragOptions();
		private var cl_defaultWindowOptions:NativeWindowInitOptions;
		private var dsp_mainContainer:DisplayObjectContainer;
		private var cl_dispatcher:IEventDispatcher;
		private var cl_dragStruct:DragInformation;
		private var dct_containers:Dictionary;
		private var i_crossDockingPolicy:int;
		private var dct_windows:Dictionary;
		private var num_thumbHeight:Number;
		private var num_thumbWidth:Number;
		private var cl_resizer:IResizer;
		private var cl_dockHelper:IDockHelper
		private var cl_dockFormat:IDockFormat;
		private var plc_dropTarget:IContainer;
		private var dct_panelStateInfo:Dictionary;
		private var dct_foreignCounter:Dictionary;
		private var cl_treeResolver:ITreeResolver;
		private var cl_panelFactory:IPanelFactory;
		private var cl_panelListFactory:IPanelListFactory;
		private var cl_containerFactory:IContainerFactory;
		private var cl_defaultContainerOptions:ContainerConfig;
		public function AIRDock() {
			init()
		}
		
		private function init():void 
		{
			createDictionaries()
			dragImageWidth = dragImageHeight = 1;
			cl_dispatcher = new EventDispatcher(this)
			crossDockingPolicy = CrossDockingPolicy.UNRESTRICTED;
			cl_allowedDragActions.allowLink = cl_allowedDragActions.allowCopy = false;
		}
		
		private function createDictionaries():void 
		{
			dct_windows = new Dictionary()
			dct_containers = new Dictionary()
			dct_panelStateInfo = new Dictionary(true)
			dct_foreignCounter = new Dictionary(true)
		}
		
		private function resizeNestedContainerOnEvent(evt:PanelContainerEvent):void 
		{
			var maxSize:Number, value:Number;
			var orientation:int = cl_resizer.sideCode
			var currContainer:IContainer = evt.relatedContainer
			var position:Point = currContainer.globalToLocal(cl_resizer.localToGlobal(new Point()))
			if (PanelContainerSide.isComplementary(orientation, PanelContainerSide.LEFT))
			{
				value = position.x
				maxSize = currContainer.width;
			}
			else if (PanelContainerSide.isComplementary(orientation, PanelContainerSide.TOP))
			{
				maxSize = currContainer.height;
				value = position.y;
			}
			else { 
				return;
			}
			
			if(currContainer.maxSideSize <= 1.0) {
				maxSize *= currContainer.maxSideSize
			}
			else if(maxSize > currContainer.maxSideSize) {
				maxSize = currContainer.maxSideSize
			}
			
			if(value < 0.0) {
				value = 0.0;
			}
			else if(value > maxSize) {
				value = maxSize;
			}
			
			currContainer.sideSize = value / maxSize
		}
		
		private function finishDragDockEvent(evt:DockEvent):void 
		{
			if(evt.isDefaultPrevented()) {
				return;
			}
			var clipBoard:Clipboard = evt.clipboard
			var dragDropTarget:DisplayObject = evt.dragTarget
			var panel:IPanel = clipBoard.getData(cl_dockFormat.panelFormat, ClipboardTransferMode.ORIGINAL_ONLY) as IPanel
			var container:IContainer = clipBoard.getData(cl_dockFormat.containerFormat, ClipboardTransferMode.ORIGINAL_ONLY) as IContainer
			var dispContainer:DisplayObjectContainer = dragDropTarget as DisplayObjectContainer
			var relatedContainer:IContainer = plc_dropTarget
			var dockTarget:IDockTarget;
			
			if (isMatchingDockPolicy(crossDockingPolicy, CrossDockingPolicy.REJECT_INCOMING) && isForeignContainer(container))
			{
				evt.preventDefault();	//ignore if it violates policy - this runs before the DRAG_DROP is cancelled
				return;					//so prevent normal behavior by exiting early
			}
			else while (dispContainer && !(dispContainer is IDockTarget)) {
				dispContainer = dispContainer.parent;
			}
			dockTarget = dispContainer as IDockTarget
			
			if (relatedContainer && dockTarget)
			{
				var side:int = dockTarget.getSideFrom(dragDropTarget as DisplayObject)
				if (panel) {
					addPanelToSideSequence(panel, relatedContainer, PanelContainerSide.toString(side))
				}
				else if (container) {
					movePanelsIntoContainer(extractOrderedPanelSideCodes(extractDockablePanels(container.getPanels(false)), container), relatedContainer.fetchSide(side))
				}
			}
			cl_dragStruct = null;
			plc_dropTarget = null;
		}
		
		private function dockContainerIfInvalidDropTarget(evt:NativeDragEvent):void 
		{
			var clipBoard:Clipboard = evt.clipboard
			if(!(clipBoard.hasFormat(cl_dockFormat.panelFormat) || clipBoard.hasFormat(cl_dockFormat.containerFormat))) {
				return;
			}
			
			var window:NativeWindow;
			var panel:IPanel = clipBoard.getData(cl_dockFormat.panelFormat, ClipboardTransferMode.ORIGINAL_ONLY) as IPanel
			var container:IContainer = clipBoard.getData(cl_dockFormat.containerFormat, ClipboardTransferMode.ORIGINAL_ONLY) as IContainer
			if (evt.dropAction != NativeDragActions.NONE || (isForeignContainer(container) && isMatchingDockPolicy(crossDockingPolicy, CrossDockingPolicy.REJECT_INCOMING))) {
				return;	//return if drop action is valid or if this is the foreign Docker, i.e. let the originating Docker handle it
			}
			else if (cl_dragStruct) {
				cl_dragStruct.updateStageCoordinates(evt.stageX, evt.stageY)
			}
			
			if (panel)
			{
				window = getWindowFromPanel(panel, true)
				dockPanel(panel)
				showPanel(panel)
			}
			else if (container)
			{
				//if container is a parked container then return its window
				//otherwise, move all the panels into the window of the first panel in the container and return that
				window = getContainerWindow(container) || getContainerWindow(dockPanelsInContainer(extractDockablePanels(container.getPanels(false)), container))
				if (window) {
					window.activate()
				}
			}
			
			if (window && cl_dragStruct) {
				moveWindowTo(window, cl_dragStruct.localX, cl_dragStruct.localY, cl_dragStruct.convertToScreen())
			}
			cl_dragStruct = null;
		}
		
		/**
		 * Finds and returns all dockable IPanel instances from the given vector of IPanel instances.
		 * @param	panels	The list of IPanel instances to get the dockable IPanel instances from.
		 * @return	A new vector of dockable IPanel instances from the supplied list.
		 */
		private function extractDockablePanels(panels:Vector.<IPanel>):Vector.<IPanel>
		{
			return panels && panels.filter(function(item:IPanel, index:int, array:Vector.<IPanel>):Boolean {
				return item && item.dockable;
			});
		}
		
		private function moveWindowTo(window:NativeWindow, localX:Number, localY:Number, windowPoint:Point):void 
		{
			if(!(window && windowPoint) || isNaN(windowPoint.x) || isNaN(windowPoint.y) || isNaN(localX) || isNaN(localY)) {
				return;
			}
			var chromeOffset:Point = window.globalToScreen(new Point(localX * window.stage.stageWidth, localY * window.stage.stageHeight))
			window.x += windowPoint.x - chromeOffset.x;
			window.y += windowPoint.y - chromeOffset.y;
		}
		
		private function preventDockIfInvalid(evt:NativeDragEvent):void
		{
			var clipBoard:Clipboard = evt.clipboard
			if(!(clipBoard.hasFormat(cl_dockFormat.panelFormat) || clipBoard.hasFormat(cl_dockFormat.containerFormat))) {
				return;
			}
			var panel:IPanel = clipBoard.getData(cl_dockFormat.panelFormat, ClipboardTransferMode.ORIGINAL_ONLY) as IPanel
			var container:IContainer = clipBoard.getData(cl_dockFormat.containerFormat, ClipboardTransferMode.ORIGINAL_ONLY) as IContainer
			
			if (panel)
			{
				if(!panel.dockable) {
					evt.preventDefault();	//prevent docking if panel is not dockable
				}
			}
			else if (container)
			{
				if(!(extractDockablePanels(container.getPanels(false)).length)) {
					evt.preventDefault();	//prevent docking if no panels in container are dockable
				}
			}
		}
		
		private function removeContainerOnEvent(evt:NativeDragEvent):void
		{
			var clipBoard:Clipboard = evt.clipboard
			if(!(clipBoard.hasFormat(cl_dockFormat.panelFormat) || clipBoard.hasFormat(cl_dockFormat.containerFormat))) {
				return;
			}
			var originalWindow:NativeWindow, newWindow:NativeWindow
			var panel:IPanel = clipBoard.getData(cl_dockFormat.panelFormat, ClipboardTransferMode.ORIGINAL_ONLY) as IPanel
			var rootContainer:IContainer, container:IContainer = clipBoard.getData(cl_dockFormat.containerFormat, ClipboardTransferMode.ORIGINAL_ONLY) as IContainer
			if(isForeignContainer(container) && isMatchingDockPolicy(crossDockingPolicy, CrossDockingPolicy.REJECT_INCOMING)) {
				return;	//do nothing, since the panel doesn't belong to this Docker
			}
			
			if (cl_dragStruct) {
				cl_dragStruct.updateStageCoordinates(evt.stageX, evt.stageY)
			}
			
			if (panel)
			{
				var removeSuccess:Boolean = removePanel(panel);
				if (removeSuccess && isMatchingDockPolicy(crossDockingPolicy, CrossDockingPolicy.PREVENT_OUTGOING)) {
					panel.addEventListener(Event.ADDED, dockPanelOnCrossViolation)
				}
			}
			else if (container) {
				removeContainer(container)
			}
		}
		
		/**
		 * Performs a lazy initialization of the container from the given window, if it does not exist and should be created.
		 * @param	window	The window to lookup.
		 * @param	createIfNotExist	Creates a new container for the given window if this parameter is true and it does not exist; if false, it performs a simple lookup which may fail (i.e. return undefined)
		 * @return	An IContainer instance which is the parked container contained by the corresponding window.
		 * 			This is also a panel's parked container. To find out which panel's parked container this belongs to, use the getWindowPanel() method.
		 * @see	#getWindowPanel()
		 */
		private function getContainerFromWindow(window:NativeWindow, createIfNotExist:Boolean = true):IContainer
		{
			if (createIfNotExist && window && !(window in dct_containers))
			{
				var container:IContainer 
				var stage:Stage = window.stage
				var panel:IPanel = getWindowPanel(window)
				var defWidth:Number = panel.getDefaultWidth(), defHeight:Number = panel.getDefaultHeight()
				cl_defaultContainerOptions.width = defWidth;
				cl_defaultContainerOptions.height = defHeight;
				container = dct_containers[window] = createContainer(cl_defaultContainerOptions)
				container.removeEventListener(PanelContainerEvent.PANEL_ADDED, setRoot)
				container.containerState = PanelContainerState.DOCKED
				stage.stageHeight = defHeight
				stage.stageWidth = defWidth
				stage.addChild(container as DisplayObject)
			}
			return dct_containers[window]
		}
		
		/**
		 * Performs a lazy initialization of the window of the given panel if it should be created, or a simple lookup otherwise.
		 * @param	panel	The panel whose window should be retrieved.
		 * @param	createIfNotExist	Creates the window if this parameter is true, and the window does not yet exist.
		 * 								If this parameter is false, it performs a simple lookup which may fail (i.e. return undefined)
		 * @return	A NativeWindow which contains the panel's parked container, and by extension, the panel (when it is docked to its parked container.)
		 */
		private function getWindowFromPanel(panel:IPanel, createIfNotExist:Boolean = true):NativeWindow
		{
			if(!panel) {
				return null;
			}
			else if(!dct_windows[panel] && createIfNotExist) {
				dct_windows[panel] = createWindow(panel)
			}
			return dct_windows[panel] as NativeWindow
		}
		
		/**
		 * @inheritDoc
		 */
		public function getPanelWindow(panel:IPanel):NativeWindow {
			return getWindowFromPanel(panel, !isForeignPanel(panel))
		}
		
		/**
		 * @inheritDoc
		 */
		public function getContainerWindow(container:IContainer):NativeWindow
		{
			var tempContainer:IContainer = cl_treeResolver.findRootContainer(container)
			for (var window:Object in dct_containers)
			{
				if (dct_containers[window] == tempContainer) {
					return window as NativeWindow;
				}
			}
			return null;
		}
		
		/**
		 * @inheritDoc
		 * Note: This does not initialize the container if it does not already exist.
		 */
		public function getWindowContainer(window:NativeWindow):IContainer {
			return getContainerFromWindow(window, false)
		}
		
		/**
		 * @inheritDoc
		 */
		public function getWindowPanel(window:NativeWindow):IPanel
		{
			for (var panel:Object in dct_windows)
			{
				if (dct_windows[panel] == window) {
					return panel as IPanel
				}
			}
			return null;
		}
		
		/**
		 * Performs a lazy initialization of the PanelStateInformation for the given panel.
		 * @param	panel	The panel to get the state information of.
		 * @return	The panel's state information. Creates it if it does not exist.
		 */
		private function getPanelStateInfo(panel:IPanel):PanelStateInformation {
			return dct_panelStateInfo[panel] ||= new PanelStateInformation()
		}
		
		private function addContainerListeners(container:IContainer):void
		{
			container.addEventListener(PanelContainerEvent.PANEL_ADDED, setRoot, false, 0, true)
			container.addEventListener(PanelContainerEvent.DRAG_REQUESTED, startPanelContainerDragOnEvent, false, 0, true)
			container.addEventListener(PanelContainerEvent.STATE_TOGGLE_REQUESTED, togglePanelStateOnEvent, false, 0, true)
			container.addEventListener(PanelContainerEvent.CONTAINER_REMOVE_REQUESTED, removeContainerIfEmpty, false, 0, true)
			container.addEventListener(PanelContainerEvent.CONTAINER_CREATED, registerContainerOnCreate, false, 0, true)
			container.addEventListener(PanelContainerEvent.CONTAINER_CREATING, createContainerOnEvent, false, 0, true)
			container.addEventListener(PanelContainerEvent.SETUP_REQUESTED, customizeContainerOnSetup, false, 0, true)
			container.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, preventDockOnCrossViolation, false, 0, true)
			container.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, showDockHelperOnEvent, false, 0, true)
			container.addEventListener(NativeDragEvent.NATIVE_DRAG_EXIT, hideDockHelperOnEvent, false, 0, true)
			container.addEventListener(DockEvent.DRAG_COMPLETING, finishDragDockEvent, false, 0, true)
			container.addEventListener(Event.REMOVED, addContainerListenersOnUnlink, false, 0, true)
			container.addEventListener(Event.ADDED, removeContainerListenersOnLink, false, 0, true)
			container.addEventListener(MouseEvent.MOUSE_MOVE, showResizerOnEvent, false, 0, true)
		}
		
		/**
		 * Used to pass an IContainer instance to the container which requests an IContainer instance.
		 * This is triggered after a PanelContainerEvent.CONTAINER_CREATING event is dispatched by the container, which signals a new container request.
		 * A response is sent in the form of a PanelContainerEvent.CONTAINER_CREATED event on the requesting container.
		 * @see	airdock.events.PanelContainerEvent
		 */
		private function createContainerOnEvent(evt:PanelContainerEvent):void {
			evt.relatedContainer.dispatchEvent(new PanelContainerEvent(PanelContainerEvent.CONTAINER_CREATED, evt.relatedPanel, cl_containerFactory.createContainer(defaultContainerOptions), false, false))
		}
		
		/**
		 * Used to prevent docking from a foreign panel or container into a local container (with respect to the current Docker instance.)
		 * This is triggered whenever the following crossDockingPolicy flags are used:
		 * * CrossDockingPolicy.REJECT_INCOMING
		 * * CrossDockingPolicy.INTERNAL_ONLY
		 * 
		 * @see	airdock.enums.CrossDockingPolicy
		 */
		private function preventDockOnCrossViolation(evt:NativeDragEvent):void 
		{
			if (isMatchingDockPolicy(crossDockingPolicy, CrossDockingPolicy.REJECT_INCOMING) && isForeignContainer(evt.clipboard.getData(cl_dockFormat.containerFormat, ClipboardTransferMode.ORIGINAL_ONLY) as IContainer))
			{
				evt.preventDefault();
				evt.stopImmediatePropagation();
				evt.dropAction = NativeDragActions.NONE;
			}
		}
		
		/**
		 * Adds the container to the list of containers created by this Docker instance, and marks it as local, i.e. non-foreign.
		 */
		private function registerContainerOnCreate(evt:PanelContainerEvent):void 
		{
			var rootContainer:IContainer = cl_treeResolver.findRootContainer(evt.currentTarget as IContainer)
			var container:IContainer = evt.relatedContainer
			if (!isForeignContainer(rootContainer)) {
				dct_foreignCounter[container] = hasContainerListeners(container)
			}
		}
		
		/**
		 * Removes the listeners for a given container.
		 * Does not check whether it is a foreign container or not, prior to removal, since there is no effect if it is.
		 * Calling this function multiple times has no additional effect.
		 * @param	container	The container to remove listeners from.
		 */
		private function removeContainerListeners(container:IContainer):void
		{
			container.removeEventListener(PanelContainerEvent.PANEL_ADDED, setRoot)
			container.removeEventListener(PanelContainerEvent.CONTAINER_REMOVE_REQUESTED, removeContainerIfEmpty)
			container.removeEventListener(PanelContainerEvent.DRAG_REQUESTED, startPanelContainerDragOnEvent)
			container.removeEventListener(PanelContainerEvent.STATE_TOGGLE_REQUESTED, togglePanelStateOnEvent)
			container.removeEventListener(PanelContainerEvent.CONTAINER_CREATED, registerContainerOnCreate)
			container.removeEventListener(PanelContainerEvent.CONTAINER_CREATING, createContainerOnEvent)
			container.removeEventListener(PanelContainerEvent.SETUP_REQUESTED, customizeContainerOnSetup)
			container.removeEventListener(NativeDragEvent.NATIVE_DRAG_DROP, preventDockOnCrossViolation)
			container.removeEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, showDockHelperOnEvent)
			container.removeEventListener(NativeDragEvent.NATIVE_DRAG_EXIT, hideDockHelperOnEvent)
			container.removeEventListener(DockEvent.DRAG_COMPLETING, finishDragDockEvent)
			container.removeEventListener(Event.REMOVED, addContainerListenersOnUnlink)
			container.removeEventListener(Event.ADDED, removeContainerListenersOnLink)
			container.removeEventListener(MouseEvent.MOUSE_MOVE, showResizerOnEvent)
		}
		
		private function removeContainerIfEmpty(evt:PanelContainerEvent):void
		{
			if(evt.isDefaultPrevented()) {
				return;
			}
			var container:IContainer = evt.relatedContainer as IContainer
			var panels:Vector.<IPanel> = container.getPanels(true);
			if (panels.length > 1 || (panels.length == 1 && panels[0] != evt.relatedPanel)) {	//TODO check whether this condition works or not
				return;	//has children, do not remove - either more than the panel being removed, or a different panel from that which is being removed
			}
			removeContainer(container);
		}
		
		/**
		 * Removes listeners when a free container instance becomes contained by another container.
		 * This is done because the parent containers (or other containers up the chain) have the same listeners.
		 * That is, only a rooted (i.e. free-floating) container should possess these listeners.
		 * 
		 * Listeners are not removed if the container is rooted (that is, if findRootContainer(container) == container)
		 */
		private function removeContainerListenersOnLink(evt:Event):void 
		{
			var target:IContainer = evt.target as IContainer
			var root:IContainer = cl_treeResolver.findRootContainer(target)
			if (target && !isForeignContainer(target) && root != target)
			{
				removeContainerListeners(target)
				dct_foreignCounter[target] = hasContainerListeners(target);
			}
		}
		
		/**
		 * Adds container listeners whenever a container is about to be removed.
		 * This is done because rooted (i.e. free-floating) containers need these listeners to function correctly.
		 * 
		 * Listeners are not added if the container already has them.
		 */
		private function addContainerListenersOnUnlink(evt:Event):void 
		{
			var target:IContainer = evt.target as IContainer
			if (target && target != evt.currentTarget && !isForeignContainer(target) && !dct_foreignCounter[target])
			{
				addContainerListeners(target);
				dct_foreignCounter[target] = hasContainerListeners(target);
			}
		}
		
		/**
		 * Checks if the supplied container has the container listeners added to it by the current Docker instance..
		 * @param	container
		 * @return
		 */
		private function hasContainerListeners(container:IContainer):Boolean
		{
			return container && container.hasEventListener(PanelContainerEvent.PANEL_ADDED) && 
								container.hasEventListener(PanelContainerEvent.DRAG_REQUESTED) &&
								container.hasEventListener(PanelContainerEvent.CONTAINER_CREATED) &&
								container.hasEventListener(PanelContainerEvent.CONTAINER_CREATING) &&
								container.hasEventListener(PanelContainerEvent.STATE_TOGGLE_REQUESTED) &&
								container.hasEventListener(PanelContainerEvent.CONTAINER_REMOVE_REQUESTED) &&
								container.hasEventListener(PanelContainerEvent.SETUP_REQUESTED) &&
								container.hasEventListener(NativeDragEvent.NATIVE_DRAG_ENTER) &&
								container.hasEventListener(NativeDragEvent.NATIVE_DRAG_EXIT) &&
								container.hasEventListener(NativeDragEvent.NATIVE_DRAG_DROP) &&
								container.hasEventListener(DockEvent.DRAG_COMPLETING) &&
								container.hasEventListener(MouseEvent.MOUSE_MOVE) &&
								container.hasEventListener(Event.REMOVED) &&
								container.hasEventListener(Event.ADDED)
		}
		
		private function showResizerOnEvent(evt:MouseEvent):void 
		{
			var target:DisplayObject = evt.target as DisplayObject
			if(target is IResizer || !cl_resizer || cl_resizer.isDragging) {
				return;
			}
			var targetContainer:IContainer = (target as IContainer) || cl_treeResolver.findParentContainer(target)
			var container:IContainer = cl_treeResolver.findParentContainer(targetContainer as DisplayObject)
			if (container)
			{
				var side:int;
				var point:Point;
				var tolerance:Number = cl_resizer.tolerance
				var localXPercent:Number = targetContainer.mouseX / targetContainer.width
				var localYPercent:Number = targetContainer.mouseY / targetContainer.height
				
				if (localXPercent <= tolerance) {
					side = PanelContainerSide.LEFT
				}
				else if(localXPercent >= (1 - tolerance)) {
					side = PanelContainerSide.RIGHT
				}
				else if (localYPercent <= tolerance) {
					side = PanelContainerSide.TOP
				}
				else if(localYPercent >= (1 - tolerance)) {
					side = PanelContainerSide.BOTTOM
				}
				else 
				{
					if(cl_resizer.parent) {
						cl_resizer.parent.removeChild(cl_resizer as DisplayObject)
					}
					return;
				}
				
				/* HOW THE RESIZER IS RESOLVED WITH RESPECT TO CONTAINERS
				 * 
				 * Consider the following container, with 3 subcontainers below it.
				 * The tree structure is shown on the right.
				 * 
				 *    ┌───────┬───────┐   ┐        A (~*)    sideCode key:
				 *    │       │   T   │   │       / \          +: TOP
				 *    │   L   ├───────┤   ┼ B    L   Z (~+)    *: LEFT
				 *    │       │   B   │   │         / \       ~+: BOTTOM
				 *    └───────┴───────┘   ┘        T   B      ~*: RIGHT
				 * 
				 *    └───────┼───────┘
				 *            R
				 * 
				 * 4 cases exist, which are listed below:
				 * * targetContainer = T, resizer direction: bottom (below T)
				 * *	-->	side code of container = B. target container does not match, 
				 * 			i.e. container.getSide(container.sideCode) != targetContainer (but is complementary)
				 * 			so display the resizer only if the side is bottom, i.e. same as container side code
				 * 
				 * * targetContainer = B,  resizer direction: top (above B)
				 * *	-->	side code of container = B. target container matches, i.e. container.getSide(container.sideCode) == targetContainer
				 * 			so display the resizer only if the side is top, i.e. complementary (but not equal) of container side code
				 * 
				 * * targetContainer = T (or) targetContainer = B, resizer direction: left
				 * *	-->	side code of container = B. not complementary or equal, so skip up and set container = parent container, and targetContainer = container
				 * 			now parent container side code = R. container matches now, i.e. container.getSide(container.sideCode) == targetContainer
				 * 			so display the resizer only if the side is left, i.e. complementary (but not equal) of container side code
				 * 
				 * * targetContainer = L, resizer direction: right
				 * *	-->	side code of container = R. target container does not match i.e. container.getSide(container.sideCode) != targetContainer
				 * 			(but is complementary)
				 *			so display the resizer only if side is right, i.e. same as container side code.
				 * 
				 * in all the above cases, there is a similarity:
				 * 
				 * [0. set side = the side closest to the user's mouse]
				 * 1. get targetContainer [= L, B, T, etc.] and container [= parent_container(targetContainer)]
				 * 2. if container.getSide(container.sideCode) == targetContainer:
				 * 		if side is only complementary (not equal) to container side code:
				 * 			display resizer
				 * 3. else if container.sideCode is complementary or equal to targetContainer.sideCode:
				 * 		if the side is equal to container.sideCode:
				 *			display resizer
				 * 4. else:
				 * 		set targetContainer = current container
				 * 		set container = parent_container(container), i.e. go up one level
				 * 		if container is not null:
				 *			go to step 2
				 * 		else break loop
				 * 
				 * see code below for reference.
				 */
				
				var displayResizer:Boolean;
				while (container)
				{
					if (PanelContainerSide.isComplementary(side, container.sideCode))
					{
						var targetContainerEqual:Boolean = (container.getSide(container.sideCode) == targetContainer);
						var sidesMatch:Boolean = (side == container.sideCode);
						displayResizer = targetContainerEqual != sidesMatch;	//i.e. targetContainerEqual xor sidesMatch
						if(displayResizer) {
							break;	//break only if the resizer can be shown, or if the container is null
						}
					}
					targetContainer = container;
					container = cl_treeResolver.findParentContainer(container as DisplayObject);
				}
				
				if (container && displayResizer)
				{
					point = new Point(targetContainer.x, targetContainer.y)
					if (PanelContainerSide.isComplementary(side, PanelContainerSide.TOP)) {
						point.offset(cl_resizer.preferredXPercentage * targetContainer.width, Math.round(localYPercent) * targetContainer.height)
					}
					else {
						point.offset(Math.round(localXPercent) * targetContainer.width, cl_resizer.preferredYPercentage * targetContainer.height)
					}
					point = container.localToGlobal(point)
					
					var containerBounds:Rectangle = container.getBounds(null)
					containerBounds.height = container.height	//set height and width to intended
					containerBounds.width = container.width		//container size - not actual
					cl_resizer.maxSize = containerBounds
					cl_resizer.container = container
					cl_resizer.sideCode = side
					cl_resizer.x = point.x;
					cl_resizer.y = point.y;
					container.stage.addChild(cl_resizer as DisplayObject)
				}
				else if(cl_resizer.parent) {
					cl_resizer.parent.removeChild(cl_resizer as DisplayObject)
				}
			}
		}
		
		private function hideDockHelperOnEvent(evt:NativeDragEvent):void
		{
			if (cl_dockHelper)
			{
				switch(evt.type)
				{
					case NativeDragEvent.NATIVE_DRAG_COMPLETE:
						if(cl_dockHelper.parent) {
							cl_dockHelper.parent.removeChild(cl_dockHelper as DisplayObject)
						}
						break;
					case NativeDragEvent.NATIVE_DRAG_EXIT:
					default:
						var targetObj:DisplayObject = evt.target as DisplayObject;
						if (!(plc_dropTarget == targetObj || plc_dropTarget == cl_treeResolver.findParentContainer(targetObj))) {
							cl_dockHelper.hide()
						}
						break;
				}
			}
		}
		
		private function showDockHelperOnEvent(evt:NativeDragEvent):void 
		{
			if(!cl_dockHelper || !(evt.clipboard.hasFormat(cl_dockFormat.panelFormat) || evt.clipboard.hasFormat(cl_dockFormat.containerFormat))) {
				return;
			}
			else if (evt.currentTarget == cl_dockHelper) {
				cl_dockHelper.show()
			}
			else if((evt.eventPhase == EventPhase.AT_TARGET && evt.target == evt.currentTarget) || (evt.eventPhase == EventPhase.BUBBLING_PHASE && evt.target != evt.currentTarget))
			{
				var targetContainer:IContainer = (evt.target as IContainer) || cl_treeResolver.findParentContainer(evt.target as DisplayObject)
				if (targetContainer && !targetContainer.hasSides)
				{
					cl_dockHelper.y = (0.5 * (targetContainer.height - cl_dockHelper.height))
					cl_dockHelper.x = (0.5 * (targetContainer.width - cl_dockHelper.width))
					targetContainer.addChild(cl_dockHelper as DisplayObject)
					plc_dropTarget = targetContainer
					cl_dockHelper.hide()
				}
			}
		}
		
		private function customizeContainerOnSetup(evt:PanelContainerEvent):void
		{
			var container:IContainer = evt.relatedContainer;
			var rootContainer:IContainer = evt.currentTarget as IContainer
			//don't modify foreign container's containers, since that container's Docker will already have listeners for it
			if (!(evt.isDefaultPrevented() || isForeignContainer(rootContainer)))
			{
				//if it has no sides and it has panels, create a new panelList for it; otherwise, remove it
				if (!container.hasSides && container.hasPanels(false)) {
					container.panelList = cl_panelListFactory.createPanelList() as IPanelList
				}
				else {
					container.panelList = null;
				}
			}
		}
		
		private function addResizerListeners(resizer:IResizer):void {
			resizer.addEventListener(PanelContainerEvent.RESIZED, resizeNestedContainerOnEvent, false, 0, true)
		}
		private function removeResizerListeners(resizer:IResizer):void {
			resizer.removeEventListener(PanelContainerEvent.RESIZED, resizeNestedContainerOnEvent)
		}
		
		private function removePanel(panel:IPanel):Boolean
		{
			var prevContainer:IContainer = cl_treeResolver.findParentContainer(panel as DisplayObject)
			var rootContainer:IContainer = cl_treeResolver.findRootContainer(prevContainer)
			var removable:Boolean = prevContainer && rootContainer
			if (removable)
			{
				//first check if it belongs to its parked container
				//in which case, shadow container while it has other panels in its window and container
				if (getAuthoritativeContainerState(prevContainer) == PanelContainerState.DOCKED && rootContainer == getPanelContainer(panel, false))
				{
					var newContainer:IContainer = getPanelContainer(getFirstPanel(new <IPanel>[panel], rootContainer), true);
					shadowContainer(rootContainer, newContainer);
					
					if (newContainer) {
						getContainerWindow(newContainer).activate();	//newContainer is a parked container; will always have a window
					}
					getContainerWindow(rootContainer).visible = false;
				}
				prevContainer.removePanel(panel);
			}
			return removable
		}
		
		/**
		 * Removes the container from its root container.
		 * If it is a parked container, it moves all the panels not in its container into the window of the first panel it can find, which is not part of the container.
		 * @param	container	The container to remove from its root container.
		 */
		private function removeContainer(container:IContainer):Boolean
		{
			var rootContainer:IContainer = cl_treeResolver.findRootContainer(container)
			var containerWindow:NativeWindow = getContainerWindow(container)
			//if the container is a parked container and it is visible
			//or if the container is not a free container (i.e. it belongs to a parent container)
			var removable:Boolean = (rootContainer && rootContainer != container) || (containerWindow && containerWindow.visible);
			if (removable)
			{
				var allPanels:Vector.<IPanel> = container.getPanels(false);
				var dockablePanels:Vector.<IPanel> = extractDockablePanels(allPanels);
				if (isMatchingDockPolicy(crossDockingPolicy, CrossDockingPolicy.PREVENT_OUTGOING) && dockablePanels && dockablePanels.length)
				{
					//selects the first panel* and docks all the panels in the current container to the parked container's window
					//when it gets added to stage, if there's a violation in crossDocking policy
					//*note - it can be any panel from the list of panels, since they are all being docked to the same container
					var parkedContainer:IContainer;
					for (var i:uint = 0; !parkedContainer && i < dockablePanels.length; ++i)
					{
						var currPanel:IPanel = dockablePanels[i] as IPanel;
						if (currPanel && !isForeignPanel(currPanel)) {
							parkedContainer = getPanelContainer(currPanel, true)
						}
					}
					if (parkedContainer)
					{
						function dockContainerOnCrossViolation(innerEvt:Event):void
						{
							var currentFunction:Function = arguments.callee
							var currPanel:IPanel = innerEvt.currentTarget as IPanel
							var rootContainer:IContainer = cl_treeResolver.findRootContainer(cl_treeResolver.findParentContainer(currPanel as DisplayObject))
							//dock all panels in the parent container if cross-docking is disabled
							//i.e. so as to prevent them from being integrated into the other Docker's containers
							if (rootContainer && isForeignContainer(rootContainer))
							{
								addPanelToSideSequence(currPanel, parkedContainer, PanelContainerSide.STRING_FILL)
								dockPanelsInContainer(parkedContainer.getPanels(false), parkedContainer)
								if (cl_dragStruct) {
									moveWindowTo(getContainerWindow(parkedContainer), cl_dragStruct.localX, cl_dragStruct.localY, cl_dragStruct.convertToScreen())
								}
							}
							currPanel.removeEventListener(Event.ADDED, currentFunction)
							currPanel.addEventListener(Event.ADDED, dockPanelOnCrossViolation, false, 0, true)
						}
						
						dockablePanels.forEach(function setContainerCrossViolationListeners(item:IPanel, index:int, array:Vector.<IPanel>):void
						{
							item.removeEventListener(Event.ADDED, dockPanelOnCrossViolation);
							item.addEventListener(Event.ADDED, dockContainerOnCrossViolation, false, 0, true);
						});
					}
				}
				
				if (containerWindow && container == rootContainer) {
					containerWindow.visible = false;
				}
				else
				{
					//undockable panels will be removed from the root container briefly
					//and then re-added back to the same position they were before
					//based on the side sequence with respect to the root, prior to their removal
					var filtered:Vector.<IPanel> = allPanels.filter(function getUndockable(item:IPanel, index:int, array:Vector.<IPanel>):Boolean {
						return item && dockablePanels.indexOf(item) == -1;
					});
					var undockablePairs:Vector.<IPair> = extractOrderedPanelSideCodes(filtered, rootContainer)
					rootContainer.removeContainer(container);					//remove containers
					movePanelsIntoContainer(undockablePairs, rootContainer);	//add them back to the same location as before
					
					var originalWindow:NativeWindow = getContainerWindow(rootContainer)
					var newContainer:IContainer = getPanelContainer(getFirstPanel(dockablePanels, rootContainer), true)
					var newWindow:NativeWindow = getContainerWindow(newContainer)
					shadowContainer(rootContainer, newContainer)
					
					//check if the panels have not been moved to its own container
					if (originalWindow && originalWindow != newWindow)
					{
						newWindow.activate();
						originalWindow.visible = false;
					}
				}
			}
			return removable;
		}
		
		/**
		 * Shadows the destination container so that its window appears behind the source container's window.
		 * Also merges the source container into the destination container.
		 * @param	sourceContainer	The source container to be shadowed.
		 * @param	destContainer	The destination container whose window will shadow the source container's window.
		 */
		private function shadowContainer(sourceContainer:IContainer, destContainer:IContainer):void 
		{
			var containerWidth:Number, containerHeight:Number;
			var fromWindow:NativeWindow = getContainerWindow(sourceContainer)
			var otherPanelWindow:NativeWindow = getContainerWindow(destContainer)
			if (fromWindow && otherPanelWindow && destContainer && sourceContainer.hasPanels(true))
			{
				destContainer.height = otherPanelWindow.stage.stageHeight = containerHeight = sourceContainer.height
				destContainer.width = otherPanelWindow.stage.stageWidth = containerWidth = sourceContainer.width
				sourceContainer.mergeIntoContainer(destContainer);
				otherPanelWindow.x = fromWindow.x
				otherPanelWindow.y = fromWindow.y
				otherPanelWindow.orderInBackOf(fromWindow);
				otherPanelWindow.visible = fromWindow.visible;
			}
		}
		
		/**
		 * Performs a deep search in the given container for the first panel it can find, excluding the panels supplied in the excluding parameter.
		 * @param	excluding	The list of panels which are to be excluded from consideration.
		 * 						(This is usually used whenever a docked panel is to be shadowed and the function is called before the panel is actually removed; 
		 * 						then, the panel (which is to be, but has not yet, removed) is passed in the excluding parameter.
		 * 						It is also used when preventing undockable panels (i.e. panels with dockable set to false) from being moved to another container.)
		 * @param	inContainer	The container to search.
		 * @return	The first panel found in the container (except the panels supplied in the excluding parameter)
		 */
		private function getFirstPanel(excluding:Vector.<IPanel>, inContainer:IContainer):IPanel
		{
			if(!inContainer) {
				return null;
			}
			var panels:Vector.<IPanel> = inContainer.getPanels(true)
			if (excluding && excluding.length)
			{
				panels = panels.filter(function exclude(item:IPanel, index:int, array:Vector.<IPanel>):Boolean {
					return item && excluding.indexOf(item) == -1;
				});
			}
			return panels.shift();
		}
		
		private function startPanelContainerDragOnEvent(evt:PanelContainerEvent):void 
		{
			if(checkResizeOccurring() || evt.isDefaultPrevented()) {
				return;
			}
			var panel:IPanel = evt.relatedPanel;
			var transferObject:Clipboard = new Clipboard();
			var dragTarget:DisplayObjectContainer = (panel || evt.relatedContainer) as DisplayObjectContainer
			var container:IContainer = evt.relatedContainer || cl_treeResolver.findParentContainer(panel as DisplayObject);
			if (panel) {
				transferObject.setData(cl_dockFormat.panelFormat, panel, false)
			}
			if (container) {
				transferObject.setData(cl_dockFormat.containerFormat, container, false)
			}
			var transform:Matrix
			var offsetPoint:Point;
			var clipRect:Rectangle;
			var proxyImage:BitmapData;
			var maxWidth:Number = dragTarget.width
			var maxHeight:Number = dragTarget.height
			var thumbWidth:Number = dragImageWidth, thumbHeight:Number = dragImageHeight
			var wholeThumbWidth:int = int(thumbWidth), wholeThumbHeight:int = int(thumbHeight);
			if (maxWidth && maxHeight && thumbHeight && thumbWidth && !isNaN(thumbHeight) && !isNaN(thumbWidth))
			{
				//draw the thumbnail preview if the size is not 0 or NaN for either dimension
				var aspect:Number, widthRatio:Number, heightRatio:Number;
				if (container)
				{
					maxWidth = container.width
					maxHeight = container.height
					if(dragTarget.width < maxWidth) {
						maxWidth = dragTarget.width
					}
					if(dragTarget.height < maxHeight) {
						maxHeight = dragTarget.height
					}
					
					//bound panel contents by its container, if available
					clipRect = new Rectangle(0, 0, maxWidth, maxHeight)
				}
				//preliminary ratio calculation
				widthRatio = 1 / maxWidth;
				heightRatio = 1 / maxHeight;
				aspect = maxHeight / maxWidth;
				if(thumbWidth <= 1) {
					maxWidth *= thumbWidth;
				}
				else if(maxWidth > wholeThumbWidth) {
					maxWidth = wholeThumbWidth;
				}
				maxHeight = aspect * maxWidth;
				if(maxHeight < 1) {
					maxHeight = 1;
				}
				
				if (thumbHeight <= 1) {
					maxHeight *= thumbHeight;
				}
				else if (maxHeight > wholeThumbHeight) {
					maxHeight = wholeThumbHeight;
				}
				maxWidth = maxHeight / aspect;
				if(maxWidth < 1) {
					maxWidth = 1;
				}
				
				proxyImage = new BitmapData(maxWidth, maxHeight, false)
				transform = new Matrix(maxWidth * widthRatio, 0, 0, maxHeight * heightRatio)
				offsetPoint = new Point( -dragTarget.mouseX * transform.a, -dragTarget.mouseY * transform.d)
				
				proxyImage.draw(dragTarget, transform, null, null, clipRect)
			}
			//always prefer container instead of panel since container has more accuracy in dragging
			if (container && container.stage) {
				cl_dragStruct = new DragInformation(container.stage, container.mouseX / container.width, container.mouseY / container.height)
			}
			NativeDragManager.doDrag(mainContainer, transferObject, proxyImage, offsetPoint, cl_allowedDragActions);
			evt.stopImmediatePropagation();
		}
		
		private function togglePanelStateOnEvent(evt:PanelContainerEvent):void 
		{
			if(checkResizeOccurring() || evt.isDefaultPrevented()) {
				return;
			}
			var sideInfo:PanelStateInformation;
			var panel:IPanel = evt.relatedPanel;
			var container:IContainer = evt.relatedContainer;
			var prevState:Boolean = getAuthoritativeContainerState(container)
			if (panel)
			{
				if(!panel.dockable) {
					return;
				}
				container = cl_treeResolver.findParentContainer(panel as DisplayObject)
				if (container)
				{
					if (getAuthoritativeContainerState(container) == PanelContainerState.INTEGRATED)
					{
						dockPanel(panel)
						showPanel(panel)
					}
					else
					{
						removePanel(panel)
						sideInfo = getPanelStateInfo(panel);
						addPanelToSideSequence(panel, sideInfo.previousRoot, sideInfo.integratedCode)
					}
				}
			}
			else if (container)
			{
				if (getAuthoritativeContainerState(container) == PanelContainerState.INTEGRATED)
				{
					var containerWindow:NativeWindow = getContainerWindow(container) || getContainerWindow(dockPanelsInContainer(extractDockablePanels(container.getPanels(false)), container))
					if (containerWindow) {
						containerWindow.activate();
					}
				}
				else
				{
					var destContainer:IContainer;
					var panels:Vector.<IPanel> = extractDockablePanels(container.getPanels(false))
					var panelPairs:Vector.<IPair> = extractOrderedPanelSideCodes(panels, container);
					if (panels.length)
					{
						panel = panels.shift()
						sideInfo = getPanelStateInfo(panel)
						destContainer = addPanelToSideSequence(panel, sideInfo.previousRoot, sideInfo.integratedCode)
						movePanelsIntoContainer(panelPairs, destContainer)
					}
					removeContainer(container)
				}
			}
			dispatchEvent(new PanelContainerStateEvent(PanelContainerStateEvent.STATE_TOGGLED, evt.relatedPanel, evt.relatedContainer, prevState, !prevState, false, false))
		}
		
		/**
		 * @inheritDoc
		 */
		public function addPanelToSideSequence(panel:IPanel, container:IContainer, sideCode:String):IContainer
		{
			for (var i:uint = 0, currContainer:IContainer = container; currContainer && i < sideCode.length; ++i) {
				currContainer = currContainer.fetchSide(PanelContainerSide.toInteger(sideCode.charAt(i)))
			}
			if (currContainer)
			{
				removePanel(panel);
				currContainer.addToSide(PanelContainerSide.FILL, panel);
			}
			return currContainer
		}
		
		private function checkResizeOccurring():Boolean
		{
			var result:Boolean = cl_resizer && cl_resizer.isDragging;
			if(cl_resizer && !result && cl_resizer.parent) {
				cl_resizer.parent.removeChild(cl_resizer as DisplayObject)
			}
			return result
		}
		
		private function dockPanelsInContainer(panels:Vector.<IPanel>, container:IContainer):IContainer
		{
			var baseContainer:IContainer;
			var basePanelWindow:NativeWindow;
			if(!(container && panels && panels.length)) {
				return null;
			}
			else if (getAuthoritativeContainerState(container) != PanelContainerState.DOCKED)
			{
				var allDockable:Boolean = panels.every(function isDockable(item:IPanel, index:int, array:Vector.<IPanel>):Boolean {
					return item && item.dockable;	//check if any panels are undockable
				});
				
				//grab first panel in the list of panels and move to that
				var currPanel:IPanel = panels[0] as IPanel;
				var parentContainer:IContainer = cl_treeResolver.findParentContainer(container as DisplayObject);
				basePanelWindow = getWindowFromPanel(currPanel, true)
				baseContainer = getContainerFromWindow(basePanelWindow, true)
				if (allDockable) {
					baseContainer.addContainer(PanelContainerSide.getComplementary(baseContainer.sideCode), container)
				}
				else {
					movePanelsIntoContainer(extractOrderedPanelSideCodes(panels, container), baseContainer);
				}
				
				panels = container.getPanels(true)	//find out how many non-dockable panels remain (after docking to container)
				if (parentContainer && !(panels && panels.length)) {
					parentContainer.removeContainer(container)
				}
			}
			else
			{
				//already docked; activate window
				baseContainer = container
				basePanelWindow = getContainerWindow(container)
			}
			
			return baseContainer
		}
		
		/**
		 * Returns a list of panels which are sorted based on their depth with respect to the root container supplied.
		 * @param	panels	The list of panels to be sorted based on depth order.
		 * @param	rootContainer	The root container on which the panel depth order is based upon.
		 * @return	A Vector of key-value pairs, where the key is the panel and the value is the side code.
		 * 			If no rootContainer is specified, the value in each pair is the default value returned by the Docker's treeResolver's serializeCode() method - usually null.
		 */
		private function extractOrderedPanelSideCodes(panels:Vector.<IPanel>, rootContainer:IContainer):Vector.<IPair>
		{
			if(!panels) {
				return null;
			}
			var sides:Vector.<IPair> = new Vector.<IPair>(panels.length);
			for (var i:uint = 0; i < panels.length; ++i) {
				sides[i] = new StaticPair(panels[i], cl_treeResolver.serializeCode(rootContainer, panels[i] as DisplayObject));
			}
			//sort the pairs according to increasing code length and add them to the respective sequence in the container
			return sides.sort(function deeperLevels(pairA:IPair, pairB:IPair):int {
				return int(pairA.value && pairB.value && (pairA.value as String).length - (pairB.value as String).length) || 0;
			});
		}
		
		private function movePanelsIntoContainer(panelPairs:Vector.<IPair>, rootContainer:IContainer):void
		{
			if (panelPairs && rootContainer)
			{
				panelPairs.forEach(function preserveSideOnDock(item:IPair, index:int, array:Vector.<IPair>):void
				{
					if (item) {
						addPanelToSideSequence(item.key as IPanel, rootContainer, item.value as String);	//re-add to same position; note this approach means they will not be part of the same container
					}
				});
			}
		}
		
		private function renameWindow(evt:PanelPropertyChangeEvent):void
		{
			if (evt.fieldName == "panelName")
			{
				var panel:IPanel = evt.currentTarget as IPanel;
				if (panel in dct_windows) {
					getWindowFromPanel(panel, false).title = evt.newValue as String	//false since plain lookup
				}
			}
		}
		
		private function resizeContainerOnEvent(evt:NativeWindowBoundsEvent):void 
		{
			var window:NativeWindow = evt.currentTarget as NativeWindow
			var container:IContainer = getWindowContainer(window)
			if (container)
			{
				container.width = window.stage.stageWidth;
				container.height = window.stage.stageHeight;
			}
		}
		
		private function removeDockHelperListeners(helper:IDockHelper):void
		{
			if (helper) {
				helper.removeEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, showDockHelperOnEvent)
			}
		}
		
		private function addDockHelperListeners(helper:IDockHelper):void
		{
			if (helper) {
				helper.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, showDockHelperOnEvent, false, 0, true)
			}
		}
		
		/**
		 * Updates the panelStateInformation object for the panel which has been added to a container, and all panels in containers deeper than it.
		 * @param	evt
		 */
		private function setRoot(evt:PanelContainerEvent):void 
		{
			var parent:DisplayObject;
			var currLevel:int, level:int;
			var panel:IPanel = evt.relatedPanel;
			var panelStateInfo:PanelStateInformation;
			var root:IContainer = cl_treeResolver.findRootContainer(evt.currentTarget as IContainer)
			var currentCode:String = cl_treeResolver.serializeCode(root, panel as DisplayObject)
			var panelContainer:DisplayObjectContainer = cl_treeResolver.findParentContainer(panel as DisplayObjectContainer) as DisplayObjectContainer
			if(isForeignContainer(panelContainer as IContainer)) {
				return;
			}
			for (parent = panel as DisplayObject, level = 0; parent; parent = parent.parent, ++level) { }
			panelStateInfo = getPanelStateInfo(panel)
			panelStateInfo.integratedCode = currentCode;
			panelStateInfo.previousRoot = root;
			
			if(!currentCode) {
				return;
			}
			var allStates:Dictionary = dct_panelStateInfo
			for (var currPanel:Object in allStates)
			{
				var dispPanel:DisplayObject = (currPanel as IPanel) as DisplayObject;
				for (parent = dispPanel, currLevel = 0; parent && currLevel < level; parent = parent.parent, ++currLevel) { }
				if(currLevel < level || dispPanel == panel) {
					continue;
				}
				
				panelStateInfo = allStates[currPanel];
				if (panelStateInfo.previousRoot == root)
				{
					var relativeCode:String = cl_treeResolver.serializeCode(cl_treeResolver.findCommonParent(panelContainer, dispPanel as DisplayObjectContainer) as IContainer, dispPanel)
					if (relativeCode) {
						panelStateInfo.integratedCode = currentCode.slice(0, -relativeCode.length) + relativeCode
					}
				}
			}
		}
		
		private function addWindowListeners(window:NativeWindow):void
		{
			window.addEventListener(Event.CLOSING, hidePanelsOnWindowClose, false, 0, true)
			window.addEventListener(NativeWindowBoundsEvent.RESIZE, resizeContainerOnEvent, false, 0, true)
		}
		
		private function removeWindowListeners(window:NativeWindow):void
		{
			window.removeEventListener(NativeWindowBoundsEvent.RESIZE, resizeContainerOnEvent)
			window.removeEventListener(Event.CLOSING, hidePanelsOnWindowClose)
		}
		
		private function hidePanelsOnWindowClose(evt:Event):void 
		{
			evt.preventDefault();
			var window:NativeWindow = evt.currentTarget as NativeWindow;
			var container:IContainer = getWindowContainer(window);
			var panels:Vector.<IPanel> = container.getPanels(true);
			for (var i:uint = 0; i < panels.length; ++i) {
				dispatchEvent(new PanelContainerStateEvent(PanelContainerStateEvent.VISIBILITY_TOGGLED, panels[i], container, true, false, false, false))
			}
			window.visible = false;
		}
		
		private function addPanelListeners(panel:IPanel):void {
			panel.addEventListener(PanelPropertyChangeEvent.PROPERTY_CHANGED, renameWindow, false, 0, true)
		}
		
		private function removePanelListeners(panel:IPanel):void {
			panel.removeEventListener(PanelPropertyChangeEvent.PROPERTY_CHANGED, renameWindow)
		}
		
		/**
		 * Docks panels local to the Docker instance in their parked container if cross-docking is disabled.
		 * This is triggered whenever the following crossDockingPolicy flags are used:
		 * * CrossDockingPolicy.INTERNAL_ONLY
		 * * CrossDockingPolicy.PREVENT_OUTGOING
		 * In effect, it prevents them from being integrated into other Docker instances' containers.
		 * @see	airdock.enums.CrossDockingPolicy
		 */
		private function dockPanelOnCrossViolation(evt:Event):void 
		{
			var panel:IPanel = evt.currentTarget as IPanel
			panel.removeEventListener(Event.ADDED, dockPanelOnCrossViolation)
			if(isForeignPanel(panel)) {
				return;
			}
			var parentContainer:IContainer = cl_treeResolver.findParentContainer(panel as DisplayObject)
			var rootContainer:IContainer = cl_treeResolver.findRootContainer(parentContainer)
			if ((rootContainer && isForeignContainer(rootContainer)) || (parentContainer && isForeignContainer(parentContainer)))
			{
				dockPanel(panel)
				if (cl_dragStruct) {
					moveWindowTo(getPanelWindow(panel), cl_dragStruct.localX, cl_dragStruct.localY, cl_dragStruct.convertToScreen())
				}
				showPanel(panel)
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function getPanelWindows():Vector.<IPair>
		{
			var panelWindows:Vector.<IPair> = new Vector.<IPair>()
			for (var obj:Object in dct_foreignCounter)
			{
				if (obj is IPanel) {
					panelWindows.push(new LazyPair(obj as IPanel, getWindowFromPanel))
				}
			}
			return panelWindows
		}
		
		/**
		 * Returns the panel's parked container, and creates it if specified.
		 * Alias for getContainerFromWindow(getWindowFromPanel(panel))
		 * @param	panel	The panel to get the container of.
		 * @param	createIfNotExist	A Boolean indicating whether the container of the panel should be created if it does not exist.
		 * 								If true, both the window and the container are created if they do not exist.
		 * @return	The panel's parked container.
		 */
		private function getPanelContainer(panel:IPanel, createIfNotExist:Boolean = true):IContainer {
			return getContainerFromWindow(getWindowFromPanel(panel, createIfNotExist), createIfNotExist);
		}
		
		/**
		 * @inheritDoc
		 */
		public function getPanelContainers():Vector.<IPair>
		{
			var panelContainers:Vector.<IPair> = new Vector.<IPair>()
			for (var panel:Object in dct_panelStateInfo)
			{
				var currPanel:IPanel = panel as IPanel
				panelContainers.push(new StaticPair(currPanel, getPanelContainer(currPanel, false)))
			}
			return panelContainers
		}
		
		/**
		 * @inheritDoc
		 */
		public function setupPanel(panel:IPanel):void
		{
			dct_foreignCounter[panel] = true;
			addPanelListeners(panel)
		}
		
		/**
		 * @inheritDoc
		 */
		public function setupWindow(window:NativeWindow):void {
			addWindowListeners(window)
		}
		
		/**
		 * @inheritDoc
		 */
		public function unhookWindow(window:NativeWindow):void {
			removeWindowListeners(window)
		}
		
		/**
		 * @inheritDoc
		 */
		public function unhookPanel(panel:IPanel):void
		{
			if(!panel) {
				return;
			}
			delete dct_panelStateInfo[panel];
			delete dct_foreignCounter[panel];
			removePanelListeners(panel)
		}
		
		/**
		 * @inheritDoc
		 */
		public function createPanel(options:PanelConfig):IPanel
		{
			var panel:IPanel = cl_panelFactory.createPanel(options)
			setupPanel(panel)
			return panel
		}
		
		/**
		 * @inheritDoc
		 */
		public function createWindow(panel:IPanel):NativeWindow
		{
			if(!panel) {
				return null
			}
			else if(panel in dct_windows) {
				return dct_windows[panel] as NativeWindow
			}
			
			var options:NativeWindowInitOptions = defaultWindowOptions
			options.resizable = panel.resizable
			
			var window:NativeWindow = new NativeWindow(options)
			var stage:Stage = window.stage
			addWindowListeners(window)
			dct_windows[panel] = window
			window.title = panel.panelName
			stage.stageWidth = panel.width
			stage.stageHeight = panel.height
			stage.align = StageAlign.TOP_LEFT
			stage.scaleMode = StageScaleMode.NO_SCALE
			return window
		}
		
		/**
		 * @inheritDoc
		 */
		public function createContainer(options:ContainerConfig):IContainer
		{
			var container:IContainer = cl_containerFactory.createContainer(options)
			container.panelList = cl_panelListFactory.createPanelList()
			addContainerListeners(container)
			dct_foreignCounter[container] = hasContainerListeners(container)
			return container
		}
		
		/**
		 * @inheritDoc
		 */
		public function setPanelFactory(panelFactory:IPanelFactory):void
		{
			if(!panelFactory) {
				throw new ArgumentError("Error: Argument panelFactory must be a non-null value.");
			}
			else {
				cl_panelFactory = panelFactory
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function setContainerFactory(containerFactory:IContainerFactory):void 
		{
			if(!containerFactory) {
				throw new ArgumentError("Error: Argument containerFactory must be a non-null value.");
			}
			else {
				cl_containerFactory = containerFactory
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function setPanelListFactory(panelListFactory:IPanelListFactory):void
		{
			cl_panelListFactory = panelListFactory
			var container:IContainer;
			for (var obj:Object in dct_containers)
			{
				container = getWindowContainer(obj as NativeWindow)
				if (container) {
					container.panelList = (Boolean(panelListFactory) && panelListFactory.createPanelList()) as IPanelList
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function set dockHelper(dockHelper:IDockHelper):void
		{
			var handles:DisplayObject = cl_dockHelper as DisplayObject
			if (handles)
			{
				removeDockHelperListeners(handles as IDockHelper)
				if (handles.parent) {
					handles.parent.removeChild(handles)
				}
			}
			cl_dockHelper = dockHelper
			if (dockHelper)
			{
				dockHelper.setDockFormat(cl_dockFormat.panelFormat, cl_dockFormat.containerFormat)
				dockHelper.draw(dockHelper.getDefaultWidth(), dockHelper.getDefaultHeight());
				addDockHelperListeners(dockHelper);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function set resizeHelper(resizer:IResizer):void
		{
			var prevSizer:DisplayObject = cl_resizer as DisplayObject
			if (prevSizer)
			{
				removeResizerListeners(prevSizer as IResizer)
				if (prevSizer.parent) {
					prevSizer.parent.removeChild(prevSizer)
				}
			}
			
			cl_resizer = resizer
			if (resizer) {
				addResizerListeners(resizer);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function dockPanel(panel:IPanel):IContainer
		{
			var basePanelWindow:NativeWindow = getWindowFromPanel(panel, true)
			var baseContainer:IContainer = getContainerFromWindow(basePanelWindow, true)
			if (!baseContainer.findPanel(panel))
			{
				var side:int = PanelContainerSide.FILL
				if (baseContainer.hasSides) {
					side = PanelContainerSide.getComplementary(baseContainer.sideCode)	//add to highest level
				}
				baseContainer.addToSide(side, panel);
			}
			baseContainer.showPanel(panel);
			return baseContainer
		}
		
		/**
		 * Integrates the panel into the previous container it occupied.
		 * Not a part of the IBasicDocker or the ICustomizableDocker interface.
		 * @param	panel	The panel to be integrated.
		 * @return	The container into which it is integrated into.
		 */
		public function integratePanel(panel:IPanel):IContainer
		{
			var sideInfo:PanelStateInformation = getPanelStateInfo(panel);
			var container:IContainer = addPanelToSideSequence(panel, sideInfo.previousRoot, sideInfo.integratedCode)
			var window:NativeWindow = getPanelWindow(panel)
			if(container != getWindowContainer(window)) {
				window.visible = false
			}
			return container
		}
		
		/**
		 * Makes the panel supplied in the parameter visible, and dispatches a PanelContainerStateEvent if it was previously hidden.
		 * No event is dispatched if the panel supplied was already visible prior to calling the function.
		 * @inheritDoc
		 */
		public function showPanel(panel:IPanel):Boolean
		{
			if(!panel) {
				return false;
			}
			var container:IContainer = cl_treeResolver.findParentContainer(panel as DisplayObject)
			var changeOccurred:Boolean = true;
			var dockToPreviousRoot:Boolean;
			if (container)
			{
				if (isForeignContainer(container)) {
					return false;	//do not attempt to show panel for external/foreign containers
				}
				else if (getAuthoritativeContainerState(container) == PanelContainerState.DOCKED)
				{
					var window:NativeWindow = getContainerWindow(container);
					if (window.visible) {
						changeOccurred = false;
					}
					container.showPanel(panel)
					window.activate()
				}
				else {
					dockToPreviousRoot = true;
				}
			}
			
			if(dockToPreviousRoot || !container)
			{
				var sideInfo:PanelStateInformation = getPanelStateInfo(panel)
				var previousRoot:IContainer = sideInfo.previousRoot
				if (previousRoot)
				{
					if(previousRoot == cl_treeResolver.findRootContainer(container)) {
						changeOccurred = false;	//no change has occurred - was already visible before
					}
					else {
						addPanelToSideSequence(panel, previousRoot, sideInfo.integratedCode)
					}
				}
				else {
					dockPanel(panel) //dock panel by default
				}
			}
			
			var newParent:IContainer = cl_treeResolver.findParentContainer(panel as DisplayObject);
			if (changeOccurred) {
				return dispatchEvent(new PanelContainerStateEvent(PanelContainerStateEvent.VISIBILITY_TOGGLED, panel, newParent, false, true, false, false));
			}
			return newParent.showPanel(panel)
		}
		
		/**
		 * @inheritDoc
		 */
		public function hidePanel(panel:IPanel):Boolean
		{
			var hideable:Boolean = isPanelVisible(panel);
			if (hideable)
			{
				var container:IContainer = cl_treeResolver.findParentContainer(panel as DisplayObject);
				var rootContainer:IContainer = cl_treeResolver.findRootContainer(container);
				if (getAuthoritativeContainerState(rootContainer) == PanelContainerState.DOCKED && rootContainer == getPanelContainer(panel, false) && rootContainer.getPanelCount(true) == 1) {
					getContainerWindow(rootContainer).visible = false;
				}
				else {
					container.removePanel(panel)
				}
				
				if (container) {
					dispatchEvent(new PanelContainerStateEvent(PanelContainerStateEvent.VISIBILITY_TOGGLED, panel, container, true, false, false, false))
				}
			}
			return hideable;
		}
		
		/**
		 * @inheritDoc
		 */
		public function movePanelToContainer(panel:IPanel, container:IContainer, side:int):IContainer {
			return addPanelToSideSequence(panel, container, PanelContainerSide.toString(side));
		}
		
		/**
		 * @inheritDoc
		 */
		public function isPanelVisible(panel:IPanel):Boolean
		{
			var container:IContainer = cl_treeResolver.findParentContainer(panel as DisplayObject);
			if(!container || isForeignContainer(container)) {
				return false;
			}
			else if (getAuthoritativeContainerState(container) == PanelContainerState.DOCKED && container == getPanelContainer(panel, false)) {
				return getContainerWindow(container).visible;
			}
			return !!container.stage;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set crossDockingPolicy(policyFlags:int):void {
			i_crossDockingPolicy = policyFlags
		}
		
		/**
		 * @inheritDoc
		 */
		public function get crossDockingPolicy():int {
			return i_crossDockingPolicy
		}
		
		/**
		 * @inheritDoc
		 */
		public function get mainContainer():DisplayObjectContainer {
			return dsp_mainContainer;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set mainContainer(container:DisplayObjectContainer):void
		{
			if (dsp_mainContainer)
			{
				dsp_mainContainer.removeEventListener(NativeDragEvent.NATIVE_DRAG_START, preventDockIfInvalid)
				dsp_mainContainer.removeEventListener(NativeDragEvent.NATIVE_DRAG_UPDATE, removeContainerOnEvent)
				dsp_mainContainer.removeEventListener(NativeDragEvent.NATIVE_DRAG_COMPLETE, hideDockHelperOnEvent)
				dsp_mainContainer.removeEventListener(NativeDragEvent.NATIVE_DRAG_COMPLETE, dockContainerIfInvalidDropTarget)
			}
			dsp_mainContainer = container;
			if (container)
			{
				container.addEventListener(NativeDragEvent.NATIVE_DRAG_START, preventDockIfInvalid)
				container.addEventListener(NativeDragEvent.NATIVE_DRAG_UPDATE, removeContainerOnEvent)
				container.addEventListener(NativeDragEvent.NATIVE_DRAG_COMPLETE, hideDockHelperOnEvent)
				container.addEventListener(NativeDragEvent.NATIVE_DRAG_COMPLETE, dockContainerIfInvalidDropTarget)
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function get dragImageHeight():Number {
			return num_thumbHeight
		}
		
		/**
		 * @inheritDoc
		 */
		public function set dragImageHeight(value:Number):void {
			num_thumbHeight = value;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get dragImageWidth():Number {
			return num_thumbWidth
		}
		
		/**
		 * Unloads all the windows and removes all listeners and other references of the panels registered to this Docker.
		 * Once this method is called, it is advised not to use the Docker instance again, and to create a new one instead.
		 */
		public function unload():void
		{
			var obj:Object;
			mainContainer = null;
			cl_dragStruct = null;
			for (obj in dct_containers)
			{
				dct_containers[obj] = null;
				delete dct_containers[obj];
			}
			for (obj in dct_windows)
			{
				dct_windows[obj as IPanel].close();
				delete dct_windows[obj]
			}
			dragImageWidth = dragImageHeight = NaN;
			setPanelListFactory(null);
			plc_dropTarget = null;
			dockHelper = null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set dragImageWidth(value:Number):void {
			num_thumbWidth = value
		}
		
		/**
		 * @inheritDoc
		 */
		public function get defaultWindowOptions():NativeWindowInitOptions {
			return cl_defaultWindowOptions;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set defaultWindowOptions(value:NativeWindowInitOptions):void
		{
			if(!value) {
				throw new ArgumentError("Error: Option defaultWindowOptions must be a non-null value.")
			}
			else {
				cl_defaultWindowOptions = value;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function get defaultContainerOptions():ContainerConfig {
			return cl_defaultContainerOptions;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set defaultContainerOptions(value:ContainerConfig):void 
		{
			if(!value) {
				throw new ArgumentError("Error: Option defaultContainerOptions must be a non-null value.")
			}
			else {
				cl_defaultContainerOptions = value;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function get dockFormat():IDockFormat {
			return cl_dockFormat;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set dockFormat(value:IDockFormat):void 
		{
			if(!value) {
				throw new ArgumentError("Error: Option dockFormat must be a non-null value.")
			}
			else {
				cl_dockFormat = value;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function set treeResolver(value:ITreeResolver):void 
		{
			if(!value) {
				throw new ArgumentError("Error: Option treeResolver must be a non-null value.")
			}
			else {
				cl_treeResolver = value;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			cl_dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		/**
		 * @inheritDoc
		 */
		public function dispatchEvent(event:Event):Boolean {
			return cl_dispatcher.dispatchEvent(event);
		}
		
		/**
		 * @inheritDoc
		 */
		public function hasEventListener(type:String):Boolean {
			return cl_dispatcher.hasEventListener(type);
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			cl_dispatcher.removeEventListener(type, listener, useCapture);
		}
		
		/**
		 * @inheritDoc
		 */
		public function willTrigger(type:String):Boolean {
			return cl_dispatcher.willTrigger(type);
		}
		
		[Inline]
		private function isForeignContainer(container:IContainer):Boolean {
			return !(container in dct_foreignCounter)
		}
		
		[Inline]
		private function isForeignPanel(panel:IPanel):Boolean {
			return !(panel in dct_foreignCounter)
		}
		
		[Inline]
		private function isMatchingDockPolicy(crossDockingPolicy:int, flag:int):Boolean {
			return (crossDockingPolicy & flag) != 0;
		}
		
		/**
		 * Gets the authoritative state of the container, by querying the root container's state.
		 * If the root container is a parked container, then it is most likely DOCKED; 
		 * otherwise, it is most likely INTEGRATED (assuming no changes have been made manually to the state)
		 * @param	container	The container to get the authoritative state of.
		 * @return	The authoritative state of the container.
		 * @see	airdock.enums.PanelContainerState
		 */
		[Inline]
		private function getAuthoritativeContainerState(container:IContainer):Boolean
		{
			var root:IContainer = cl_treeResolver.findRootContainer(container)
			return root && root.containerState;
		}
		
		/**
		 * Checks whether AIRDock is supported on the target runtime or not.
		 * Use this method to determine whether AIRDock is supported on the target runtime before creating an instance via the create() method.
		 * However, in general, any system which supports both the NativeWindow and NativeDragManager class will support AIRDock as well.
		 * @see	#create()
		 */
		public static function get isSupported():Boolean {
			return NativeWindow.isSupported && NativeDragManager.isSupported;
		}
		
		/**
		 * Creates an AIRDock instance, based on the supplied configuration, if supported. To check whether it is supported, see the static isSupported() method.
		 * It is advised to use this method to create a new AIRDock instance rather than creating it via the new() operator.
		 * @param	config	A DockConfig instance representing the configuration options that must be used when creating the new AIRDock instance.
		 * @throws	ArgumentError If either the configuration is null, or any of the mainContainer, defaultWindowOptions, or treeResolver attributes are null in the configuration.
		 * @throws	IllegalOperationError If AIRDock is not supported on the target system. To check whether it is supported, see the static isSupported() method.
		 * @return	An AIRDock instance as an ICustomizableDocker.
		 * @see	#isSupported
		 */
		public static function create(config:DockConfig):ICustomizableDocker
		{
			if (!(config && config.mainContainer && config.defaultWindowOptions && config.treeResolver))
			{
				var reason:String = "Invalid options: "
				if(!config) {
					reason += "Options must be non-null."
				}
				else 
				{
					if(!config.mainContainer) {
						reason += "Option mainContainer must be a non-null value. ";
					}
					if(!config.defaultWindowOptions) {
						reason += "Option defaultWindowOptions must be a non-null value. ";
					}
					if(!config.treeResolver) {
						reason += "Option treeResolver must be a non-null value. ";
					}
				}
				throw new ArgumentError(reason)
			}
			else if(!isSupported) {
				throw new IllegalOperationError("Error: AIRDock is not supported on the current system.");
			}
			var dock:AIRDock = new AIRDock()
			dock.setPanelFactory(config.panelFactory)
			dock.setPanelListFactory(config.panelListFactory)
			dock.setContainerFactory(config.containerFactory)
			dock.defaultWindowOptions = config.defaultWindowOptions
			dock.defaultContainerOptions = config.defaultContainerOptions
			dock.crossDockingPolicy = config.crossDockingPolicy
			dock.mainContainer = config.mainContainer
			dock.treeResolver = config.treeResolver
			dock.resizeHelper = config.resizeHelper
			dock.dockFormat = config.dockFormat
			dock.dockHelper = config.dockHelper
			if (dock.mainContainer.stage) {
				dock.defaultWindowOptions.owner = dock.mainContainer.stage.nativeWindow
			}
			if (!(isNaN(config.dragImageWidth) || isNaN(config.dragImageHeight)))
			{
				dock.dragImageHeight = config.dragImageHeight
				dock.dragImageWidth = config.dragImageWidth
			}
			return dock as ICustomizableDocker
		}
	}
	
}

import airdock.interfaces.docking.IContainer;
import flash.display.Stage;
import flash.geom.Point;
internal class DragInformation
{
	private var st_dragStage:Stage;
	private var num_localX:Number;
	private var num_localY:Number;
	private var num_stageX:Number;
	private var num_stageY:Number;
	public function DragInformation(stage:Stage, localX:Number, localY:Number)
	{
		st_dragStage = stage;
		num_localX = localX;
		num_localY = localY;
	}
	
	public function convertToScreen():Point {
		return dragStage.nativeWindow.globalToScreen(new Point(num_stageX, num_stageY))
	}
	
	public function updateStageCoordinates(stageX:Number, stageY:Number):void 
	{
		num_stageX = stageX;
		num_stageY = stageY;
	}
	
	public function get dragStage():Stage {
		return st_dragStage;
	}
	
	/**
	 * Stored initial property relative to container.
	 */
	public function get localX():Number {
		return num_localX;
	}
	
	/**
	 * Stored initial property relative to container.
	 */
	public function get localY():Number {
		return num_localY;
	}
	
	public function get stageX():Number {
		return num_stageX;
	}
	
	public function get stageY():Number {
		return num_stageY;
	}
}

internal class PanelStateInformation
{
	private var plc_prevRoot:IContainer;
	private var str_integratedCode:String;
	public function PanelStateInformation() { }
	
	public function get previousRoot():IContainer {
		return plc_prevRoot; 
	}
	
	public function set previousRoot(value:IContainer):void {
		plc_prevRoot = value;
	}
	
	public function get integratedCode():String {
		return str_integratedCode;
	}
	
	public function set integratedCode(value:String):void {
		str_integratedCode = value;
	}
}