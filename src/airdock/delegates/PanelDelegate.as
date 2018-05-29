package airdock.delegates 
{
	import airdock.events.PropertyChangeEvent;
	import airdock.interfaces.display.IDisplayFilter;
	import airdock.interfaces.docking.IPanel;
	import airdock.util.PropertyChangeProxy;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	
	/**
	 * ...
	 * @author	Gimmick
	 */
	public class PanelDelegate implements IEventDispatcher
	{
		private var cl_basePanel:IPanel;
		private var cl_changeProxy:PropertyChangeProxy;
		private var cl_displayFilterDelegate:DisplayFilterDelegate;
		public function PanelDelegate(panel:IPanel)
		{
			cl_basePanel = panel;
			cl_changeProxy = new PropertyChangeProxy(panel)
			cl_displayFilterDelegate = new DisplayFilterDelegate(panel)
		}
		
		public function dispatchChanging(property:String, oldValue:Object, newValue:Object):Boolean {
			return dispatchEvent(new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGING, property, oldValue, newValue, true, true))
		}
		
		public function dispatchChanged(property:String, oldValue:Object, newValue:Object):void {
			dispatchEvent(new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGED, property, oldValue, newValue, true, false))
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
		
		public function applyFilters(filters:Vector.<IDisplayFilter>):void {
			cl_displayFilterDelegate.applyFilters(filters);
		}
		
		public function clearFilters(filters:Vector.<IDisplayFilter>):void {
			cl_displayFilterDelegate.clearFilters(filters);
		}
		
		public function get displayFilters():Vector.<IDisplayFilter>
		{
			var filters:Vector.<IDisplayFilter> = cl_changeProxy.displayFilters as Vector.<IDisplayFilter>;
			return filters && filters.concat();
		}
		
		public function set displayFilters(value:Vector.<IDisplayFilter>):void
		{
			cl_displayFilterDelegate.clearFilters(cl_changeProxy.displayFilters as Vector.<IDisplayFilter>)
			cl_changeProxy.displayFilters = value && value.concat();
			cl_displayFilterDelegate.applyFilters(value)
		}
		
		public function get panelName():String {
			return cl_changeProxy.panelName as String
		}
		
		public function set panelName(value:String):void {
			cl_changeProxy.panelName = value;
		}
		
		public function get resizable():Boolean {
			return cl_changeProxy.resizable;
		}
		
		public function set resizable(value:Boolean):void {
			cl_changeProxy.resizable = value
		}
		
		public function get dockable():Boolean {
			return cl_changeProxy.dockable;
		}
		
		public function set dockable(value:Boolean):void {
			cl_changeProxy.dockable = value
		}
	}

}