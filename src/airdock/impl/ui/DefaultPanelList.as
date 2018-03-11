package airdock.impl.ui 
{
	import airdock.enums.PanelContainerSide;
	import airdock.events.DockEvent;
	import airdock.events.PanelContainerEvent;
	import airdock.interfaces.docking.IDockTarget;
	import airdock.interfaces.ui.IDisplayablePanelList;
	import airdock.interfaces.docking.IPanel;
	import flash.desktop.NativeDragManager;
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.NativeDragEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	/**
	 * Dispatched when the user has dropped the panel or container onto a tab, and the Docker is to decide what action to take.
	 * @eventType	airdock.events.DockEvent.DRAG_COMPLETING
	 */
	[Event(name="deDragCompleting", type="airdock.events.DockEvent")]
	
	/**
	 * Dispatched when the user has clicked on a tab and the corresponding panel is to be shown.
	 * @eventType	airdock.events.PanelContainerEvent.SHOW_REQUESTED
	 */
	[Event(name="pcShowPanel", type="airdock.events.PanelContainerEvent")]
	
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
	 * this can be changed by modifying the static attribute ACTIVATED_COLOR and DEACTIVATED_COLOR (respectively).
	 * 
	 * A panel or the entire container can be docked to its parked container by double clicking either a tab or the tabbed bar, respectively.
	 * 
	 * Also acts as an IDockTarget implementation for integrating into the center/the same container, whenever the user drags a panel or container over a tab.
	 * 
	 * @author	Gimmick
	 * @see	airdock.interfaces.docking.IDockTarget
	 * @see	airdock.interfaces.ui.IDisplayablePanelList
	 */
	public class DefaultPanelList extends Sprite implements IDisplayablePanelList, IDockTarget
	{
		/**
		 * The color of the tabbed bar, and the color of a tab which is activated. Can be changed.
		 * @default 0x86B7E8
		 */
		public static var ACTIVATED_COLOR:int = 0x86B7E8;
		
		/**
		 * The color of the top bar, and the color of a tab which has been deactivated. Can be changed.
		 * @default 0x164B9C
		 */
		public static var DEACTIVATED_COLOR:int = 0x164B9C;
		
		private var u_color:uint;
		private var num_maxWidth:Number;
		private var num_maxHeight:Number;
		private var tf_panelName:TextField;
		private var vec_panels:Vector.<IPanel>;
		private var vec_tabs:Vector.<PanelTab>;
		private var pt_preferredLocation:Point;
		private var rect_visibleRegion:Rectangle;
		public function DefaultPanelList() 
		{
			super();
			addEventListener(MouseEvent.CLICK, dispatchShowPanel)
			addEventListener(MouseEvent.DOUBLE_CLICK, dispatchDock)
			addEventListener(MouseEvent.MOUSE_DOWN, startDispatchDrag)
			addEventListener(NativeDragEvent.NATIVE_DRAG_OVER, onDragOver)
			addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, onDragDrop)
			rect_visibleRegion = new Rectangle()
			vec_tabs = new Vector.<PanelTab>()
			pt_preferredLocation = new Point()
			vec_panels = new Vector.<IPanel>()
			tf_panelName = new TextField()
			doubleClickEnabled = true
			redraw(100, 100)
		}
		
		private function startDispatchDrag(evt:MouseEvent):void 
		{
			if (evt.target is PanelTab && !vec_panels[vec_tabs.indexOf(evt.target as PanelTab)].dockable) {
				return;
			}
			removeEventListener(MouseEvent.MOUSE_DOWN, startDispatchDrag)
			addEventListener(MouseEvent.MOUSE_MOVE, dispatchDrag)
		}
		
		private function onDragDrop(evt:NativeDragEvent):void {
			dispatchEvent(new DockEvent(DockEvent.DRAG_COMPLETING, evt.clipboard, evt.target as DisplayObject, true, true))
		}
		
		private function onDragOver(evt:NativeDragEvent):void
		{
			if (evt.target is PanelTab) {
				NativeDragManager.acceptDragDrop(evt.target as InteractiveObject)
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function getSideFrom(target:DisplayObject):int {
			return PanelContainerSide.FILL
		}
		
		/**
		 * @inheritDoc
		 */
		public function addPanelAt(panel:IPanel, index:int):void
		{
			if(!panel) {
				return;
			}
			var tab:PanelTab = createPanelTab()
			tab.setTabName(panel.panelName)
			vec_tabs.splice(index, 0, tab)
			vec_panels.splice(index, 0, panel)
			showPanel(panel)
			redraw(width, height)
		}
		
		private function createPanelTab():PanelTab
		{
			var tab:PanelTab = new PanelTab()
			tab.activatedColor = ACTIVATED_COLOR
			tab.deactivatedColor = DEACTIVATED_COLOR
			tab.doubleClickEnabled = true
			tab.activate()
			return tab
		}
		
		/**
		 * @inheritDoc
		 */
		public function addPanel(panel:IPanel):void {
			addPanelAt(panel, vec_panels.length)
		}
		
		/**
		 * @inheritDoc
		 */
		public function updatePanel(panel:IPanel):void
		{
			var index:int = vec_panels.indexOf(panel);
			if(index == -1) {
				return;
			}
			vec_tabs[index].setTabName(panel.panelName);
			redraw(width, height)
		}
		
		private function dispatchShowPanel(evt:MouseEvent):void
		{
			if(!(evt.target is PanelTab)) {
				return;
			}
			var index:int = vec_tabs.indexOf(evt.target as PanelTab)
			if(!dispatchEvent(new PanelContainerEvent(PanelContainerEvent.SHOW_REQUESTED, vec_panels[index], null, true, true))) {
				return;
			}
			
			var tab:PanelTab = vec_tabs[index];
			for (var i:uint = 0; i < vec_tabs.length; ++i) {
				vec_tabs[i].deactivate()
			}
			tab.activate()
			
			var panelName:String = vec_panels[index].panelName
			if(!panelName) {
				panelName = "";
			}
			tf_panelName.text = panelName
		}
		
		private function dispatchDock(evt:MouseEvent):void
		{
			var panel:IPanel;
			if (evt.target is PanelTab) {
				panel = vec_panels[vec_tabs.indexOf(evt.target as PanelTab)];
			}
			if (panel && !panel.dockable) {
				return;
			}
			dispatchEvent(new PanelContainerEvent(PanelContainerEvent.STATE_TOGGLE_REQUESTED, panel, null, true, true))
			evt.stopImmediatePropagation()
		}
		
		private function dispatchDrag(evt:MouseEvent):void
		{
			removeEventListener(MouseEvent.MOUSE_MOVE, dispatchDrag)
			var panel:IPanel;
			if (evt.target is PanelTab) {
				panel = vec_panels[vec_tabs.indexOf(evt.target as PanelTab)];
			}
			dispatchEvent(new PanelContainerEvent(PanelContainerEvent.DRAG_REQUESTED, panel, null, true, false))
			evt.stopImmediatePropagation()
			addEventListener(MouseEvent.MOUSE_DOWN, startDispatchDrag)
		}
		
		private function redraw(width:Number, height:Number):void 
		{
			var barHeight:Number = 25
			if(height < 25) {
				barHeight = height * 0.1
			}
			graphics.clear()
			graphics.lineStyle(1)
			graphics.beginFill(DEACTIVATED_COLOR, 1)
			graphics.drawRect(0, 0, width - 1, barHeight)
			graphics.beginFill(ACTIVATED_COLOR, 1)
			graphics.drawRect(0, height - barHeight, width - 1, barHeight)
			graphics.endFill()
			tf_panelName.width = width;
			tf_panelName.height = barHeight;
			for (var i:uint = 0, currX:Number = 0; i < vec_tabs.length; ++i)
			{
				var currTab:PanelTab = vec_tabs[i];
				currTab.activatedColor = ACTIVATED_COLOR
				currTab.deactivatedColor = DEACTIVATED_COLOR
				currTab.y = height - (barHeight + 1)
				currTab.height = barHeight
				currTab.x = currX;
				currX += currTab.width
				if (currX < width) {
					addChild(currTab)
				}
				else if(currTab.parent) {
					removeChild(vec_tabs[i])
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function removePanelAt(index:int):void
		{
			var tab:PanelTab = vec_tabs.splice(index, 1)[0];
			if(tab.parent == this) {
				removeChild(tab)
			}
			vec_panels.splice(index, 1)
			redraw(width, height)
		}
		
		/**
		 * @inheritDoc
		 */
		public function removePanel(panel:IPanel):void 
		{
			var index:int = vec_panels.indexOf(panel)
			if(index == -1) {
				return;
			}
			removePanelAt(index)
		}
		
		/**
		 * @inheritDoc
		 */
		public function showPanel(panel:IPanel):void 
		{
			var index:int = vec_panels.indexOf(panel)
			if(index == -1) {
				return;
			}
			var tab:PanelTab = vec_tabs[index];
			for (var i:uint = 0; i < vec_tabs.length; ++i) {
				vec_tabs[i].deactivate()
			}
			tab.activate()
		}
		
		/**
		 * @inheritDoc
		 */
		public function set maxWidth(value:Number):void 
		{
			num_maxWidth = value;
			rect_visibleRegion.width = value
			pt_preferredLocation.x = 0;
			redraw(value, height)
		}
		
		/**
		 * @inheritDoc
		 */
		public function set maxHeight(value:Number):void 
		{
			num_maxHeight = value;
			redraw(width, value)
			pt_preferredLocation.y = 0
			rect_visibleRegion.y = 16
			rect_visibleRegion.height = value - 40
		}
		
		/**
		 * @inheritDoc
		 */
		public function get visibleRegion():Rectangle {
			return rect_visibleRegion
		}
		
		/**
		 * @inheritDoc
		 */
		public function get preferredLocation():Point {
			return pt_preferredLocation;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get maxHeight():Number {
			return num_maxHeight;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get maxWidth():Number {
			return num_maxWidth;
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
	private var u_color:uint;
	private var u_activatedColor:uint;
	private var u_deactivatedColor:uint;
	private var tf_panelName:TextField;
	public function PanelTab()
	{
		u_color = u_deactivatedColor
		u_activatedColor = 0xFFFFFF
		tf_panelName = new TextField()
		tf_panelName.mouseEnabled = false;
		tf_panelName.selectable = tf_panelName.multiline = false;
		tf_panelName.autoSize = TextFieldAutoSize.CENTER
		addChild(tf_panelName)
	}
	public function setTabName(name:String):void
	{
		if(!name) {
			name = "";
		}
		tf_panelName.text = name;
		redraw(tf_panelName.width + 8, tf_panelName.height + 4)
	}
	public function redraw(width:Number, height:Number):void
	{
		graphics.clear()
		graphics.beginFill(color, 1)
		graphics.drawRect(0, 0, width, height)
		graphics.endFill()
		tf_panelName.x = (width - tf_panelName.width) * 0.5;
		tf_panelName.y = (height - tf_panelName.height) * 0.5;
	}
	public function activate():void
	{
		u_color = u_activatedColor
		redraw(width, height)
	}
	public function deactivate():void
	{
		u_color = u_deactivatedColor
		redraw(width, height)
	}
	override public function set height(value:Number):void {
		redraw(width, value)
	}
	
	override public function set width(value:Number):void {
		redraw(value, height)
	}
	
	public function get color():uint {
		return u_color;
	}
	
	public function set color(value:uint):void {
		u_color = value;
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