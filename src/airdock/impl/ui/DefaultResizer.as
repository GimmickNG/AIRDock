package airdock.impl.ui 
{
	import airdock.delegates.ResizerDelegate;
	import airdock.enums.PanelContainerSide;
	import airdock.events.PanelContainerEvent;
	import airdock.events.ResizerEvent;
	import airdock.interfaces.docking.IContainer;
	import airdock.interfaces.ui.IResizer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	
	/**
	 * Dispatched when the resizing operation has completed.
	 * @eventType	flash.events.Event.COMPLETE
	 */
	[Event(name="complete", type="flash.events.Event")]
	
	/**
	 * Dispatched whenever a resize operation is about to be applied, that is, when a container is about to be resized.
	 * @eventType	airdock.events.ResizerEvent.RESIZING
	 */
	[Event(name="reResizing", type="airdock.events.ResizerEvent")]
	
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
		private var cl_resizerDelegate:ResizerDelegate;
		public function DefaultResizer()
		{
			buttonMode = doubleClickEnabled = true;
			resizerDelegate = new ResizerDelegate(this)
			addEventListener(MouseEvent.MOUSE_DOWN, startResize, false, 0, true)
			addEventListener(MouseEvent.DOUBLE_CLICK, togglePanelSizeOnDoubleClick, false, 0, true)
		}
		
		private function startResize(evt:MouseEvent):void 
		{
			resizerDelegate.isDragging = true
			removeEventListener(MouseEvent.MOUSE_DOWN, startResize)
			if (stage)
			{
				stage.addEventListener(MouseEvent.MOUSE_UP, stopResize, false, 0, true)
				stage.addEventListener(MouseEvent.MOUSE_MOVE, dispatchResize, false, 0, true)
			}
		}
		
		private function stopResize(evt:MouseEvent):void 
		{
			if(!resizerDelegate.isDragging) {
				return;
			}
			else if (stage)
			{
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, dispatchResize)
				stage.removeEventListener(MouseEvent.MOUSE_UP, stopResize)
			}
			resizerDelegate.isDragging = false
			dispatchEvent(new Event(Event.COMPLETE, false, false))
			addEventListener(MouseEvent.MOUSE_DOWN, startResize, false, 0, true)
		}
		
		private function dispatchResize(evt:MouseEvent):void 
		{
			var newPosition:Number;
			var sideCode:int = resizerDelegate.sideCode;
			var bounds:Rectangle = resizerDelegate.getDragBounds();
			if(!bounds) {
				return;
			}
			else if (PanelContainerSide.isComplementary(PanelContainerSide.LEFT, sideCode))
			{
				newPosition = x + mouseX;
				if (!bounds.contains(newPosition, bounds.y)) {
					return;
				}
			}
			else
			{
				newPosition = y + mouseY;
				if (!bounds.contains(bounds.x, newPosition)) {
					return;
				}
			}
			var ratio:Number;
			var position:Point = container.globalToLocal(new Point(newPosition, newPosition))
			if (PanelContainerSide.isComplementary(PanelContainerSide.LEFT, sideCode))
			{
				x = newPosition;
				ratio = position.x / container.width;
			}
			else
			{
				y = newPosition;
				ratio = position.y / container.height;
			}
			resizerDelegate.requestResize(ratio)
		}
		
		/**
		 * Minimizes the container when the resizer is double-clicked.
		 */
		private function togglePanelSizeOnDoubleClick(evt:MouseEvent):void 
		{
			var newPosition:Number, ratio:Number = 0.0;
			var bounds:Rectangle = resizerDelegate.getDragBounds();
			if(!bounds) {
				return;
			}
			else if(sideCode == PanelContainerSide.LEFT || sideCode == PanelContainerSide.TOP) {
				ratio = 1.0;
			}
			switch(sideCode)
			{
				case PanelContainerSide.LEFT:
				case PanelContainerSide.RIGHT:
					newPosition = x = bounds.x + (bounds.width * int(ratio))
					break;
				case PanelContainerSide.TOP:
					newPosition = y = bounds.y + (bounds.height * int(ratio));
					break;
				default:
					return;
			}
			
			resizerDelegate.requestResize(ratio);
			drawSide(PanelContainerSide.getComplementary(sideCode));	//flips handle to show it on other side
		}
		
		/**
		 * @inheritDoc
		 */
		public function get isDragging():Boolean {
			return resizerDelegate.isDragging
		}
		
		/**
		 * @inheritDoc
		 */
		public function set container(container:IContainer):void {
			resizerDelegate.container = container
		}
		
		/**
		 * @inheritDoc
		 */
		public function get container():IContainer {
			return resizerDelegate.container
		}
		
		/**
		 * @inheritDoc
		 */
		public function set sideCode(sideCode:int):void
		{
			resizerDelegate.sideCode = sideCode
			drawSide(sideCode)
		}
		
		private function drawSide(sideCode:int):void 
		{
			var maxSize:Rectangle = resizerDelegate.maxSize;
			if (PanelContainerSide.isComplementary(PanelContainerSide.LEFT, sideCode)) {	//horizontal
				redraw(4, maxSize.height, sideCode);
			}
			else if(PanelContainerSide.isComplementary(PanelContainerSide.TOP, sideCode)) {	//vertical
				redraw(maxSize.width, 4, sideCode);
			}
		}
		
		private function redraw(width:Number, height:Number, sideCode:int):void
		{
			const handleHeight:int = 16;
			const handleWidth:int = 8;
			graphics.clear()
			graphics.beginFill(0, 1)
			graphics.drawRect(0, 0, width, height)
			switch(sideCode)
			{
				case PanelContainerSide.LEFT:
					graphics.drawRect(width, ((height * 0.5) - handleWidth), handleWidth, handleHeight);
					break;
				case PanelContainerSide.RIGHT:
					graphics.drawRect(-handleWidth, ((height * 0.5) - handleWidth), handleWidth, handleHeight);
					break;
				case PanelContainerSide.TOP:
					graphics.drawRect(((width * 0.5) - handleWidth), height, handleHeight, handleWidth);
					break;
				case PanelContainerSide.BOTTOM:
					graphics.drawRect(((width * 0.5) - handleWidth), -handleWidth, handleHeight, handleWidth);
					break;	
			}
			graphics.endFill()
		}
		/**
		 * @inheritDoc
		 */
		public function set maxSize(size:Rectangle):void {
			resizerDelegate.maxSize = size
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
			return resizerDelegate.sideCode
		}
		
		/**
		 * @inheritDoc
		 */
		public function get tolerance():Number {
			return 0.05
		}	
		
		protected function get resizerDelegate():ResizerDelegate {
			return cl_resizerDelegate;
		}
		
		protected function set resizerDelegate(value:ResizerDelegate):void {
			cl_resizerDelegate = value;
		}
	}
}