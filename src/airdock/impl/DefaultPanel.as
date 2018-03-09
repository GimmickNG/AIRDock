package airdock.impl 
{
	import airdock.enums.PanelContainerState;
	import airdock.events.PanelPropertyChangeEvent;
	import airdock.interfaces.docking.IPanel;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.InteractiveObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventPhase;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public class DefaultPanel extends Sprite implements IPanel
	{
		private var u_color:uint;
		private var b_dockable:Boolean
		private var b_resizable:Boolean
		private var str_panelName:String
		public function DefaultPanel() {
			super();
		}
		
		public function draw(color:uint, width:int, height:int):void
		{
			var prevWidth:Number = this.width
			var prevHeight:Number = this.height
			if (u_color != color)
			{
				var prevColor:uint = u_color;
				u_color = color;
				dispatchEvent(new PanelPropertyChangeEvent(PanelPropertyChangeEvent.PROPERTY_CHANGED, "backgroundColor", prevColor, color, true, false))
			}
			var colorAlpha:Number = ((color >>> 24) & 0xFF) / 0xFF
			graphics.clear()
			graphics.beginFill(color & 0x00FFFFFF, colorAlpha)
			graphics.drawRect(0, 0, width, height)
			graphics.endFill()
			if (prevWidth != width) {
				dispatchEvent(new PanelPropertyChangeEvent(PanelPropertyChangeEvent.PROPERTY_CHANGED, "width", prevWidth, width, true, false))
			}
			if (prevHeight != height) {
				dispatchEvent(new PanelPropertyChangeEvent(PanelPropertyChangeEvent.PROPERTY_CHANGED, "height", prevHeight, height, true, false))
			}
		}
		
		public function getDefaultHeight():Number {
			return 256;
		}
		
		public function getDefaultWidth():Number {
			return 256;
		}
		
		public function get backgroundColor():uint {
			return u_color;
		}
		
		public function set backgroundColor(value:uint):void 
		{
			if (value != u_color) {
				draw(value, width, height)
			}
		}
		
		public function get panelName():String {
			return str_panelName;
		}
		
		public function set panelName(value:String):void
		{
			if (str_panelName != value)
			{
				var prevValue:String = str_panelName
				str_panelName = value;
				dispatchEvent(new PanelPropertyChangeEvent(PanelPropertyChangeEvent.PROPERTY_CHANGED, "panelName", prevValue, value, true, false))
			}
		}
		
		public function get resizable():Boolean {
			return b_resizable;
		}
		
		public function set resizable(value:Boolean):void
		{
			if (b_resizable != value)
			{
				b_resizable = value;
				dispatchEvent(new PanelPropertyChangeEvent(PanelPropertyChangeEvent.PROPERTY_CHANGED, "resizable", !value, value, true, false))
			}
		}
		
		public function get dockable():Boolean {
			return b_dockable;
		}
		
		public function set dockable(value:Boolean):void
		{
			if (b_dockable != value) 
			{
				b_dockable = value;
				dispatchEvent(new PanelPropertyChangeEvent(PanelPropertyChangeEvent.PROPERTY_CHANGED, "dockable", !value, value, true, false))
			}
		}
		
		override public function get width():Number {
			return super.width;
		}
		
		override public function set width(value:Number):void 
		{
			if (width != value) {
				draw(u_color, value, height)
			}
		}
		
		override public function get height():Number {
			return super.height;
		}
		
		override public function set height(value:Number):void 
		{
			if (height != value) {
				draw(u_color, width, value);
			}
		}
	}

}