package airdock.delegates 
{
	import airdock.enums.PanelContainerSide;
	import airdock.events.PanelContainerEvent;
	import airdock.events.ResizerEvent;
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
		private var cl_resizer:IResizer;
		private var rect_maxSize:Rectangle;
		private var plc_container:IContainer;
		public function ResizerDelegate(resizer:IResizer)
		{
			cl_resizer = resizer;
			rect_maxSize = new Rectangle();
		}
		
		/**
		 * Signals that a resize for the given container is going to be resized.
		 * Can be canceled to prevent default action.
		 * @param	sideSize	The new side size, which is usually the position that the resizer will be at.
		 */
		public function requestResize(sideSize:Number):Boolean {
			return dispatchEvent(new ResizerEvent(ResizerEvent.RESIZING, container, sideSize, sideCode, false, false))
		}
		
		public function getDragBounds():Rectangle
		{
			var bounds:Rectangle = container.getBounds(cl_resizer.parent)
			bounds.height = container.height	//since container overrides width and height
			bounds.width = container.width		//set to the visible width and height
			return bounds
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
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			cl_resizer.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function dispatchEvent(event:Event):Boolean {
			return cl_resizer.dispatchEvent(event);
		}
		
		public function hasEventListener(type:String):Boolean {
			return cl_resizer.hasEventListener(type);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			cl_resizer.removeEventListener(type, listener, useCapture);
		}
		
		public function willTrigger(type:String):Boolean {
			return cl_resizer.willTrigger(type);
		}
	}

}