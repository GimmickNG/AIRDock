package airdock.impl 
{
	import airdock.enums.PanelContainerSide;
	import airdock.events.PanelContainerEvent;
	import airdock.events.PanelPropertyChangeEvent;
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
		private var num_maxWidth:Number;
		private var num_maxHeight:Number;
		private var num_minSideSize:Number;
		private var num_maxSideSize:Number;
		private var cl_panelList:IPanelList;
		private var b_containerState:Boolean;
		private var plc_otherSide:IContainer;
		private var plc_currentSide:IContainer;
		private var vec_panels:Vector.<IPanel>;
		private var vec_displayFilters:Vector.<IDisplayFilter>;
		public function DefaultContainer()
		{
			addEventListener(PanelPropertyChangeEvent.PROPERTY_CHANGED, updatePanelBar, false, 0, true)
			i_currSide = PanelContainerSide.FILL;
			vec_panels = new Vector.<IPanel>();
			num_maxWidth = num_maxHeight = 128;
			otherSide = currentSide = null;
			addChildUpdateListeners();
			maxSideSize = 1.0;
			minSideSize = 0.0;
			panelList = null;
			sideSize = 0.5;
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
			if (target && target.parent == this && getPanelCount(true) <= 1)
			{
				clearFilters(vec_displayFilters)
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.CONTAINER_REMOVE_REQUESTED, null, this, true, true))
			}
		}
		
		private function clearFilters(filters:Vector.<IDisplayFilter>):void 
		{
			for (var k:int = int(filters && filters.length) - 1; k >= 0; --k) {
				filters[k].remove(this);
			}
		}
		
		private function updatePanelBar(evt:PanelPropertyChangeEvent):void 
		{
			var currPanel:IPanel = evt.target as IPanel
			if (panelList && currPanel && currPanel.parent == this && evt.eventPhase == EventPhase.BUBBLING_PHASE) {
				panelList.updatePanel(currPanel)
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
				setContainers(PanelContainerSide.FILL, null, null)	//this may not be necessary since otherSide will anyways have side FILL and no subcontainers; keep it just in case?
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
			if (displayablePanelList && displayablePanelList.parent == this) {
				removeChild(displayablePanelList)
			}
			//---
			cl_panelList = panelList
			if (panelList)
			{
				var panelArray:Vector.<IPanel> = getPanels(false);
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
		//TODO drag_requested does not work for some reason
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
				var relatedPanel:IPanel = evt.relatedPanel
				removePanel(relatedPanel)
				var panelList:Vector.<IPanel> = getPanels(false);
				if (panelList.length) {
					showPanel(panelList[panelList.length - 1])
				}
			}
		}
		
		private function bumpPanelToTop(evt:PanelContainerEvent):void
		{
			if(!evt.isDefaultPrevented()) {
				showPanel(evt.relatedPanel)
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
		
		private function sendDockPanelRequest(evt:PanelContainerEvent):void
		{
			evt.stopImmediatePropagation();
			if(evt.isDefaultPrevented()) {
				return;
			}
			dispatchEvent(new PanelContainerEvent(evt.type, evt.relatedPanel, this, true, false))
			//for the listeners registered - DRAG and STATE_TOGGLE the relatedPanel is
			//the panel which is going to be removed (that is, this event occurs before it is removed)
			//if there is no relatedPanel then it implies that the entire container is to be removed instead
			//in which case there is no need to show the last panel in the UIPanelList.
			var relatedPanel:IPanel = evt.relatedPanel
			if (relatedPanel)
			{
				var panelList:Vector.<IPanel> = getPanels(false)
				//stops when it shows a panel that's not the related panel
				panelList.some(function showOtherPanel(item:IPanel, index:int, array:Vector.<IPanel>):Boolean
				{
					var endPanel:IPanel = array[array.length - (index + 1)];	//from right to left
					var showPanelAndStop:Boolean = endPanel != relatedPanel
					if(showPanelAndStop) {
						showPanel(endPanel);
					}
					return showPanelAndStop;
				});
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
						addChild(displayablePanelList)
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
			clearFilters(vec_displayFilters)	//remove all filters, in case they have added children of their own via apply()
			if (hasSides && hasSides == container.hasSides && PanelContainerSide.isComplementary(sideCode, container.sideCode))
			{
				/* Merges two containers if they have same number of sides, and are complementary.
				 * For example, suppose two trees exist:
				 * 
				 *          A             H
				 *        B   C         I   J
				 *       d e f g       k l m n
				 * 
				 * where the leafs [d, e, f, g] and [k, l, m, n] are panels
				 * 
				 * Then, merging H into A should yield:
				 *                 A
				 *           B           C
				 *       d,k   e,l   f,m   g,n
				 * 
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
					//is not equal; flip sides
					otherCont = currentSide;
					tempCont = otherSide;
				}
				//TODO test this part
				tempCont.mergeIntoContainer(container.getSide(containerSideCode))
				otherCont.mergeIntoContainer(container.getSide(PanelContainerSide.getComplementary(containerSideCode)))
			}
			else
			{
				container.setContainers(sideCode, currentSide, otherSide)	//TODO should the container to be merged call mergeIntoContainer on the destination, or the other way around?
				removeChildUpdateListeners()	//remove listener since we don't want this to occur while we're anyways emptying the container
				var k:int;
				while(k < numChildren)
				{
					var currChild:DisplayObject = getChildAt(k)
					if (currChild == displayablePanelList || currChild == currentSide || currChild == otherSide) {
						++k;
					}
					else if(currChild is IPanel) {	//add panels through normal means
						container.addToSide(PanelContainerSide.FILL, currChild as IPanel)
					}
					else {		//some other type of child object; directly add to container
						container.addChild(currChild)
					}
				}
				vec_panels.length = 0;	//since all children have been removed but vec_panels has not been updated
				addChildUpdateListeners()
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
			clearFilters(vec_displayFilters)
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
			return (currentSide && otherSide)
		}
		
		/**
		 * @inheritDoc
		 */
		public function getPanels(recursive:Boolean):Vector.<IPanel>
		{
			var result:Vector.<IPanel> = vec_panels.concat()
			if (recursive)
			{
				if (currentSide) {
					result = result.concat(currentSide.getPanels(true))
				}
				if (otherSide) {
					result = result.concat(otherSide.getPanels(true))
				}
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
			if (PanelContainerSide.isComplementary(side, PanelContainerSide.LEFT))
			{
				otherSideHeight = sideHeight = maxHeight;
				sideWidth = sideSize
				if(sideSize <= 1.0) {
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
				if(sideSize <= 1.0) {
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
				//merge if there are no sides for this current container,
				//if this has no panels and the side is this container,
				//or if this container has a side equal to the side supplied
				container.mergeIntoContainer(sideContainer);
				retCon = sideContainer;
			}
			else
			{
				//shift everything that's in this container (subcontainers or panels) into a new container
				//and then add that container as a subcontainer of this container, along with the container to be added
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
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.SETUP_REQUESTED, null, container, true, true));
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.SETUP_REQUESTED, null, selfContainer, true, true));
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
		public function set sideSize(value:Number):void
		{
			if (num_sideSize != value)
			{
				num_sideSize = value
				render()
			}
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
		public function set maxSideSize(value:Number):void
		{
			num_maxSideSize = value;
			if(value < sideSize) {
				sideSize = value;
			}
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
		public function set minSideSize(value:Number):void
		{
			num_minSideSize = value;
			if(value > sideSize) {
				sideSize = value;
			}
		}
		
		public function get displayFilters():Vector.<IDisplayFilter> {
			return vec_displayFilters && vec_displayFilters.concat();
		}
		
		public function set displayFilters(value:Vector.<IDisplayFilter>):void
		{
			clearFilters(vec_displayFilters)
			applyFilters(value)
			vec_displayFilters = value.concat();
		}
		
		/**
		 * Applies the given filters to the container.
		 * @param	filters	A Vector of IDisplayFilters which are to be applied to the container.
		 */
		private function applyFilters(filters:Vector.<IDisplayFilter>):void 
		{
			for (var i:int = int(filters && filters.length) - 1; i >= 0; --i) {
				filters[i].apply(this);
			}
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
			if (!(container && containerCreated)) {
				container = new DefaultContainer();	//fallback if there is no response from Docker
			}
			//finally...
			if (container)
			{
				removeEventListener(PanelContainerEvent.CONTAINER_CREATED, getContainer);
				dispatchEvent(new PanelContainerEvent(PanelContainerEvent.CONTAINER_CREATED, null, container, true, false));
			}
			return container
		}
		private function redraw(width:Number, height:Number):void 
		{
			var i:int;
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
				applyFilters(displayFilters)
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
				var panelArray:Vector.<IPanel> = getPanels(false);
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