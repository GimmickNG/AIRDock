package airdock.util 
{
	import airdock.events.PropertyChangeEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	/**
	 * Proxy class which stores properties of classes.
	 * Dispatches PropertyChangeEvents when a property has changed.
	 * @author Gimmick
	 */
	use namespace flash_proxy;
	dynamic public class PropertyChangeProxy extends Proxy implements IEventDispatcher
	{
		private var dct_elements:Dictionary;
		private var cl_dispatcher:IEventDispatcher;
		private var vec_properties:Vector.<String>;
		public function PropertyChangeProxy(target:IEventDispatcher)
		{
			cl_dispatcher = target
			dct_elements = new Dictionary(true);
			vec_properties = new Vector.<String>();
		}
		
		override flash_proxy function callProperty(methodName:*, ...args):*
		{
			const functor:Function = getProperty(methodName) as Function
			if (functor != null) {
				return functor.apply(null, args);
			}
			return undefined;
		}
		
		override flash_proxy function deleteProperty(name:*):Boolean
		{
			if (hasProperty(name) && !dispatchChanging(name, getProperty(name), null)) {
				return false;
			}
			const result:Boolean = delete dct_elements[name];
			return result;
		}
		
		override flash_proxy function getDescendants(name:*):* {
			return dct_elements[name];
		}
		
		override flash_proxy function getProperty(name:*):* {
			return dct_elements[name];
		}
		
		override flash_proxy function hasProperty(name:*):Boolean {
			return name in dct_elements;
		}
		
		override flash_proxy function isAttribute(name:*):Boolean {
			return name in dct_elements;
		}
		
		override flash_proxy function nextName(index:int):String {
			return vec_properties[index-1];
		}
		
		override flash_proxy function nextNameIndex(index:int):int
		{
			if (!index)
			{
				const propNames:Vector.<String> = vec_properties;
				propNames.length = 0;
				for (var obj:String in dct_elements) {
					propNames.push(obj);
				}
			}
			if(index < vec_properties.length) {
				return index + 1;
			}
			return 0;
		}
		
		override flash_proxy function nextValue(index:int):* {
			return dct_elements[vec_properties[index-1]];
		}
		
		override flash_proxy function setProperty(name:*, value:*):void
		{
			const prevValue:* = getProperty(name);
			if (prevValue === value || !dispatchChanging(name, prevValue, value)) {
				return;
			}
			dct_elements[name] = value;
			dispatchChanged(name, prevValue, value)
		}
		
		public function dispatchChanging(property:String, oldValue:Object, newValue:Object):Boolean {
			return dispatchEvent(new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGING, property, oldValue, newValue, true, true))
		}
		
		public function dispatchChanged(property:String, oldValue:Object, newValue:Object):void {
			dispatchEvent(new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGED, property, oldValue, newValue, true, false))
		}
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			cl_dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function dispatchEvent(event:Event):Boolean {
			return cl_dispatcher.dispatchEvent(event);
		}
		
		public function hasEventListener(type:String):Boolean {
			return cl_dispatcher.hasEventListener(type);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			cl_dispatcher.removeEventListener(type, listener, useCapture);
		}
		
		public function willTrigger(type:String):Boolean {
			return cl_dispatcher.willTrigger(type);
		}
	}

}