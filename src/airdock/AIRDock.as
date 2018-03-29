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
	import flash.utils.Dictionary;
	
	/**
	 * Dispatched whenever a panel is either added to a container, or when it is removed from its container.
	 * @eventType airdock.events.PanelContainerStateEvent.VISIBILITY_TOGGLED
	 */
	[Event(name = "pcPanelVisibilityToggled", type = "airdock.events.PanelContainerStateEvent")]
	
	/**
	 * Dispatched whenever a panel is moved to its parked container (docked), or when it is moved into another container which is not its own parked container (integrated).
	 */
	[Event(name = "pcPanelStateToggled", type = "airdock.events.PanelContainerStateEvent")]
	
	/**
	 * Implementation of ICustomizableDocker (and by extension, IBasicDocker) which manages the main docking panels mechanism.
	 * 
	 * @author Gimmick
	 * @see	airdock.interfaces.docking.IBasicDocker
	 * @see	airdock.interfaces.docking.ICustomizableDocker
	 */
	public final class AIRDock implements ICustomizableDocker
	{
		private static const ALLOWED_DRAG_ACTIONS:NativeDragOptions = new NativeDragOptions();
		static: {
			ALLOWED_DRAG_ACTIONS.allowLink = ALLOWED_DRAG_ACTIONS.allowCopy = false;
		};
		
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
			crossDockingPolicy = CrossDockingPolicy.UNRESTRICTED
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
			
			if(currContainer.maxSideSize < 1) {
				maxSize *= currContainer.maxSideSize
			}
			else if(maxSize > currContainer.maxSideSize) {
				maxSize = currContainer.maxSideSize
			}
			
			if (0 < value && value < maxSize) {
				currContainer.sideSize = value
			}
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
			
			while (dispContainer && !(dispContainer is IDockTarget)) {
				dispContainer = dispContainer.parent
			}
			dockTarget = dispContainer as IDockTarget
			if (isMatchingDockPolicy(crossDockingPolicy, CrossDockingPolicy.REJECT_INCOMING) && isForeignContainer(container)) {
				return;	//ignore if it violates policy - this runs before the DRAG_DROP is cancelled, so prevent normal behavior by exiting early
			}
			else if (relatedContainer && dockTarget)
			{
				var side:int = dockTarget.getSideFrom(dragDropTarget as DisplayObject)
				if (panel) {
					movePanelToContainer(panel, relatedContainer, side)
				}
				else if (container && container != relatedContainer)
				{
					var panels:Vector.<IPanel> = container.getPanels(false)
					var undockablePanels:Vector.<IPanel> = filterUndockablePanels(panels);
					panels = panels.filter(function(item:IPanel, index:int, arr:Vector.<IPanel>):Boolean {
						return undockablePanels.indexOf(item) == -1;	//exclude non-dockable panels from docking
					});
					movePanelsIntoContainer(panels, relatedContainer, side)
				}
			}
			cl_dragStruct = null;
			plc_dropTarget = null;
		}
		
		private function movePanelsIntoContainer(panels:Vector.<IPanel>, container:IContainer, initialSide:int):IContainer
		{
			var side:int = initialSide;
			var tempCont:IContainer = container;
			for (var i:uint = 0; i < panels.length; ++i)
			{
				tempCont = movePanelToContainer(panels[i], tempCont, side)
				side = PanelContainerSide.FILL //as after first, the container is made - replace with reserved container by FILL
			}
			return tempCont
		}
		
		private function dockContainerIfInvalidDropTarget(evt:NativeDragEvent):void 
		{
			if(cl_dockHelper && cl_dockHelper.parent) {
				cl_dockHelper.parent.removeChild(cl_dockHelper as DisplayObject)
			}
			var clipBoard:Clipboard = evt.clipboard
			if(!(clipBoard.hasFormat(cl_dockFormat.panelFormat) || clipBoard.hasFormat(cl_dockFormat.containerFormat))) {
				return;
			}
			trace("completed", evt.dropAction)
			var panel:IPanel = clipBoard.getData(cl_dockFormat.panelFormat, ClipboardTransferMode.ORIGINAL_ONLY) as IPanel
			var container:IContainer = clipBoard.getData(cl_dockFormat.containerFormat, ClipboardTransferMode.ORIGINAL_ONLY) as IContainer
			if (evt.dropAction != NativeDragActions.NONE || (isForeignContainer(container) && isMatchingDockPolicy(crossDockingPolicy, CrossDockingPolicy.REJECT_INCOMING))) {
				return;	//return if drop action is valid or if this is the foreign Docker, i.e. let the originating Docker handle it
			}
			var window:NativeWindow;
			if (panel)
			{
				window = getWindowFromPanel(panel, true)
				dockPanel(panel)
				showPanel(panel)
			}
			else if (container)
			{
				window = getContainerWindow(container)
				if (window) {
					window.visible = true
				}
				else
				{
					var filtered:Vector.<IPanel> = filterUndockablePanels(container.getPanels(false))
					window = getWindowFromPanel(getFirstPanel(filtered, container), true)
					dockAllPanelsInContainer(filtered, container)	//grab first panel in container's window and move to that
				}
			}
			
			if (window && cl_dragStruct)
			{
				cl_dragStruct.updateStageCoordinates(evt.stageX, evt.stageY)
				moveWindowTo(window, cl_dragStruct.localX, cl_dragStruct.localY, cl_dragStruct.convertToScreen())
			}
			cl_dragStruct = null;
		}
		
		/**
		 * Finds and returns all undockable IPanel instances from the given vector of IPanel instances.
		 * @param	panels	The list of IPanel instances to get the undockable IPanel instances from.
		 * @return	A new vector of undockable IPanel instances from the supplied list.
		 */
		private function filterUndockablePanels(panels:Vector.<IPanel>):Vector.<IPanel>
		{
			if(!(panels && panels.length)) {
				return null;
			}
			var undockable:Vector.<IPanel> = new Vector.<IPanel>()
			for (var i:uint = 0; i < panels.length; ++i)
			{
				var item:IPanel = panels[i];
				if(!item.dockable) {
					undockable.push(item)
				}
			}
			return undockable
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
					evt.preventDefault()	//prevent docking if panel is not dockable
				}
			}
			else if (container)
			{
				var panels:Vector.<IPanel> = container.getPanels(false)
				var excludedPanels:Vector.<IPanel> = filterUndockablePanels(panels)
				if(panels.length == excludedPanels.length) {
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
				return;	//do nothing since panel doesn't belong to this Docker
			}
			else if (panel)
			{
				rootContainer = cl_treeResolver.findRootContainer(cl_treeResolver.findParentContainer(panel as DisplayObject))
				if (rootContainer)
				{
					originalWindow = getWindowFromPanel(panel, false)		//false since we're comparing -- a panel which has never had a window created
					if (getContainerFromWindow(originalWindow, false) == rootContainer)	//cannot be the container/stage of the panel
					{
						moveExistingPanelsFrom(new <IPanel>[panel], rootContainer, getFirstPanel);
						originalWindow.visible = false
					}
				}
				
				var removeSuccess:Boolean = removePanel(panel);
				if (removeSuccess && isMatchingDockPolicy(crossDockingPolicy, CrossDockingPolicy.PREVENT_OUTGOING)) {
					panel.addEventListener(Event.ADDED, dockPanelOnCrossViolation)
				}
			}
			else if (container)
			{
				var containerWindow:NativeWindow = getContainerWindow(container)
				rootContainer = cl_treeResolver.findRootContainer(container)
				if ((rootContainer && rootContainer != container) || (containerWindow && containerWindow.visible))
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
							movePanelToContainer(currPanel, parkedContainer, PanelContainerSide.FILL)
							dockAllPanelsInContainer(null, parkedContainer)
							if (cl_dragStruct)
							{
								cl_dragStruct.updateStageCoordinates(evt.stageX, evt.stageY)
								moveWindowTo(getContainerWindow(parkedContainer), cl_dragStruct.localX, cl_dragStruct.localY, cl_dragStruct.convertToScreen())
							}
						}
						currPanel.removeEventListener(Event.ADDED, currentFunction)
					}
					
					var allPanels:Vector.<IPanel> = container.getPanels(false);
					var dockablePanels:Vector.<IPanel> = allPanels.filter(function(item:IPanel, index:int, arr:Vector.<IPanel>):Boolean {
						return item.dockable;	//get only dockable panels
					});
					if (isMatchingDockPolicy(crossDockingPolicy, CrossDockingPolicy.PREVENT_OUTGOING) && dockablePanels && dockablePanels.length)
					{
						//selects the first panel* and docks all the panels in the current container to the parked container's window
						//when it gets added to stage, if there's a violation in crossDocking policy
						//*note - it can be any panel from the list of panels, since they are all being docked to the same container
						var i:uint
						var currPanel:IPanel;
						var parkedContainer:IContainer
						for (i = 0; !parkedContainer && i < dockablePanels.length; ++i)
						{
							currPanel = dockablePanels[i] as IPanel;
							if(currPanel && !isForeignPanel(currPanel)) {
								parkedContainer = getContainerFromWindow(getWindowFromPanel(currPanel, true), true)
							}
						}
						if (parkedContainer)
						{
							for (i = 0; i < dockablePanels.length; ++i)
							{
								currPanel = dockablePanels[i] as IPanel;
								currPanel.removeEventListener(Event.ADDED, dockPanelOnCrossViolation);
								currPanel.addEventListener(Event.ADDED, dockContainerOnCrossViolation);
							}
						}
					}
					
					if (containerWindow && container == cl_treeResolver.findRootContainer(container)) {
						containerWindow.visible = false;
					}
					else
					{
						//undockable panels will be removed from the root container briefly
						//and then re-added back to the same position they were before
						//based on the side sequence with respect to the root
						//prior to their removal
						var filtered:Vector.<IPanel> = filterUndockablePanels(allPanels)
						var sideSequences:Vector.<String> = new Vector.<String>(filtered.length, true)
						for (i = 0; i < filtered.length; ++i) {
							sideSequences[i] = cl_treeResolver.serializeCode(rootContainer, filtered[i] as DisplayObject)
						}
						rootContainer.removeContainer(container)	//remove containers
						//re-add to same position
						//note: this approach means they will not be part of the same container
						for (i = 0; i < filtered.length; ++i) {
							addPanelToSideSequence(filtered[i], rootContainer, sideSequences[i])
						}
						originalWindow = getContainerWindow(rootContainer)
						newWindow = getContainerWindow(moveExistingPanelsFrom(dockablePanels, rootContainer, getFirstPanel))
						if (originalWindow && originalWindow != newWindow) {
							originalWindow.visible = false;
						}
					}
				}
			}
			
			if (cl_dragStruct) {
				cl_dragStruct.updateStageCoordinates(evt.stageX, evt.stageY)
			}
		}
		
		/**
		 * Performs a lazy initialization of the container from the given window, if it does not exist and should be created.
		 * @param	window	The window to lookup.
		 * @param	createIfNotExist	Creates a new container for the given window if this parameter is true and it does not exist; if false, it performs a simple lookup which may fail (i.e. return undefined)
		 * @return
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
		 * @param	createIfNotExist	Creates the window if this parameter is true and the window does not yet exist; if this parameter is false, it performs a simple lookup which may fail (i.e. return undefined)
		 * @return
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
		 * @inheritDoc
		 */
		public function getPanelStateInfo(panel:IPanel):IReadablePanelStateInformation {
			return getInternalPanelStateInfo(panel) as IReadablePanelStateInformation
		}
		
		/**
		 * Performs a lazy initialization of the PanelStateInformation for the given panel.
		 * @param	panel
		 * @return
		 */
		private function getInternalPanelStateInfo(panel:IPanel):PanelStateInformation {
			return dct_panelStateInfo[panel] ||= new PanelStateInformation()
		}
		
		private function addContainerListeners(container:IContainer):void
		{
			container.addEventListener(PanelContainerEvent.DRAG_REQUESTED, startDragOnEvent, false, 0, true)
			container.addEventListener(PanelContainerEvent.STATE_TOGGLE_REQUESTED, togglePanelStateOnEvent, false, 0, true)
			container.addEventListener(PanelContainerEvent.REMOVE_REQUESTED, removeContainerIfEmpty, false, 0, true)
			container.addEventListener(PanelContainerEvent.CONTAINER_CREATED, registerContainerOnCreate, false, 0, true)
			container.addEventListener(PanelContainerEvent.SETUP_REQUESTED, customizeContainerOnSetup, false, 0, true)
			container.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, preventDockOnCrossViolation, false, 0, true)
			container.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, showDockHelperOnEvent, false, 0, true)
			container.addEventListener(NativeDragEvent.NATIVE_DRAG_EXIT, hideDockHelperOnEvent, false, 0, true)
			container.addEventListener(Event.REMOVED, addContainerListenersOnUnlink, false, 0, true)
			container.addEventListener(Event.ADDED, removeContainerListenersOnLink, false, 0, true)
			container.addEventListener(DockEvent.DRAG_COMPLETING, finishDragDockEvent, false, 0, true)
			container.addEventListener(MouseEvent.MOUSE_MOVE, showResizerOnEvent, false, 0, true)
			container.addEventListener(PanelContainerEvent.PANEL_ADDED, setRoot, false, 0, true)
		}
		
		private function preventDockOnCrossViolation(evt:NativeDragEvent):void 
		{
			if (isMatchingDockPolicy(crossDockingPolicy, CrossDockingPolicy.REJECT_INCOMING) && isForeignContainer(evt.clipboard.getData(cl_dockFormat.containerFormat, ClipboardTransferMode.ORIGINAL_ONLY) as IContainer))
			{
				//reject it if it's not allowed in policy
				evt.preventDefault()
				evt.stopImmediatePropagation()
				evt.dropAction = NativeDragActions.NONE
			}
		}
		
		/**
		 * Adds the container to the list of containers created by this Docker instance, and marks it as local, i.e. non-foreign.
		 */
		private function registerContainerOnCreate(evt:PanelContainerEvent):void 
		{
			var rootContainer:IContainer = cl_treeResolver.findRootContainer(evt.currentTarget as IContainer)
			if (!isForeignContainer(rootContainer)) {
				dct_foreignCounter[evt.relatedContainer] = false;
			}
		}
		
		/**
		 * Removes the listeners for a given container.
		 * Does not check whether it is a foreign container or not, prior to removal, since there is no effect if it is.
		 * Calling this function multiple times has no additional effect.
		 * @param	container
		 */
		private function removeContainerListeners(container:IContainer):void
		{
			container.removeEventListener(PanelContainerEvent.PANEL_ADDED, setRoot)
			container.removeEventListener(PanelContainerEvent.DRAG_REQUESTED, startDragOnEvent)
			container.removeEventListener(PanelContainerEvent.REMOVE_REQUESTED, removeContainerIfEmpty)
			container.removeEventListener(PanelContainerEvent.STATE_TOGGLE_REQUESTED, togglePanelStateOnEvent)
			container.removeEventListener(PanelContainerEvent.CONTAINER_CREATED, registerContainerOnCreate)
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
			//TODO check whether this condition works or not
			var panels:Vector.<IPanel> = container.getPanels(true);
			if (panels.length > 1 || (panels.length == 1 && panels[0] != evt.relatedPanel)) {
				return;	//has children, do not remove - either more than the panel being removed, or a different panel from that which is being removed
			}
			var parentContainer:IContainer = cl_treeResolver.findParentContainer(container as DisplayObject)
			if (parentContainer) {
				parentContainer.removeContainer(container)
			}
			container.panelList = null
		}
		
		private function removeContainerListenersOnLink(evt:Event):void 
		{
			//remove listeners if it's contained by another container, because it may have listeners too
			//if it's the root (i.e. findRootContainer(target) == target (or != evt.currentTarget), then it won't remove the listeners
			var target:IContainer = evt.target as IContainer
			var root:IContainer = cl_treeResolver.findRootContainer(target)
			if (target && !isForeignContainer(target) && root != target)
			{
				removeContainerListeners(target)
				dct_foreignCounter[target] = false;
			}
		}
		
		private function addContainerListenersOnUnlink(evt:Event):void 
		{
			//add container listeners whenever a container is going to be removed
			//and it's not already containing them (i.e. event occurs downstream)
			var target:IContainer = evt.target as IContainer
			if (target && !isForeignContainer(target) && target != evt.currentTarget)
			{
				addContainerListeners(target)
				dct_foreignCounter[target] = true
			}
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
				
				/* HOW THE RESIZER IS RESOLVED WITH RESPECT TO CONTAINERS:
				 * go up a container until it is complementary:
				 * targetContainer: check if the container's side code is T or B. then, if it is the same as targetContainer's side code
				 * for the given containers:
				 *    |------|----|   -|
				 *    |      | T  |    |
				 *    |   L  |----|    }- B
				 *    |      | B  |    |
				 *    |------|----|   -|
				 * 
				 *    |-----v-----|
				 *          |
				 *          R
				 * 
				 * suppose targetContainer is T as labeled above and need to find resizer below it
				 * side code of container = B. target container does not match, i.e. container.getSide(container.sideCode) != targetContainer
				 * (but is complementary)
				 * so display the resizer only if the side is bottom, i.e. same as container side code
				 * 
				 * suppose targetContainer is B as labeled above and need to find resizer above it
				 * side code of container = B. target container matches, i.e. container.getSide(container.sideCode) == targetContainer
				 * so display the resizer only if the side is top, i.e. complementary (but not equal) of container side code
				 * 
				 * suppose targetContainer is B or T as labeled above, and need to find resizer left of it
				 * side code of container = B. not complementary or equal, so skip up and set container = parent container, and targetContainer = container
				 * now parent container side code = R. container matches now, i.e. container.getSide(container.sideCode) == targetContainer
				 * so display the resizer only if the side is left, i.e. complementary (but not equal) of container side code
				 * 
				 * suppose targetContainer is L as labeled above and need to find resizer to the right of it
				 * side code of container = R. target container does not match i.e. container.getSide(container.sideCode) != targetContainer
				 * (but is complementary)
				 * so display the resizer only if side is right, i.e. same as container side code.
				 * 
				 * in all the above cases, there is a similarity:
				 * 
				 * 1. get targetContainer
				 * 2. is container.getSide(container.sideCode) == targetContainer?
				 * 		if yes, then display resizer only if the side is complementary - but not equal - of container side code
				 * 3. else, is the side code of container at least complementary or equal to target container?
				 * 		if yes, then display resizer only if the side is equal to the container side code
				 * 4. else, if it is neither same nor complementary (e.g. L and B or R and T)
				 * 		then set targetContainer as current container and skip currentcontainer up one level
				 * 
				 * see implementation below.
				 */
				
				var displayResizer:Boolean;
				while (container)
				{
					if (PanelContainerSide.isComplementary(side, container.sideCode))
					{
						var targetContainerEqual:Boolean = (container.getSide(container.sideCode) == targetContainer);
						var sidesMatch:Boolean = (side == container.sideCode);
						//i.e. targetContainerEqual xor sidesMatch
						displayResizer = targetContainerEqual != sidesMatch;
						break;
					}
					else
					{
						targetContainer = container;
						container = cl_treeResolver.findParentContainer(container as DisplayObject);
					}
				}
				
				point = new Point(targetContainer.x, targetContainer.y)
				if (PanelContainerSide.isComplementary(side, PanelContainerSide.TOP))
				{
					point.y += Math.round(localYPercent) * targetContainer.height
					point.x += cl_resizer.preferredXPercentage * targetContainer.width
				}
				else
				{
					point.x += Math.round(localXPercent) * targetContainer.width
					point.y += cl_resizer.preferredYPercentage * targetContainer.height
				}
				
				if (container && displayResizer)
				{
					cl_resizer.maxSize = container.getBounds(null)
					point = container.localToGlobal(point)
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
				var targetObj:DisplayObject = evt.target as DisplayObject
				if (plc_dropTarget != targetObj && cl_treeResolver.findParentContainer(targetObj) != plc_dropTarget) {
					cl_dockHelper.hide()
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
				var targetContainer:IContainer = evt.target as IContainer
				if (!targetContainer) {
					targetContainer = cl_treeResolver.findParentContainer(evt.target as DisplayObject)
				}
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
			//if it has no sides and it has panels, create a new panelList for it; otherwise, remove it
			if (!(evt.isDefaultPrevented() || isForeignContainer(rootContainer))) {
				container.panelList = ((container.hasSides || !container.hasPanels(true)) || cl_panelListFactory.createPanelList()) as IPanelList
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
			var removed:Boolean;
			var prevContainerState:Boolean;
			var prevContainer:IContainer = cl_treeResolver.findParentContainer(panel as DisplayObject)
			if (prevContainer)
			{
				prevContainerState = getAuthoritativeContainerState(prevContainer)
				prevContainer.removePanel(panel);
				if (prevContainerState == PanelContainerState.DOCKED)
				{
					var window:NativeWindow = getContainerWindow(cl_treeResolver.findRootContainer(prevContainer));
					//false for getWindowFromPanel since we're comparing - a null window cannot container the panel
					if (window && getWindowFromPanel(panel, false) == window) {
						window.visible = false
					}
				}
			}
			return !!prevContainer
		}
		
		private function shadowContainer(container:IContainer, otherContainer:IContainer):void 
		{
			var fromWindow:NativeWindow = getContainerWindow(container)
			var otherPanelWindow:NativeWindow = getContainerWindow(otherContainer)
			if (fromWindow && otherPanelWindow && otherContainer && container.hasPanels(true))
			{
				//shadow the panel with other window's panel 
				var containerHeight:Number = container.height
				var containerWidth:Number = container.width
				otherContainer.height = otherPanelWindow.stage.stageHeight = containerHeight
				otherContainer.width = otherPanelWindow.stage.stageWidth = containerWidth
				otherPanelWindow.x = fromWindow.x
				otherPanelWindow.y = fromWindow.y
				otherPanelWindow.orderInBackOf(fromWindow)
				container.mergeIntoContainer(otherContainer)
				otherPanelWindow.visible = fromWindow.visible;
			}
		}
		
		/**
		 * Moves the panels from the given container to the container of the first panel returned by the panelRetriever function. Usually, this is the getFirstPanel function.
		 * @param	excluding		The set of panels to ignore when searching for the first panel to take. 
		 * 							This is usually used whenever a docked panel is to be shadowed and the function is called before the panel is actually removed;
		 * 							then, the panel (which is to be, but has not yet, removed) is passed in the excluding parameter.
		 * 							It is also used when preventing undockable panels (i.e. panels with dockable set to false) from being moved to another container.
		 * @param	container		The container to move panels from. This is usually the container of the panel, resolved by the tree resolver.
		 * @param	panelRetriever	The panel retrieving function. This is a function which takes two parameters, (excluding, container), which returns a panel from the given container. 
		 * 							The contents of the container passed in the moveExistingPanelsFrom function is then moved into the container of the panel returned by the panelRetriever function.
		 * @return	The container into which the existing contents (excluding the panels, and by extension their containers, passed in the excluding parameter) of the container passed to this function are moved into.
		 */
		private function moveExistingPanelsFrom(excluding:Vector.<IPanel>, container:IContainer, panelRetriever:Function):IContainer
		{
			if(panelRetriever == null) {
				return null;
			}
			//suppose main panel of container ie panel's original container is removed from window
			//then get first OTHER panel that's there and then swap contents of this container with that panel's window's container
			//start with panels in the container, and then work down to left and right
			//i.e. to "leave behind" existing panels
			var toContainer:IContainer;
			var otherPanel:IPanel = panelRetriever.call(null, excluding, container)
			if (otherPanel)
			{
				toContainer = getContainerFromWindow(getWindowFromPanel(otherPanel, true), true)
				shadowContainer(container, toContainer)
			}
			return toContainer
		}
		
		/**
		 * Performs a deep search in the given container for the first panel it can find, excluding the panels supplied in the excluding parameter.
		 * @param	excluding	
		 * @param	inContainer
		 * @return
		 */
		private function getFirstPanel(excluding:Vector.<IPanel>, inContainer:IContainer):IPanel
		{
			if(!inContainer) {
				return null;
			}
			
			var result:IPanel;
			var basePanels:Vector.<IPanel> = inContainer.getPanels(false);
			if (basePanels.length)
			{
				do {
					result = basePanels.pop();	//skip over excluded panel
				} while (excluding && basePanels.length && excluding.indexOf(result) != -1);
				
				if(excluding && excluding.indexOf(result) != -1) {
					result = null;	//no more panels left, all excluded
				}
				return result
			}
			var sideCode:int = inContainer.sideCode
			if (inContainer.hasSides)
			{
				result = getFirstPanel(excluding, inContainer.getSide(sideCode))
				if(result && (!excluding || excluding.indexOf(result) == -1)) {
					return result
				}
				result = getFirstPanel(excluding, inContainer.getSide(PanelContainerSide.getComplementary(sideCode)))
				if(result && (!excluding || excluding.indexOf(result) == -1)) {
					return result
				}
			}
			return null;
		}
		
		private function startDragOnEvent(evt:PanelContainerEvent):void 
		{
			if(checkResizeOccurring() || evt.isDefaultPrevented()) {
				return;
			}
			var panel:IPanel = evt.relatedPanel;
			var container:IContainer = evt.relatedContainer || cl_treeResolver.findParentContainer(panel as DisplayObject);
			var displayContainer:DisplayObjectContainer = panel as DisplayObjectContainer
			var transferObject:Clipboard = new Clipboard();
			if (panel) {
				transferObject.setData(cl_dockFormat.panelFormat, panel, false)
			}
			if (container) {
				transferObject.setData(cl_dockFormat.containerFormat, container, false)
			}
			if (!displayContainer) {
				displayContainer = evt.relatedContainer as DisplayObjectContainer
			}
			var transform:Matrix
			var offsetPoint:Point;
			var proxyImage:BitmapData
			var maxWidth:Number = displayContainer.width
			var maxHeight:Number = displayContainer.height
			var wholeThumbHeight:int = int(num_thumbHeight)
			var wholeThumbWidth:int = int(num_thumbWidth)
			if (maxWidth && maxHeight && num_thumbHeight && num_thumbWidth && !isNaN(num_thumbHeight) && !isNaN(num_thumbWidth))
			{
				var aspect:Number = maxHeight / maxWidth
				if (num_thumbWidth > 1)
				{
					if (maxWidth > wholeThumbWidth) {
						maxWidth = wholeThumbWidth
					}
				}
				else {
					maxWidth *= num_thumbWidth
				}
				maxHeight = aspect * maxWidth
				
				if (num_thumbHeight > 1)
				{
					if (maxHeight > wholeThumbHeight) {
						maxHeight = wholeThumbHeight
					}
				}
				else {
					maxHeight *= num_thumbHeight
				}
				maxWidth = maxHeight / aspect
				if(maxHeight < 1) {
					maxHeight = 1
				}
				if(maxWidth < 1) {
					maxWidth = 1
				}
				transform = new Matrix(maxWidth / displayContainer.width, 0, 0, maxHeight / displayContainer.height)
				offsetPoint = new Point(-displayContainer.mouseX * transform.a, -displayContainer.mouseY * transform.d)
				proxyImage = new BitmapData(maxWidth, maxHeight, false)
				proxyImage.draw(displayContainer, transform)
			}
			if (container && container.stage) {	//always prefer container instead of panel since container has more accuracy in dragging
				cl_dragStruct = new DragInformation(container.stage, container.mouseX / container.width, container.mouseY / container.height)
			}
			NativeDragManager.doDrag(mainContainer, transferObject, proxyImage, offsetPoint, ALLOWED_DRAG_ACTIONS);
			evt.stopImmediatePropagation()
		}
		
		private function togglePanelStateOnEvent(evt:PanelContainerEvent):void 
		{
			if(checkResizeOccurring() || evt.isDefaultPrevented()) {
				return;
			}
			var container:IContainer = evt.relatedContainer;
			var panel:IPanel = evt.relatedPanel;
			var sideInfo:PanelStateInformation;
			var containerWindow:NativeWindow;
			var currContainer:IContainer;
			var prevState:Boolean = getAuthoritativeContainerState(container)
			if (panel)
			{
				if(!panel.dockable) {
					return;
				}
				container = cl_treeResolver.findParentContainer(panel as DisplayObject)
				if (container)
				{
					const panelList:Vector.<IPanel> = new <IPanel>[panel]
					var rootContainer:IContainer = cl_treeResolver.findRootContainer(container)
					//false for both gets() since comparison only done to check for ownership
					if (rootContainer && getContainerFromWindow(getWindowFromPanel(panel, false), false) == rootContainer) {
						moveExistingPanelsFrom(panelList, rootContainer, getFirstPanel)	//shadow container if it is being docked while it has other panels in its window+container
					}
					if (getAuthoritativeContainerState(container) == PanelContainerState.INTEGRATED)
					{
						dockPanel(panel)
						showPanel(panel)
					}
					else
					{
						sideInfo = getInternalPanelStateInfo(panel)
						addPanelToSideSequence(panel, sideInfo.previousRoot, sideInfo.integratedCode)
						containerWindow = getContainerWindow(container)
						if (containerWindow) {
							containerWindow.visible = false;
						}
					}
				}
			}
			else if (container)
			{
				if (getAuthoritativeContainerState(container) != PanelContainerState.DOCKED) {
					dockAllPanelsInContainer(filterUndockablePanels(container.getPanels(false)), container)
				}
				else
				{
					//integrate panels
					var panels:Vector.<IPanel> = filterUndockablePanels(container.getPanels(false))
					panel = panels.shift()
					if (panel)
					{
						sideInfo = getInternalPanelStateInfo(panel)
						currContainer = addPanelToSideSequence(panel, sideInfo.previousRoot, sideInfo.integratedCode)
						for (var i:uint = 0; i < panels.length; ++i) {
							currContainer.addToSide(PanelContainerSide.FILL, panels[i] as IPanel)
						}
						containerWindow = getContainerWindow(container)
						if (containerWindow) {
							containerWindow.visible = false;
						}
					}
				}
			}
			dispatchEvent(new PanelContainerStateEvent(PanelContainerStateEvent.STATE_TOGGLED, evt.relatedPanel, evt.relatedContainer, prevState, !prevState, false, false))
			trace(cl_treeResolver.findRootContainer(evt.currentTarget as IContainer).name)
		}
		
		private function addPanelToSideSequence(panel:IPanel, container:IContainer, sideCode:String):IContainer
		{
			for (var i:uint = 0, currContainer:IContainer = container; currContainer && i < sideCode.length; ++i) {
				currContainer = currContainer.fetchSide(PanelContainerSide.toInteger(sideCode.charAt(i)))
			}
			if(currContainer) {
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
		
		private function dockAllPanelsInContainer(excluding:Vector.<IPanel>, container:IContainer):void
		{
			var basePanelWindow:NativeWindow;
			var baseContainer:IContainer;
			if(!container) {
				return;
			}
			else if (getAuthoritativeContainerState(container) != PanelContainerState.DOCKED)
			{
				var originalPanels:Vector.<IPanel> = container.getPanels(false);
				var panels:Vector.<IPanel> = originalPanels.filter(function(item:IPanel, index:int, arr:Vector.<IPanel>):Boolean {
					return (!excluding || excluding.indexOf(item) == -1);	//exclude non-dockable panels from docking
				});
				if (!panels.length) {
					return;
				}
				//grab first panel in container's original window and move to that
				var currPanel:IPanel = panels[0] as IPanel;
				var parentContainer:IContainer = cl_treeResolver.findParentContainer(container as DisplayObject);
				basePanelWindow = getWindowFromPanel(currPanel, true)
				baseContainer = getContainerFromWindow(basePanelWindow, true)
				if (originalPanels.length == panels.length) {	//i.e. when no panels have been excluded from docking
					container.mergeIntoContainer(baseContainer)
				}
				else for (var i:uint = 0; i < panels.length; ++i) {
					baseContainer.addToSide(PanelContainerSide.FILL, panels[i]);
				}
				
				panels = container.getPanels(false)	//find out how many non-dockable panels remain (after docking to container)
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
			
			if (basePanelWindow)
			{
				basePanelWindow.stage.stageWidth = baseContainer.width
				basePanelWindow.stage.stageHeight = baseContainer.height
				basePanelWindow.activate()
			}
		}
		
		private function renameWindow(evt:PanelPropertyChangeEvent):void
		{
			if (evt.fieldName == "panelName")
			{
				var panel:IPanel = evt.currentTarget as IPanel;
				if (panel in dct_windows) {
					getWindowFromPanel(panel, true).title = evt.newValue as String
				}
			}
		}
		
		private function resizeContainerOnEvent(evt:NativeWindowBoundsEvent):void 
		{
			//doesn't matter if true or false since this event is only triggered by the parent window, so both have to exist
			//but keep it false just in case
			var window:NativeWindow = evt.currentTarget as NativeWindow
			var container:IContainer = getContainerFromWindow(window, false)
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
			panelStateInfo = getInternalPanelStateInfo(panel)
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
			window.addEventListener(NativeWindowBoundsEvent.RESIZE, resizeContainerOnEvent, false, 0, true)
			window.addEventListener(Event.CLOSING, preventWindowClose, false, 0, true)
		}
		
		private function removeWindowListeners(window:NativeWindow):void
		{
			window.removeEventListener(NativeWindowBoundsEvent.RESIZE, resizeContainerOnEvent)
			window.removeEventListener(Event.CLOSING, preventWindowClose)
		}
		
		private function preventWindowClose(evt:Event):void 
		{
			evt.preventDefault();
			(evt.currentTarget as NativeWindow).visible = false;
		}
		
		private function addPanelListeners(panel:IPanel):void {
			panel.addEventListener(PanelPropertyChangeEvent.PROPERTY_CHANGED, renameWindow, false, 0, true)
		}
		
		private function removePanelListeners(panel:IPanel):void {
			panel.removeEventListener(PanelPropertyChangeEvent.PROPERTY_CHANGED, renameWindow)
		}
		
		private function dockPanelOnCrossViolation(evt:Event):void 
		{
			var panel:IPanel = evt.currentTarget as IPanel
			panel.removeEventListener(Event.ADDED, dockPanelOnCrossViolation)
			if(isForeignPanel(panel)) {
				return;
			}
			var parentContainer:IContainer = cl_treeResolver.findParentContainer(panel as DisplayObject)
			var rootContainer:IContainer = cl_treeResolver.findRootContainer(parentContainer)
			//dock all panels in the parent container if cross-docking is disabled
			//i.e. so as to prevent them from being integrated into the other Docker's containers
			if (rootContainer && isForeignContainer(rootContainer))
			{
				dockPanel(panel)
				if (cl_dragStruct) {
					moveWindowTo(getWindowFromPanel(panel, true), cl_dragStruct.localX, cl_dragStruct.localY, cl_dragStruct.convertToScreen())
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
		 * @inheritDoc
		 */
		public function getPanelContainers():Vector.<IPair>
		{
			var panelContainers:Vector.<IPair> = new Vector.<IPair>()
			for (var obj:Object in dct_foreignCounter)
			{
				if (obj is IPanel) {
					panelContainers.push(new StaticPair(obj as IPanel, cl_treeResolver.findParentContainer(obj as DisplayObject)))
				}
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
			dct_foreignCounter[container] = true
			addContainerListeners(container)
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
				container = getContainerFromWindow(obj as NativeWindow, false)
				if (container)
				{
					if (panelListFactory) {
						container.panelList = panelListFactory.createPanelList()
					}
					else {
						container.panelList = null;
					}
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
				handles = dockHelper as DisplayObject
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
			baseContainer.addToSide(PanelContainerSide.FILL, panel);
			basePanelWindow.stage.stageHeight = baseContainer.height
			basePanelWindow.stage.stageWidth = baseContainer.width
			
			return baseContainer
		}
		
		/**
		 * @inheritDoc
		 */
		public function showPanel(panel:IPanel):void
		{
			//shows the panel and dispatches a change event
			//returns if everything is the same
			if(!panel) {
				return;
			}
			var container:IContainer = cl_treeResolver.findParentContainer(panel as DisplayObject)
			var dockToPreviousRoot:Boolean;
			if (container)
			{
				if (isForeignContainer(container)) {
					return;
				}
				else if (getAuthoritativeContainerState(container) == PanelContainerState.DOCKED)
				{
					var window:NativeWindow = getContainerWindow(container);
					if(window.visible) {
						return;
					}
					window.activate()
				}
				else {
					dockToPreviousRoot = true;
				}
			}
			
			if(dockToPreviousRoot || !container)
			{
				var sideInfo:PanelStateInformation = getInternalPanelStateInfo(panel)
				if(sideInfo.previousRoot == cl_treeResolver.findRootContainer(container)) {
					return;
				}
				addPanelToSideSequence(panel, sideInfo.previousRoot, sideInfo.integratedCode)
			}
			dispatchEvent(new PanelContainerStateEvent(PanelContainerStateEvent.VISIBILITY_TOGGLED, panel, cl_treeResolver.findParentContainer(panel as DisplayObject), false, true, false, false))
		}
		
		/**
		 * @inheritDoc
		 */
		public function hidePanel(panel:IPanel):void
		{
			if(!panel) {
				return;
			}
			var container:IContainer = cl_treeResolver.findParentContainer(panel as DisplayObject);
			if(!container || isForeignContainer(container)) {
				return;
			}
			else 
			{
				var sourceWindow:NativeWindow = getContainerWindow(container);
				if(getAuthoritativeContainerState(container) == PanelContainerState.DOCKED && sourceWindow && container.getPanelCount(true) == 1) {
					sourceWindow.visible = false;
				}
				else {
					container.removePanel(panel)
				}
			}
			dispatchEvent(new PanelContainerStateEvent(PanelContainerStateEvent.VISIBILITY_TOGGLED, panel, container, true, false, false, false))
		}
		
		/**
		 * @inheritDoc
		 */
		public function movePanelToContainer(panel:IPanel, container:IContainer, side:int):IContainer
		{
			var panelContainer:IContainer = cl_treeResolver.findParentContainer(panel as DisplayObject)
			if(panelContainer && container == panelContainer && side == container.sideCode) {
				return container
			}
			//false for the two below since we're comparing
			var window:NativeWindow = getWindowFromPanel(panel, false)
			var origContainer:IContainer = getContainerFromWindow(window, false)
			if (panelContainer)
			{
				panelContainer.removePanel(panel)
				if (panelContainer == origContainer) {
					window.visible = false
				}
			}
			var newSide:IContainer = container.addToSide(side, panel)
			var rootContainer:IContainer = cl_treeResolver.findRootContainer(container)
			var containerWindow:NativeWindow = getContainerWindow(rootContainer)
			if (containerWindow)
			{
				containerWindow.stage.stageHeight = rootContainer.height
				containerWindow.stage.stageWidth = rootContainer.width
			}
			return newSide
		}
		
		/**
		 * @inheritDoc
		 */
		public function isPanelVisible(panel:IPanel):Boolean
		{
			if(!panel) {
				return false;
			}
			var container:IContainer = cl_treeResolver.findParentContainer(panel as DisplayObject);
			if(!container || isForeignContainer(container)) {
				return false
			}
			else if(getAuthoritativeContainerState(container) == PanelContainerState.DOCKED) {
				return getContainerWindow(container).visible
			}
			return !!container.stage
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
				dsp_mainContainer.removeEventListener(NativeDragEvent.NATIVE_DRAG_COMPLETE, dockContainerIfInvalidDropTarget)
			}
			dsp_mainContainer = container;
			if (container)
			{
				container.addEventListener(NativeDragEvent.NATIVE_DRAG_START, preventDockIfInvalid)
				container.addEventListener(NativeDragEvent.NATIVE_DRAG_UPDATE, removeContainerOnEvent)
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
			num_thumbWidth = num_thumbHeight = NaN;
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
			return root && root.containerState	
		}
		
		/**
		 * Checks whether AIRDock is supported on the target runtime or not.
		 * Use this method to determine whether AIRDock is supported on the target runtime before creating an instance via the create() method.
		 * However, in general, any system which supports both the NativeWindow and NativeDragManager class will support AIRDock as well.
		 * @see #create()
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

internal interface IReadablePanelStateInformation
{
	function get previousRoot():IContainer;
	function get integratedCode():String
}

internal interface IWritablePanelStateInformation
{
	function set previousRoot(value:IContainer):void
	function set integratedCode(value:String):void;
}

internal class PanelStateInformation implements IReadablePanelStateInformation, IWritablePanelStateInformation
{
	private var str_integratedCode:String;
	private var plc_prevRoot:IContainer;
	public function PanelStateInformation() {
	}
	
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