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
	 * Dispatched when a subcontainer is emptied, and this container is to be flattened (by having the other subcontainer merge into it.)
	 * @eventType	airdock.events.PanelContainerEvent.REMOVE_REQUESTED
	 */
	[Event(name="pcPanelRemoveRequested", type="airdock.events.PanelContainerEvent")]
	
	/**
	 * Dispatched when the (previously empty) container has panels added to it, or right after it is created.
	 * @eventType	airdock.events.PanelContainerEvent.SETUP_REQUESTED
	 */
	[Event(name="pcSetupRequested", type="airdock.events.PanelContainerEvent")]
	
	/**
	 * Dispatched whenever a new container is created automatically by this container; this is done when it is to be added as a subcontainer of this container.
	 * @eventType	airdock.events.PanelContainerEvent.CONTAINER_CREATED
	 */
	[Event(name="pcContainerCreated", type="airdock.events.PanelContainerEvent")]
	
	/**
	 * Dispatched whenever a container has had its size (width, height, or both) changed.
	 * @eventType	airdock.events.PanelContainerEvent.RESIZED
	 */
	[Event(name="pcContainerResized", type="airdock.events.PanelContainerEvent")]
	
	/**
	 * Dispatched when a panel is added directly to this container.
	 * @eventType	airdock.events.PanelContainerEvent.PANEL_ADDED
	 */
	[Event(name="pcPanelAdded", type="airdock.events.PanelContainerEvent")]
	
	/**
	 * Default IContainer implementation.
	 * 
	 * Always has either zero or two subcontainers at a time, even if only one is occupied.
	 * 
	 * @author	Gimmick
	 * @see	airdock.interfaces.docking.IContainer
	 */
	public class DefaultContainer extends Sprite implements IContainer
	{
		private var i_currSide:int;
		private var num_sideSize:Number;
		private var num_minSideSize:Number;
		private var num_maxSideSize:Number;
		private var num_maxWidth:Number;
		private var num_maxHeight:Number;
		private var cl_panelList:IPanelList;
		private var b_containerState:Boolean;
		private var plc_otherSide:IContainer;
		private var plc_currentSide:IContainer;
		private var vec_panels:Vector.<IPanel>
		public function DefaultContainer()
		{
			sideSize = 0.5;
			panelList = null;
			minSideSize = 0.0;
			maxSideSize = 0.999999;
			addChildUpdateListeners()
			otherSide = currentSide = null;
			num_maxWidth = num_maxHeight = 128
			vec_panels = new Vector.<IPanel>();
			i_currSide = PanelContainerSide.FILL;
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
		
		/**
		 * @inheritDoc
		 */
		public function removePanels(recursive:Boolean):int
		{
			if (hasSides)
			{
				if (!recursive) {
					return 0;
				}
				var removeFromCurrentSide:int = currentSide.removePanels(true);
				var removeFromOtherSide:int = otherSide.removePanels(true);
				setContainers(PanelContainerSide.FILL, null, null);
				return (removeFromCurrentSide + removeFromOtherSide);
			}
			else
			{
				var panelArray:Vector.<IPanel> = panels;
				for (var i:uint = 0; i < panelArray.length; ++i) {
					removePanel(panelArray[i])
				}
				return panelArray.length
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function flattenContainer():Boolean
		{
			var canFlatten:Boolean = (hasSides && sideCode != PanelContainerSide.FILL)
			if (canFlatten)
			{
				otherSide.flattenContainer()
				currentSide.flattenContainer()
				otherSide.mergeIntoContainer(this)
				setContainers(PanelContainerSide.FILL, null, null)
			}
			return canFlatten
		}
		
		/**
		 * @inheritDoc
		 */
		public function get panelList():IPanelList {
			return cl_panelList
		}
		
		/**
		 * @inheritDoc
		 */
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
				var panelArray:Vector.<IPanel> = panels;
				for (var i:uint = 0; i < panelArray.length; ++i) {
					panelList.addPanel(panelArray[i]);
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
			panelList.removeEventListener(PanelContainerEvent.STATE_TOGGLE_REQUESTED, sendDockPanelRequest)
		}
		
		private function addPanelListListeners(panelList:IPanelList):void 
		{
			if(!panelList) {
				return;
			}
			panelList.addEventListener(PanelContainerEvent.STATE_TOGGLE_REQUESTED, sendDockPanelRequest, false, 0, true)
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
				var panelList:Vector.<IPanel> = panels;
				if (panelList.length) {	//shows the other panel in the UIPanelList
					(evt.currentTarget as IPanelList).showPanel(panelList.shift())
				}
			}
		}
		
		private function updatePanelBarOnEvent(evt:Event):void 
		{
			var panel:IPanel = evt.target as IPanel;
			if (!(panel && evt.eventPhase == EventPhase.BUBBLING_PHASE && panel.parent == this)) {
				return;
			}
			var index:int = vec_panels.indexOf(panel)
			if (evt.type == Event.ADDED && index == -1) {
				vec_panels.push(panel)
			}
			else if(evt.type == Event.REMOVED && index != -1) {
				vec_panels.splice(index, 1)
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
		 * @inheritDoc
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
			container.minSideSize = minSideSize
			container.maxSideSize = maxSideSize
			container.sideSize = sideSize
			removePanels(true)
			dispatchEvent(new PanelContainerEvent(PanelContainerEvent.SETUP_REQUESTED, null, container, true, false));
		}
		
		/**
		 * @inheritDoc
		 */
		public function setContainers(sideCode:int, currentSide:IContainer, otherSide:IContainer):void
		{
			var prevCurrentSide:DisplayObject = this.currentSide as DisplayObject;
			var prevOtherSide:DisplayObject = this.otherSide as DisplayObject;
			if(prevCurrentSide) {
				removeChild(prevCurrentSide)
			}
			if(prevOtherSide) {
				removeChild(prevOtherSide)
			}
			this.currentSide = currentSide
			this.otherSide = otherSide
			sideCode = sideCode
			render()
		}
		
		/**
		 * @inheritDoc
		 */
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
		
		/**
		 * @inheritDoc
		 */
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
		
		/**
		 * @inheritDoc
		 */
		public function get hasSides():Boolean {
			return (currentSide || otherSide)
		}
		
		/**
		 * @inheritDoc
		 */
		public function get panels():Vector.<IPanel> {
			return vec_panels.concat()
		}
		
		/**
		 * @inheritDoc
		 */
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
		
		/**
		 * @inheritDoc
		 */
		public function addToSide(side:int, panel:IPanel):IContainer
		{
			var container:IContainer = getSide(side)
			if (container == this)
			{
				var displayablePanel:DisplayObject = panel as DisplayObject
				addChild(displayablePanel)
				if (displayablePanelList)
				{
					var rect:Rectangle;
					var displayableList:IDisplayablePanelList = panelList as IDisplayablePanelList;
					displayableList.maxWidth = width;
					displayableList.maxHeight = height;
					rect = displayableList.visibleRegion;
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
		
		private function resizeContainers(side:int, maxWidth:Number, maxHeight:Number, sideSize:Number, sideContainer:IContainer, otherContainer:IContainer):void 
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
				sideWidth = sideSize
				if(sideSize < 1) {
					sideWidth *= maxWidth
				}
				if(sideWidth > maxWidth) {
					sideWidth = maxWidth
				}
				otherSideX = sideWidth
				otherSideWidth = maxWidth - sideWidth
			}
			else
			{
				otherSideWidth = sideWidth = maxWidth
				sideHeight = sideSize
				if(sideSize < 1) {
					sideHeight *= maxHeight
				}
				if(sideHeight > maxHeight) {
					sideHeight = maxHeight
				}
				otherSideY = sideHeight
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
		
		/**
		 * @inheritDoc
		 */
		public function removePanel(panel:IPanel):IContainer
		{
			var result:IContainer = findPanel(panel);
			if (result) {
				result.removeChild(panel as DisplayObject);
			}
			return result;
		}
		
		/**
		 * @inheritDoc
		 */
		public function findPanel(panel:IPanel):IContainer
		{
			if(!panel) {
				return null;
			}
			else if (panel.parent == this) {
				return this;
			}
			else if(hasSides)
			{
				var result:IContainer;
				if (currentSide) {
					result = currentSide.findPanel(panel)
				}
				if(result) {
					return result;
				}
				else if(otherSide) {
					return otherSide.findPanel(panel)
				}
			}
			return null;
		}
		
		/**
		 * @inheritDoc
		 */
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
		
		/**
		 * @inheritDoc
		 */
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
				resizeContainers(side, width, height, sideSize, selfContainer, container);
				mergeIntoContainer(selfContainer)
				currentSide = selfContainer;
				otherSide = container
				i_currSide = side;
				addChild(container as DisplayObject)
				addChild(selfContainer as DisplayObject)
				
				render()
				retCon = container;
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.SETUP_REQUESTED, null, container, true, false));
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.SETUP_REQUESTED, null, selfContainer, true, false));
			}
			return retCon
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get height():Number {
			return num_maxHeight
		}
		
		/**
		 * @inheritDoc
		 */
		override public function set height(value:Number):void
		{
			if (height != value) {
				redraw(width, value)
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get width():Number {
			return num_maxWidth;
		}
		
		/**
		 * @inheritDoc
		 */
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
		
		/**
		 * @inheritDoc
		 */
		public function get sideCode():int {
			return i_currSide
		}
		
		/**
		 * @inheritDoc
		 */
		public function set sideCode(sideCode:int):void {
			i_currSide = sideCode
		}
		
		/**
		 * @inheritDoc
		 */
		public function get sideSize():Number {
			return num_sideSize
		}
		
		/**
		 * @inheritDoc
		 */
		public function set sideSize(value:Number):void {
			num_sideSize = value
		}
		
		/**
		 * @inheritDoc
		 */
		public function get containerState():Boolean {
			return b_containerState;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set containerState(value:Boolean):void {
			b_containerState = value;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get maxSideSize():Number {
			return num_maxSideSize;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set maxSideSize(value:Number):void {
			num_maxSideSize = value;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get minSideSize():Number {
			return num_minSideSize;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set minSideSize(value:Number):void {
			num_minSideSize = value;
		}
		
		/**
		 * @inheritDoc
		 */
		public function render():void {
			redraw(width, height)
		}
		
		/**
		 * @inheritDoc
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
			var preferredLocation:Point;
			var dispPanelList:DisplayObject = displayablePanelList;
			var displayable:IDisplayablePanelList = dispPanelList as IDisplayablePanelList;
			var effX:Number, effY:Number, effHeight:Number = height, effWidth:Number = width;
			var oldWidth:Number = num_maxWidth, oldHeight:Number = num_maxHeight
			if (!(num_maxWidth == width && num_maxHeight == height))
			{
				num_maxHeight = height
				num_maxWidth = width
				valueChange = true;
				if (displayable)
				{
					displayable.maxWidth = width;
					displayable.maxHeight = height;
					preferredLocation = displayable.preferredLocation
					dispPanelList.x = preferredLocation.x
					dispPanelList.y = preferredLocation.y
					addChild(dispPanelList)
				}
			}
			
			if (hasSides) {
				resizeContainers(sideCode, width, height, sideSize, currentSide, otherSide)
			}
			else
			{
				if (dispPanelList)
				{
					var rect:Rectangle = (dispPanelList as IDisplayablePanelList).visibleRegion
					effHeight = rect.height;
					effWidth = rect.width;
					effX = rect.x;
					effY = rect.y;
				}
				var panelArray:Vector.<IPanel> = panels;
				var i:int;
				for (i = panelArray.length - 1; i >= 0; --i)
				{
					if (!panelArray[i].resizable)
					{
						//this panel is not resizable; halt resizing and cancel operations
						num_maxHeight = oldHeight
						num_maxWidth = oldWidth
						if (displayable)
						{
							displayable.maxWidth = oldWidth
							displayable.maxHeight = oldHeight
							preferredLocation = displayable.preferredLocation
							dispPanelList.x = preferredLocation.x
							dispPanelList.y = preferredLocation.y
						}
						return;
					}
				}
				for (i = panelArray.length - 1; i >= 0; --i)
				{
					var currPanel:IPanel = panelArray[i];
					currPanel.height = effHeight;
					currPanel.width = effWidth;
					currPanel.x = effX;
					currPanel.y = effY;
				}
			}
			if(valueChange) {
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.RESIZED, null, this, true, false))
			}
		}
	}
}
