package airdock.impl 
{
	import airdock.enums.PanelContainerSide;
	import airdock.events.PanelContainerEvent;
	import airdock.events.PanelPropertyChangeEvent;
	import airdock.interfaces.docking.IPanel;
	import airdock.interfaces.docking.IContainer;
	import airdock.interfaces.ui.IDockHelper;
	import airdock.interfaces.display.IDisplayObjectContainer;
	import airdock.interfaces.ui.IDisplayablePanelList;
	import airdock.interfaces.ui.IPanelList;
	import flash.desktop.NativeDragActions;
	import flash.desktop.NativeDragManager;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventPhase;
	import flash.events.NativeDragEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getQualifiedClassName;
	/**
	 * ...
	 * @author Gimmick
	 */
	public class DefaultContainer extends Sprite implements IContainer
	{
		private var i_currSide:int;
		private var num_ratio:Number;
		private var num_minRatio:Number;
		private var num_maxRatio:Number;
		private var num_maxWidth:Number;
		private var num_maxHeight:Number;
		private var cl_panelList:IPanelList;
		private var b_containerState:Boolean;
		private var plc_otherSide:IContainer;
		private var plc_currentSide:IContainer;
		public function DefaultContainer()
		{
			resetContainer()
			addChildUpdateListeners()
			num_maxWidth = num_maxHeight = 128
			addEventListener(PanelPropertyChangeEvent.PROPERTY_CHANGED, updatePanelBar, false, 0, true)
		}
		
		private function addChildUpdateListeners():void
		{
			addEventListener(Event.ADDED, updatePanelBarOnEvent, false, 0, true)
			addEventListener(Event.REMOVED, updatePanelBarOnEvent, false, 0, true)
			addEventListener(Event.REMOVED, dispatchRemoveOnEmpty, false, 0, true)
		}
		
		private function removeChildUpdateListeners():void
		{
			removeEventListener(Event.REMOVED, dispatchRemoveOnEmpty)
			removeEventListener(Event.REMOVED, updatePanelBarOnEvent)
			removeEventListener(Event.ADDED, updatePanelBarOnEvent)
		}
		
		private function dispatchRemoveOnEmpty(evt:Event):void 
		{
			var target:IPanel = evt.target as IPanel
			if (target && target.parent == this && getPanelCount(true) <= 1) {
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.REMOVE_REQUESTED, null, this, true, false))
			}
		}
		
		private function updatePanelBar(evt:PanelPropertyChangeEvent):void 
		{
			var currPanel:IPanel = evt.target as IPanel
			if (evt.fieldName == "panelName" && currPanel && evt.eventPhase == EventPhase.BUBBLING_PHASE && currPanel.parent == this) {
				cl_panelList.updatePanel(currPanel)
			}
		}
		
		public function get panelList():IPanelList {
			return cl_panelList
		}
		
		public function set panelList(panelList:IPanelList):void
		{
			//cleanup
			removePanelListListeners(cl_panelList)
			if (displayablePanelList) {
				removeChild(displayablePanelList)
			}
			//---
			cl_panelList = panelList
			if (panelList)
			{
				var panelArray:Array = panels;
				for (var i:uint = 0; i < panelArray.length; ++i) {
					panelList.addPanel(panelArray[i] as IPanel);
				}
				if (panelList is IDisplayablePanelList) {
					displayablePanelList = DisplayObject(panelList)	//hard cast to throw error if panelList is not of type DisplayObject
				}
			}
			addPanelListListeners(panelList)
		}
		
		private function get displayablePanelList():DisplayObject {
			return cl_panelList as DisplayObject;
		}
		
		private function set displayablePanelList(displayable:DisplayObject):void
		{
			if(!displayable) {
				return;
			}
			var displayableList:IDisplayablePanelList = displayable as IDisplayablePanelList
			addChild(displayable)
			displayableList.maxWidth = width;
			displayableList.maxHeight = height;
		}
		
		private function removePanelListListeners(panelList:IPanelList):void 
		{
			if(!panelList) {
				return;
			}
			panelList.removeEventListener(PanelContainerEvent.SHOW_REQUESTED, bumpPanelToTop)
			panelList.removeEventListener(PanelContainerEvent.DRAG_REQUESTED, sendDockPanelRequest)
			panelList.removeEventListener(PanelContainerEvent.REMOVE_REQUESTED, removePanelOnEvent)
			panelList.removeEventListener(PanelContainerEvent.STATE_TOGGLED, sendDockPanelRequest)
		}
		
		private function addPanelListListeners(panelList:IPanelList):void 
		{
			if(!panelList) {
				return;
			}
			panelList.addEventListener(PanelContainerEvent.STATE_TOGGLED, sendDockPanelRequest, false, 0, true)
			panelList.addEventListener(PanelContainerEvent.REMOVE_REQUESTED, removePanelOnEvent, false, 0, true)
			panelList.addEventListener(PanelContainerEvent.DRAG_REQUESTED, sendDockPanelRequest, false, 0, true)
			panelList.addEventListener(PanelContainerEvent.SHOW_REQUESTED, bumpPanelToTop, false, 0, true)
		}
		
		private function removePanelOnEvent(evt:PanelContainerEvent):void {
			removePanel(evt.relatedPanel)
		}
		
		private function bumpPanelToTop(evt:PanelContainerEvent):void
		{
			var panel:IPanel = evt.relatedPanel
			if (panel && panel.parent == this) {
				setChildIndex(panel as DisplayObject, numChildren - 1)
			}
			if(displayablePanelList) {
				setChildIndex(displayablePanelList, numChildren - 1)
			}
		}
		
		private function sendDockPanelRequest(evt:PanelContainerEvent):void
		{
			evt.stopImmediatePropagation()
			dispatchEvent(new PanelContainerEvent(evt.type, evt.relatedPanel, this, true, false))
			
			//for the listeners registered - DRAG and STATE_TOGGLE the relatedPanel is
			//the panel which is going to be removed (that is, this event occurs before it is removed)
			//if there is no relatedPanel then it implies that the entire container is to be removed instead
			//in which case there is no need to show the last panel in the UIPanelList.
			if (evt.relatedPanel)
			{
				var panelList:Array = panels;
				if (panelList.length) {	//shows the other panel in the UIPanelList
					(evt.currentTarget as IPanelList).showPanel(panelList.shift() as IPanel)
				}
			}
		}
		
		private function updatePanelBarOnEvent(evt:Event):void 
		{
			var panel:IPanel = evt.target as IPanel;
			if (!(panel && evt.eventPhase == EventPhase.BUBBLING_PHASE && panel.parent == this)) {
				return;
			}
			if (cl_panelList)
			{
				if (evt.type == Event.ADDED)
				{
					cl_panelList.addPanelAt(panel, getChildIndex(panel as DisplayObject))
					if(displayablePanelList) {
						setChildIndex(displayablePanelList, numChildren - 1)
					}
				}
				else {
					cl_panelList.removePanel(panel)
				}
				for (var i:int = numChildren - 1; i >= 0; --i)
				{
					var child:IPanel = getChildAt(i) as IPanel
					if (child)
					{
						cl_panelList.showPanel(child)
						break;
					}
				}
			}
			else {
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.SETUP_REQUESTED, null, this, true, false));
			}
		}
		
		/**
		 * Merges the contents of the current container into the destination container, and empties the current container in the process.
		 * In effect, it empties the container (node) into another container by transferring all its children and its branches into the other container.
		 * @param	container
		 */
		public function mergeIntoContainer(container:IContainer):void
		{
			if(this == container) {
				return;
			}
			//remove listener since we don't want this to occur while we're anyways emptying the container
			removeChildUpdateListeners()
			var k:int;
			while(k < numChildren)
			{
				var currChild:DisplayObject = getChildAt(k)
				if (currChild == displayablePanelList)
				{
					++k;
					continue;
				}
				container.addChild(currChild)
			}
			addChildUpdateListeners()
			container.setContainers(sideCode, currentSide, otherSide)
			if(container.panelList is IDisplayablePanelList) {
				container.setChildIndex(container.panelList as DisplayObject, container.numChildren - 1)
			}
			container.minSideRatio = minSideRatio
			container.maxSideRatio = maxSideRatio
			container.sideRatio = sideRatio
			dispatchEvent(new PanelContainerEvent(PanelContainerEvent.SETUP_REQUESTED, null, container, true, false));
			resetContainer()
		}
		
		public function setContainers(sideCode:int, currentSide:IContainer, otherSide:IContainer):void
		{
			this.currentSide = currentSide
			this.otherSide = otherSide
			currentSideCode = sideCode
			render()
		}
		
		public function resetContainer():void 
		{
			sideCode = PanelContainerSide.FILL;
			otherSide = currentSide = null;
			minSideRatio = 0.0;
			maxSideRatio = 1.0;
			panelList = null;
			sideRatio = 0.5;
		}
		
		public function getPanelCount(recursive:Boolean):int
		{
			var numPanels:int;
			for (var i:int = numChildren - 1; i >= 0; --i)
			{
				var currChild:DisplayObject = getChildAt(i)
				if(recursive && currChild is IContainer) {
					numPanels += (currChild as IContainer).getPanelCount(true)
				}
				else {
					numPanels += int(currChild is IPanel)
				}
			}
			return numPanels
		}
		
		public function hasPanels(recursive:Boolean):Boolean
		{
			for (var i:int = numChildren - 1; i >= 0; --i)
			{
				var currChild:DisplayObject = getChildAt(i)
				if(recursive && currChild is IContainer) {
					return (currChild as IContainer).hasPanels(true)
				}
				else if(currChild is IPanel) {
					return true
				}
			}
			return false
		}
		
		public function get hasSides():Boolean {
			return (currentSide || otherSide)
		}
		
		public function get panels():Array
		{
			var panelList:Array = new Array()
			for (var i:int = numChildren - 1; i >= 0; --i)
			{
				var currChild:DisplayObject = getChildAt(i)
				if(currChild is IPanel) {
					panelList.push(currChild)
				}
			}
			return panelList
		}
		
		public function getSide(side:int):IContainer
		{
			if(side == PanelContainerSide.FILL) {
				return this;
			}
			else if (hasSides)
			{
				if(sideCode == side) {
					return currentSide
				}
				else if(PanelContainerSide.isComplementary(sideCode, side)) {
					return otherSide
				}
			}
			return null;
		}
		
		public function addToSide(side:int, panel:IPanel):IContainer
		{
			var container:IContainer = getSide(side)
			if (container == this)
			{
				var displayablePanel:DisplayObject = panel as DisplayObject
				addChild(displayablePanel)
				if (displayablePanelList)
				{
					var rect:Rectangle = (displayablePanelList as IDisplayablePanelList).visibleRegion;
					displayablePanel.height = rect.height;
					displayablePanel.width = rect.width;
					displayablePanel.x = rect.x
					displayablePanel.y = rect.y
					setChildIndex(displayablePanelList, numChildren - 1)
				}
				else
				{
					displayablePanel.x = displayablePanel.y = 0;
					displayablePanel.height = height
					displayablePanel.width = width;
				}
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.PANEL_ADDED, panel, this, true, false))
			}
			else
			{
				if (!container) {
					addContainer(PanelContainerSide.getComplementary(side), createContainer())
				}
				container = getSide(side);
				container.addToSide(PanelContainerSide.FILL, panel)
			}
			return container
		}
		
		private function resizeContainers(side:int, maxWidth:Number, maxHeight:Number, sideRatio:Number, sideContainer:IContainer, otherContainer:IContainer):void 
		{
			if(!(sideContainer || otherContainer)) {
				return;
			}
			var swap:Number;
			var sideX:Number = 0, sideY:Number = 0, sideWidth:Number, sideHeight:Number;
			var otherSideX:Number, otherSideY:Number, otherSideWidth:Number, otherSideHeight:Number;
			if (side == PanelContainerSide.LEFT || side == PanelContainerSide.RIGHT)
			{
				otherSideHeight = sideHeight = maxHeight;
				otherSideX = sideWidth = maxWidth * sideRatio
				otherSideWidth = maxWidth - sideWidth
			}
			else
			{
				otherSideWidth = sideWidth = maxWidth
				otherSideY = sideHeight = maxHeight * sideRatio;
				otherSideHeight = maxHeight - sideHeight
			}
			if (side == PanelContainerSide.BOTTOM || side == PanelContainerSide.RIGHT)
			{
				//swap container x, y, width and height
				swap = sideX;
				sideX = otherSideX;
				otherSideX = swap;
				
				swap = sideY;
				sideY = otherSideY;
				otherSideY = swap;
				
				swap = sideWidth;
				sideWidth = otherSideWidth;
				otherSideWidth = swap;
				
				swap = sideHeight;
				sideHeight = otherSideHeight;
				otherSideHeight = swap;
			}
			
			if (sideContainer)
			{
				sideContainer.x = sideX
				sideContainer.y = sideY
				sideContainer.width = sideWidth;
				sideContainer.height = sideHeight;
			}
			
			if (otherContainer)
			{
				otherContainer.x = otherSideX
				otherContainer.y = otherSideY
				otherContainer.width = otherSideWidth;
				otherContainer.height = otherSideHeight;
			}
		}
		
		public function removePanel(panel:IPanel):IContainer
		{
			if(!panel) {
				return null;
			}
			else if (panel.parent == this) {
				removeChild(panel as DisplayObject)
			}
			else
			{
				var result:IContainer;
				if (currentSide) {
					result = currentSide.removePanel(panel)
				}
				if(result) {
					return result;
				}
				else if(otherSide) {
					return otherSide.removePanel(panel)
				}
			}
			return null;
		}
		
		public function removeContainer(panelContainer:IContainer):IContainer
		{
			var oppContainer:IContainer;
			if (panelContainer == currentSide) {
				oppContainer = otherSide
			}
			else if (panelContainer == otherSide) {
				oppContainer = currentSide
			}
			else
			{
				var result:IContainer;
				if (currentSide) {
					result = currentSide.removeContainer(panelContainer)
				}
				if(result) {
					return result
				}
				if (otherSide) {
					result = otherSide.removeContainer(panelContainer)
				}
				return result
			}
			oppContainer.mergeIntoContainer(this)
			removeChild(oppContainer as DisplayObject)
			removeChild(panelContainer as DisplayObject)
			return panelContainer
		}
		
		public function addContainer(side:int, container:IContainer):IContainer
		{
			if (!container) {
				return null;
			}
			
			var retCon:IContainer							//heh
			var sideContainer:IContainer = getSide(side)	//get: FILL (this) or side (child container)
			if (sideContainer && sideContainer.hasSides == container.hasSides)
			{
				//merge if there are no sides for this current container
				//or this container has a side equal to the side supplied
				container.mergeIntoContainer(sideContainer)
				retCon = sideContainer
			}
			else
			{
				var selfContainer:IContainer = createContainer()
				resizeContainers(side, width, height, sideRatio, selfContainer, container);
				mergeIntoContainer(selfContainer)
				currentSide = selfContainer;
				otherSide = container
				sideCode = side;
				addChild(container as DisplayObject)
				addChild(selfContainer as DisplayObject)
				
				render()
				retCon = container;
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.SETUP_REQUESTED, null, container, true, false));
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.SETUP_REQUESTED, null, selfContainer, true, false));
			}
			return retCon
		}
		
		override public function get height():Number {
			return num_maxHeight
		}
		
		override public function set height(value:Number):void
		{
			if (height != value) {
				redraw(width, value)
			}
		}
		
		override public function get width():Number {
			return num_maxWidth;
		}
		
		override public function set width(value:Number):void
		{
			if (width != value) {
				redraw(value, height)
			}
		}
		
		private function get otherSide():IContainer {
			return plc_otherSide;
		}
		
		private function set otherSide(value:IContainer):void {
			plc_otherSide = value;
		}
		
		private function get currentSide():IContainer {
			return plc_currentSide;
		}
		
		private function set currentSide(value:IContainer):void {
			plc_currentSide = value;
		}
		
		public function get currentSideCode():int {
			return i_currSide
		}
		
		public function set currentSideCode(sideCode:int):void {
			i_currSide = sideCode
		}
		/**
		 * Analog for currentSideCode, but allows setting as well
		 */
		private function get sideCode():int {
			return i_currSide;
		}
		/**
		 * Analog for currentSideCode, but allows setting as well
		 */
		private function set sideCode(value:int):void {
			i_currSide = value;
		}
		
		public function set sideRatio(ratio:Number):void
		{
			if(ratio == num_ratio) {
				return;
			}
			else if(ratio > num_maxRatio) {
				ratio = num_maxRatio
			}
			else if(ratio < num_minRatio) {
				ratio = num_minRatio
			}
			num_ratio = ratio;
			render()
		}
		
		public function get sideRatio():Number {
			return num_ratio
		}
		
		public function get containerState():Boolean {
			return b_containerState;
		}
		
		public function set containerState(value:Boolean):void {
			b_containerState = value;
		}
		
		public function get maxSideRatio():Number {
			return num_maxRatio;
		}
		
		public function set maxSideRatio(value:Number):void {
			num_maxRatio = value;
		}
		
		public function get minSideRatio():Number {
			return num_minRatio;
		}
		
		public function set minSideRatio(value:Number):void {
			num_minRatio = value;
		}
		
		public function render():void {
			redraw(width, height)
		}
		
		/**
		 * Gets the given side from the container. Creates it if it does not exist.
		 * @param	side
		 * @return
		 */
		public function fetchSide(side:int):IContainer
		{
			if(!getSide(side)) {
				addContainer(PanelContainerSide.getComplementary(side), createContainer())
			}
			return getSide(side)
		}
		
		private function createContainer():IContainer
		{
			var container:IContainer = new DefaultContainer()
			dispatchEvent(new PanelContainerEvent(PanelContainerEvent.CONTAINER_CREATED, null, container, true, false));
			return container
		}
		
		private function redraw(width:Number, height:Number):void 
		{
			var valueChange:Boolean;
			var dispPanelList:DisplayObject = displayablePanelList;
			var effX:Number, effY:Number , effHeight:Number = height, effWidth:Number = width;
			if (!(num_maxWidth == width && num_maxHeight == height))
			{
				num_maxHeight = height
				num_maxWidth = width
				valueChange = true;
				if (dispPanelList)
				{
					var displayable:IDisplayablePanelList = dispPanelList as IDisplayablePanelList;
					var preferredLocation:Point = displayable.preferredLocation
					dispPanelList.x = preferredLocation.x
					dispPanelList.y = preferredLocation.y
					displayable.maxHeight = height;
					displayable.maxWidth = width;
					addChild(dispPanelList)
				}
			}
			resizeContainers(sideCode, width, height, sideRatio, currentSide, otherSide)
			if (dispPanelList)
			{
				var rect:Rectangle = (dispPanelList as IDisplayablePanelList).visibleRegion
				effHeight = rect.height;
				effWidth = rect.width;
				effX = rect.x;
				effY = rect.y;
			}
			for (var i:int = numChildren - 1; i >= 0; --i)
			{
				var currPanel:IPanel = getChildAt(i) as IPanel
				if (currPanel)
				{
					currPanel.x = effX;
					currPanel.y = effY;
					currPanel.width = effWidth;
					currPanel.height = effHeight;
				}
			}
			if(valueChange) {
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.RESIZED, null, this, true, false))
			}
		}
	}
}