package airdock.impl 
{
	import airdock.delegates.ContainerDelegate;
	import airdock.enums.ContainerSide;
	import airdock.events.PanelContainerEvent;
	import airdock.events.PropertyChangeEvent;
	import airdock.interfaces.display.IDisplayFilter;
	import airdock.interfaces.docking.IContainer;
	import airdock.interfaces.docking.IPanel;
	import airdock.interfaces.ui.IDisplayablePanelList;
	import airdock.interfaces.ui.IPanelList;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventPhase;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
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
			sideCode = ContainerSide.FILL;
			
			addEventListener(PanelContainerEvent.PANEL_REMOVE_REQUESTED, removePanelOnEvent, false, 0, true)
			addEventListener(PanelContainerEvent.PANEL_REMOVED, showOtherPanelOnRemoved, false, 0, true)
			addEventListener(PropertyChangeEvent.PROPERTY_CHANGED, updateContainer, false, 0, true)
			addEventListener(PanelContainerEvent.PANEL_ADDED, showPanelOnAdded, false, 0, true)
			addEventListener(PanelContainerEvent.SHOW_REQUESTED, bumpPanelToTop, false, 0, true)
			
			addEventListener(PanelContainerEvent.PANEL_ADDED, applyFiltersOnEvent, false, 0, true)
			addEventListener(PanelContainerEvent.PANEL_REMOVED, applyFiltersOnEvent, false, 0, true)
			
			otherSide = currentSide = null;
			addChildUpdateListeners();
			panelList = null;
		}
		
		private function applyFiltersOnEvent(evt:PanelContainerEvent):void {
			cl_containerDelegate.applyFilters(displayFilters)
		}
		
		private function showPanelOnAdded(evt:PanelContainerEvent):void 
		{
			const panels:Vector.<IPanel> = getPanels(false);
			evt.relatedPanels.forEach(function(item:IPanel, index:int, array:Vector.<IPanel>):void
			{
				if (panels.indexOf(item) != -1) {
					showPanel(item)
				}
			});
		}
		
		private function showOtherPanelOnRemoved(evt:PanelContainerEvent):void 
		{
			const relatedPanels:Vector.<IPanel> = evt.relatedPanels;
			showPanel(getPanels(false).filter(function(item:IPanel, index:int, array:Vector.<IPanel>):Boolean {
				return relatedPanels.indexOf(item) == -1;
			}).pop());
		}
		
		private function updateContainer(evt:PropertyChangeEvent):void 
		{
			const value:Number = Number(evt.newValue)
			if (evt.target is IPanel)
			{
				const currPanel:IPanel = evt.target as IPanel
				if (panelList && currPanel && currPanel.parent == this && evt.eventPhase == EventPhase.BUBBLING_PHASE) {
					panelList.updatePanel(currPanel)
				}
			}
			else if (evt.target == this)
			{
				switch(evt.fieldName)
				{
					case "width":
						redraw(value, height)
						break;
					case "height":
						redraw(width, value)
						break;
					case "sideSize":
					case "panelList":
					case "displayFilters":
						render();
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
		}
		
		private function addChildUpdateListeners():void
		{
			addEventListener(Event.ADDED, updateContentsOnEvent, false, 0, true)
			addEventListener(Event.REMOVED, updateContentsOnEvent, false, 0, true)
			addEventListener(Event.REMOVED, dispatchRemoveOnEmpty, false, 0, true)
		}
		
		private function removeChildUpdateListeners():void
		{
			removeEventListener(Event.REMOVED, dispatchRemoveOnEmpty)
			removeEventListener(Event.REMOVED, updateContentsOnEvent)
			removeEventListener(Event.ADDED, updateContentsOnEvent)
		}
		
		private function dispatchRemoveOnEmpty(evt:Event):void 
		{
			const target:IPanel = evt.target as IPanel;
			const panels:Vector.<IPanel> = getPanels(true);
			if (target && (panels.length <= 1 && panels.indexOf(target) != -1))
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
				//cache sides in case they're removed in between
				const oppSide:IContainer = otherSide
				const currSide:IContainer = currentSide
				const removeFromOtherSide:int = oppSide.removePanels(true);
				const removeFromCurrentSide:int = currSide.removePanels(true);
				
				setContainers(ContainerSide.FILL, null, null);
				return (removeFromCurrentSide + removeFromOtherSide);
			}
			else
			{
				const panelArray:Vector.<IPanel> = getPanels(false);
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
			setContainers(ContainerSide.FILL, null, null)	//this may not be necessary since otherSide will anyways have side FILL and no subcontainers; keep it just in case?
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
			if(panelList == this.panelList) {
				return;
			}
			else if (displayablePanelList && displayablePanelList.parent == this) {
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
		}
		
		private function get displayablePanelList():DisplayObject {
			return panelList as DisplayObject;
		}
		
		private function set displayablePanelList(displayable:DisplayObject):void
		{
			if(!displayable) {
				return;
			}
			const displayableList:IDisplayablePanelList = displayable as IDisplayablePanelList
			displayableList.draw(width, height)
			addChild(displayable)
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
				const container:IContainer = findPanel(panel);
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
				const container:IContainer = findPanel(panel);
				if(container) {
					return container.isPanelVisible(panel);
				}
			}
			return false;
		}
		
		private function updateContentsOnEvent(evt:Event):void 
		{
			const panel:IPanel = evt.target as IPanel;
			const panelList:IPanelList = this.panelList;
			if (!(panel && evt.eventPhase == EventPhase.BUBBLING_PHASE && panel.parent == this)) {
				return;
			}
			
			if (panelList)
			{
				if (evt.type == Event.REMOVED) {
					panelList.removePanel(panel)
				}
				else if(evt.type == Event.ADDED)
				{
					panelList.addPanelAt(panel, getChildIndex(panel as DisplayObject))
					if(displayablePanelList) {
						addChild(displayablePanelList)
					}
				}
				
				for (var i:int = numChildren - 1, child:IPanel; !child && i >= 0; child = getChildAt(i) as IPanel, --i)
				{
					if (child) {
						panelList.showPanel(child);
					}
				}
			}
			else {
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.SETUP_REQUESTED, null, this, true, true));
			}
			
			if (evt.type == Event.REMOVED) {
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.PANEL_REMOVED, new <IPanel>[panel], this, true, false))
			}
			else if(evt.type == Event.ADDED) {
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.PANEL_ADDED, new <IPanel>[panel], this, true, false))
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function mergeIntoContainer(container:IContainer):void
		{
			if(!container || container == this) {
				return;
			}
			cl_containerDelegate.clearFilters(displayFilters)	//remove all filters, in case they have added children of their own via apply()
			//NOTE: Should the container to be merged call mergeIntoContainer() on the destination, or the other way around?
			container.setContainers(sideCode, currentSide, otherSide);
			removeChildUpdateListeners();	//remove listener since we don't want this to occur while we're anyways emptying the container
			getPanels(false).forEach(function addPanelToContainer(item:IPanel, index:int, array:Vector.<IPanel>):void {
				container.addToSide(ContainerSide.FILL, item);
			});
			const children:Vector.<DisplayObject> = new Vector.<DisplayObject>()
			for (var i:int = 0; i < numChildren; ++i)
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
			setContainers(ContainerSide.FILL, null, null)
			if(container.panelList is IDisplayablePanelList) {
				container.setChildIndex(container.panelList as DisplayObject, container.numChildren - 1)
			}
			container.sideSize = sideSize
			container.minSideSize = minSideSize
			container.maxSideSize = maxSideSize
			dispatchEvent(new PanelContainerEvent(PanelContainerEvent.SETUP_REQUESTED, null, container, true, true));
		}
		
		/**
		 * @inheritDoc
		 */
		public function setContainers(sideCode:String, currentSide:IContainer, otherSide:IContainer):void
		{
			const prevCurrentSide:DisplayObject = this.currentSide as DisplayObject;
			const prevOtherSide:DisplayObject = this.otherSide as DisplayObject;
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
				result = result.concat(currentSide.getPanels(true), otherSide.getPanels(true));
			}
			return result;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getSide(side:String):IContainer
		{
			if(side == ContainerSide.FILL) {
				return this;
			}
			else if (hasSides)
			{
				if(sideCode == side) {
					return currentSide
				}
				else if(ContainerSide.isComplementary(sideCode, side)) {
					return otherSide
				}
			}
			return null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function addToSide(side:String, panel:IPanel):IContainer
		{
			const container:IContainer = fetchSide(side)
			if (container == this)
			{
				const displayablePanel:DisplayObject = panel as DisplayObject
				if (displayablePanelList)
				{
					const displayableList:IDisplayablePanelList = panelList as IDisplayablePanelList;
					displayableList.draw(width, height)
					
					const rect:Rectangle = displayableList.visibleRegion;
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
			}
			else {
				container.addToSide(ContainerSide.FILL, panel)
			}
			return container
		}
		
		private function resizeContainers(side:String, maxWidth:Number, maxHeight:Number, sideSize:Number, sideContainer:IContainer, otherContainer:IContainer):void 
		{
			if(!(sideContainer || otherContainer)) {
				return;
			}
			var swap:Number;
			var sideX:Number = 0, sideY:Number = 0, sideWidth:Number, sideHeight:Number;
			var otherSideX:Number, otherSideY:Number, otherSideWidth:Number, otherSideHeight:Number;
			if (ContainerSide.isComplementary(side, ContainerSide.LEFT))
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
			
			if (side == ContainerSide.BOTTOM || side == ContainerSide.RIGHT)	//swap container x, y, width and height
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
			const result:IContainer = findPanel(panel)
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
			else if(hasSides) {
				return (currentSide && currentSide.findPanel(panel)) || (otherSide && otherSide.findPanel(panel))
			}
			return null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeContainer(container:IContainer):IContainer
		{
			var oppContainer:IContainer;
			if(container == this) {
				return null;	//cannot return this, because remove operation did not succeed
			}
			else if (container == currentSide) {
				oppContainer = otherSide
			}
			else if (container == otherSide) {
				oppContainer = currentSide
			}
			else {
				return (currentSide && currentSide.removeContainer(container)) || (otherSide && otherSide.removeContainer(container))
			}
			oppContainer.mergeIntoContainer(this)
			return container
		}
		
		/**
		 * @inheritDoc
		 */
		public function addContainer(side:String, container:IContainer):IContainer
		{
			if (!(side && container)) {
				return null;
			}
			
			var retCon:IContainer							//heh
			const sideContainer:IContainer = getSide(side)	//get: FILL (this) or side (child container)
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
				const selfContainer:IContainer = createContainer()
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
		public function get sideCode():String {
			return cl_containerDelegate.sideCode
		}
		
		/**
		 * @inheritDoc
		 */
		public function set sideCode(sideCode:String):void {
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
		public function fetchSide(side:String):IContainer
		{
			if(!getSide(side)) {
				addContainer(ContainerSide.getComplementary(side), createContainer())
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
			const dispPanelList:DisplayObject = displayablePanelList;
			const oldWidth:Number = this.width, oldHeight:Number = this.height
			const displayable:IDisplayablePanelList = dispPanelList as IDisplayablePanelList;
			
			graphics.clear()
			graphics.beginFill(0, 0)				//draws transparent graphics
			graphics.drawRect(0, 0, width, height)	//so that it receives mouse/interaction events
			graphics.endFill()						//even if it is empty
			
			if (displayable)
			{
				displayable.draw(width, height)
				addChild(dispPanelList)
			}
			
			if (hasSides) {
				resizeContainers(sideCode, width, height, sideSize, currentSide, otherSide)
			}
			else
			{
				var effX:Number = 0.0, effY:Number = 0.0, effWidth:Number = 0.0, effHeight:Number = 0.0, hidePanels:Boolean = false
				if (displayable)
				{
					const rect:Rectangle = displayable.visibleRegion
					hidePanels = rect.isEmpty()
					effHeight = rect.height;
					effWidth = rect.width;
					effX = rect.x;
					effY = rect.y;
				}
				getPanels(false).forEach(function resizePanels(item:IPanel, index:int, array:Vector.<IPanel>):void
				{
					item.height != effHeight && (item.height = effHeight);
					item.width != effWidth && (item.width = effWidth);
					item.x != effX && (item.x = effX);
					item.y != effY && (item.y = effY);
					if (item.visible == hidePanels) {
						item.visible = !hidePanels	//hide items if rect.size == 0, or show them if rect.size > 0
					}
				}, this);
			}
			cl_containerDelegate.applyFilters(displayFilters)
		}
	}
}