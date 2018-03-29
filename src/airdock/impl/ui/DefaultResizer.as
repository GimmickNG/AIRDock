package airdock.impl.ui 
{
	import airdock.delegates.ResizerDelegate;
	import airdock.enums.PanelContainerSide;
	import airdock.events.PanelContainerEvent;
	import airdock.interfaces.docking.IContainer;
	import airdock.interfaces.ui.IResizer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	
	/**
	 * Dispatched when the resizing operation has completed.
	 * @eventType	flash.events.Event.COMPLETE
	 */
	[Event(name = "complete", type = "flash.events.Event")]
	
	/**
	 * Dispatched whenever a resize operation has been applied, i.e. the corresponding container has been resized.
	 * @eventType	airdock.events.PanelContainerEvent.RESIZED
	 */
	[Event(name = "pcContainerResized", type = "airdock.events.PanelContainerEvent")]
	
	/**
	 * Default IResizer implementation.
	 * 
	 * Shows a black bar which is either horizontal or vertical whenever a container resize operation 
	 * is about to take place (i.e. when the user brings the cursor near the edge of the container)
	 * 
	 * Also shows the side which is going to be resized.
	 * 
	 * @author	Gimmick
	 * @see	airdock.interfaces.ui.IResizer
	 */
	public class DefaultResizer extends Sprite implements IResizer
	{
		private var str_prevCursor:String;
		private var rect_maxSize:Rectangle;
		private var rect_orientation:Rectangle;
		private var cl_resizerDelegate:ResizerDelegate;
		public function DefaultResizer()
		{
			buttonMode = true
			rect_maxSize = new Rectangle()
			rect_orientation = new Rectangle()
			cl_resizerDelegate = new ResizerDelegate(this)
			addEventListener(MouseEvent.MOUSE_DOWN, startResize, false, 0, true)
		}
		
		private function setCursorOnEvent(evt:MouseEvent):void {
			Mouse.cursor = str_prevCursor;
		}
		
		private function startResize(evt:MouseEvent):void 
		{
			str_prevCursor = Mouse.cursor
			Mouse.cursor = MouseCursor.HAND
			cl_resizerDelegate.isDragging = true
			removeEventListener(MouseEvent.MOUSE_DOWN, startResize)
			if (stage)
			{
				stage.addEventListener(MouseEvent.MOUSE_UP, stopResize, false, 0, true)
				stage.addEventListener(MouseEvent.MOUSE_MOVE, dispatchResize, false, 0, true)
			}
		}
		
		private function stopResize(evt:MouseEvent):void 
		{
			if(!cl_resizerDelegate.isDragging) {
				return;
			}
			else if (stage)
			{
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, dispatchResize)
				stage.removeEventListener(MouseEvent.MOUSE_UP, stopResize)
			}
			Mouse.cursor = str_prevCursor
			cl_resizerDelegate.isDragging = false
			dispatchEvent(new Event(Event.COMPLETE, false, false))
			addEventListener(MouseEvent.MOUSE_DOWN, startResize, false, 0, true)
		}
		
		private function dispatchResize(evt:MouseEvent):void 
		{
			if(!cl_resizerDelegate.dispatchResizing()) {
				return;
			}
			var newPosition:Number;
			var bounds:Rectangle = cl_resizerDelegate.getDragBounds();
			if (PanelContainerSide.isComplementary(PanelContainerSide.LEFT, cl_resizerDelegate.sideCode))
			{
				newPosition = x + mouseX;
				if (bounds.contains(newPosition, bounds.y)) {
					x = newPosition;
				}
			}
			else
			{
				newPosition = y + mouseY
				if (bounds.contains(bounds.x, newPosition)) {
					y = newPosition
				}
			}
			cl_resizerDelegate.dispatchResize();
		}
		
		/**
		 * @inheritDoc
		 */
		public function get isDragging():Boolean {
			return cl_resizerDelegate.isDragging
		}
		
		/**
		 * @inheritDoc
		 */
		public function set container(container:IContainer):void {
			cl_resizerDelegate.container = container
		}
		
		/**
		 * @inheritDoc
		 */
		public function get container():IContainer {
			return cl_resizerDelegate.container
		}
		
		/**
		 * @inheritDoc
		 */
		public function set sideCode(sideCode:int):void
		{
			cl_resizerDelegate.sideCode = sideCode
			if (PanelContainerSide.isComplementary(PanelContainerSide.LEFT, sideCode)) {	//horizontal
				rect_orientation.setTo(x, rect_maxSize.y, 4, rect_maxSize.height)
			}
			else if(PanelContainerSide.isComplementary(PanelContainerSide.TOP, sideCode)) {	//vertical
				rect_orientation.setTo(rect_maxSize.x, y, rect_maxSize.width, 4)
			}
			graphics.clear()
			graphics.beginFill(0, 1)
			graphics.drawRect(0, 0, rect_orientation.width, rect_orientation.height)
			var tempSideCode:int = sideCode
			switch(tempSideCode)
			{
				case PanelContainerSide.LEFT:
					graphics.drawRect(rect_orientation.width, ((rect_orientation.height * 0.5) - 8), 8, 16);
					break;
				case PanelContainerSide.RIGHT:
					graphics.drawRect(-8, ((rect_orientation.height * 0.5) - 8), 8, 16);
					break;
				case PanelContainerSide.TOP:
					graphics.drawRect(((rect_orientation.width * 0.5) - 8), rect_orientation.height, 16, 8);
					break;
				case PanelContainerSide.BOTTOM:
					graphics.drawRect(((rect_orientation.width * 0.5) - 8), -8, 16, 8);
					break;	
			}
			graphics.endFill()
		}
		
		/**
		 * @inheritDoc
		 */
		public function set maxSize(size:Rectangle):void {
			rect_maxSize.copyFrom(size)
		}
		
		/**
		 * @inheritDoc
		 */
		public function get preferredXPercentage():Number {
			return 0
		}
		
		/**
		 * @inheritDoc
		 */
		public function get preferredYPercentage():Number {
			return 0
		}
		
		/**
		 * @inheritDoc
		 */
		public function get sideCode():int {
			return cl_resizerDelegate.sideCode
		}
		
		/**
		 * @inheritDoc
		 */
		public function get tolerance():Number {
			return 0.05
		}	
	}
}