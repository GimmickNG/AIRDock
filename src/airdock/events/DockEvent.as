package airdock.events 
{
	import flash.desktop.Clipboard;
	import flash.display.DisplayObject;
	import flash.display.NativeWindow;
	import flash.events.Event;
	
	/**
	 * @eventType	airdock.events.DockEvent.DRAG_COMPLETING
	 */
	[Event(name="deDragCompleting", type="airdock.events.DockEvent")]
	
	/**
	 * @eventType	airdock.events.DockEvent.DRAGGING
	 */
	[Event(name="deDragging", type="airdock.events.DockEvent")]

	/**
	 * A DockEvent is dispatched, and should be dispatched, whenever a drag-dock action is occurring, or when it is to be completed.
	 * This is to notify the originating Docker instance, which then takes appropriate action.
	 * @author	Gimmick
	 */
	public class DockEvent extends Event 
	{
		/**
		 * The constant used to define a dragCompleting event. Is dispatched whenever a drag-dock action is to be completed.
		 * Since this occurs before the drag-dock action is actually completed, it is usually cancelable.
		 */
		public static const DRAG_COMPLETING:String = "deDragCompleting";
		/**
		 * The constant used to define a dragging event. Is dispatched whenever a panel or container is currently taking part in a drag-dock action, usually as a result of user action.
		 */
		public static const DRAGGING:String = "deDragging";
		
		private var cl_clipBoard:Clipboard;
		private var dsp_dragTarget:DisplayObject;
		public function DockEvent(type:String, clipboard:Clipboard, dragTarget:DisplayObject, bubbles:Boolean=false, cancelable:Boolean=false) 
		{
			super(type, bubbles, cancelable);
			dsp_dragTarget = dragTarget;
			cl_clipBoard = clipboard;
		} 
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Event { 
			return new DockEvent(type, clipboard, dragTarget, bubbles, cancelable);
		} 
		
		/**
		 * @inheritDoc
		 */
		override public function toString():String { 
			return formatToString("DockEvent", "type", "clipboard", "dragTarget", "bubbles", "cancelable", "eventPhase"); 
		}
		
		/**
		 * The clipboard instance of the NativeDragEvent which caused this event to occur (which is usually a NativeDragEvent.NATIVE_DRAG_DROP event.)
		 * @see	flash.events.NativeDragEvent
		 */
		public function get clipboard():Clipboard {
			return cl_clipBoard;
		}
		
		/**
		 * The DisplayObject instance on which the object has been dropped on. Is usually part of an IDockTarget instance.
		 */
		public function get dragTarget():DisplayObject {
			return dsp_dragTarget;
		}
	}	
}