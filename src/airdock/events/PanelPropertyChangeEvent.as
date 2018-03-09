package airdock.events 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public class PanelPropertyChangeEvent extends Event 
	{
		public static const PROPERTY_CHANGED:String = "ppcPropertyChange";
		
		private var str_fieldName:String
		private var obj_newValue:Object;
		private var obj_oldValue:Object;
		public function PanelPropertyChangeEvent(type:String, fieldName:String, oldValue:Object, newValue:Object, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
			str_fieldName = fieldName
			obj_oldValue = oldValue
			obj_newValue = newValue
		} 
		
		public override function clone():Event { 
			return new PanelPropertyChangeEvent(type, fieldName, oldValue, newValue, bubbles, cancelable);
		} 
		
		public override function toString():String { 
			return formatToString("PanelPropertyChangeEvent", "type", "fieldName", "oldValue", "newValue", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get oldValue():Object {
			return obj_oldValue;
		}
		
		public function get newValue():Object {
			return obj_newValue;
		}
		
		public function get fieldName():String {
			return str_fieldName;
		}
		
	}
	
}