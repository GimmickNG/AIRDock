package airdock.delegates 
{
	import airdock.events.PanelContainerEvent;
	import airdock.interfaces.docking.IContainer;
	import airdock.interfaces.ui.IResizer;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.geom.Rectangle;
	/**
	 * ...
	 * @author	Gimmick
	 */
	public class ResizerDelegate 
	{
		private var i_sideCode:int;
		private var b_dragging:Boolean;
		private var rect_maxSize:Rectangle;
		private var cl_dispatcher:IResizer;
		private var plc_container:IContainer;
		public function ResizerDelegate(resizer:IResizer)
		{
			cl_dispatcher = resizer;
			rect_maxSize = new Rectangle();
		}
		
		/**
		 * Signals that a resize for the dragging container (specified in the container property of this class) has occurred.
		 */
		public function dispatchResize():Boolean {
			return dispatchEvent(new PanelContainerEvent(PanelContainerEvent.RESIZED, null, container, false, false))
		}
		
		/**
		 * Signals that a resize for the given container is going to be resized.
		 * Can be canceled to prevent default action.
		 * @param	container	The container which is going to be resized.
		 */
		public function dispatchResizing():Boolean {
			return dispatchEvent(new PanelContainerEvent(PanelContainerEvent.RESIZING, null, container, false, false))
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
		
		public function getDragBounds():Rectangle {
			return container.getBounds(cl_dispatcher.parent)
		}
		
		public function get isDragging():Boolean {
			return b_dragging;
		}
		
		public function set isDragging(value:Boolean):void {
			b_dragging = value;
		}
		
		public function get sideCode():int {
			return i_sideCode;
		}
		
		public function set sideCode(value:int):void {
			i_sideCode = value;
		}
		
		public function get container():IContainer {
			return plc_container;
		}
		
		public function set container(value:IContainer):void {
			plc_container = value;
		}
		
		public function get maxSize():Rectangle {	//returns a reference because no public getter
			return rect_maxSize						//in IResizer; only class that should modify this is
		}											//the IResizer implementation
		
		public function set maxSize(size:Rectangle):void 
		{
			if (size) {
				rect_maxSize.copyFrom(size)
			}
		}
		
	}

}