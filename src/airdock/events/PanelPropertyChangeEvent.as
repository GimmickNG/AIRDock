package airdock.events 
{
	import flash.events.Event;
	
	/**
	 * @eventType	airdock.events.PanelPropertyChangeEvent.PROPERTY_CHANGED
	 */
	[Event(name="ppcPropertyChange", type="airdock.events.PanelPropertyChangeEvent")]
	
	/**
	 * A PanelPropertyChangeEvent is usually dispatched by an IPanel instance whenever any of its properties has changed.
	 * This is done to notify its container's IPanelList instance, amongst others, to update, in order to reflect the change in the property.
	 * @author Gimmick
	 */
	public class PanelPropertyChangeEvent extends Event 
	{
		/**
		 * The constant used to define a propertyChanged event. Is dispatched whenever a panel's property has changed.
		 */
		public static const PROPERTY_CHANGED:String = "ppcPropertyChange";
		
		private var obj_newValue:Object;
		private var obj_oldValue:Object;
		private var str_fieldName:String;
		public function PanelPropertyChangeEvent(type:String, fieldName:String, oldValue:Object, newValue:Object, bubbles:Boolean = false, cancelable:Boolean = false)
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
			return new PanelPropertyChangeEvent(type, fieldName, oldValue, newValue, bubbles, cancelable);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function toString():String { 
			return formatToString("PanelPropertyChangeEvent", "type", "fieldName", "oldValue", "newValue", "bubbles", "cancelable", "eventPhase"); 
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