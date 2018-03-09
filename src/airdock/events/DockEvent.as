package airdock.events 
{
	import flash.desktop.Clipboard;
	import flash.display.DisplayObject;
	import flash.display.NativeWindow;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public class DockEvent extends Event 
	{
		public static const DRAG_COMPLETED:String = "deDragComplete";
		public static const DRAGGING:String = "deDragging";
		
		private var cl_clipBoard:Clipboard;
		private var dsp_dragTarget:DisplayObject
		public function DockEvent(type:String, clipboard:Clipboard, dragTarget:DisplayObject, bubbles:Boolean=false, cancelable:Boolean=false) 
		{
			super(type, bubbles, cancelable);
			dsp_dragTarget = dragTarget
			cl_clipBoard = clipboard;
		} 
		
		public override function clone():Event 
		{ 
			return new DockEvent(type, clipboard, dragTarget, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("DockEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get clipboard():Clipboard 
		{
			return cl_clipBoard;
		}
		
		public function get dragTarget():DisplayObject 
		{
			return dsp_dragTarget;
		}
	
	}
	
}