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
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public class DefaultPanelList extends Sprite implements IDisplayablePanelList, IDockTarget
	{
		public static const PREFERRED_HEIGHT:int = 24;
		public static var DEACTIVATED_COLOR:int = 0x164B9C;
		public static var ACTIVATED_COLOR:int = 0x87CEEB;
		
		private var u_color:uint;
		private var num_maxWidth:Number;
		private var num_maxHeight:Number;
		private var vec_panels:Vector.<IPanel>;
		private var vec_tabs:Vector.<PanelTab>
		private var pt_preferredLocation:Point;
		private var rect_visibleRegion:Rectangle;
		public function DefaultPanelList() 
		{
			super();
			addEventListener(MouseEvent.DOUBLE_CLICK, dispatchDock)
			addEventListener(MouseEvent.MOUSE_DOWN, startDispatchDrag)
			addEventListener(MouseEvent.CLICK, dispatchShowPanel)
			addEventListener(NativeDragEvent.NATIVE_DRAG_OVER, onDragOver)
			addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, onDragDrop)
			rect_visibleRegion = new Rectangle()
			vec_tabs = new Vector.<PanelTab>()
			pt_preferredLocation = new Point()
			vec_panels = new Vector.<IPanel>()
			doubleClickEnabled = true
			redraw(100, 100)
		}
		
		private function startDispatchDrag(evt:MouseEvent):void 
		{
			removeEventListener(MouseEvent.MOUSE_DOWN, startDispatchDrag)
			addEventListener(MouseEvent.MOUSE_MOVE, dispatchDrag)
		}
		
		private function onDragDrop(evt:NativeDragEvent):void {
			dispatchEvent(new DockEvent(DockEvent.DRAG_COMPLETED, evt.clipboard, evt.target as DisplayObject, true, false))
		}
		
		private function onDragOver(evt:NativeDragEvent):void
		{
			if (evt.target is PanelTab) {
				NativeDragManager.acceptDragDrop(evt.target as InteractiveObject)
			}
		}
		
		public function getSideFrom(target:DisplayObject):int {
			return PanelContainerSide.FILL
		}
		
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
		
		public function addPanel(panel:IPanel):void {
			addPanelAt(panel, vec_panels.length)
		}
		
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
				return
			}
			var index:int = vec_tabs.indexOf(evt.target as PanelTab)
			dispatchEvent(new PanelContainerEvent(PanelContainerEvent.SHOW_REQUESTED, vec_panels[index], null, true, false))
			var tab:PanelTab = vec_tabs[index];
			for (var i:uint = 0; i < vec_tabs.length; ++i) {
				vec_tabs[i].deactivate()
			}
			tab.activate()
		}
		
		private function dispatchDock(evt:MouseEvent):void
		{
			var panel:IPanel;
			if (evt.target is PanelTab) {
				panel = vec_panels[vec_tabs.indexOf(evt.target as PanelTab)];
			}
			dispatchEvent(new PanelContainerEvent(PanelContainerEvent.STATE_TOGGLE_REQUESTED, panel, null, true, false))
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
		
		public function removePanelAt(index:int):void
		{
			var tab:PanelTab = vec_tabs.splice(index, 1)[0];
			if(tab.parent == this) {
				removeChild(tab)
			}
			vec_panels.splice(index, 1)
			redraw(width, height)
		}
		
		public function removePanel(panel:IPanel):void 
		{
			var index:int = vec_panels.indexOf(panel)
			if(index == -1) {
				return;
			}
			removePanelAt(index)
		}
		
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
		
		public function set maxWidth(value:Number):void 
		{
			num_maxWidth = value;
			rect_visibleRegion.width = value
			pt_preferredLocation.x = 0;
			redraw(value, height)
		}
		
		public function set maxHeight(value:Number):void 
		{
			num_maxHeight = value;
			redraw(width, value)
			pt_preferredLocation.y = 0
			rect_visibleRegion.y = 16
			rect_visibleRegion.height = value - 40
		}
		
		public function get visibleRegion():Rectangle {
			return rect_visibleRegion
		}
		
		public function get preferredLocation():Point {
			return pt_preferredLocation;
		}
		public function get maxHeight():Number {
			return num_maxHeight;
		}
		
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