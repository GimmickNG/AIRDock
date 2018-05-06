package airdock.delegates 
{
	import airdock.events.PanelPropertyChangeEvent;
	import airdock.interfaces.display.IDisplayFilter;
	import airdock.interfaces.docking.IPanel;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	
	/**
	 * ...
	 * @author	Gimmick
	 */
	public class PanelDelegate implements IEventDispatcher
	{
		private var b_dockable:Boolean;
		private var b_resizable:Boolean;
		private var cl_basePanel:IPanel;
		private var str_panelName:String;
		private var vec_displayFilters:Vector.<IDisplayFilter>;
		public function PanelDelegate(panel:IPanel) {
			cl_basePanel = panel;
		}
		
		public function dispatchChanging(property:String, oldValue:Object, newValue:Object):Boolean {
			return dispatchEvent(new PanelPropertyChangeEvent(PanelPropertyChangeEvent.PROPERTY_CHANGING, property, oldValue, newValue, true, true))
		}
		
		public function dispatchChanged(property:String, oldValue:Object, newValue:Object):void {
			dispatchEvent(new PanelPropertyChangeEvent(PanelPropertyChangeEvent.PROPERTY_CHANGED, property, oldValue, newValue, true, false))
		}
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			cl_basePanel.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function dispatchEvent(event:Event):Boolean {
			return cl_basePanel.dispatchEvent(event);
		}
		
		public function hasEventListener(type:String):Boolean {
			return cl_basePanel.hasEventListener(type);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			cl_basePanel.removeEventListener(type, listener, useCapture);
		}
		
		public function willTrigger(type:String):Boolean {
			return cl_basePanel.willTrigger(type);
		}
		
		public function get panelName():String 
		{
			return str_panelName;
		}
		
		public function set panelName(value:String):void 
		{
			var prevValue:String = str_panelName
			if (str_panelName != value && dispatchChanging("panelName", prevValue, value))
			{
				str_panelName = value;
				dispatchChanged("panelName", prevValue, value)
			}
		}
		
		public function get resizable():Boolean {
			return b_resizable;
		}
		
		public function set resizable(value:Boolean):void
		{
			if (b_resizable != value && dispatchChanging("resizable", !value, value))
			{
				b_resizable = value;
				dispatchChanged("resizable", !value, value)
			}
		}
		
		public function get dockable():Boolean {
			return b_dockable;
		}
		
		public function set dockable(value:Boolean):void 
		{
			if (b_dockable != value && dispatchChanging("dockable", !value, value))
			{
				b_dockable = value;
				dispatchChanged("dockable", !value, value)
			}
		}
		
		public function get displayFilters():Vector.<IDisplayFilter> {
			return vec_displayFilters && vec_displayFilters.concat();
		}
		
		public function set displayFilters(value:Vector.<IDisplayFilter>):void
		{
			var i:int;
			var filters:Vector.<IDisplayFilter> = vec_displayFilters
			for (i = int(filters && filters.length) - 1; i >= 0; --i) {
				filters[i].remove(cl_basePanel);
			}
			vec_displayFilters = value.concat();
			for (i = int(value && value.length) - 1; i >= 0; --i) {
				value[i].apply(cl_basePanel);
			}
		}
	}

}