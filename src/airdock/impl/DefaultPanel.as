package airdock.impl 
{
	import airdock.delegates.PanelDelegate;
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
	 * Dispatched when any of the listed panel's attributes have been changed:
	 * * color
	 * * dockable
	 * * resizable
	 * * width
	 * * height
	 * * panelName
	 * @eventType	airdock.events.PanelPropertyChangeEvent.PROPERTY_CHANGED
	 */
	[Event(name="ppcPropertyChange", type="airdock.events.PanelPropertyChangeEvent")]
	
	/**
	 * Default IPanel implementation. Is a container with a background color which can be changed on demand.
	 * 
	 * @author	Gimmick
	 * @see	airdock.interfaces.docking.IPanel
	 */
	public class DefaultPanel extends Sprite implements IPanel
	{
		private var u_color:uint;
		private var b_dockable:Boolean
		private var b_resizable:Boolean
		private var str_panelName:String
		private var cl_panelDelegate:PanelDelegate
		public function DefaultPanel()
		{
			super();
			cl_panelDelegate = new PanelDelegate(this)
		}
		
		public function draw(color:uint, width:int, height:int):void
		{
			var prevWidth:Number = this.width
			var prevHeight:Number = this.height
			if((prevWidth != width && !cl_panelDelegate.dispatchChanging("width", prevWidth, width) || (prevHeight != height && !cl_panelDelegate.dispatchChanging("height", prevHeight, height)))) {
				return;
			}
			
			if (u_color != color && cl_panelDelegate.dispatchChanging("backgroundColor", prevColor, color))
			{
				var prevColor:uint = u_color;
				u_color = color;
				cl_panelDelegate.dispatchChanged("backgroundColor", prevColor, color)
			}
			var colorAlpha:Number = ((color >>> 24) & 0xFF) / 0xFF
			graphics.clear()
			graphics.beginFill(color & 0x00FFFFFF, colorAlpha)
			graphics.drawRect(0, 0, width, height)
			graphics.endFill()
			if (prevWidth != width) {
				cl_panelDelegate.dispatchChanged("width", prevWidth, width)
			}
			if (prevHeight != height) {
				cl_panelDelegate.dispatchChanged("height", prevHeight, height)
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function getDefaultHeight():Number {
			return 256;
		}
		
		/**
		 * @inheritDoc
		 */
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
		
		/**
		 * @inheritDoc
		 */
		public function get panelName():String {
			return str_panelName;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set panelName(value:String):void
		{
			var prevValue:String = str_panelName
			if (str_panelName != value && cl_panelDelegate.dispatchChanging("panelName", prevValue, value))
			{
				str_panelName = value;
				cl_panelDelegate.dispatchChanged("panelName", prevValue, value)
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function get resizable():Boolean {
			return b_resizable;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set resizable(value:Boolean):void
		{
			if (b_resizable != value && cl_panelDelegate.dispatchChanging("resizable", !value, value))
			{
				b_resizable = value;
				cl_panelDelegate.dispatchChanged("resizable", !value, value)
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function get dockable():Boolean {
			return b_dockable;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set dockable(value:Boolean):void
		{
			if (b_dockable != value && cl_panelDelegate.dispatchChanging("dockable", !value, value))
			{
				b_dockable = value;
				cl_panelDelegate.dispatchChanged("dockable", !value, value)
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get width():Number {
			return super.width;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function set width(value:Number):void 
		{
			if (width != value) {
				draw(u_color, value, height)
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get height():Number {
			return super.height;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function set height(value:Number):void 
		{
			if (height != value) {
				draw(u_color, width, value);
			}
		}
	}

}