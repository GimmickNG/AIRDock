package airdock.delegates 
{
	import airdock.events.PropertyChangeEvent;
	import airdock.interfaces.display.IDisplayFilter;
	import airdock.interfaces.docking.IContainer;
	import airdock.interfaces.ui.IPanelList;
	import airdock.util.PropertyChangeProxy;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	
	/**
	 * ...
	 * @author	Gimmick
	 */
	public class ContainerDelegate implements IEventDispatcher
	{
		private var cl_baseContainer:IContainer;
		private var cl_changeProxy:PropertyChangeProxy;
		private var cl_displayFilterDelegate:DisplayFilterDelegate;
		public function ContainerDelegate(container:IContainer)
		{
			cl_baseContainer = container;
			cl_changeProxy = new PropertyChangeProxy(container)
			cl_displayFilterDelegate = new DisplayFilterDelegate(container)
		}
		
		public function dispatchChanging(property:String, oldValue:Object, newValue:Object):Boolean {
			return dispatchEvent(new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGING, property, oldValue, newValue, true, true))
		}
		
		public function dispatchChanged(property:String, oldValue:Object, newValue:Object):void {
			dispatchEvent(new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGED, property, oldValue, newValue, true, false))
		}
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			cl_baseContainer.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function dispatchEvent(event:Event):Boolean {
			return cl_baseContainer.dispatchEvent(event);
		}
		
		public function hasEventListener(type:String):Boolean {
			return cl_baseContainer.hasEventListener(type);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			cl_baseContainer.removeEventListener(type, listener, useCapture);
		}
		
		public function willTrigger(type:String):Boolean {
			return cl_baseContainer.willTrigger(type);
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
		
		public function get sideCode():int {
			return cl_changeProxy.sideCode;
		}
		
		public function set sideCode(sideCode:int):void {
			cl_changeProxy.sideCode = sideCode
		}
		
		public function get sideSize():Number {
			return cl_changeProxy.sideSize;
		}
		
		public function set sideSize(value:Number):void {
			cl_changeProxy.sideSize = value
		}
		
		public function get containerState():Boolean {
			return cl_changeProxy.containerState;
		}
		
		public function set containerState(value:Boolean):void {
			cl_changeProxy.containerState = value;
		}
		
		public function get maxSideSize():Number {
			return cl_changeProxy.maxSideSize;
		}
		
		public function set maxSideSize(value:Number):void {
			cl_changeProxy.maxSideSize = value;
		}
		
		public function get minSideSize():Number {
			return cl_changeProxy.minSideSize;
		}
		
		public function set minSideSize(value:Number):void {
			cl_changeProxy.minSideSize = value;
		}
		
		public function get panelList():IPanelList {
			return cl_changeProxy.panelList;
		}
		
		public function set panelList(panelList:IPanelList):void {
			cl_changeProxy.panelList = panelList
		}
		
		public function get width():Number {
			return cl_changeProxy.width;
		}
		
		public function set width(width:Number):void {
			cl_changeProxy.width = width
		}
		
		public function get height():Number {
			return cl_changeProxy.height;
		}
		
		public function set height(height:Number):void {
			cl_changeProxy.height = height;
		}
	}

}