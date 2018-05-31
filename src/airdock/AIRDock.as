package airdock
{
	import airdock.config.ContainerConfig;
	import airdock.config.DockConfig;
	import airdock.config.PanelConfig;
	import airdock.enums.CrossDockingPolicy;
	import airdock.enums.PanelContainerSide;
	import airdock.enums.PanelContainerState;
	import airdock.events.PanelContainerEvent;
	import airdock.events.PanelContainerStateEvent;
	import airdock.events.PropertyChangeEvent;
	import airdock.interfaces.docking.IBasicDocker;
	import airdock.interfaces.strategies.IDockerStrategy;
	import airdock.util.IDisposable;
	import airdock.interfaces.docking.IContainer;
	import airdock.interfaces.docking.ICustomizableDocker;
	import airdock.interfaces.docking.IDockFormat;
	import airdock.interfaces.docking.IPanel;
	import airdock.interfaces.docking.ITreeResolver;
	import airdock.interfaces.factories.IContainerFactory;
	import airdock.interfaces.factories.IPanelFactory;
	import airdock.interfaces.factories.IPanelListFactory;
	import airdock.interfaces.ui.IDockHelper;
	import airdock.interfaces.ui.IPanelList;
	import airdock.interfaces.ui.IResizer;
	import airdock.impl.strategies.DockHelperStrategy;
	import airdock.impl.strategies.ResizerStrategy;
	import airdock.util.IPair;
	import airdock.util.PropertyChangeProxy;
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
	[Event(name="pcPanelVisibilityToggled", type="airdock.events.PanelContainerStateEvent")]
	
	/**
	 * Dispatched whenever a panel is moved to its parked container (docked), or when it is moved into another container which is not its own parked container (integrated).
	 */
	[Event(name="pcPanelStateToggled", type="airdock.events.PanelContainerStateEvent")]
	
	/**
	 * Dispatched whenever an IContainer instance is about to be created by the current Docker, using the IContainerFactory instance available to it.
	 * Can be canceled to prevent default action.
	 */
	[Event(name="pcContainerCreating", type="airdock.events.PanelContainerEvent")]
	
	/**
	 * Dispatched when an IContainer instance has been created by the current Docker using the IContainerFactory instance available to it.
	 * However, if it has been created via the createContainer() method, then this is dispatched before the function returns.
	 * This can then be used to customize or apply other operations on the container before it is actually used.
	 */
	[Event(name="pcContainerCreated", type="airdock.events.PanelContainerEvent")]
	
	/**
	 * The constant used to define a removed event.
	 * Is dispatched whenever a container (which has requested to be removed) has been removed from its parent container.
	 * Containers which are removed from their parent containers (and are not parked) are unreachable and can be safely disposed of.
	 */
	[Event(name="pcContainerRemoved", type="airdock.events.PanelContainerEvent")]
	
	/**
	 * Implementation of ICustomizableDocker (and by extension, IBasicDocker) which manages the main docking panels mechanism.
	 * 
	 * @author	Gimmick
	 * @see	airdock.interfaces.docking.IBasicDocker
	 * @see	airdock.interfaces.docking.ICustomizableDocker
	 */
	public final class AIRDock implements ICustomizableDocker, IDisposable
	{
		/**
		 * The list of allowed NativeDragActions for docking.
		 * Currently, only MOVE is allowed.
		 */
		private const cl_allowedDragActions:NativeDragOptions = new NativeDragOptions();
		/**
		 * Delegate event dispatcher instance.
		 */
		private var cl_dispatcher:IEventDispatcher;
		/**
		 * Used to determine the final position of the window of the panel or container being dragged.
		 * Without this, the position of the window at the end of a drag-dock operation is not consistent with the mouse location.
		 */
		private var cl_dragStruct:DragInformation;
		/**
		 * A Dictionary of all the containers local to this Docker instance.
		 */
		private var dct_containers:Dictionary;
		/**
		 * A Dictionary of all the NativeWindow instances created by this docker via the createWindow() method.
		 */
		private var dct_windows:Dictionary;
		/**
		 * The panel state information for each panel local to this Docker.
		 * Lists the previous (non-parked) container it was attached to, with its relative distance.
		 * @see PanelStateInformation
		 */
		private var dct_panelStateInfo:Dictionary;
		/**
		 * Is used to decide whether panels and containers are foreign to the current Docker instance or not.
		 * The key is more important than the value, since the mere existence of a key marks it as local.
		 * As a result, the value does not matter, but it is taken as the presence of listeners (i.e. whether listeners have been added)
		 * This is because listeners are registered for all local panels (to mark them as local.)
		 */
		private var dct_foreignCounter:Dictionary;
		/**
		 * The default IPanelFactory instance used to create panels by this Docker.
		 */
		private var cl_panelFactory:IPanelFactory;
		/**
		 * The default IPanelListFactory instance used to creaate panel lists for each panel local to this Docker.
		 */
		private var cl_panelListFactory:IPanelListFactory;
		/**
		 * The default IContainerFactory instance used to create containers by this Docker.
		 */
		private var cl_containerFactory:IContainerFactory;
		/**
		 * Dispatches events whenever a public property changes within this class, which can be intercepted and prevented.
		 * @see	airdock.util.PropertyChangeProxy
		 */
		private var cl_propertyChangeProxy:PropertyChangeProxy;
		/**
		 * The list of dock strategies which, taken together, let the Docker initiate, manage and terminate drag-docking operations.
		 * Currently, the <<implemented>> dock strategies are:
			* ResizerStrategy
				* The instance which handles when and how the resizer should be shown, and how it resizes containers.
				* @see airdock.impl.strategies.ResizerStrategy
			* DockHelperStrategy
				* The instance which handles when the dock helper should be shown, and how it interfaces with the rest of the docking system.
				* NOTE: Currently, it is structured in a way that precludes use of any other drag-docking method apart from the default NativeDrag method.
				* @see airdock.impl.strategies.DockHelperStrategy
		 */
		private var vec_dockStrategies:Vector.<IDockerStrategy>
		/**
		 * Creates a new AIRDock instance.
		 * However, creating it directly is discouraged, and it is recommended to use the static create() function instead.
		 * 
		 * @see airdock.AIRDock#create
		 */
		public function AIRDock() {
			init()
		}
		
		private function init():void 
		{
			dct_windows = new Dictionary()
			dct_containers = new Dictionary()
			dct_panelStateInfo = new Dictionary(true)
			dct_foreignCounter = new Dictionary(true)
			cl_dispatcher = new EventDispatcher(this)
			cl_propertyChangeProxy = new PropertyChangeProxy(this);
			cl_allowedDragActions.allowLink = cl_allowedDragActions.allowCopy = false;
			vec_dockStrategies = new <IDockerStrategy>[new DockHelperStrategy(), new ResizerStrategy()];	//define the strategies here
			crossDockingPolicy = CrossDockingPolicy.UNRESTRICTED;
			dragImageWidth = dragImageHeight = 1;
			
			addEventListener(PropertyChangeEvent.PROPERTY_CHANGED, applyPropertyChanges, false, 0, true);
			vec_dockStrategies.forEach(function setupStrategies(item:IDockerStrategy, index:int, array:Vector.<IDockerStrategy>):void {
				item.setup(this as IBasicDocker);
			}, this);
		}
		
		private function applyPropertyChanges(evt:PropertyChangeEvent):void 
		{
			if (evt.fieldName == "dockHelper")
			{
				var newHelper:IDockHelper = evt.newValue as IDockHelper
				var prevHelper:IDockHelper = evt.oldValue as IDockHelper
				if(prevHelper) {
					prevHelper.removeEventListener(NativeDragEvent.NATIVE_DRAG_DROP, preventDockOnIncomingCrossViolation)
				}
				if(newHelper) {
					newHelper.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, preventDockOnIncomingCrossViolation, false, 0, true)
				}
			}
		}
		
		private function startPanelContainerDragOnEvent(evt:PanelContainerEvent):void 
		{
			if (evt.isDefaultPrevented()) {
				return;
			}
			var transform:Matrix
			var offsetPoint:Point;
			var clipRect:Rectangle;
			var proxyImage:BitmapData;
			var panels:Vector.<IPanel> = evt.relatedPanels;
			var transferObject:Clipboard = new Clipboard();
			var container:IContainer = evt.relatedContainer || findCommonContainer(panels);	//the container is the target to be dragged as well
			var maxWidth:Number = container.width, maxHeight:Number = container.height;
			var thumbWidth:Number = dragImageWidth, thumbHeight:Number = dragImageHeight;
			var wholeThumbWidth:int = int(thumbWidth), wholeThumbHeight:int = int(thumbHeight);
			transferObject.setData(dockFormat.containerFormat, container, false);
			transferObject.setData(dockFormat.panelFormat, panels, false);
			transferObject.setData(dockFormat.destinationFormat, new DragDockContainerInformation(), false);
			if (maxWidth && maxHeight && thumbHeight && thumbWidth && !isNaN(thumbHeight) && !isNaN(thumbWidth))
			{
				//draw the thumbnail preview if the size is not 0 or NaN for either dimension
				var aspect:Number, widthRatio:Number, heightRatio:Number;
				maxWidth = container.width
				maxHeight = container.height
				if (container.width < maxWidth) {
					maxWidth = container.width
				}
				if (container.height < maxHeight) {
					maxHeight = container.height
				}
				
				widthRatio = 1.0 / maxWidth;	//preliminary ratio calculation
				heightRatio = 1.0 / maxHeight;	//for drawing the thumbnail
				aspect = maxHeight / maxWidth;
				if (thumbWidth <= 1.0) {
					maxWidth *= thumbWidth;
				}
				else if (maxWidth > wholeThumbWidth) {
					maxWidth = wholeThumbWidth;
				}
				maxHeight = aspect * maxWidth;
				if (maxHeight < 1.0) {
					maxHeight = 1.0;
				}
				
				if (thumbHeight <= 1.0) {
					maxHeight *= thumbHeight;
				}
				else if (maxHeight > wholeThumbHeight) {
					maxHeight = wholeThumbHeight;
				}
				maxWidth = maxHeight / aspect;
				if (maxWidth < 1.0) {
					maxWidth = 1.0;
				}
				
				proxyImage = new BitmapData(maxWidth, maxHeight, false)
				transform = new Matrix(maxWidth * widthRatio, 0, 0, maxHeight * heightRatio)
				offsetPoint = new Point( -container.mouseX * transform.a, -container.mouseY * transform.d)
				
				proxyImage.draw(container, transform)
			}
			cl_dragStruct = new DragInformation(container.stage, container.mouseX / container.width, container.mouseY / container.height)
			NativeDragManager.doDrag(mainContainer, transferObject, proxyImage, offsetPoint, cl_allowedDragActions);
			evt.stopImmediatePropagation();
		}
		
		private function finishDragDockOperation(evt:NativeDragEvent):void 
		{
			var clipBoard:Clipboard = evt.clipboard
			if(!isCompatibleClipboard(clipBoard)) {
				return;
			}
			var window:NativeWindow;
			var panels:Vector.<IPanel> = clipBoard.getData(dockFormat.panelFormat, ClipboardTransferMode.ORIGINAL_ONLY) as Vector.<IPanel>
			var container:IContainer = clipBoard.getData(dockFormat.containerFormat, ClipboardTransferMode.ORIGINAL_ONLY) as IContainer	|| findCommonContainer(panels)
			var dropContainerInfo:DragDockContainerInformation = clipBoard.getData(dockFormat.destinationFormat, ClipboardTransferMode.ORIGINAL_ONLY) as DragDockContainerInformation
			if (!(panels && panels.length) && container) {
				panels = container.getPanels(false);
			}
			
			panels = extractDockablePanels(panels)
			if (evt.dropAction == NativeDragActions.NONE)
			{
				window = getContainerWindow(dockPanels(panels, container))
				if (window)
				{
					if (cl_dragStruct) {
						moveWindowTo(window, cl_dragStruct.localX, cl_dragStruct.localY, cl_dragStruct.convertToScreen())
					}
					window.activate();
				}
			}
			else
			{
				var relatedContainer:IContainer = dropContainerInfo.destinationContainer
				if (relatedContainer) {
					movePanelsIntoContainer(extractOrderedPanelSideCodes(panels, container), resolveContainerSideSequence(relatedContainer, dropContainerInfo.sideSequence));
				}
			}
			cl_dragStruct = null;
		}
		
		private function preventDockIfInvalid(evt:PanelContainerEvent):void
		{
			if (!(extractDockablePanels(evt.relatedPanels || evt.relatedContainer.getPanels(false)).length)) {
				evt.preventDefault();	//prevent the drag-dock operation from starting if no panel is dockable
			}
		}
		
		private function removeContainerOnEvent(evt:NativeDragEvent):void
		{
			var clipBoard:Clipboard = evt.clipboard
			if (evt.isDefaultPrevented() || !isCompatibleClipboard(clipBoard)) {
				return;
			}
			const ORIGINAL_ONLY:String = ClipboardTransferMode.ORIGINAL_ONLY
			var panels:Vector.<IPanel> = clipBoard.getData(dockFormat.panelFormat, ORIGINAL_ONLY) as Vector.<IPanel>
			var container:IContainer = clipBoard.getData(dockFormat.containerFormat, ORIGINAL_ONLY) as IContainer || findCommonContainer(panels)
			if (!violatesIncomingCrossPolicy(crossDockingPolicy, container))	//remove panels only if the panel belongs to this Docker
			{
				var parkedWindow:NativeWindow = getContainerWindow(dockPanels(panels, container));
				if(parkedWindow) {
					parkedWindow.visible = false;
				}
			}
		}
		
		private function togglePanelStateOnEvent(evt:PanelContainerEvent):void 
		{
			if (evt.isDefaultPrevented()) {
				return;
			}
			var window:NativeWindow;
			var sideInfo:PanelStateInformation;
			var panels:Vector.<IPanel> = extractDockablePanels(evt.relatedPanels)
			var container:IContainer = evt.relatedContainer || findCommonContainer(panels)
			var prevState:Boolean = getAuthoritativeContainerState(container)
			var newContainer:IContainer;
			
			newContainer = dockPanels(panels, container)
			if (prevState == PanelContainerState.INTEGRATED)
			{
				window = getContainerWindow(newContainer)
				if (window) {
					window.activate();
				}
			}
			
			dispatchEvent(new PanelContainerStateEvent(PanelContainerStateEvent.STATE_TOGGLED, panels, evt.relatedContainer, prevState, !prevState, false, false))
		}
		
		/**
		 * Finds and returns all dockable IPanel instances from the given vector of IPanel instances.
		 * @param	panels	The list of IPanel instances to get the dockable IPanel instances from.
		 * @return	A new vector of dockable IPanel instances from the supplied list.
		 */
		private function extractDockablePanels(panels:Vector.<IPanel>):Vector.<IPanel>
		{
			return panels && panels.filter(function(item:IPanel, index:int, array:Vector.<IPanel>):Boolean {
				return item && item.dockable && !isForeignPanel(item);
			});
		}
		
		private function moveWindowTo(window:NativeWindow, localX:Number, localY:Number, windowPoint:Point):void 
		{
			if (!(window && windowPoint) || isNaN(windowPoint.x) || isNaN(windowPoint.y) || isNaN(localX) || isNaN(localY)) {
				return;
			}
			var chromeOffset:Point = window.globalToScreen(new Point(localX * window.stage.stageWidth, localY * window.stage.stageHeight))
			window.x += windowPoint.x - chromeOffset.x;
			window.y += windowPoint.y - chromeOffset.y;
		}
		
		/**
		 * Performs a lazy initialization of the container from the given window, if it does not exist and should be created.
		 * @param	window	The window to lookup.
		 * @param	createIfNotExist	Creates a new container for the given window if this parameter is true and it does not exist; if false, it performs a simple lookup which may fail (i.e. return undefined)
		 * @return	An IContainer instance which is the parked container contained by the corresponding window.
		 * 			This is also a panel's parked container. To find out which panel's parked container this belongs to, use the getWindowPanel() method.
		 * @see	#getWindowPanel()
		 */
		private function getContainerFromWindow(window:NativeWindow, createIfNotExist:Boolean):IContainer
		{
			if (createIfNotExist && window && !(window in dct_containers))
			{
				var container:IContainer 
				var stage:Stage = window.stage
				var panel:IPanel = getWindowPanel(window)
				var defWidth:Number = panel.getDefaultWidth(), defHeight:Number = panel.getDefaultHeight()
				defaultContainerOptions.width = defWidth;
				defaultContainerOptions.height = defHeight;
				container = dct_containers[window] = createContainer(defaultContainerOptions)
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
		private function getWindowFromPanel(panel:IPanel, createIfNotExist:Boolean):NativeWindow
		{
			if (!panel) {
				return null;
			}
			else if (!dct_windows[panel] && createIfNotExist) {
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
			var tempContainer:IContainer = treeResolver.findRootContainer(container)
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
			container.addEventListener(PanelContainerEvent.DRAG_REQUESTED, preventDockIfInvalid, false, 0, true)
			container.addEventListener(PanelContainerEvent.DRAG_REQUESTED, startPanelContainerDragOnEvent, false, 0, true)
			container.addEventListener(PanelContainerEvent.STATE_TOGGLE_REQUESTED, togglePanelStateOnEvent, false, 0, true)
			container.addEventListener(PanelContainerEvent.CONTAINER_REMOVE_REQUESTED, removeContainerIfEmpty, false, 0, true)
			container.addEventListener(PanelContainerEvent.CONTAINER_CREATED, registerContainerOnCreate, false, 0, true)
			container.addEventListener(PanelContainerEvent.CONTAINER_CREATING, createContainerOnEvent, false, 0, true)
			container.addEventListener(PanelContainerEvent.SETUP_REQUESTED, customizeContainerOnSetup, false, 0, true)
			container.addEventListener(Event.REMOVED, addContainerListenersOnUnlink, false, 0, true)
			container.addEventListener(Event.ADDED, removeContainerListenersOnLink, false, 0, true)
		}
		
		/**
		 * Used to pass an IContainer instance to the container which requests an IContainer instance.
		 * This is triggered after a PanelContainerEvent.CONTAINER_CREATING event is dispatched by the container, which signals a new container request.
		 * A response is sent in the form of a PanelContainerEvent.CONTAINER_CREATED event on the requesting container.
		 * @see	airdock.events.PanelContainerEvent
		 */
		private function createContainerOnEvent(evt:PanelContainerEvent):void
		{
			function redispatchOnContainer(innerEvt:PanelContainerEvent):void
			{
				evt.relatedContainer.dispatchEvent(innerEvt);
				removeEventListener(PanelContainerEvent.CONTAINER_CREATED, arguments.callee);
			}
			addEventListener(PanelContainerEvent.CONTAINER_CREATED, redispatchOnContainer, false, 0, true)
			createContainer(defaultContainerOptions);	//this function dispatches the CONTAINER_CREATED event indirectly
		}
		
		/**
		 * Used to prevent docking from a foreign panel or container into a local container (with respect to the current Docker instance.)
		 * This is triggered whenever the following crossDockingPolicy flags are used:
		 * * CrossDockingPolicy.REJECT_INCOMING
		 * * CrossDockingPolicy.INTERNAL_ONLY
		 * 
		 * Note that this function is called by the target container's Docker, not the source container's Docker, during a drag-dock operation.
		 * @see	airdock.enums.CrossDockingPolicy
		 */
		private function preventDockOnIncomingCrossViolation(evt:NativeDragEvent):void 
		{
			var clipBoard:Clipboard = evt.clipboard
			if(!isCompatibleClipboard(clipBoard)) {
				return;
			}
			var panels:Vector.<IPanel> = clipBoard.getData(dockFormat.panelFormat, ClipboardTransferMode.ORIGINAL_ONLY) as Vector.<IPanel>
			var container:IContainer = clipBoard.getData(dockFormat.containerFormat, ClipboardTransferMode.ORIGINAL_ONLY) as IContainer || findCommonContainer(panels)
			if (violatesIncomingCrossPolicy(crossDockingPolicy, container)) {
				evt.dropAction = NativeDragActions.NONE;	//set the drop action to NONE so that it won't commit the operation
			}
		}
		
		private function preventDockOnOutgoingCrossViolation(evt:NativeDragEvent):void
		{
			var clipBoard:Clipboard = evt.clipboard
			if(!isCompatibleClipboard(clipBoard)) {
				return;
			}
			var panels:Vector.<IPanel> = clipBoard.getData(dockFormat.panelFormat, ClipboardTransferMode.ORIGINAL_ONLY) as Vector.<IPanel>
			var container:IContainer = clipBoard.getData(dockFormat.containerFormat, ClipboardTransferMode.ORIGINAL_ONLY) as IContainer || findCommonContainer(panels)
			var dropContainerInfo:DragDockContainerInformation = clipBoard.getData(dockFormat.destinationFormat, ClipboardTransferMode.ORIGINAL_ONLY) as DragDockContainerInformation
			if (violatesOutgoingCrossPolicy(crossDockingPolicy, dropContainerInfo.destinationContainer)) {
				evt.dropAction = NativeDragActions.NONE;	//prevent the event and hence roll back docking process
			}
		}
		
		/**
		 * Adds the container to the list of containers created by this Docker instance, and marks it as local, i.e. non-foreign.
		 */
		private function registerContainerOnCreate(evt:PanelContainerEvent):void 
		{
			var container:IContainer = evt.relatedContainer
			if (!isForeignContainer(treeResolver.findRootContainer(evt.currentTarget as IContainer))) {
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
			container.removeEventListener(PanelContainerEvent.CONTAINER_REMOVE_REQUESTED, removeContainerIfEmpty)
			container.removeEventListener(PanelContainerEvent.STATE_TOGGLE_REQUESTED, togglePanelStateOnEvent)
			container.removeEventListener(PanelContainerEvent.DRAG_REQUESTED, startPanelContainerDragOnEvent)
			container.removeEventListener(PanelContainerEvent.CONTAINER_CREATED, registerContainerOnCreate)
			container.removeEventListener(PanelContainerEvent.CONTAINER_CREATING, createContainerOnEvent)
			container.removeEventListener(PanelContainerEvent.SETUP_REQUESTED, customizeContainerOnSetup)
			container.removeEventListener(PanelContainerEvent.DRAG_REQUESTED, preventDockIfInvalid)
			container.removeEventListener(PanelContainerEvent.PANEL_ADDED, setRoot)
			container.removeEventListener(Event.ADDED, removeContainerListenersOnLink)
			container.removeEventListener(Event.REMOVED, addContainerListenersOnUnlink)
		}
		
		/**
		 * Removes a container whenever it dispatches a PanelContainerEvent.CONTAINER_REMOVE_REQUESTED event and fulfils the criteria for removal.
		 * A container can be removed if:
			* It has no panels in it, or
			* Any panels in it are about to be removed (e.g. as part of a REMOVED event)
		 * A PanelContainerEvent.CONTAINER_REMOVED event is dispatched after this event.
		 * However, if the container is a parked container, no event is dispatched; instead, its window is hidden.
		 */
		private function removeContainerIfEmpty(evt:PanelContainerEvent):void
		{
			if (evt.isDefaultPrevented()) {
				return;
			}
			var hasChildren:Boolean
			var panels:Vector.<IPanel> = evt.relatedPanels
			var container:IContainer = evt.relatedContainer as IContainer || findCommonContainer(panels)
			var currentPanels:Vector.<IPanel> = container.getPanels(false);
			if (panels.length < currentPanels.length) {
				return;
			}
			hasChildren = currentPanels.length && currentPanels.some(function getDisjointPanels(item:IPanel, index:int, array:Vector.<IPanel>):Boolean {
				return item && panels.indexOf(item) == -1;
			});
 			if (hasChildren) {
				return;	//has children, do not remove - either more than the panel being removed, or a different panel from that which is being removed
			}
			
			var rootContainer:IContainer = treeResolver.findRootContainer(container)
			var parkedWindow:NativeWindow = getContainerWindow(rootContainer)
			if (parkedWindow && rootContainer == container) {
				parkedWindow.visible = false;	//do not dispose of container; since it is a parked container, just hide it
			}
			else if(rootContainer.removeContainer(container)) {
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.CONTAINER_REMOVED, panels, container, false, false))	//not a parked container; can remove
			}
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
			var root:IContainer = treeResolver.findRootContainer(target)
			if (!isForeignContainer(target) && root != target)
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
			if (target != evt.currentTarget && !isForeignContainer(target) && !dct_foreignCounter[target])
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
			return container && container.hasEventListener(Event.REMOVED) && container.hasEventListener(Event.ADDED) &&
								container.hasEventListener(PanelContainerEvent.CONTAINER_REMOVE_REQUESTED) &&
								container.hasEventListener(PanelContainerEvent.STATE_TOGGLE_REQUESTED) &&
								container.hasEventListener(PanelContainerEvent.CONTAINER_CREATING) &&
								container.hasEventListener(PanelContainerEvent.CONTAINER_CREATED) &&
								container.hasEventListener(PanelContainerEvent.SETUP_REQUESTED) &&
								container.hasEventListener(PanelContainerEvent.DRAG_REQUESTED) &&
								container.hasEventListener(PanelContainerEvent.PANEL_ADDED) && 
								container.hasEventListener(MouseEvent.MOUSE_MOVE);
		}
		
		/**
		 * Customizes the container when it dispatches a PanelContainerEvent.SETUP_REQUESTED event which has not been prevented.
		 * This is used to add or remove panel lists to containers.
		 * 
		 * Panel lists are added to containers if:
			* The container contains panels, and
			* It does not have any subcontainers.
		 * If it does not fulfil the above conditions, the panel list, if any, is removed from the container.
		 */
		private function customizeContainerOnSetup(evt:PanelContainerEvent):void
		{
			var container:IContainer = evt.relatedContainer;
			var rootContainer:IContainer = evt.currentTarget as IContainer
			if (!(evt.isDefaultPrevented() || isForeignContainer(rootContainer)))
			{
				/* Foreign container policy note:
					* Don't modify foreign container's containers, since that container's Docker will already have listeners for it
					* In effect, whenever a foreign container changes, the source Docker will add or remove its panelLists to the container.
				 */
				if (!container.hasSides && container.hasPanels(false)) {
					container.panelList = cl_panelListFactory.createPanelList() as IPanelList
				}
				else {
					container.panelList = null;
				}
			}
		}
		
		/**
		 * Shadows the destination container so that its window appears behind the source container's window.
		 * @param	sourceContainer	The source container to be shadowed.
		 * @param	destContainer	The destination container whose window will shadow the source container's window.
		 * 							A window which shadows another will be located behind the shadowing window and possess the same bounds as the shadowing window.
		 */
		private function shadowContainer(sourceContainer:IContainer, destContainer:IContainer):void
		{
			var sourceWindow:NativeWindow = getContainerWindow(sourceContainer)
			var destWindow:NativeWindow = getContainerWindow(destContainer)
			if (sourceWindow && destWindow)
			{
				destWindow.bounds = sourceWindow.bounds;
				destContainer.width = destWindow.stage.stageWidth;		//manually resize container
				destContainer.height = destWindow.stage.stageHeight;	//since no resize event dispatched in window
				destWindow.visible = sourceWindow.visible;
				destWindow.orderInBackOf(sourceWindow);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function addPanelToSideSequence(panel:IPanel, container:IContainer, sideCode:String):IContainer
		{
			if(!(panel && container)) {
				return null;
			}
			var prevContainer:IContainer, currContainer:IContainer;
			currContainer = resolveContainerSideSequence(container, sideCode);
			prevContainer = treeResolver.findParentContainer(panel as DisplayObject);
			if(prevContainer) {
				prevContainer.removePanel(panel);
			}
			return currContainer.addToSide(PanelContainerSide.FILL, panel);
		}
		
		private function resolveContainerSideSequence(container:IContainer, sideCode:String):IContainer
		{
			var currContainer:IContainer = container
			if (sideCode)
			{
				for (var i:uint = 0; i < sideCode.length; ++i) {
					currContainer = currContainer.fetchSide(PanelContainerSide.toInteger(sideCode.charAt(i)));
				}
			}
			return currContainer
		}
		
		/**
		 * Returns a list of panels which are sorted based on their depth with respect to the root container supplied.
		 * @param	panels	The list of panels to be sorted based on depth order.
		 * @param	rootContainer	The root container on which the panel depth order is based upon.
		 * @return	A Vector of PanelSideSequence instances (a key-value IPair), where the key is the panel and the value is the side code.
		 * 			If no rootContainer is specified, the value in each pair is the default value returned by the Docker's treeResolver's serializeCode() method - usually null.
		 */
		private function extractOrderedPanelSideCodes(panels:Vector.<IPanel>, rootContainer:IContainer):Vector.<PanelSideSequence>
		{
			if (!panels) {
				return null;
			}
			var sides:Vector.<PanelSideSequence> = new Vector.<PanelSideSequence>(panels.length);
			for (var i:uint = 0; i < panels.length; ++i) {	//cannot use map() here since Vector#map() requires same type
				sides[i] = new PanelSideSequence(panels[i], treeResolver.serializeCode(rootContainer, panels[i] as DisplayObject));
			}
			
			return sides.sort(function deeperLevels(pairA:PanelSideSequence, pairB:PanelSideSequence):int {	//sort side sequences according to increasing length
				return int(pairA.sideSequence && pairB.sideSequence && pairA.sideSequence.length - pairB.sideSequence.length) || 0;
			});
		}
		
		private function movePanelsIntoContainer(panelPairs:Vector.<PanelSideSequence>, newRoot:IContainer):void
		{
			if (panelPairs && newRoot)
			{
				panelPairs.forEach(function preserveSideOnDock(item:PanelSideSequence, index:int, array:Vector.<PanelSideSequence>):void
				{
					if (item) {
						addPanelToSideSequence(item.panel, newRoot, item.sideSequence);	//re-add to same position; note this approach means they will not be part of the same container
					}
				});
			}
		}
		
		private function renameWindow(evt:PropertyChangeEvent):void
		{
			if (evt.fieldName == "panelName")
			{
				var panel:IPanel = evt.currentTarget as IPanel;
				var window:NativeWindow = getWindowFromPanel(panel, false);	//false since plain lookup
				if (window) {
					window.title = evt.newValue as String;
				}
			}
		}
		
		private function resizeContainerOnEvent(evt:NativeWindowBoundsEvent):void 
		{
			var window:NativeWindow = evt.currentTarget as NativeWindow
			var container:IContainer = getWindowContainer(window)
			if (container)
			{
				container.height = window.stage.stageHeight;
				container.width = window.stage.stageWidth;
			}
		}
		
		/**
		 * Updates the panelStateInformation object for the panel which has been added to a container, and all panels in containers deeper than it.
		 * @param	evt
		 */
		private function setRoot(evt:PanelContainerEvent):void 
		{
			var panels:Vector.<IPanel> = evt.relatedPanels;
			var root:IContainer = treeResolver.findRootContainer(evt.relatedContainer)
			if (isForeignContainer(root)) {
				return;
			}
			else panels.forEach(function setRootFor(panel:IPanel, index:int, array:Vector.<IPanel>):void
			{
				var parent:DisplayObject;
				var currLevel:int, level:int;
				var panelStateInfo:PanelStateInformation;
				var currentCode:String = treeResolver.serializeCode(root, panel as DisplayObject)
				for (parent = panel as DisplayObject, level = 0; parent; parent = parent.parent, ++level) { /*find depth of panel*/ }
				panelStateInfo = getPanelStateInfo(panel)
				panelStateInfo.integratedCode = currentCode;
				panelStateInfo.previousRoot = root;
				
				if (!currentCode) {
					return;
				}
				var allStates:Dictionary = dct_panelStateInfo
				var panelContainer:DisplayObjectContainer = treeResolver.findParentContainer(panel as DisplayObjectContainer) as DisplayObjectContainer
				for (var currPanel:Object in allStates)
				{
					var dispPanel:DisplayObject = (currPanel as IPanel) as DisplayObject;
					if (dispPanel == panel) {
						continue;
					}
					else for (parent = dispPanel, currLevel = 0; parent && currLevel < level; parent = parent.parent, ++currLevel) { /*find depth of current panel*/ }
					
					if (currLevel < level) {
						continue;	//ignore if the depth of the current panel is less (i.e. higher) than the target panel
					}
					
					panelStateInfo = allStates[currPanel];
					if (panelStateInfo.previousRoot == root)
					{
						var relativeCode:String = treeResolver.serializeCode(treeResolver.findCommonParent(new <DisplayObject>[panelContainer, dispPanel as DisplayObject]) as IContainer, dispPanel)
						if (relativeCode) {
							panelStateInfo.integratedCode = currentCode.slice(0, -relativeCode.length) + relativeCode
						}
					}
				}
			});
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
			var window:NativeWindow = evt.currentTarget as NativeWindow;
			var container:IContainer = getWindowContainer(window);
			
			evt.preventDefault();	//prevent the window from closing automatically
			window.visible = false;	//and instead hide it and dispatch a VISIBILITY_TOGGLED event for the panels in it
			dispatchEvent(new PanelContainerStateEvent(PanelContainerStateEvent.VISIBILITY_TOGGLED, container.getPanels(true), container, PanelContainerState.VISIBLE, PanelContainerState.INVISIBLE, false, false))
		}
		
		private function addPanelListeners(panel:IPanel):void {
			panel.addEventListener(PropertyChangeEvent.PROPERTY_CHANGED, renameWindow, false, 0, true)
		}
		
		private function removePanelListeners(panel:IPanel):void {
			panel.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGED, renameWindow)
		}
		
		/**
		 * Returns the panel's parked container, and creates it if specified.
		 * Alias for getContainerFromWindow(getWindowFromPanel(panel))
		 * @param	panel	The panel to get the container of.
		 * @param	createIfNotExist	A Boolean indicating whether the container of the panel should be created if it does not exist.
		 * 								If true, both the window and the container are created if they do not exist.
		 * @return	The panel's parked container.
		 */
		private function getContainerFromPanel(panel:IPanel, createIfNotExist:Boolean):IContainer {
			return getContainerFromWindow(getWindowFromPanel(panel, createIfNotExist), createIfNotExist);
		}
		
		/**
		 * @inheritDoc
		 */
		public function getPanelContainer(panel:IPanel):IContainer {
			return getContainerFromPanel(panel, !isForeignPanel(panel))
		}
		
		/**
		 * @inheritDoc
		 */
		public function setupPanel(panel:IPanel):void
		{
			if (!((panel in dct_foreignCounter) && dct_foreignCounter[panel]))
			{
				addPanelListeners(panel)
				dct_foreignCounter[panel] = true;
			}
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
			if (!((panel in dct_foreignCounter) && dct_foreignCounter[panel])) {
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
			if (!panel) {
				return null
			}
			else if (panel in dct_windows) {
				return dct_windows[panel] as NativeWindow
			}
			
			var options:NativeWindowInitOptions = defaultWindowOptions
			options.resizable = panel.resizable
			
			var window:NativeWindow = new NativeWindow(options)
			var stage:Stage = window.stage
			setupWindow(window)
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
			var container:IContainer;
			if (dispatchEvent(new PanelContainerEvent(PanelContainerEvent.CONTAINER_CREATING, null, null, false, true)))
			{
				container = cl_containerFactory.createContainer(options)
				container.panelList = cl_panelListFactory.createPanelList()
				addContainerListeners(container);
				dct_foreignCounter[container] = hasContainerListeners(container)
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.CONTAINER_CREATED, null, container, false, false));
			}
			return container
		}
		
		/**
		 * @inheritDoc
		 */
		public function setPanelFactory(panelFactory:IPanelFactory):void
		{
			if (!panelFactory) {
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
			if (!containerFactory) {
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
					container.panelList = (panelListFactory != null && panelListFactory.createPanelList()) as IPanelList
				}
			}
		}
		
		/**
		 * Recursively empties the first panel's container if it is occupied.
		 * @inheritDoc
		 */
		public function dockPanels(panels:Vector.<IPanel>, parentContainer:IContainer):IContainer
		{
			/* Procedure:
				* Get the (first panel in panels)'s parked container as firstContainer
				* Move all the panels into firstContainer
				* Special case: If some panels already exist in firstContainer, which are not in panels:
					* Move them to the container of their first panel:
						* Find the panels in firstContainer which are NOT in panels as preExistingPanels
						* Call dockPanels() recursively on preExistingPanels
			 * Note: If all the panels are removed from the container, the container must also be removed
				* This is handled by the removeContainerIfEmpty() method.
			 */
			var dockablePanels:Vector.<IPanel> = extractDockablePanels(panels);
			if(!(dockablePanels && dockablePanels.length)) {
				return null;
			}
			var panelPairs:Vector.<PanelSideSequence> = extractOrderedPanelSideCodes(dockablePanels, parentContainer);
			var firstContainer:IContainer = getPanelContainer(panelPairs[0].key as IPanel);	//first panel's parked container will have all the other panels moved into it
			var preExistingPanels:Vector.<IPanel> = firstContainer.getPanels(true).filter(function getPanelsDifference(item:IPanel, index:int, array:Vector.<IPanel>):Boolean {
				return item && dockablePanels.indexOf(item) == -1;	//exclude panels which are going to be moved to this container
			});
			if (parentContainer != firstContainer)
			{
				shadowContainer(parentContainer, firstContainer)
				movePanelsIntoContainer(panelPairs, firstContainer)
			}
			dockPanels(preExistingPanels, firstContainer)	//recursively empty the first panel's parked container by calling dockPanels() on it
			return firstContainer;
		}
		
		/**
		 * @inheritDoc
		 */
		public function integratePanels(panels:Vector.<IPanel>, parentContainer:IContainer):IContainer
		{
			/* Structurally similar to the dockPanels() method.
			 * The only difference is that this method does not care if previous root is occupied.
			 * Procedure:
				* Get the (first panel in panels)'s previous root container as firstContainer
				* Move all the panels into firstContainer
			 * Note: If all the panels are removed from the container, the container must also be removed
				* This is handled by the removeContainerIfEmpty() method.
			 */
			var dockablePanels:Vector.<IPanel> = extractDockablePanels(panels);
			if(!(dockablePanels && dockablePanels.length)) {
				return null;
			}
			var panelPairs:Vector.<PanelSideSequence> = extractOrderedPanelSideCodes(dockablePanels, parentContainer);
			var sideInfo:PanelStateInformation = getPanelStateInfo(panelPairs[0].panel);
			var firstContainer:IContainer = resolveContainerSideSequence(sideInfo.previousRoot, sideInfo.integratedCode);
			if(!firstContainer) {
				return null;
			}
			movePanelsIntoContainer(panelPairs, firstContainer);
			return firstContainer;
		}
		
		/**
		 * Makes the panels supplied in the parameter visible, and dispatches a PanelContainerStateEvent if it was previously hidden.
		 * No event is dispatched if the panel supplied was already visible prior to calling the function.
		 * @inheritDoc
		 */
		public function showPanels(panels:Vector.<IPanel>):Boolean
		{
			if (!(panels && panels.length)) {
				return false;
			}
			panels = extractDockablePanels(panels);
			var panel:IPanel = panels[0];
			var changeOccurred:Boolean = true;
			var container:IContainer = treeResolver.findParentContainer(panel as DisplayObject);
			if (container && isForeignContainer(container)) {
				return false;	//do not attempt to show panel for external/foreign containers
			}
			else if (!container || getAuthoritativeContainerState(container) == PanelContainerState.DOCKED)
			{
				if (!container) {
					dockPanels(panels, null);
				}
				/* Panels are part of a parked container now
				 * Show the window and the panel along with it */
				var window:NativeWindow = getContainerWindow(container);
				changeOccurred = !window.visible;
				container.showPanel(panel)
				window.activate()
			}
			else
			{
				var sideInfo:PanelStateInformation = getPanelStateInfo(panel)
				var previousRoot:IContainer = sideInfo.previousRoot
				var newRoot:IContainer = previousRoot && integratePanels(panels, previousRoot)
				if(!newRoot) {
					return false;
				}
				changeOccurred = previousRoot != newRoot
			}
			var newParent:IContainer = treeResolver.findParentContainer(panel as DisplayObject);
			if (changeOccurred) {
				dispatchEvent(new PanelContainerStateEvent(PanelContainerStateEvent.VISIBILITY_TOGGLED, panels, newParent, PanelContainerState.INVISIBLE, PanelContainerState.VISIBLE, false, false));
			}
			var success:Boolean = !!newParent && panels.every(function showAllPanels(item:IPanel, index:int, array:Vector.<IPanel>):Boolean {
				return newParent.showPanel(item);
			});
			return success;
		}
		
		/**
		 * @inheritDoc
		 */
		public function hidePanel(panel:IPanel):Boolean
		{
			var hideable:Boolean = isPanelVisible(panel);
			if (hideable)
			{
				var container:IContainer = treeResolver.findParentContainer(panel as DisplayObject);
				var rootContainer:IContainer = treeResolver.findRootContainer(container);
				if (rootContainer == getContainerFromPanel(panel, false) && rootContainer.getPanelCount(true) == 1) {
					getContainerWindow(rootContainer).visible = false;
				}
				else if(container) {
					container.removePanel(panel);
				}
				
				if (container) {
					dispatchEvent(new PanelContainerStateEvent(PanelContainerStateEvent.VISIBILITY_TOGGLED, new <IPanel>[panel], container, PanelContainerState.VISIBLE, PanelContainerState.INVISIBLE, false, false))
				}
			}
			return hideable;
		}
		
		/**
		 * @inheritDoc
		 */
		public function isPanelVisible(panel:IPanel):Boolean
		{
			var parentContainer:IContainer = treeResolver.findParentContainer(panel as DisplayObject);
			var rootContainer:IContainer = treeResolver.findRootContainer(parentContainer);
			if (!rootContainer || isForeignContainer(rootContainer)) {
				return false;
			}
			var window:NativeWindow = getContainerWindow(rootContainer);
			return (window && window.visible) && rootContainer.isPanelVisible(panel);
		}
		
		/**
		 * @inheritDoc
		 */
		public function get dockHelper():IDockHelper {
			return cl_propertyChangeProxy.dockHelper as IDockHelper;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set dockHelper(dockHelper:IDockHelper):void {
			cl_propertyChangeProxy.dockHelper = dockHelper;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get resizeHelper():IResizer {
			return cl_propertyChangeProxy.resizeHelper as IResizer
		}
		
		/**
		 * @inheritDoc
		 */
		public function set resizeHelper(resizer:IResizer):void {
			cl_propertyChangeProxy.resizeHelper = resizer
		}
		
		/**
		 * @inheritDoc
		 */
		public function set crossDockingPolicy(policyFlags:int):void {
			cl_propertyChangeProxy.crossDockingPolicy = policyFlags
		}
		
		/**
		 * @inheritDoc
		 */
		public function get crossDockingPolicy():int {
			return int(cl_propertyChangeProxy.crossDockingPolicy)
		}
		
		/**
		 * @inheritDoc
		 */
		public function get mainContainer():DisplayObjectContainer {
			return cl_propertyChangeProxy.mainContainer as DisplayObjectContainer
		}
		
		/**
		 * @inheritDoc
		 */
		public function set mainContainer(container:DisplayObjectContainer):void
		{
			function setMainContainer(evt:PropertyChangeEvent):void
			{
				if (evt.fieldName == "mainContainer")
				{
					var prevContainer:DisplayObjectContainer = evt.oldValue as DisplayObjectContainer
					var container:DisplayObjectContainer = evt.newValue as DisplayObjectContainer
					if (prevContainer)
					{
						prevContainer.removeEventListener(NativeDragEvent.NATIVE_DRAG_START, removeContainerOnEvent)
						prevContainer.removeEventListener(NativeDragEvent.NATIVE_DRAG_COMPLETE, updateDragCoordinatesOnEvent)
						prevContainer.removeEventListener(NativeDragEvent.NATIVE_DRAG_COMPLETE, preventDockOnOutgoingCrossViolation)
						prevContainer.removeEventListener(NativeDragEvent.NATIVE_DRAG_COMPLETE, finishDragDockOperation)
					}
					
					if (container)
					{
						/**
						 * Docking process:
						 * 1) Check if the drag-dock operation can be started. If the panel is not dockable, stop.
						 * 2) Start the native drag via NativeDragManager.doDrag()
						 * 3) Remove the panel or container from its parent container.
						 * 3.5) Continually update the dragging coordinates for the window (if it ends up being docked)
						 * 4) Finish the docking operation by adding the panel or container to the target (NativeDragEvent.NATIVE_DRAG_COMPLETE)
						 * 5) Clean up - hide the dock helper, update the drag coordinates one last time, and if step 3 does not succeed, dock the container
						 * 
						 * Note: The priority for preventDockOnOutgoingCrossViolation must be higher (i.e. before) finishDragDockOperation
						 */
						container.addEventListener(NativeDragEvent.NATIVE_DRAG_START, removeContainerOnEvent)
						container.addEventListener(NativeDragEvent.NATIVE_DRAG_COMPLETE, updateDragCoordinatesOnEvent)
						container.addEventListener(NativeDragEvent.NATIVE_DRAG_COMPLETE, preventDockOnOutgoingCrossViolation)
						container.addEventListener(NativeDragEvent.NATIVE_DRAG_COMPLETE, finishDragDockOperation)
					}
				}
				removeEventListener(PropertyChangeEvent.PROPERTY_CHANGED, arguments.callee)
			}
			addEventListener(PropertyChangeEvent.PROPERTY_CHANGED, setMainContainer, false, 0, true)
			
			cl_propertyChangeProxy.mainContainer = container;
			removeEventListener(PropertyChangeEvent.PROPERTY_CHANGED, setMainContainer)
		}
		
		private function updateDragCoordinatesOnEvent(evt:NativeDragEvent):void 
		{
			if (cl_dragStruct) {
				cl_dragStruct.updateStageCoordinates(evt.stageX, evt.stageY)
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function get dragImageHeight():Number {
			return Number(cl_propertyChangeProxy.dragImageHeight)
		}
		
		/**
		 * @inheritDoc
		 */
		public function set dragImageHeight(value:Number):void {
			cl_propertyChangeProxy.dragImageHeight = value;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get dragImageWidth():Number {
			return Number(cl_propertyChangeProxy.dragImageWidth)
		}
		
		/**
		 * @inheritDoc
		 */
		public function set dragImageWidth(value:Number):void {
			cl_propertyChangeProxy.dragImageWidth = value;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get defaultWindowOptions():NativeWindowInitOptions {
			return cl_propertyChangeProxy.defaultWindowOptions as NativeWindowInitOptions;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set defaultWindowOptions(value:NativeWindowInitOptions):void
		{
			if (!value) {
				throw new ArgumentError("Error: Option defaultWindowOptions must be a non-null value.")
			}
			else {
				cl_propertyChangeProxy.defaultWindowOptions = value
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function get defaultContainerOptions():ContainerConfig {
			return cl_propertyChangeProxy.defaultContainerOptions as ContainerConfig
		}
		
		/**
		 * @inheritDoc
		 */
		public function set defaultContainerOptions(value:ContainerConfig):void 
		{
			if (!value) {
				throw new ArgumentError("Error: Option defaultContainerOptions must be a non-null value.")
			}
			else {
				cl_propertyChangeProxy.defaultContainerOptions = value
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function get dockFormat():IDockFormat {
			return cl_propertyChangeProxy.dockFormat as IDockFormat;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set dockFormat(value:IDockFormat):void 
		{
			if (!value) {
				throw new ArgumentError("Error: Option dockFormat must be a non-null value.")
			}
			else {
				cl_propertyChangeProxy.dockFormat = value
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function get treeResolver():ITreeResolver {
			return cl_propertyChangeProxy.treeResolver
		}
		
		/**
		 * @inheritDoc
		 */
		public function set treeResolver(value:ITreeResolver):void 
		{
			if (!value) {
				throw new ArgumentError("Error: Option treeResolver must be a non-null value.")
			}
			else {
				cl_propertyChangeProxy.treeResolver = value
			}
		}
		
		/**
		 * Disposes of all the windows and removes all listeners and other references of the panels registered to this Docker.
		 * Once this method is called, it is advised not to use the Docker instance again, and to create a new one instead.
		 * @inheritDoc
		 */
		public function dispose():void
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
			vec_dockStrategies.forEach(function disposeObject(item:IDockerStrategy, index:int, array:Vector.<IDockerStrategy>):void
			{
				if (item is IDisposable) {
					(item as IDisposable).dispose();
				}
			});
			setPanelListFactory(null);
			dockHelper = null;
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
			return !(container && (container in dct_foreignCounter))
		}
		
		[Inline]
		private function isForeignPanel(panel:IPanel):Boolean {
			return !(panel in dct_foreignCounter)
		}
		
		[Inline]
		private function isMatchingDockPolicy(crossDockingPolicy:int, flag:int):Boolean {
			return (crossDockingPolicy & flag) != 0;
		}
		
		[Inline]
		private function isCompatibleClipboard(clipboard:Clipboard):Boolean {
			return clipboard.hasFormat(dockFormat.panelFormat) || clipboard.hasFormat(dockFormat.containerFormat)
		}
		
		[Inline]
		private function violatesIncomingCrossPolicy(crossDockingPolicy:int, container:IContainer):Boolean {
			return isMatchingDockPolicy(crossDockingPolicy, CrossDockingPolicy.REJECT_INCOMING) && isForeignContainer(container)
		}
		
		[Inline]
		private function violatesOutgoingCrossPolicy(crossDockingPolicy:int, container:IContainer):Boolean {
			return isMatchingDockPolicy(crossDockingPolicy, CrossDockingPolicy.PREVENT_OUTGOING) && isForeignContainer(container)
		}
		
		[Inline]
		private function findCommonContainer(panels:Vector.<IPanel>):IContainer
		{
			var displayObject:DisplayObject = treeResolver.findCommonParent(Vector.<DisplayObject>(panels))
			return displayObject as IContainer || treeResolver.findParentContainer(displayObject)
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
			var root:IContainer = treeResolver.findRootContainer(container)
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
				var reason:Vector.<String> = new <String>["Invalid options:"]
				if (!config) {
					reason.push("Options must be non-null.")
				}
				else 
				{
					if (!config.mainContainer) {
						reason.push("Option mainContainer must be a non-null value.");
					}
					if (!config.defaultWindowOptions) {
						reason.push("Option defaultWindowOptions must be a non-null value.");
					}
					if (!config.treeResolver) {
						reason.push("Option treeResolver must be a non-null value.");
					}
				}
				throw new ArgumentError(reason.join("\n"))
			}
			else if (!isSupported) {
				throw new IllegalOperationError("Error: AIRDock is not supported on the current system.");
			}
			var dock:AIRDock = new AIRDock()
			if (config.mainContainer.stage) {
				config.defaultWindowOptions.owner = config.mainContainer.stage.nativeWindow
			}
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
import airdock.interfaces.docking.IDragDockFormat;
import airdock.interfaces.docking.IPanel;
import airdock.util.IPair;
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

/**
 * The class containing information about the container which is to receive a panel or container near the end of a drag-dock operation.
 */
internal class DragDockContainerInformation implements IDragDockFormat
{
	private var str_sideSequence:String
	private var plc_destination:IContainer
	public function DragDockContainerInformation() { }
	
	public function get destinationContainer():IContainer {
		return plc_destination
	}
	
	public function set destinationContainer(dropTarget:IContainer):void {
		plc_destination = dropTarget
	}
	
	public function get sideSequence():String {
		return str_sideSequence;
	}
	
	public function set sideSequence(value:String):void {
		str_sideSequence = value;
	}
}

internal class PanelSideSequence implements IPair
{
	private var pl_panel:IPanel
	private var str_sideSequence:String
	public function PanelSideSequence(panel:IPanel, sideSequence:String)
	{
		pl_panel = panel;
		str_sideSequence = sideSequence
	}
	
	public function get sideSequence():String {
		return str_sideSequence;
	}
	
	public function get panel():IPanel {
		return pl_panel;
	}
	
	public function get key():Object {
		return panel
	}
	
	public function get value():Object {
		return sideSequence
	}
}