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
	import flash.events.EventPhase;
	import flash.events.MouseEvent;
	import flash.events.NativeDragEvent;
	import flash.events.NativeWindowBoundsEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public final class AIRDock implements ICustomizableDocker
	{
		private static const ALLOWED_DRAG_ACTIONS:NativeDragOptions = new NativeDragOptions();
		static: {
			ALLOWED_DRAG_ACTIONS.allowLink = ALLOWED_DRAG_ACTIONS.allowCopy = false;
		};
		
		private var cl_defaultWindowOptions:NativeWindowInitOptions
		private var dsp_mainContainer:DisplayObjectContainer
		private var cl_dragStruct:DragInformation
		private var dct_containers:Dictionary
		private var dct_windows:Dictionary;
		private var num_thumbHeight:Number;
		private var num_thumbWidth:Number;
		private var cl_resizer:IResizer;
		private var cl_dockHelper:IDockHelper
		private var cl_dockFormat:IDockFormat;
		private var plc_dropTarget:IContainer;
		private var dct_panelStateInfo:Dictionary;
		private var cl_treeResolver:ITreeResolver;
		private var cl_panelFactory:IPanelFactory;
		private var cl_panelListFactory:IPanelListFactory;
		private var cl_containerFactory:IContainerFactory;
		private var cl_defaultContainerOptions:ContainerConfig;
		private var dct_containerCounter:Dictionary;
		private var i_crossDockingPolicy:int;
		public function AIRDock() {
			init()
		}
		
		private function init():void 
		{
			createDictionaries()
			dragImageWidth = dragImageHeight = 1;
			crossDockingPolicy = CrossDockingPolicy.UNRESTRICTED
		}
		
		private function createDictionaries():void 
		{
			dct_windows = new Dictionary()
			dct_containers = new Dictionary()
			dct_panelStateInfo = new Dictionary(true)
			dct_containerCounter = new Dictionary(true)
		}
		
		private function resizeNestedContainerOnEvent(evt:PanelContainerEvent):void 
		{
			var orientation:int = cl_resizer.getSideCode()
			var currContainer:IContainer = evt.relatedContainer
			var pos:Point = currContainer.globalToLocal(cl_resizer.localToGlobal(new Point()))
			var maxSize:Number, value:Number;
			switch(orientation)
			{
				case PanelContainerSide.LEFT:
				case PanelContainerSide.RIGHT:
					value = pos.x
					maxSize = currContainer.width;
					break;
				case PanelContainerSide.TOP:
				case PanelContainerSide.BOTTOM:
					value = pos.y;
					maxSize = currContainer.height;
					break;
				case PanelContainerSide.FILL:
				default:
					return;
			}
			if (0 < value && value < maxSize) {
				currContainer.sideRatio = value / maxSize
			}
		}
		
		private function finishNativeDrag(evt:DockEvent):void 
		{
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
			if(container && isForeignContainer(container) && isMatchingDockPolicy(crossDockingPolicy, CrossDockingPolicy.REJECT_INCOMING)) {
				return trace('foreign container', crossDockingPolicy, container.name);
			}
			if (relatedContainer && dockTarget)
			{
				var side:int = dockTarget.getSideFrom(dragDropTarget as DisplayObject)
				if (panel) {
					integratePanel(panel, relatedContainer, side)
				}
				else if (container)
				{
					var panels:Array = container.panels;
					for (var i:uint = 0; i < panels.length; ++i)
					{
						relatedContainer = integratePanel(panels[i] as IPanel, relatedContainer, side)
						side = PanelContainerSide.FILL //as after first, the container is made - replace with reserved container by FILL
					}
				}
			}
			plc_dropTarget = null;
			cl_dragStruct = null;
		}
		
		private function dockContainerIfInvalid(evt:NativeDragEvent):void 
		{
			if(cl_dockHelper && cl_dockHelper.parent) {
				cl_dockHelper.parent.removeChild(cl_dockHelper as DisplayObject)
			}
			var clipBoard:Clipboard = evt.clipboard
			if(!(clipBoard.hasFormat(cl_dockFormat.panelFormat) || clipBoard.hasFormat(cl_dockFormat.containerFormat))) {
				return;
			}
			var panel:IPanel = clipBoard.getData(cl_dockFormat.panelFormat, ClipboardTransferMode.ORIGINAL_ONLY) as IPanel
			var container:IContainer = clipBoard.getData(cl_dockFormat.containerFormat, ClipboardTransferMode.ORIGINAL_ONLY) as IContainer
			if (evt.dropAction != NativeDragActions.NONE || (isForeignContainer(container) && isMatchingDockPolicy(crossDockingPolicy, CrossDockingPolicy.REJECT_INCOMING))) {
				return;
			}
			
			var window:NativeWindow;
			if (panel)
			{
				window = getWindowFromPanel(panel, true)
				dockPanel(panel)
			}
			else if (container)
			{
				window = getWindowFromContainer(container)
				if (window) {
					window.visible = true
				}
				else
				{
					var panels:Array = container.panels;
					if (panels.length) {
						window = getWindowFromPanel(panels[0] as IPanel, true)
					}
					dockAllPanelsInContainer(container)	//grab first panel in container's window and move to that
				}
			}
			
			if (window && cl_dragStruct)
			{
				var winPoint:Point = cl_dragStruct.dragStage.nativeWindow.globalToScreen(new Point(evt.stageX, evt.stageY))
				var chromeOffset:Point = window.globalToScreen(new Point(cl_dragStruct.localX * window.stage.stageWidth, cl_dragStruct.localY * window.stage.stageHeight))
				window.x += winPoint.x - chromeOffset.x;
				window.y += winPoint.y - chromeOffset.y;
				cl_dragStruct = null;
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
				return;
			}
			else if (panel)
			{
				rootContainer = cl_treeResolver.findRootContainer(cl_treeResolver.findParentContainer(panel as DisplayObject))
				if (rootContainer)
				{
					originalWindow = getWindowFromPanel(panel, false)		//false since we're comparing -- a panel which has never had a window created
					if (getContainerFromWindow(originalWindow, false) == rootContainer)	//cannot be the container/stage of the panel
					{
						moveExistingPanelsFrom(panel, rootContainer, getFirstPanel);
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
				var containerWindow:NativeWindow = getWindowFromContainer(container)
				rootContainer = cl_treeResolver.findRootContainer(container)
				if ((rootContainer && rootContainer != container) || (containerWindow && containerWindow.visible))
				{
					function dockContainerOnCrossViolation(evt:Event):void
					{
						var currentFunction:Function = arguments.callee
						var currPanel:IPanel = evt.currentTarget as IPanel
						var rootContainer:IContainer = cl_treeResolver.findRootContainer(cl_treeResolver.findParentContainer(currPanel as DisplayObject))
						//dock all panels in the parent container if cross-docking is disabled
						//i.e. so as to prevent them from being integrated into the other Docker's containers
						if (!crossDockingPolicy && rootContainer && isForeignContainer(rootContainer))
						{
							integratePanel(currPanel, parkedContainer, PanelContainerSide.FILL)
							dockAllPanelsInContainer(parkedContainer)
						}
						currPanel.removeEventListener(Event.ADDED, currentFunction)
					}
					
					var panels:Array = container.panels
					if (isMatchingDockPolicy(crossDockingPolicy, CrossDockingPolicy.PREVENT_OUTGOING) && panels && panels.length)
					{
						//selects the first panel* and docks all the panels in the current container to the parked container's window
						//when it gets added to stage, if there's a violation in crossDocking policy
						//*note - it can be any panel from the list of panels, since they are all being docked to the same container
						var parkedContainer:IContainer = getContainerFromWindow(getWindowFromPanel(panels[0] as IPanel, true), true)
						for (var i:uint = 0; i < panels.length; ++i)
						{
							var currPanel:IPanel = panels[i] as IPanel;
							currPanel.removeEventListener(Event.ADDED, dockPanelOnCrossViolation)
							currPanel.addEventListener(Event.ADDED, dockContainerOnCrossViolation);
						}
					}
					
					if (containerWindow) {
						containerWindow.visible = false;
					}
					else
					{
						rootContainer.removeContainer(container)
						originalWindow = getWindowFromContainer(rootContainer)
						newWindow = getWindowFromContainer(moveExistingPanelsFrom(null, rootContainer, getFirstPanel))
						if (originalWindow && originalWindow != newWindow) {
							originalWindow.visible = false;
						}
					}
				}
			}
		}
		
		public function setupPanel(panel:IPanel):void {
			addPanelListeners(panel)
		}
		
		public function unhookPanel(panel:IPanel):void
		{
			if(!panel) {
				return;
			}
			delete dct_panelStateInfo[panel];
			removePanelListeners(panel)
		}
		
		public function createPanel(options:PanelConfig):IPanel
		{
			var panel:IPanel = cl_panelFactory.createPanel(options)
			setupPanel(panel)
			return panel
		}
		
		public function createWindow(panel:IPanel):NativeWindow
		{
			if(!panel) {
				return null
			}
			
			var options:NativeWindowInitOptions = defaultWindowOptions
			options.resizable = panel.resizable
			
			var window:NativeWindow = new NativeWindow(options)
			var stage:Stage = window.stage
			addWindowListeners(window)
			dct_windows[panel] = window
			window.title = panel.panelName
			stage.align = StageAlign.TOP_LEFT
			stage.scaleMode = StageScaleMode.NO_SCALE
			return window
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
				var panel:IPanel = getPanelFromWindow(window)
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
		
		private function getPanelFromWindow(window:NativeWindow):IPanel
		{
			for (var panel:Object in dct_windows)
			{
				if (dct_windows[panel] == window) {
					return panel as IPanel
				}
			}
			return null;
		}
		
		private function getWindowFromContainer(container:IContainer):NativeWindow
		{
			for (var window:Object in dct_containers)
			{
				if (dct_containers[window] == container) {
					return window as NativeWindow;
				}
			}
			return null;
		}
		
		/**
		 * Performs a lazy initialization of the window of the given panel if it should be created, or a simple lookup otherwise.
		 * @param	panel	The panel whose window should be retrieved.
		 * @param	createIfNotExist	Creates the window if this parameter is true and the window does not yet exist; if this parameter is false, it performs a simple lookup which may fail (i.e. return undefined)
		 * @return
		 */
		private function getWindowFromPanel(panel:IPanel, createIfNotExist:Boolean = true):NativeWindow {
			return dct_windows[panel] ||= createIfNotExist ? createWindow(panel) : null;
		}
		
		/**
		 * Performs a lazy initialization of the PanelStateInformation for the given panel.
		 * @param	panel
		 * @return
		 */
		private function getPanelStateInfo(panel:IPanel):PanelStateInformation {
			return dct_panelStateInfo[panel] ||= new PanelStateInformation()
		}
		
		public function createContainer(options:ContainerConfig):IContainer
		{
			var container:IContainer = cl_containerFactory.createContainer(options)
			container.panelList = cl_panelListFactory.createPanelList()
			dct_containerCounter[container] = true
			addContainerListeners(container)
			return container
		}
		
		private function addContainerListeners(container:IContainer):void
		{
			container.addEventListener(PanelContainerEvent.DRAG_REQUESTED, startDragOnEvent, false, 0, true)
			container.addEventListener(PanelContainerEvent.STATE_TOGGLED, togglePanelStateOnEvent, false, 0, true)
			container.addEventListener(PanelContainerEvent.REMOVE_REQUESTED, removeContainerIfEmpty, false, 0, true)
			container.addEventListener(PanelContainerEvent.CONTAINER_CREATED, registerContainerOnCreate, false, 0, true)
			container.addEventListener(PanelContainerEvent.SETUP_REQUESTED, customizeContainerOnSetup, false, 0, true)
			container.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, showDockHelperOnEvent, false, 0, true)
			container.addEventListener(NativeDragEvent.NATIVE_DRAG_EXIT, hideDockHelperOnEvent, false, 0, true)
			container.addEventListener(Event.REMOVED, addContainerListenersOnUnlink, false, 0, true)
			container.addEventListener(Event.ADDED, removeContainerListenersOnLink, false, 0, true)
			container.addEventListener(DockEvent.DRAG_COMPLETED, finishNativeDrag, false, 0, true)
			container.addEventListener(MouseEvent.MOUSE_MOVE, showResizerOnEvent, false, 0, true)
			container.addEventListener(PanelContainerEvent.PANEL_ADDED, setRoot, false, 0, true)
		}
		
		/**
		 * Adds the container to the list of containers created by this Docker instance, and marks it as local, i.e. non-foreign.
		 */
		private function registerContainerOnCreate(evt:PanelContainerEvent):void 
		{
			var rootContainer:IContainer = cl_treeResolver.findRootContainer(evt.currentTarget as IContainer)
			if (!isForeignContainer(rootContainer)) {
				dct_containerCounter[evt.relatedContainer] = false;
			}
		}
		
		private function removeContainerListeners(container:IContainer):void
		{
			container.removeEventListener(PanelContainerEvent.PANEL_ADDED, setRoot)
			container.removeEventListener(PanelContainerEvent.DRAG_REQUESTED, startDragOnEvent)
			container.removeEventListener(PanelContainerEvent.STATE_TOGGLED, togglePanelStateOnEvent)
			container.removeEventListener(PanelContainerEvent.REMOVE_REQUESTED, removeContainerIfEmpty)
			container.removeEventListener(PanelContainerEvent.CONTAINER_CREATED, registerContainerOnCreate)
			container.removeEventListener(PanelContainerEvent.SETUP_REQUESTED, customizeContainerOnSetup)
			container.removeEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, showDockHelperOnEvent)
			container.removeEventListener(NativeDragEvent.NATIVE_DRAG_EXIT, hideDockHelperOnEvent)
			container.removeEventListener(Event.REMOVED, addContainerListenersOnUnlink)
			container.removeEventListener(Event.ADDED, removeContainerListenersOnLink)
			container.removeEventListener(DockEvent.DRAG_COMPLETED, finishNativeDrag)
			container.removeEventListener(MouseEvent.MOUSE_MOVE, showResizerOnEvent)
		}
		
		private function removeContainerIfEmpty(evt:PanelContainerEvent):void
		{
			var container:IContainer = evt.relatedContainer as IContainer
			
			//TODO handle this condition - it should check after the panel is removed
			if (container.hasPanels(true)) {
			//	return;	//has children, do not remove
			}
			var parentContainer:IContainer = cl_treeResolver.findParentContainer(container as DisplayObject)
			if (parentContainer) {
				parentContainer.removeContainer(container)
			}
			container.resetContainer()
		}
		
		private function removeContainerListenersOnLink(evt:Event):void 
		{
			//remove listeners if it's contained by another container, because it may have listeners too
			//if it's the root (i.e. findRootContainer(target) == target (or != evt.currentTarget), then it won't remove the listeners
			var target:IContainer = evt.target as IContainer
			var root:IContainer = cl_treeResolver.findRootContainer(target)
			if (target && !isForeignContainer(target) && root != target && root == evt.currentTarget)
			{
				removeContainerListeners(target)
				dct_containerCounter[target] = false;
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
				dct_containerCounter[target] = true
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
				var tolerance:Number = cl_resizer.tolerance
				var point:Point = new Point(targetContainer.x, targetContainer.y)
				var localXPercent:Number = targetContainer.mouseX / targetContainer.width
				var localYPercent:Number = targetContainer.mouseY / targetContainer.height
				if (localXPercent <= tolerance || localXPercent >= (1 - tolerance))
				{
					point.x += Math.round(localXPercent) * targetContainer.width
					point.y += cl_resizer.preferredYPercentage * targetContainer.height
					if (localXPercent <= tolerance) {
						side = PanelContainerSide.LEFT
					}
					else {
						side = PanelContainerSide.RIGHT
					}
				}
				else if (localYPercent <= tolerance || localYPercent >= (1 - tolerance))
				{
					point.y += Math.round(localYPercent) * targetContainer.height
					point.x += cl_resizer.preferredXPercentage * targetContainer.width
					if (localYPercent <= tolerance) {
						side = PanelContainerSide.TOP
					}
					else {
						side = PanelContainerSide.BOTTOM
					}
				}
				else 
				{
					if(cl_resizer.parent) {
						cl_resizer.parent.removeChild(cl_resizer as DisplayObject)
					}
					return;
				}
				
				if (!PanelContainerSide.isComplementary(container.currentSideCode, side)) {
					return;
				}
				else while(container && (!PanelContainerSide.isComplementary(container.currentSideCode, side) || container.currentSideCode == side)) {
					container = cl_treeResolver.findParentContainer(container as DisplayObject)
				}
				if (container)
				{
					cl_resizer.maxSize = container.getBounds(null)
					point = container.localToGlobal(point)
					cl_resizer.setContainer(container)
					cl_resizer.setSideCode(side)
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
					cl_dockHelper.hideAll()
				}
			}
		}
		
		private function showDockHelperOnEvent(evt:NativeDragEvent):void 
		{
			if(!cl_dockHelper) {
				return;
			}
			else if (evt.currentTarget == cl_dockHelper) {
				(evt.currentTarget as IDockHelper).showAll()
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
					cl_dockHelper.hideAll()
				}
			}
		}
		
		private function customizeContainerOnSetup(evt:PanelContainerEvent):void
		{
			var container:IContainer = evt.relatedContainer;
			var rootContainer:IContainer = evt.currentTarget as IContainer
			//don't modify foreign container's containers, since that container's Docker will already have listeners for it
			if (!isForeignContainer(rootContainer))
			{
				//if it has no sides and it has panels, create a new panelList for it; otherwise, remove it
				container.panelList = ((container.hasSides || !container.hasPanels(true)) || cl_panelListFactory.createPanelList()) as IPanelList
			}
		}
		
		public function setPanelFactory(panelFactory:IPanelFactory):void
		{
			if(!panelFactory) {
				throw new ArgumentError("Error: Argument panelFactory must be a non-null value.");
			}
			else {
				cl_panelFactory = panelFactory
			}
		}
		
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
		 * Convenience function for removing the panel list UI for all containers.
		 */
		public function unsetPanelListFactory():void {
			setPanelListFactory(null)
		}
		
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
		 * Sets the dock helper UI for allowing the user to dock panels and containers.
		 * Setting this to null will effectively prevent the user from docking panels and containers, but will not prevent programmatic docking.
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
				if (handles)
				{
					dockHelper.draw(dockHelper.getDefaultWidth(), dockHelper.getDefaultHeight());
					addDockHelperListeners(dockHelper);
				}
			}
		}
		
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
					var window:NativeWindow = getWindowFromContainer(cl_treeResolver.findRootContainer(prevContainer));
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
			var fromWindow:NativeWindow = getWindowFromContainer(container)
			var otherPanelWindow:NativeWindow = getWindowFromContainer(otherContainer)
			if (fromWindow && otherPanelWindow && otherContainer && container.hasPanels(true))
			{
				//shadow the panel with other window's panel 
				var containerHeight:Number = container.height
				var containerWidth:Number = container.width
				otherContainer.height = otherPanelWindow.stage.stageHeight = containerHeight
				otherContainer.width = otherPanelWindow.stage.stageWidth = containerWidth
				otherPanelWindow.visible = fromWindow.visible;
				otherPanelWindow.x = fromWindow.x
				otherPanelWindow.y = fromWindow.y
				container.mergeIntoContainer(otherContainer)
				otherPanelWindow.orderInBackOf(fromWindow)
			}
		}
		
		/**
		 * Moves the panels from the given container to the container of the first panel returned by the panelRetriever function. Usually, this is the getFirstPanel function.
		 * @param	excluding		The panel to ignore when searching for the first panel to take. This is usually used whenever a docked panel is to be shadowed and the function is called before the panel is actually removed;
		 * 							then, the panel (which is to be, but has not yet, removed) is passed in the excluding parameter.
		 * @param	container		The container to move panels from. This is usually the container of the panel, resolved by the tree resolver.
		 * @param	panelRetriever	The panel retrieving function. This is a function which takes two parameters, (excluding, container), which returns a panel from the given container. 
		 * 							The contents of the container passed in the moveExistingPanelsFrom function is then moved into the container of the panel returned by the panelRetriever function.
		 * @return	The container into which the existing contents (excluding the panel, and by extension its container, passed in the excluding parameter) of the container passed to this function are moved into.
		 */
		private function moveExistingPanelsFrom(excluding:IPanel, container:IContainer, panelRetriever:Function):IContainer
		{
			var window:NativeWindow = getWindowFromContainer(container)
			if(!(window && panelRetriever != null)) {
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
		 * Performs a deep search in the given container for the first panel it can find, excluding the panel supplied in the excluding parameter.
		 * @param	excluding	
		 * @param	inContainer
		 * @return
		 */
		private function getFirstPanel(excluding:IPanel, inContainer:IContainer):IPanel
		{
			if(!inContainer) {
				return null;
			}
			
			var result:IPanel;
			var basePanels:Array = inContainer.panels;
			if (basePanels.length)
			{
				result = basePanels.pop()
				while(excluding && basePanels.length && excluding == result) {
					result = basePanels.pop();	//skip over excluded panel
				}
				return result
			}
			var currentSideCode:int = inContainer.currentSideCode
			if (inContainer.hasSides)
			{
				result = getFirstPanel(excluding, inContainer.getSide(currentSideCode))
				if(result && result != excluding) {
					return result
				}
				result = getFirstPanel(excluding, inContainer.getSide(PanelContainerSide.getComplementary(currentSideCode)))
				if(result && result != excluding) {
					return result
				}
			}
			return null;
		}
		
		private function startDragOnEvent(evt:PanelContainerEvent):void 
		{
			if(checkResizeOccurring()) {
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
			if(checkResizeOccurring()) {
				return;
			}
			var container:IContainer = evt.relatedContainer;
			var panel:IPanel = evt.relatedPanel;
			var sideInfo:PanelStateInformation;
			var containerWindow:NativeWindow;
			var currContainer:IContainer;
			if (panel)
			{
				container = cl_treeResolver.findParentContainer(panel as DisplayObject)
				if (container)
				{
					var rootContainer:IContainer = cl_treeResolver.findRootContainer(container)
					//false for both gets() since comparison only done to check for ownership
					if (rootContainer && getContainerFromWindow(getWindowFromPanel(panel, false), false) == rootContainer) {
						moveExistingPanelsFrom(panel, rootContainer, getFirstPanel)	//shadow container if it is being docked while it has other panels in its window+container
					}
					if (getAuthoritativeContainerState(container) == PanelContainerState.INTEGRATED) {
						dockPanel(panel)
					}
					else
					{
						sideInfo = getPanelStateInfo(panel)
						addPanelToSides(panel, sideInfo.previousRoot, sideInfo.integratedCode)
						containerWindow = getWindowFromContainer(container)
						if (containerWindow) {
							containerWindow.visible = false;
						}
					}
				}
			}
			else if (container)
			{
				if (getAuthoritativeContainerState(container) == PanelContainerState.INTEGRATED) {
					dockAllPanelsInContainer(container)
				}
				else
				{
					var panels:Array = container.panels
					panel = panels.shift()
					if (panel)
					{
						sideInfo = getPanelStateInfo(panel)
						currContainer = addPanelToSides(panel, sideInfo.previousRoot, sideInfo.integratedCode)
						for (var i:uint = 0; i < panels.length; ++i) {
							currContainer.addToSide(PanelContainerSide.FILL, panels[i] as IPanel)
						}
						containerWindow = getWindowFromContainer(container)
						if (containerWindow) {
							containerWindow.visible = false;
						}
					}
				}
			}
		}
		
		private function addPanelToSides(panel:IPanel, container:IContainer, sideCode:String):IContainer
		{
			for (var i:uint = 0, currContainer:IContainer = container; currContainer && i < sideCode.length; ++i) {
				currContainer = currContainer.addToSide(PanelContainerSide.toInteger(sideCode.charAt(i)), panel)
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
		
		public function dockPanel(panel:IPanel):void 
		{
			var basePanelWindow:NativeWindow = getWindowFromPanel(panel, true)
			var baseContainer:IContainer = getContainerFromWindow(basePanelWindow, true)
			baseContainer.addToSide(PanelContainerSide.FILL, panel);
			basePanelWindow.stage.stageHeight = baseContainer.height
			basePanelWindow.stage.stageWidth = baseContainer.width
			basePanelWindow.activate();
		}
		
		private function dockAllPanelsInContainer(container:IContainer):void
		{
			var basePanelWindow:NativeWindow;
			var baseContainer:IContainer;
			if(!container) {
				return;
			}
			else if (getAuthoritativeContainerState(container) != PanelContainerState.DOCKED)
			{
				var panels:Array = container.panels;
				if (!panels.length) {
					return;
				}
				//grab first panel in container's original window and move to that
				var currPanel:IPanel = panels[0] as IPanel;
				var parentContainer:IContainer = cl_treeResolver.findParentContainer(container as DisplayObject);
				basePanelWindow = getWindowFromPanel(currPanel, true)
				baseContainer = getContainerFromWindow(basePanelWindow, true)
				container.mergeIntoContainer(baseContainer)
				if (parentContainer) {
					parentContainer.removeContainer(container)
				}
			}
			else
			{
				baseContainer = container
				basePanelWindow = getWindowFromContainer(container)
			}
			
			if (basePanelWindow)
			{
				basePanelWindow.stage.stageWidth = baseContainer.width
				basePanelWindow.stage.stageHeight = baseContainer.height
				basePanelWindow.activate()
			}
		}
		
		public function integratePanel(panel:IPanel, container:IContainer, side:int):IContainer
		{
			var panelContainer:IContainer = cl_treeResolver.findParentContainer(panel as DisplayObject)
			if(panelContainer && container == panelContainer && side == container.currentSideCode) {
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
			var containerWindow:NativeWindow = getWindowFromContainer(rootContainer)
			if (containerWindow)
			{
				containerWindow.stage.stageHeight = rootContainer.height
				containerWindow.stage.stageWidth = rootContainer.width
			}
			return newSide
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
		
		public function set crossDockingPolicy(policyFlags:int):void {
			i_crossDockingPolicy = policyFlags
		}
		
		public function get crossDockingPolicy():int {
			return i_crossDockingPolicy
		}
		
		public function get mainContainer():DisplayObjectContainer {
			return dsp_mainContainer;
		}
		
		public function set mainContainer(container:DisplayObjectContainer):void
		{
			if (dsp_mainContainer)
			{
				dsp_mainContainer.removeEventListener(NativeDragEvent.NATIVE_DRAG_UPDATE, removeContainerOnEvent)
				dsp_mainContainer.removeEventListener(NativeDragEvent.NATIVE_DRAG_COMPLETE, dockContainerIfInvalid)
			}
			dsp_mainContainer = container;
			if (container)
			{
				container.addEventListener(NativeDragEvent.NATIVE_DRAG_UPDATE, removeContainerOnEvent)
				container.addEventListener(NativeDragEvent.NATIVE_DRAG_COMPLETE, dockContainerIfInvalid)
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
			panelStateInfo = getPanelStateInfo(panel)
			panelStateInfo.integratedCode = currentCode;
			panelStateInfo.previousRoot = root;
			
			//BUG here - incorrect code set for foreign panels
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
		
		public function get dragImageHeight():Number {
			return num_thumbHeight
		}
		
		public function set dragImageHeight(value:Number):void {
			num_thumbHeight = value;
		}
		
		public function get dragImageWidth():Number {
			return num_thumbWidth
		}
		
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
			unsetPanelListFactory();
			plc_dropTarget = null;
			dockHelper = null;
		}
		
		public function set dragImageWidth(value:Number):void {
			num_thumbWidth = value
		}
		
		private function addWindowListeners(window:NativeWindow):void {
			window.addEventListener(NativeWindowBoundsEvent.RESIZE, resizeContainerOnEvent)
		}
		
		private function addPanelListeners(panel:IPanel):void {
			panel.addEventListener(PanelPropertyChangeEvent.PROPERTY_CHANGED, renameWindow, false, 0, true)
		}
		
		private function dockPanelOnCrossViolation(evt:Event):void 
		{
			var panel:IPanel = evt.currentTarget as IPanel
			var parentContainer:IContainer = cl_treeResolver.findParentContainer(panel as DisplayObject)
			var rootContainer:IContainer = cl_treeResolver.findRootContainer(parentContainer)
			//dock all panels in the parent container if cross-docking is disabled
			//i.e. so as to prevent them from being integrated into the other Docker's containers
			if (!crossDockingPolicy && rootContainer && isForeignContainer(rootContainer)) {
				dockPanel(panel)
			}
			panel.removeEventListener(Event.ADDED, dockPanelOnCrossViolation)
		}
		
		private function removePanelListeners(panel:IPanel):void {
			panel.removeEventListener(PanelPropertyChangeEvent.PROPERTY_CHANGED, renameWindow)
		}
		
		public static function get isSupported():Boolean {
			return NativeWindow.isSupported && NativeDragManager.isSupported;
		}
		
		public function get defaultWindowOptions():NativeWindowInitOptions {
			return cl_defaultWindowOptions;
		}
		
		public function set defaultWindowOptions(value:NativeWindowInitOptions):void
		{
			if(!value) {
				throw new ArgumentError("Error: Option defaultWindowOptions must be a non-null value.")
			}
			else {
				cl_defaultWindowOptions = value;
			}
		}
		
		public function get defaultContainerOptions():ContainerConfig {
			return cl_defaultContainerOptions;
		}
		
		public function set defaultContainerOptions(value:ContainerConfig):void 
		{
			if(!value) {
				throw new ArgumentError("Error: Option defaultContainerOptions must be a non-null value.")
			}
			else {
				cl_defaultContainerOptions = value;
			}
		}
		
		public function get dockFormat():IDockFormat {
			return cl_dockFormat;
		}
		
		public function set dockFormat(value:IDockFormat):void 
		{
			if(!value) {
				throw new ArgumentError("Error: Option dockFormat must be a non-null value.")
			}
			else {
				cl_dockFormat = value;
			}
		}
		
		public function set treeResolver(value:ITreeResolver):void 
		{
			if(!value) {
				throw new ArgumentError("Error: Option treeResolver must be a non-null value.")
			}
			else {
				cl_treeResolver = value;
			}
		}
		
		[Inline]
		private function isForeignContainer(container:IContainer):Boolean {
			return !(container in dct_containerCounter)
		}
		
		/**
		 * Get authoritative container state from root container:
		 * 	a container that is part of a docked container will be docked
		 * 	and a container that is part of an integrated container will be integrated
		 * @param	container
		 * @return	The state of the container.
		 */
		[Inline]
		private function getAuthoritativeContainerState(container:IContainer):Boolean {
			return cl_treeResolver.findRootContainer(container).containerState	
		}
		
		[Inline]
		private function isMatchingDockPolicy(crossDockingPolicy:int, flag:int):Boolean {
			return (crossDockingPolicy & flag) != 0;
		}
		
		public static function create(options:DockConfig):ICustomizableDocker
		{
			if (!(options && options.mainContainer && options.defaultWindowOptions && options.treeResolver))
			{
				var reason:String = "Invalid options: "
				if(!options) {
					reason += "Options must be non-null."
				}
				else 
				{
					if(!options.mainContainer) {
						reason += "Option mainContainer must be a non-null value. ";
					}
					if(!options.defaultWindowOptions) {
						reason += "Option defaultWindowOptions must be a non-null value. ";
					}
					if(!options.treeResolver) {
						reason += "Option treeResolver must be a non-null value. ";
					}
				}
				throw new ArgumentError(reason)
			}
			else if(!isSupported) {
				throw new IllegalOperationError("Error: AIRDock is not supported on the current system.");
			}
			var dock:AIRDock = new AIRDock()
			dock.setPanelFactory(options.panelFactory)
			dock.setPanelListFactory(options.panelListFactory)
			dock.setContainerFactory(options.containerFactory)
			dock.defaultWindowOptions = options.defaultWindowOptions
			dock.defaultContainerOptions = options.defaultContainerOptions
			dock.crossDockingPolicy = options.crossDockingPolicy
			dock.mainContainer = options.mainContainer
			dock.treeResolver = options.treeResolver
			dock.resizeHelper = options.resizeHelper
			dock.dockFormat = options.dockFormat
			dock.dockHelper = options.dockHelper
			if (dock.mainContainer.stage) {
				dock.defaultWindowOptions.owner = dock.mainContainer.stage.nativeWindow
			}
			if (!(isNaN(options.dragImageWidth) || isNaN(options.dragImageHeight)))
			{
				dock.dragImageHeight = options.dragImageHeight
				dock.dragImageWidth = options.dragImageWidth
			}
			return dock as ICustomizableDocker
		}
		
	}
	
}

import airdock.interfaces.docking.IContainer;
import flash.display.Stage;
internal class DragInformation
{
	private var st_dragStage:Stage;
	private var num_localX:Number;
	private var num_localY:Number;
	public function DragInformation(stage:Stage, localX:Number, localY:Number)
	{
		st_dragStage = stage;
		num_localX = localX;
		num_localY = localY;
	}
	
	public function get dragStage():Stage {
		return st_dragStage;
	}
	
	public function get localX():Number {
		return num_localX;
	}
	
	public function get localY():Number {
		return num_localY;
	}
}

internal class PanelStateInformation
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