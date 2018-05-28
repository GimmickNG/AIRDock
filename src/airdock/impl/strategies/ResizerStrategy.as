package airdock.impl.strategies 
{
	import airdock.enums.PanelContainerSide;
	import airdock.events.PanelContainerEvent;
	import airdock.events.PropertyChangeEvent;
	import airdock.events.ResizerEvent;
	import airdock.util.IDisposable;
	import airdock.interfaces.strategies.IDockerStrategy;
	import airdock.interfaces.docking.IBasicDocker;
	import airdock.interfaces.docking.IContainer;
	import airdock.interfaces.docking.ICustomizableDocker;
	import airdock.interfaces.docking.ITreeResolver;
	import airdock.interfaces.ui.IResizer;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	/**
	 * The resizer manager class decides when to display and hide the resizer of the Docker whose resizer it manages.
	 * It also handles the resizing of containers as per the resizer's actions.
	 * @author Gimmick
	 */
	public class ResizerStrategy implements IDockerStrategy, IEventDispatcher, IDisposable
	{
		private var dct_containers:Dictionary;
		private var cl_hostDocker:ICustomizableDocker;
		public function ResizerStrategy() {
			dct_containers = new Dictionary(true);
		}
		
		public function setup(baseDocker:IBasicDocker):void
		{
			if (cl_hostDocker) {
				dispose()
			}
			
			if(!(baseDocker && baseDocker is ICustomizableDocker)) {
				throw new ArgumentError("Error: Argument baseDocker must be a non-null ICustomizableDocker instance.");
			}
			var customizableDocker:ICustomizableDocker = ICustomizableDocker(baseDocker);
			addResizerListeners(customizableDocker.resizeHelper);
			cl_hostDocker = customizableDocker;
			addDockerListeners(baseDocker);
		}
		
		public function dispose():void
		{
			removeDockerListeners(cl_hostDocker)
			removeResizerListeners(cl_hostDocker.resizeHelper)
			for (var container:Object in dct_containers) {
				removeContainerListeners(container as IContainer)	//also clears dictionary
			}
			cl_hostDocker = null;
		}
		
		private function removeDockerListeners(docker:IBasicDocker):void
		{
			docker.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGED, changeResizerListeners)
			docker.removeEventListener(PanelContainerEvent.CONTAINER_CREATED, addContainerListenersOnEvent)
			docker.removeEventListener(PanelContainerEvent.CONTAINER_REMOVED, removeContainerListenersOnEvent)
		}
		
		private function changeResizerListeners(evt:PropertyChangeEvent):void 
		{
			var oldResizer:IResizer = evt.oldValue as IResizer, newResizer:IResizer = evt.newValue as IResizer
			if (newResizer && oldResizer != newResizer)
			{
				addResizerListeners(newResizer)
				removeResizerListeners(oldResizer)
			}
		}
		
		private function addDockerListeners(docker:IBasicDocker):void
		{
			docker.addEventListener(PropertyChangeEvent.PROPERTY_CHANGED, changeResizerListeners, false, 0, true)
			docker.addEventListener(PanelContainerEvent.CONTAINER_CREATED, addContainerListenersOnEvent, false, 0, true)
			docker.addEventListener(PanelContainerEvent.CONTAINER_REMOVED, removeContainerListenersOnEvent, false, 0, true)
		}
		
		private function removeContainerListenersOnEvent(evt:PanelContainerEvent):void {
			removeContainerListeners(evt.relatedContainer);
		}
		
		private function addContainerListenersOnEvent(evt:PanelContainerEvent):void {
			addContainerListeners(evt.relatedContainer);
		}
		
		private function addContainerListeners(container:IContainer):void 
		{
			if(container in dct_containers) {
				return;
			}
			container.addEventListener(PanelContainerEvent.STATE_TOGGLE_REQUESTED, preventIfResizing, false, 0, true);
			container.addEventListener(PanelContainerEvent.DRAG_REQUESTED, preventIfResizing, false, 0, true);
			container.addEventListener(MouseEvent.MOUSE_MOVE, setResizerTargetOnEvent, false, 0, true);
			dct_containers[container] = true;	//value does not matter as much as key
		}
		
		private function removeContainerListeners(container:IContainer):void 
		{
			if(!(container in dct_containers)) {
				return;
			}
			container.removeEventListener(PanelContainerEvent.STATE_TOGGLE_REQUESTED, preventIfResizing);
			container.removeEventListener(PanelContainerEvent.DRAG_REQUESTED, preventIfResizing);
			container.removeEventListener(MouseEvent.MOUSE_MOVE, setResizerTargetOnEvent)
			delete dct_containers[container];
		}
		
		private function preventIfResizing(evt:PanelContainerEvent):void 
		{
			if (resizer)
			{
				var resizerParent:DisplayObjectContainer = resizer.parent;
				if(resizer.isDragging) {
					evt.preventDefault();
				}
				else if(resizerParent) {
					resizerParent.removeChild(resizer as DisplayObject);
				}
			}
		}
		
		private function resizeNestedContainerOnEvent(evt:ResizerEvent):void 
		{
			if(evt.isDefaultPrevented()) {
				return;
			}
			
			var size:Number = evt.position;
			var orientation:int = evt.sideCode;
			var currContainer:IContainer = evt.container;
			if(size < 0.0) {
				size = 0.0;
			}
			else if (size > 1.0)
			{
				var maxSize:Number;	//get maximum allowed size (width or height, based on side) since absolute size
				if (PanelContainerSide.isComplementary(orientation, PanelContainerSide.LEFT)) {
					maxSize = currContainer.width;
				}
				else if (PanelContainerSide.isComplementary(orientation, PanelContainerSide.TOP)) {
					maxSize = currContainer.height;
				}
				
				if(currContainer.maxSideSize <= 1.0) {
					maxSize *= currContainer.maxSideSize	//maxSideSize is a ratio; calculate size
				}
				else if(maxSize > currContainer.maxSideSize) {
					maxSize = currContainer.maxSideSize		//maxSideSize is absolute size; cap size
				}
				
				if(size > maxSize) {
					size = maxSize;
				}
			}
			
			currContainer.sideSize = size;
			dispatchEvent(new ResizerEvent(ResizerEvent.RESIZED, currContainer, size, orientation, false, false))
		}
		
		/**
		 * Displays the resizer for a container when the mouse is hovered over the container's edges.
		 */
		private function setResizerTargetOnEvent(evt:MouseEvent):void 
		{
			var target:DisplayObject = evt.target as DisplayObject
			if(target is IResizer || !resizer || resizer.isDragging) {
				return;	//resizer does not exist, or already has target; do not recalculate
			}
			var targetContainer:IContainer = (target as IContainer) || treeResolver.findParentContainer(target)
			var container:IContainer = treeResolver.findParentContainer(targetContainer as DisplayObject)
			if (container)
			{
				var side:int;
				var point:Point;
				var tolerance:Number = resizer.tolerance
				var localXPercent:Number = targetContainer.mouseX / targetContainer.width
				var localYPercent:Number = targetContainer.mouseY / targetContainer.height
				
				if (localXPercent <= tolerance) {
					side = PanelContainerSide.LEFT;		//left edge
				}
				else if(localXPercent >= (1 - tolerance)) {
					side = PanelContainerSide.RIGHT;	//right edge
				}
				else if (localYPercent <= tolerance) {
					side = PanelContainerSide.TOP;		//top edge
				}
				else if(localYPercent >= (1 - tolerance)) {
					side = PanelContainerSide.BOTTOM;	//bottom edge
				}
				else 
				{
					if(resizer.parent) {
						resizer.parent.removeChild(resizer as DisplayObject)
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
					container = treeResolver.findParentContainer(container as DisplayObject);
				}
				
				if (container && displayResizer)
				{
					point = new Point(targetContainer.x, targetContainer.y)
					if (PanelContainerSide.isComplementary(side, PanelContainerSide.TOP)) {
						point.offset(resizer.preferredXPercentage * targetContainer.width, Math.round(localYPercent) * targetContainer.height)
					}
					else {
						point.offset(Math.round(localXPercent) * targetContainer.width, resizer.preferredYPercentage * targetContainer.height)
					}
					point = container.localToGlobal(point)
					
					var containerBounds:Rectangle = container.getBounds(null)
					containerBounds.height = container.height	//set height and width to intended
					containerBounds.width = container.width		//container size - not actual
					resizer.maxSize = containerBounds
					resizer.container = container
					resizer.sideCode = side
					resizer.x = point.x;
					resizer.y = point.y;
					container.stage.addChild(resizer as DisplayObject)
				}
				else if(resizer.parent) {
					resizer.parent.removeChild(resizer as DisplayObject)
				}
			}
		}
		
		private function get resizer():IResizer {
			return cl_hostDocker.resizeHelper as IResizer;
		}
		
		private function get treeResolver():ITreeResolver {
			return cl_hostDocker.treeResolver as ITreeResolver;
		}
		
		private function addResizerListeners(resizer:IResizer):void
		{
			if (resizer) {
				resizer.addEventListener(ResizerEvent.RESIZING, resizeNestedContainerOnEvent, false, 0, true)
			}
		}
		
		private function removeResizerListeners(resizer:IResizer):void
		{
			if (resizer) {
				resizer.removeEventListener(PanelContainerEvent.RESIZING, resizeNestedContainerOnEvent)
			}
		}
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			cl_hostDocker.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function dispatchEvent(event:Event):Boolean {
			return cl_hostDocker.dispatchEvent(event);
		}
		
		public function hasEventListener(type:String):Boolean {
			return cl_hostDocker.hasEventListener(type);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			cl_hostDocker.removeEventListener(type, listener, useCapture);
		}
		
		public function willTrigger(type:String):Boolean {
			return cl_hostDocker.willTrigger(type);
		}
	}

}