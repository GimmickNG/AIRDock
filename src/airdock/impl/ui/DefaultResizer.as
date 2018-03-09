package airdock.impl.ui 
{
	import airdock.enums.PanelContainerSide;
	import airdock.events.PanelContainerEvent;
	import airdock.interfaces.docking.IContainer;
	import airdock.interfaces.ui.IResizer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public class DefaultResizer extends Sprite implements IResizer
	{
		private var i_sideCode:int;
		private var b_dragging:Boolean;
		private var rect_maxSize:Rectangle
		private var rect_orientation:Rectangle
		private var plc_dragContainer:IContainer;
		public function DefaultResizer()
		{
			buttonMode = true
			rect_maxSize = new Rectangle()
			rect_orientation = new Rectangle()
			addEventListener(MouseEvent.MOUSE_DOWN, startResize, false, 0, true)
		}
		private function startResize(evt:MouseEvent):void 
		{
			removeEventListener(MouseEvent.MOUSE_DOWN, startResize)
			b_dragging = true
			if (stage)
			{
				stage.addEventListener(MouseEvent.MOUSE_MOVE, dispatchResize, false, 0, true)
				stage.addEventListener(MouseEvent.MOUSE_UP, stopResize, false, 0, true)
			}
		}
		
		private function stopResize(evt:MouseEvent):void 
		{
			if(!b_dragging) {
				return;
			}
			b_dragging = false
			if (stage)
			{
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, dispatchResize)
				stage.removeEventListener(MouseEvent.MOUSE_UP, stopResize)
			}
			dispatchEvent(new Event(Event.COMPLETE, false, false))
			addEventListener(MouseEvent.MOUSE_DOWN, startResize, false, 0, true)
		}
		
		private function dispatchResize(evt:MouseEvent):void 
		{
			var bounds:Rectangle = plc_dragContainer.getBounds(parent);
			if (i_sideCode == PanelContainerSide.LEFT || i_sideCode == PanelContainerSide.RIGHT)
			{
				if (bounds.contains(x + mouseX, bounds.y)) {
					x += mouseX
				}
			}
			else
			{
				if (bounds.contains(bounds.x, y + mouseY)) {
					y += mouseY
				}
			}
			dispatchEvent(new PanelContainerEvent(PanelContainerEvent.RESIZED, null, plc_dragContainer, false, false))
		}
		
		public function get isDragging():Boolean {
			return b_dragging
		}
		
		public function setContainer(container:IContainer):void {
			plc_dragContainer = container
		}
		
		public function getContainer():IContainer {
			return plc_dragContainer
		}
		
		public function setSideCode(sideCode:int):void
		{
			if (PanelContainerSide.isComplementary(PanelContainerSide.LEFT, sideCode)) {	//horizontal
				rect_orientation.setTo(x, rect_maxSize.y, 4, rect_maxSize.height)
			}
			else if(PanelContainerSide.isComplementary(PanelContainerSide.TOP, sideCode)) {	//vertical
				rect_orientation.setTo(rect_maxSize.x, y, rect_maxSize.width, 4)
			}
			graphics.clear()
			graphics.beginFill(0, 1)
			graphics.drawRect(0, 0, rect_orientation.width, rect_orientation.height)
			graphics.endFill()
			i_sideCode = sideCode
		}
		
		public function set maxSize(size:Rectangle):void {
			rect_maxSize.copyFrom(size)
		}
		
		public function get preferredXPercentage():Number {
			return 0
		}
		
		public function get preferredYPercentage():Number {
			return 0
		}
		
		public function getSideCode():int {
			return i_sideCode
		}
		
		public function get tolerance():Number {
			return 0.05
		}	
	}
}