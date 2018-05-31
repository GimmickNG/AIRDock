package airdock.impl 
{
	import airdock.delegates.ContainerDelegate;
	import airdock.enums.PanelContainerSide;
	import airdock.events.PanelContainerEvent;
	import airdock.events.PropertyChangeEvent;
	import airdock.interfaces.display.IDisplayFilter;
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
	 * @eventType	airdock.events.PanelContainerEvent.CONTAINER_REMOVE_REQUESTED
	 */
	[Event(name="pcContainerRemoveRequested", type="airdock.events.PanelContainerEvent")]
	
	/**
	 * Dispatched when the (previously empty) container has panels added to it, or right after it is created.
	 * @eventType	airdock.events.PanelContainerEvent.SETUP_REQUESTED
	 */
	[Event(name="pcSetupRequested", type="airdock.events.PanelContainerEvent")]
	
	/**
	 * Dispatched whenever a new container needs to be created for this container, and the Docker implementation has to return an instance to it.
	 * Can be intercepted to return a different type of container instead.
	 * 
	 * If no container is sent to the container, then it falls back to creating a new container automatically, and dispatches a CONTAINER_CREATED event.
	 * @eventType	airdock.events.PanelContainerEvent.CONTAINER_CREATING
	 */
	[Event(name="pcContainerCreating", type="airdock.events.PanelContainerEvent")]
	
	/**
	 * Dispatched whenever a new container has been created for this container, either by the Docker implementation which it is a part of, or by the container itself.
	 * @eventType	airdock.events.PanelContainerEvent.CONTAINER_CREATED
	 */
	[Event(name="pcContainerCreated", type="airdock.events.PanelContainerEvent")]
	
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
		private var plc_otherSide:IContainer;
		private var plc_currentSide:IContainer;
		private var cl_containerDelegate:ContainerDelegate;
		public function DefaultContainer()
		{
			cl_containerDelegate = new ContainerDelegate(this)
			
			sideSize = 0.5;
			maxSideSize = 1.0;
			minSideSize = 0.0;
			width = height = 128;
			sideCode = PanelContainerSide.FILL;
			addEventListener(PropertyChangeEvent.PROPERTY_CHANGING, updateSizeOnRedraw, false, 0, true)
			addEventListener(PropertyChangeEvent.PROPERTY_CHANGED, updateContainer, false, 0, true)
			otherSide = currentSide = null;
			addChildUpdateListeners();
			panelList = null;
		}
		
		private function updateSizeOnRedraw(evt:PropertyChangeEvent):void 
		{
			var value:Number = Number(evt.newValue)
			if(evt.isDefaultPrevented() || evt.target != this) {
				return;
			}
			else switch(evt.fieldName)
			{
				case "width":
					redraw(value, height);
					break;
				case "height":
					redraw(width, value);
					break;
			}
		}
		
		private function updateContainer(evt:PropertyChangeEvent):void 
		{
			if (evt.target == this)
			{
				var value:Number = Number(evt.newValue)
				switch(evt.fieldName)
				{
					case "sideSize":
						render();
					case "width":
					case "height":
						cl_containerDelegate.applyFilters(displayFilters)
						break;
					case "maxSideSize":
						if(value < sideSize) {
							sideSize = value
						}
						break;
					case "minSideSize":
						if(value > sideSize) {
							sideSize = value;
						}
						break;
				}
			}
			else 
			{
				var currPanel:IPanel = evt.target as IPanel
				if (panelList && currPanel && currPanel.parent == this && evt.eventPhase == EventPhase.BUBBLING_PHASE) {
					panelList.updatePanel(currPanel)
				}
			}
		}
		
		private function addChildUpdateListeners():void
		{
			addEventListener(Event.ADDED, updatePanelListOnEvent, false, 0, true)
			addEventListener(Event.REMOVED, updatePanelListOnEvent, false, 0, true)
			addEventListener(Event.REMOVED, dispatchRemoveOnEmpty, false, 0, true)
		}
		
		private function removeChildUpdateListeners():void
		{
			removeEventListener(Event.REMOVED, dispatchRemoveOnEmpty)
			removeEventListener(Event.REMOVED, updatePanelListOnEvent)
			removeEventListener(Event.ADDED, updatePanelListOnEvent)
		}
		
		private function dispatchRemoveOnEmpty(evt:Event):void 
		{
			var target:IPanel = evt.target as IPanel;
			var panels:Vector.<IPanel> = getPanels(true);
			if (target && (!panels.length || (panels.length <= 1 && panels.indexOf(target) != -1)))
			{
				cl_containerDelegate.clearFilters(displayFilters)
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.CONTAINER_REMOVE_REQUESTED, panels, this, true, true))
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
				var panelArray:Vector.<IPanel> = getPanels(false);
				panelArray.forEach(function clearContainer(panel:IPanel, index:int, array:Vector.<IPanel>):void {
					removePanel(panel);
				});
				return panelArray.length;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function flattenContainer():Boolean
		{
			if(!hasSides) {
				return false;
			}
			otherSide.flattenContainer()
			currentSide.flattenContainer()
			otherSide.mergeIntoContainer(this)
			setContainers(PanelContainerSide.FILL, null, null)	//this may not be necessary since otherSide will anyways have side FILL and no subcontainers; keep it just in case?
			return true;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get panelList():IPanelList {
			return cl_containerDelegate.panelList
		}
		
		/**
		 * @inheritDoc
		 */
		public function set panelList(panelList:IPanelList):void
		{
			removePanelListListeners(this.panelList)
			if (displayablePanelList && displayablePanelList.parent == this) {
				removeChild(displayablePanelList)
			}
			
			cl_containerDelegate.panelList = panelList
			if (panelList)
			{
				getPanels(false).forEach(function populatePanelList(panel:IPanel, index:int, array:Vector.<IPanel>):void {
					panelList.addPanel(panel);
				})
				if (panelList is IDisplayablePanelList) {
					displayablePanelList = DisplayObject(panelList)	//hard cast to throw error if panelList is not of type DisplayObject
				}
			}
			addPanelListListeners(panelList)
		}
		
		private function get displayablePanelList():DisplayObject {
			return panelList as DisplayObject;
		}
		
		private function set displayablePanelList(displayable:DisplayObject):void
		{
			if(!displayable) {
				return;
			}
			var displayableList:IDisplayablePanelList = displayable as IDisplayablePanelList
			displayableList.maxHeight = height;
			displayableList.maxWidth = width;
			addChild(displayable)
		}
		
		private function removePanelListListeners(panelList:IPanelList):void 
		{
			if(!panelList) {
				return;
			}
			panelList.removeEventListener(PanelContainerEvent.SHOW_REQUESTED, bumpPanelToTop)
			panelList.removeEventListener(PanelContainerEvent.DRAG_REQUESTED, sendDockPanelRequest)
			panelList.removeEventListener(PanelContainerEvent.PANEL_REMOVE_REQUESTED, removePanelOnEvent)
			panelList.removeEventListener(PanelContainerEvent.STATE_TOGGLE_REQUESTED, sendDockPanelRequest)
		}
		
		private function addPanelListListeners(panelList:IPanelList):void 
		{
			if(!panelList) {
				return;
			}
			panelList.addEventListener(PanelContainerEvent.STATE_TOGGLE_REQUESTED, sendDockPanelRequest, false, 0, true)
			panelList.addEventListener(PanelContainerEvent.PANEL_REMOVE_REQUESTED, removePanelOnEvent, false, 0, true)
			panelList.addEventListener(PanelContainerEvent.DRAG_REQUESTED, sendDockPanelRequest, false, 0, true)
			panelList.addEventListener(PanelContainerEvent.SHOW_REQUESTED, bumpPanelToTop, false, 0, true)
		}
		
		private function removePanelOnEvent(evt:PanelContainerEvent):void
		{
			if (!evt.isDefaultPrevented())
			{
				evt.relatedPanels.forEach(function removePanelsFromContainer(item:IPanel, index:int, array:Vector.<IPanel>):void {
					removePanel(item);
				});
				showPanel(getPanels(false).pop());
			}
		}
		
		private function bumpPanelToTop(evt:PanelContainerEvent):void
		{
			if (!evt.isDefaultPrevented())
			{
				evt.relatedPanels.forEach(function showPanels(item:IPanel, index:int, array:Vector.<IPanel>):void {
					showPanel(item);
				});
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function showPanel(panel:IPanel):Boolean
		{
			if(!panel) {
				return false;
			}
			else if (panel.parent == this)
			{
				for (var i:int = numChildren - 1, currPanel:IPanel; !currPanel && i >= 0; --i) {
					currPanel = getChildAt(i) as IPanel;	//gets topmost panel
				}
				if (currPanel)
				{
					swapChildren(currPanel as DisplayObject, panel as DisplayObject);
					if(panelList) {
						panelList.showPanel(panel)
					}
					return true;
				}
			}
			else
			{
				var container:IContainer = findPanel(panel);
				if(container) {
					return container.showPanel(panel);
				}
			}
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		public function isPanelVisible(panel:IPanel):Boolean
		{
			if(!panel) {
				return false;
			}
			else if (panel.parent == this)
			{
				for (var i:int = numChildren - 1, currPanel:IPanel; !currPanel && i >= 0; --i) {
					currPanel = getChildAt(i) as IPanel;	//gets topmost panel
				}
				return currPanel == panel;
			}
			else
			{
				var container:IContainer = findPanel(panel);
				if(container) {
					return container.isPanelVisible(panel);
				}
			}
			return false;
		}
		
		private function sendDockPanelRequest(evt:PanelContainerEvent):void
		{
			evt.stopImmediatePropagation();
			if(evt.isDefaultPrevented()) {
				return;
			}
			var relatedPanels:Vector.<IPanel> = evt.relatedPanels
			if (dispatchEvent(new PanelContainerEvent(evt.type, relatedPanels, this, true, true)) && relatedPanels && relatedPanels.length)
			{
				var panelList:Vector.<IPanel> = getPanels(false).filter(function getListDifference(item:IPanel, index:int, array:Vector.<IPanel>):Boolean {
					return item && relatedPanels.indexOf(item) == -1;	//search and show a panel that's not any of the related panels
				});
				showPanel(panelList.pop())
			}
		}
		
		private function updatePanelListOnEvent(evt:Event):void 
		{
			var panel:IPanel = evt.target as IPanel;
			var panelList:IPanelList = this.panelList;
			if (!(panel && evt.eventPhase == EventPhase.BUBBLING_PHASE && panel.parent == this)) {
				return;
			}
			else if (panelList)
			{
				if (evt.type == Event.REMOVED) {
					panelList.removePanel(panel)
				}
				else
				{
					panelList.addPanelAt(panel, getChildIndex(panel as DisplayObject))
					if(displayablePanelList) {
						addChild(displayablePanelList)
					}
				}
				
				for (var i:int = numChildren - 1, child:IPanel; !child && i >= 0; --i, child = getChildAt(i) as IPanel)
				{
					if (child) {
						panelList.showPanel(child);
					}
				}
			}
			else {
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.SETUP_REQUESTED, null, this, true, true));
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function mergeIntoContainer(container:IContainer):void
		{
			if(container == this) {
				return;
			}
			cl_containerDelegate.clearFilters(displayFilters)	//remove all filters, in case they have added children of their own via apply()
			if (hasSides && hasSides == container.hasSides && PanelContainerSide.isComplementary(sideCode, container.sideCode))
			{
				/* Merges two containers if they have same number of sides, and are complementary.
				 * For example, suppose two trees exist:
				 *          A             H
				 *        B   C         I   J
				 *       d e f g       k l m n
				 * 
				 * where the leafs [d, e, f, g] and [k, l, m, n] are panels
				 * Then, merging H into A should yield:
				 *                 A
				 *           B           C
				 *       d,k   e,l   f,m   g,n
				 * Or if the sides are not the same, and it has to be flipped for H prior to merging
				 * (assuming only the level under A has to be flipped; otherwise, recursively flip as needed)
				 *                 A
				 *           B           C
				 *       D,M   E,N   F,K   G,L
				 */
				var tempCont:IContainer = currentSide, otherCont:IContainer = otherSide;
				var containerSideCode:int = container.sideCode
				if (sideCode != containerSideCode)
				{
					otherCont = currentSide;	//is not equal;
					tempCont = otherSide;		//flip sides
				}
				tempCont.mergeIntoContainer(container.getSide(containerSideCode))
				otherCont.mergeIntoContainer(container.getSide(PanelContainerSide.getComplementary(containerSideCode)))
			}
			else
			{
				//NOTE: Should the container to be merged call mergeIntoContainer() on the destination, or the other way around?
				container.setContainers(sideCode, currentSide, otherSide);
				removeChildUpdateListeners();	//remove listener since we don't want this to occur while we're anyways emptying the container
				getPanels(false).forEach(function addPanelToContainer(item:IPanel, index:int, array:Vector.<IPanel>):void {
					container.addToSide(PanelContainerSide.FILL, item);
				});
				var children:Vector.<DisplayObject> = new Vector.<DisplayObject>()
				for (var i:uint = 0; i < numChildren; ++i)
				{
					var currChild:DisplayObject = getChildAt(i)
					if (!(currChild == displayablePanelList || currChild == currentSide || currChild == otherSide)) {
						children.push(currChild);
					}
				}
				children.forEach(function addAsDirectChild(item:DisplayObject, index:int, array:Vector.<DisplayObject>):void {
					container.addChild(item);
				});
				addChildUpdateListeners();
				setContainers(PanelContainerSide.FILL, null, null)
				if(container.panelList is IDisplayablePanelList) {
					container.setChildIndex(container.panelList as DisplayObject, container.numChildren - 1)
				}
			}
			container.sideSize = sideSize
			container.minSideSize = minSideSize
			container.maxSideSize = maxSideSize
			dispatchEvent(new PanelContainerEvent(PanelContainerEvent.SETUP_REQUESTED, null, container, true, true));
		}
		
		/**
		 * @inheritDoc
		 */
		public function setContainers(sideCode:int, currentSide:IContainer, otherSide:IContainer):void
		{
			var prevCurrentSide:DisplayObject = this.currentSide as DisplayObject;
			var prevOtherSide:DisplayObject = this.otherSide as DisplayObject;
			if(prevCurrentSide && prevCurrentSide.parent == this) {
				removeChild(prevCurrentSide)
			}
			if(prevOtherSide && prevOtherSide.parent == this) {
				removeChild(prevOtherSide)
			}
			cl_containerDelegate.clearFilters(displayFilters)
			this.sideCode = sideCode
			this.otherSide = otherSide
			this.currentSide = currentSide
			if(otherSide) {
				addChild(otherSide as DisplayObject)
			}
			if(currentSide) {
				addChild(currentSide as DisplayObject)
			}
			dispatchEvent(new PanelContainerEvent(PanelContainerEvent.SETUP_REQUESTED, null, this, true, true));
			render()
		}
		
		/**
		 * @inheritDoc
		 */
		public function getPanelCount(recursive:Boolean):int
		{
			var numPanels:int;
			for (var i:int = 0; i < numChildren; ++i)
			{
				if(getChildAt(i) is IPanel) {
					++numPanels;
				}
			}
			if (recursive && hasSides) {
				numPanels += currentSide.getPanelCount(true) + otherSide.getPanelCount(true)
			}
			return numPanels
		}
		
		/**
		 * @inheritDoc
		 */
		public function hasPanels(recursive:Boolean):Boolean
		{
			for (var i:int = 0; i < numChildren; ++i)
			{
				if(getChildAt(i) is IPanel) {
					return true;
				}
			}
			if (recursive && hasSides) {
				return currentSide.hasPanels(true) || otherSide.hasPanels(true)
			}
			return false
		}
		
		/**
		 * @inheritDoc
		 */
		public function get hasSides():Boolean {
			return currentSide && otherSide;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getPanels(recursive:Boolean):Vector.<IPanel>
		{
			var result:Vector.<IPanel> = new Vector.<IPanel>()
			for (var i:int = 0; i < numChildren; ++i)
			{
				var panel:IPanel = getChildAt(i) as IPanel
				if(panel) {
					result.push(panel)
				}
			}
			if (recursive && hasSides) {
				result = result.concat(currentSide.getPanels(true).concat(otherSide.getPanels(true)));
			}
			return result;
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
				}
				else
				{
					displayablePanel.x = displayablePanel.y = 0;
					displayablePanel.height = height
					displayablePanel.width = width;
				}
				
				for (var index:int = numChildren - 1; index >= 0 && !(getChildAt(index) is IPanel); --index) { /*gets topmost panel*/ }
				addChildAt(displayablePanel, index + 1)	//adds panels above the previously highest panel, so as to not obscure filters, etc.
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.PANEL_ADDED, new <IPanel>[panel], this, true, false))
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
			if (PanelContainerSide.isComplementary(side, PanelContainerSide.LEFT))
			{
				otherSideHeight = sideHeight = maxHeight;
				sideWidth = sideSize
				if(sideSize <= 1.0) {
					sideWidth *= maxWidth
				}
				else if(sideWidth > maxWidth) {
					sideWidth = maxWidth
				}
				otherSideX = sideWidth
				otherSideWidth = maxWidth - sideWidth
			}
			else
			{
				otherSideWidth = sideWidth = maxWidth
				sideHeight = sideSize
				if(sideSize <= 1.0) {
					sideHeight *= maxHeight
				}
				else if(sideHeight > maxHeight) {
					sideHeight = maxHeight
				}
				otherSideY = sideHeight
				otherSideHeight = maxHeight - sideHeight
			}
			if (side == PanelContainerSide.BOTTOM || side == PanelContainerSide.RIGHT)	//swap container x, y, width and height
			{
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
			var result:IContainer = findPanel(panel)
			if (result) {
				result.removeChild(panel as DisplayObject)
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
			else if (getPanels(false).indexOf(panel) != -1) {
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
			if(panelContainer == this) {
				return null;	//cannot return this, because remove operation did not succeed
			}
			else if (panelContainer == currentSide) {
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
			if (sideContainer && ((sideContainer == this && !getPanelCount(true)) || (sideContainer.hasSides == container.hasSides && sideContainer.sideCode == container.sideCode)))
			{
				/* Merge into this container if:
					* there are no sides for this current container, or
					* this has no panels and the side is this container, or
					* this container has a side equal to the side supplied.
				 */
				container.mergeIntoContainer(sideContainer);
				retCon = sideContainer;
			}
			else
			{
				/* Procedure:
					 * Merge this container into a new container, selfContainer
					 * Add selfContainer as a subcontainer of this container
					 * Add the supplied container as a subcontainer of this container
				 */
				var selfContainer:IContainer = createContainer()
				resizeContainers(side, width, height, sideSize, selfContainer, container);
				mergeIntoContainer(selfContainer)
				currentSide = selfContainer;
				otherSide = container
				sideCode = side;
				addChild(container as DisplayObject)
				addChild(selfContainer as DisplayObject)
				
				render()
				retCon = container;
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.SETUP_REQUESTED, null, container, true, true));
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.SETUP_REQUESTED, null, selfContainer, true, true));
			}
			return retCon
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get height():Number {
			return cl_containerDelegate.height
		}
		
		/**
		 * @inheritDoc
		 */
		override public function set height(value:Number):void {
			cl_containerDelegate.height = value
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get width():Number {
			return cl_containerDelegate.width;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function set width(value:Number):void {
			cl_containerDelegate.width = value
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
			return cl_containerDelegate.sideCode
		}
		
		/**
		 * @inheritDoc
		 */
		public function set sideCode(sideCode:int):void {
			cl_containerDelegate.sideCode = sideCode
		}
		
		/**
		 * @inheritDoc
		 */
		public function get sideSize():Number {
			return cl_containerDelegate.sideSize
		}
		
		/**
		 * @inheritDoc
		 */
		public function set sideSize(value:Number):void {
			cl_containerDelegate.sideSize = value
		}
		
		/**
		 * @inheritDoc
		 */
		public function get containerState():Boolean {
			return cl_containerDelegate.containerState;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set containerState(value:Boolean):void {
			cl_containerDelegate.containerState = value;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get maxSideSize():Number {
			return cl_containerDelegate.maxSideSize;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set maxSideSize(value:Number):void {
			cl_containerDelegate.maxSideSize = value;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get minSideSize():Number {
			return cl_containerDelegate.minSideSize;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set minSideSize(value:Number):void {
			cl_containerDelegate.minSideSize = value;
		}
		
		public function get displayFilters():Vector.<IDisplayFilter> {
			return cl_containerDelegate.displayFilters;
		}
		
		public function set displayFilters(value:Vector.<IDisplayFilter>):void {
			cl_containerDelegate.displayFilters = value
		}
		
		/**
		 * @inheritDoc
		 */
		private function render():void {
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
		
		/**
		 * Signals that this container wants a new container to be attached to it.
		 * Returns the IContainer instance which the Docker returns to it via the createContainer() method in the Docker's IContainerFactory.
		 * If there is no connection to its Docker instance, or if there is otherwise no IContainer instance returned to it, then it falls back to creating a default container.
		 * @return	A container which is either created by the Docker's IContainerFactory, or a default container.
		 */
		private function createContainer():IContainer
		{
			var container:IContainer;
			var containerCreated:Boolean;
			function getContainer(evt:PanelContainerEvent):void
			{
				containerCreated = true;
				container = evt.relatedContainer;
				removeEventListener(PanelContainerEvent.CONTAINER_CREATED, getContainer);
			}
			addEventListener(PanelContainerEvent.CONTAINER_CREATED, getContainer, false, 0, true);
			dispatchEvent(new PanelContainerEvent(PanelContainerEvent.CONTAINER_CREATING, null, this, true, true));
			container ||= (!containerCreated && new DefaultContainer()) as IContainer;	//fallback if there is no response from Docker
			
			if (container)
			{
				removeEventListener(PanelContainerEvent.CONTAINER_CREATED, getContainer);
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.CONTAINER_CREATED, null, container, true, false));
			}
			return container
		}
		
		private function redraw(width:Number, height:Number):void 
		{
			var dispPanelList:DisplayObject = displayablePanelList;
			var effHeight:Number = height, effWidth:Number = width;
			var oldWidth:Number = this.width, oldHeight:Number = this.height
			var valueChange:Boolean = !(oldWidth == effWidth && oldHeight == effHeight)
			if (valueChange)
			{
				var displayable:IDisplayablePanelList = dispPanelList as IDisplayablePanelList;
				var preferredLocation:Point;
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
				var effX:Number, effY:Number;
				if (dispPanelList)
				{
					var rect:Rectangle = (dispPanelList as IDisplayablePanelList).visibleRegion
					effHeight = rect.height;
					effWidth = rect.width;
					effX = rect.x;
					effY = rect.y;
				}
				var panelArray:Vector.<IPanel> = getPanels(false);
				for (var i:int = panelArray.length - 1; i >= 0; --i)
				{
					var currPanel:IPanel = panelArray[i];
					currPanel.height = effHeight;
					currPanel.width = effWidth;
					currPanel.x = effX;
					currPanel.y = effY;
				}
			}
		}
	}
}