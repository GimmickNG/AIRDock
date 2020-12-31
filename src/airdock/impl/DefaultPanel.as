package airdock.impl 
{
	import airdock.delegates.PanelDelegate;
	import airdock.events.PropertyChangeEvent;
	import airdock.interfaces.display.IDisplayFilter;
	import airdock.interfaces.docking.IPanel;
	import flash.display.Sprite;
	
	/**
	 * Dispatched after a PROPERTY_CHANGING event has been dispatched, and if it has not been prevented, causing the related property to change.
	 * @eventType	airdock.events.PropertyChangeEvent.PROPERTY_CHANGED
	 */
	[Event(name="pchPropertyChange", type="airdock.events.PropertyChangeEvent")]
	
	/**
	 * Dispatched when any of the current panel's attributes are about to be changed:
	 * * color
	 * * dockable
	 * * resizable
	 * * width
	 * * height
	 * * panelName
	 * This is done to notify its container's IPanelList instance, amongst others, to update, in order to reflect the change in the panel's property.
	 * @eventType	airdock.events.PropertyChangeEvent.PROPERTY_CHANGING
	 */
	[Event(name="pchPropertyChanging", type="airdock.events.PropertyChangeEvent")]
	
	/**
	 * Default IPanel implementation. Is a container with a background color which can be changed on demand.
	 * 
	 * @author	Gimmick
	 * @see	airdock.interfaces.docking.IPanel
	 */
	public class DefaultPanel extends Sprite implements IPanel
	{
		private var u_color:uint;
		private var cl_panelDelegate:PanelDelegate
		public function DefaultPanel()
		{
			super();
			cl_panelDelegate = new PanelDelegate(this)
			addEventListener(PropertyChangeEvent.PROPERTY_CHANGING, updateSizeOnRedraw, false, 0, true)
			addEventListener(PropertyChangeEvent.PROPERTY_CHANGED, applyFiltersOnUpdate, false, 0, true)
		}
		
		override public function toString():String 
		{
			return panelName
		}
		
		private function applyFiltersOnUpdate(evt:PropertyChangeEvent):void 
		{
			if(evt.target == this && (evt.fieldName == "width" || evt.fieldName == "height")) {
				cl_panelDelegate.applyFilters(displayFilters)
			}
		}
		
		private function updateSizeOnRedraw(evt:PropertyChangeEvent):void 
		{
			const value:Number = Number(evt.newValue)
			if(evt.isDefaultPrevented() || evt.target != this) {
				return;
			}
			else switch(evt.fieldName)
			{
				case "backgroundColor":
					redraw(value, width, height);
					break;
				case "width":
					redraw(backgroundColor, value, height);
					break;
				case "height":
					redraw(backgroundColor, width, value);
					break;
			}
		}
		
		private function redraw(color:uint, width:Number, height:Number):void 
		{
			if(isNaN(width) || isNaN(height)) {
				return;
			}
			graphics.clear()
			graphics.beginFill(color & 0x00FFFFFF, ((color >>> 24) & 0xFF) / 0xFF)
			graphics.drawRect(0, 0, width, height)
			graphics.endFill()
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
		
		public function get displayFilters():Vector.<IDisplayFilter> {
			return cl_panelDelegate.displayFilters;
		}
		
		public function set displayFilters(value:Vector.<IDisplayFilter>):void {
			cl_panelDelegate.displayFilters = value;
		}
		
		public function get backgroundColor():uint {
			return cl_panelDelegate.backgroundColor;
		}
		
		public function set backgroundColor(value:uint):void {
			cl_panelDelegate.backgroundColor = value
		}
		
		/**
		 * @inheritDoc
		 */
		public function get panelName():String {
			return cl_panelDelegate.panelName;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set panelName(value:String):void {
			cl_panelDelegate.panelName = value;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get resizable():Boolean {
			return cl_panelDelegate.resizable;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set resizable(value:Boolean):void {
			cl_panelDelegate.resizable = value
		}
		
		/**
		 * @inheritDoc
		 */
		public function get dockable():Boolean {
			return cl_panelDelegate.dockable
		}
		
		/**
		 * @inheritDoc
		 */
		public function set dockable(value:Boolean):void {
			cl_panelDelegate.dockable = value
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get width():Number {
			return cl_panelDelegate.width
		}
		
		/**
		 * @inheritDoc
		 */
		override public function set width(value:Number):void {
			cl_panelDelegate.width = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get height():Number {
			return cl_panelDelegate.height
		}
		
		/**
		 * @inheritDoc
		 */
		override public function set height(value:Number):void {
			cl_panelDelegate.height = value
		}
	}

}