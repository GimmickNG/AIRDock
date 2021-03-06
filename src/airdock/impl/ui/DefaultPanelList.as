package airdock.impl.ui
{
	import airdock.delegates.PanelListDelegate;
	import airdock.interfaces.docking.IPanel;
	import airdock.interfaces.ui.IDisplayablePanelList;
	import flash.display.Graphics;
	import flash.display.LineScaleMode;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	/**
	 * Dispatched when the user has clicked on a tab and the corresponding panel is to be shown.
	 * @eventType	airdock.events.PanelContainerEvent.SHOW_REQUESTED
	 */
	[Event(name="pcShowPanel", type="airdock.events.PanelContainerEvent")]
	
	/**
	 * Dispatched when the user has clicked on the close button and the panel is to be removed.
	 * @eventType	airdock.events.PanelContainerEvent.PANEL_REMOVE_REQUESTED
	 */
	[Event(name="pcPanelRemoveRequested", type="airdock.events.PanelContainerEvent")]
	
	/**
	 * Dispatched when the user has double clicked on a tab and the corresponding panel is to be docked, 
	 * or when the user has double clicked on the background of the panel list and the entire container's contents are to be docked.
	 * @eventType	airdock.events.PanelContainerEvent.STATE_TOGGLE_REQUESTED
	 */
	[Event(name="pcPanelStateToggleRequested", type="airdock.events.PanelContainerEvent")]
	
	/**
	 * Dispatched when the user has started dragging a tab and the corresponding panel is to participate in a drag-docking operation,
	 * or when the user has started dragging the background of the panel list and the entire container is to participate in a drag-docking operation.
	 * @eventType	airdock.events.PanelContainerEvent.DRAG_REQUESTED
	 */
	[Event(name="pcDragPanel", type ="airdock.events.PanelContainerEvent")]
	
	/**
	 * Default IDisplayablePanelList (and by extension, IPanelList) implementation.
	 * 
	 * Provides a tabbed list at the bottom of the container with a bar at the top with the active panel's name.
	 * 
	 * The colour of the tabbed bar and the top bar are light blue and dark blue by default, respectively; 
	 * this can be changed by modifying the activated and deactivated colors, respectively, via the setColors() method.
	 * 
	 * A panel or the entire container can be docked to its parked container by double clicking either a tab or the tabbed bar, respectively.
	 * 
	 * Also acts as an IDockTarget implementation for integrating into the center/the same container, whenever the user drags a panel or container over a tab.
	 * 
	 * @author	Gimmick
	 * @see	airdock.interfaces.docking.IDockTarget
	 * @see	airdock.interfaces.ui.IDisplayablePanelList
	 */
	public class DefaultPanelList extends Sprite implements IDisplayablePanelList
	{
		public static const DEACTIVATED_COLOR:uint = 0xFF164B9C;
		public static const ACTIVATED_COLOR:uint = 0xFF86B7E8;
		
		private var u_deactivatedColor:uint;
		private var u_activatedColor:uint;
		private var u_color:uint;
		private var num_maxWidth:Number;
		private var num_maxHeight:Number;
		private var shp_extraTabs:Shape;
		private var spr_removePanel:Sprite;
		private var tf_panelName:TextField;
		private var vec_tabs:Vector.<PanelTab>;
		private var rect_visibleRegion:Rectangle;
		private var cl_listDelegate:PanelListDelegate;
		public function DefaultPanelList() 
		{
			super();
			doubleClickEnabled = true;
			tf_panelName = new TextField();
			tf_panelName.selectable = false;
			tf_panelName.mouseEnabled = false;
			addChild(tf_panelName)
			
			u_deactivatedColor = DEACTIVATED_COLOR
			u_activatedColor = ACTIVATED_COLOR;
			vec_tabs = new Vector.<PanelTab>();
			rect_visibleRegion = new Rectangle();
			cl_listDelegate = new PanelListDelegate(this);
			
			shp_extraTabs = new Shape()
			addChild(shp_extraTabs)
			
			spr_removePanel = new Sprite()
			addChild(spr_removePanel)
			spr_removePanel.buttonMode = true;
			
			redraw(100, 100);
			addEventListener(MouseEvent.CLICK, handlePanelListClick, false, 0, true)
			addEventListener(MouseEvent.DOUBLE_CLICK, dispatchDock, false, 0, true);
			addEventListener(MouseEvent.MOUSE_DOWN, startDispatchDrag, false, 0, true);
		}
		
		/**
		 * Sets the activated and the deactivated colors for the panelList.
		 * The activated color is that color for each tab when its panel is active, and that of the tab bar as well;
		 * the deactivated color is the color each tab has when its panel is not active, and that of the top bar as well.
		 * @param	activatedColor	The activated color as an AARRGGBB value.
		 * @param	deactivatedColor	The deactivated color as an AARRGGBB value.
		 */
		public function setColors(activatedColor:uint, deactivatedColor:uint):void
		{
			u_deactivatedColor = deactivatedColor
			u_activatedColor = activatedColor
			redraw(width, height)
		}
		
		private function startDispatchDrag(evt:MouseEvent):void 
		{
			removeEventListener(MouseEvent.MOUSE_DOWN, startDispatchDrag)
			addEventListener(MouseEvent.MOUSE_MOVE, dispatchDrag, false, 0, true)
			addEventListener(MouseEvent.MOUSE_UP, stopDispatchDrag, false, 0, true)
		}
		
		private function dispatchDrag(evt:MouseEvent):void
		{
			const panels:Vector.<IPanel> = new Vector.<IPanel>();
			const dockAll:Boolean = !(evt.target is PanelTab);
			const ACTIVATED:Boolean = PanelTab.ACTIVATED;
			
			if(evt.target is PanelTab) {
				activateTab(evt.target as PanelTab, evt.ctrlKey)
			}
			vec_tabs.forEach(function requestDrag(item:PanelTab, index:int, array:Vector.<PanelTab>):void
			{
				if(dockAll || item.activeState == ACTIVATED) {
					panels.push(cl_listDelegate.getPanelAt(index));
				}
			});
			cl_listDelegate.requestDrag(panels)
			stopDispatchDrag(evt)
		}
		
		private function stopDispatchDrag(evt:MouseEvent):void 
		{
			addEventListener(MouseEvent.MOUSE_DOWN, startDispatchDrag, false, 0, true)
			removeEventListener(MouseEvent.MOUSE_UP, stopDispatchDrag)
			removeEventListener(MouseEvent.MOUSE_MOVE, dispatchDrag)
		}
		
		/**
		 * @inheritDoc
		 */
		public function addPanelAt(panel:IPanel, index:int):void
		{
			if(!panel) {
				return;
			}
			cl_listDelegate.addPanelAt(panel, index)
			
			const tab:PanelTab = new PanelTab()
			tab.activatedColor = u_activatedColor
			tab.deactivatedColor = u_deactivatedColor
			tab.setTabName(panel.panelName)
			tab.doubleClickEnabled = true
			vec_tabs.splice(index, 0, tab)
			tab.activate()
			showPanel(panel)
			redraw(width, height)
		}
		
		/**
		 * @inheritDoc
		 */
		public function addPanel(panel:IPanel):void {
			addPanelAt(panel, cl_listDelegate.numPanels)
		}
		
		/**
		 * @inheritDoc
		 */
		public function updatePanel(panel:IPanel):void
		{
			const index:int = cl_listDelegate.getPanelIndex(panel);
			if (index != -1)
			{
				const currTab:PanelTab = vec_tabs[index]
				if (currTab.activeState == PanelTab.ACTIVATED) {
					tf_panelName.text = panel.panelName || "";
				}
				currTab.setTabName(panel.panelName);
				redraw(width, height)
			}
		}
		
		private function handlePanelListClick(evt:MouseEvent):void
		{
			const ACTIVATED:Boolean = PanelTab.ACTIVATED;
			if (evt.target is PanelTab) {
				activateTab(evt.target as PanelTab, evt.ctrlKey)
			}
			else if (evt.target == spr_removePanel)
			{
				const panels:Vector.<IPanel> = new Vector.<IPanel>();
				vec_tabs.forEach(function requestRemoveIfActive(item:PanelTab, index:int, array:Vector.<PanelTab>):void
				{
					if(item.activeState == ACTIVATED) {
						panels.push(cl_listDelegate.getPanelAt(index));
					}
				});
				cl_listDelegate.requestRemove(panels);
			}
		}
		
		private function activateTab(tab:PanelTab, multipleSelection:Boolean):void 
		{
			const panel:IPanel = cl_listDelegate.getPanelAt(vec_tabs.indexOf(tab));
			const ACTIVATED:Boolean = PanelTab.ACTIVATED;
			if (multipleSelection)
			{
				/* holding down the Ctrl or Command key will allow the user to select multiple panels;
				 * this is done by caching the active tabs before, and reactivating them after (since showPanel resets them) */
				const activeTabs:Vector.<PanelTab> = vec_tabs.filter(function getActiveTabs(item:PanelTab, index:int, array:Vector.<PanelTab>):Boolean {
					return item.activeState == ACTIVATED;
				});
			}
			
			if(cl_listDelegate.requestShow(new <IPanel>[panel])) {
				showPanel(panel)
			}
			
			activeTabs && activeTabs.forEach(function activatePreviousTabs(item:PanelTab, index:int, array:Vector.<PanelTab>):void {
				item.activate()
			});
		}
		
		private function dispatchDock(evt:MouseEvent):void
		{
			const panels:Vector.<IPanel> = new Vector.<IPanel>();
			const dockAll:Boolean = !(evt.target is PanelTab);
			const ACTIVATED:Boolean = PanelTab.ACTIVATED;
			vec_tabs.forEach(function requestDock(item:PanelTab, index:int, array:Vector.<PanelTab>):void
			{
				if(dockAll || item.activeState == ACTIVATED) {
					panels.push(cl_listDelegate.getPanelAt(index));
				}
			});
			cl_listDelegate.requestStateToggle(panels)
		}
		
		private function redraw(width:Number, height:Number):void 
		{
			const activatedColor:uint = u_activatedColor, deactivatedColor:uint = u_deactivatedColor;
			var barHeight:Number = 24
			if(height < 24) {
				barHeight = height * 0.1
			}
			const xOffset:Number = width - barHeight;
			var graphics:Graphics;
			spr_removePanel.graphics.clear()
			shp_extraTabs.graphics.clear()
			if (xOffset > 0)
			{
				const removeButtonSize:Number = barHeight * 0.3;
				const removeButtonBegin:Number = 0.5 * (barHeight - removeButtonSize);
				const removeButtonEnd:Number = removeButtonBegin + removeButtonSize
				graphics = spr_removePanel.graphics
				graphics.beginFill(deactivatedColor & 0x00FFFFFF, ((deactivatedColor & 0xFF000000) >>> 24) / 0xFF)
				graphics.drawRect(xOffset + removeButtonBegin, removeButtonBegin, removeButtonSize, removeButtonSize)
				graphics.lineStyle(1, 0, 1, false, LineScaleMode.NONE)
				graphics.moveTo(xOffset + removeButtonBegin, removeButtonBegin)
				graphics.lineTo(xOffset + removeButtonEnd, removeButtonEnd)
				graphics.moveTo(xOffset + removeButtonBegin, removeButtonEnd)
				graphics.lineTo(xOffset + removeButtonEnd, removeButtonBegin)
				var currX:Number = 0;
				const panelsOmitted:Boolean = vec_tabs.some(function getLastPanelTabVisible(item:PanelTab, index:int, array:Vector.<PanelTab>):Boolean
				{
					var maxX:Number = item.x + item.width;
					var omitted:Boolean = maxX > width;
					if(!omitted) {
						currX = maxX;
					}
					return omitted;
				});
				const radius:Number = barHeight * 0.05;
				const circSpacing:Number = radius * 2.5, circY:Number = height - (circSpacing * 2);
				if (panelsOmitted && (width - currX) > (circSpacing * 4))
				{
					const baseX:Number = width - (circSpacing * 4)
					graphics.beginFill(deactivatedColor, 1);
					for (var i:uint = 0; i < 3; ++i) {
						graphics.drawCircle(baseX + (i * circSpacing), circY, radius)
					}
					graphics.endFill()
				}
			}
			graphics = this.graphics
			graphics.clear()
			graphics.lineStyle(1, 0, 1, false, LineScaleMode.NONE)
			graphics.beginFill(deactivatedColor & 0x00FFFFFF, ((deactivatedColor & 0xFF000000) >>> 24) / 0xFF)
			graphics.drawRect(0, 0, width - 1, barHeight)
			graphics.endFill()
			graphics.beginFill(activatedColor, ((activatedColor & 0xFF000000) >>> 24) / 0xFF)
			graphics.drawRect(0, height - barHeight, width - 1, barHeight)
			graphics.endFill()
			tf_panelName.width = xOffset;
			tf_panelName.height = barHeight;
			var tabX:Number = 0;
			vec_tabs.forEach(function repositionTabs(item:PanelTab, index:int, array:Vector.<PanelTab>):void
			{
				item.activatedColor = activatedColor
				item.deactivatedColor = deactivatedColor
				item.redraw(item.width, barHeight);
				item.y = height - (barHeight + 1);
				item.x = tabX;
				tabX += item.width
				if (tabX < width) {
					addChild(item)
				}
				else if(item.parent) {
					removeChild(item)
				}
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function removePanelAt(index:int):void
		{
			const tab:PanelTab = vec_tabs.splice(index, 1)[0];
			if(tab.parent == this) {
				removeChild(tab)
			}
			cl_listDelegate.removePanelAt(index)
			redraw(width, height)
		}
		
		/**
		 * @inheritDoc
		 */
		public function removePanel(panel:IPanel):void 
		{
			const index:int = cl_listDelegate.getPanelIndex(panel)
			if(index != -1) {
				removePanelAt(index)
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function showPanel(panel:IPanel):void 
		{
			const index:int = cl_listDelegate.getPanelIndex(panel)
			if (index != -1)
			{
				vec_tabs.forEach(function deactivateAllTabs(item:PanelTab, index:int, array:Vector.<PanelTab>):void {
					item.deactivate();
				});
				vec_tabs[index].activate();
				tf_panelName.text = panel.panelName || "";
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function draw(maxWidth:Number, maxHeight:Number):void
		{
			if(num_maxWidth == maxWidth && num_maxHeight == maxHeight) {
				return;
			}
			var barHeight:Number = 24
			if(maxHeight < barHeight) {
				barHeight = maxHeight * 0.1
			}
			rect_visibleRegion.setTo(0, barHeight, maxWidth, maxHeight - (barHeight * 2))
			num_maxHeight = maxHeight;
			num_maxWidth = maxWidth
			redraw(maxWidth, maxHeight)
		}
		
		/**
		 * @inheritDoc
		 */
		public function get visibleRegion():Rectangle {
			return rect_visibleRegion
		}
		
		public function get color():uint {
			return u_color;
		}
		
		public function set color(value:uint):void {
			u_color = value;
		}
		
	}

}

import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
internal class PanelTab extends Sprite
{
	public static const ACTIVATED:Boolean = true;
	public static const DEACTIVATED:Boolean = false;
	
	private var b_state:Boolean;
	private var tf_panelName:TextField;
	private var u_activatedColor:uint;
	private var u_deactivatedColor:uint;
	public function PanelTab()
	{
		b_state = DEACTIVATED;
		u_activatedColor = 0xFFFFFF
		tf_panelName = new TextField()
		tf_panelName.mouseEnabled = false;
		tf_panelName.selectable = tf_panelName.multiline = false;
		tf_panelName.autoSize = TextFieldAutoSize.CENTER
		addChild(tf_panelName)
	}
	
	public function setTabName(name:String):void
	{
		tf_panelName.text = name || "";
		redraw(tf_panelName.width + 8, tf_panelName.height + 4)
	}
	
	public function redraw(width:Number, height:Number):void
	{
		const colorAlpha:Number = ((color & 0xFF000000) >>> 24) / 0xFF;
		graphics.clear()
		graphics.beginFill(color & 0x00FFFFFF, colorAlpha)
		graphics.drawRect(0, 0, width, height)
		graphics.endFill()
		tf_panelName.x = (width - tf_panelName.width) * 0.5;
		tf_panelName.y = (height - tf_panelName.height) * 0.5;
	}
	
	public function activate():void
	{
		b_state = ACTIVATED;
		redraw(width, height)
	}
	
	public function deactivate():void
	{
		b_state = DEACTIVATED;
		redraw(width, height)
	}
	
	override public function set height(value:Number):void {
		redraw(width, value)
	}
	
	override public function set width(value:Number):void {
		redraw(value, height)
	}
	
	public function get color():uint
	{
		if(b_state == ACTIVATED) {
			return u_activatedColor
		}
		return u_deactivatedColor
	}
	
	public function get activeState():Boolean {
		return b_state
	}
	
	public function get deactivatedColor():uint {
		return u_deactivatedColor;
	}
	
	public function set deactivatedColor(value:uint):void {
		u_deactivatedColor = value;
	}
	
	public function get activatedColor():uint {
		return u_activatedColor;
	}
	
	public function set activatedColor(value:uint):void {
		u_activatedColor = value;
	}
}