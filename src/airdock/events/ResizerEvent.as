package airdock.events 
{
	import airdock.enums.ContainerSide;
	import airdock.interfaces.docking.IContainer;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public class ResizerEvent extends Event 
	{
		public static const RESIZING:String = "reResizing";
		public static const RESIZED:String = "reResized";
		
		private var str_sideCode:String;
		private var num_position:Number;
		private var plc_container:IContainer;
		public function ResizerEvent(type:String, container:IContainer = null, position:Number = NaN, sideCode:String = ContainerSide.FILL, bubbles:Boolean = false, cancelable:Boolean = false)
		{ 
			super(type, bubbles, cancelable);
			plc_container = container
			num_position = position;
			str_sideCode = sideCode
		}
		
		public override function clone():Event { 
			return new ResizerEvent(type, container, position, sideCode, bubbles, cancelable);
		} 
		
		public override function toString():String { 
			return formatToString("ResizerEvent", "container", "position", "side", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get sideCode():String {
			return str_sideCode;
		}
		
		public function get position():Number {
			return num_position;
		}
		
		public function get container():IContainer {
			return plc_container;
		}
		
	}
	
}