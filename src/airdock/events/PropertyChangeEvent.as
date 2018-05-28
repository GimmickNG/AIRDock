package airdock.events 
{
	import flash.events.Event;
	
	/**
	 * @eventType	airdock.events.PropertyChangeEvent.PROPERTY_CHANGED
	 */
	[Event(name="pchPropertyChange", type="airdock.events.PropertyChangeEvent")]
	
	/**
	 * @eventType	airdock.events.PropertyChangeEvent.PROPERTY_CHANGING
	 */
	[Event(name="pchPropertyChanging", type="airdock.events.PropertyChangeEvent")]
	
	/**
	 * A PropertyChangeEvent is usually dispatched by any supporting instance whenever any of its properties has changed.
	 * Currently, the list of classes/interfaces which (are required to) dispatch PropertyChangeEvents are the IBasicDocker and the IPanel interface implementations.
	 * @author	Gimmick
	 */
	public class PropertyChangeEvent extends Event 
	{
		/**
		 * The constant used to define a propertyChanged event. Is dispatched whenever a panel's property is about to change.
		 */
		public static const PROPERTY_CHANGING:String = "pchPropertyChanging";
		/**
		 * The constant used to define a propertyChanged event. Is dispatched whenever a panel's property has changed.
		 * Can be canceled to prevent the property from being changed.
		 */
		public static const PROPERTY_CHANGED:String = "pchPropertyChange";
		
		private var obj_newValue:Object;
		private var obj_oldValue:Object;
		private var str_fieldName:String;
		public function PropertyChangeEvent(type:String, fieldName:String, oldValue:Object, newValue:Object, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
			str_fieldName = fieldName
			obj_oldValue = oldValue
			obj_newValue = newValue
		} 
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Event { 
			return new PropertyChangeEvent(type, fieldName, oldValue, newValue, bubbles, cancelable);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function toString():String { 
			return formatToString("PropertyChangeEvent", "type", "fieldName", "oldValue", "newValue", "bubbles", "cancelable", "eventPhase"); 
		}
		
		/**
		 * The previous value of the property which has changed.
		 */
		public function get oldValue():Object {
			return obj_oldValue;
		}
		
		/**
		 * The new value of the property which has changed.
		 */
		public function get newValue():Object {
			return obj_newValue;
		}
		
		/**
		 * The name of the property which has changed.
		 */
		public function get fieldName():String {
			return str_fieldName;
		}
	}
}