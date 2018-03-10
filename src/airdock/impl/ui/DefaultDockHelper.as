package airdock.impl.ui 
{
	import airdock.enums.PanelContainerSide;
	import airdock.events.DockEvent;
	import airdock.interfaces.docking.IDockTarget;
	import airdock.interfaces.ui.IDockHelper;
	import flash.desktop.NativeDragManager;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.NativeDragEvent;

	/**
	 * Dispatched when the user has dropped the panel or container onto the dock target, and the Docker is to decide what action to take.
	 * @eventType airdock.events.DockEvent.DRAG_COMPLETING
	 */
	[Event(name="deDragCompleting", type="airdock.events.DockEvent")]
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public class DefaultDockHelper extends Sprite implements IDockHelper
	{
		private var spr_centerShape:Sprite
		private var spr_leftShape:Sprite;
		private var spr_rightShape:Sprite;
		private var spr_topShape:Sprite;
		private var spr_bottomShape:Sprite;
		public function DefaultDockHelper() 
		{
			spr_leftShape = new Sprite()
			spr_rightShape = new Sprite()
			spr_topShape = new Sprite()
			spr_bottomShape = new Sprite()
			spr_centerShape = new Sprite()
			
			addChild(spr_leftShape)
			addChild(spr_rightShape)
			addChild(spr_topShape)
			addChild(spr_bottomShape)
			addChild(spr_centerShape)
			
			addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, acceptDragDrop)
			addEventListener(NativeDragEvent.NATIVE_DRAG_OVER, displayDockHandlesOnDrag, false, 0, true)
		}
		
		private function acceptDragDrop(evt:NativeDragEvent):void {
			dispatchEvent(new DockEvent(DockEvent.DRAG_COMPLETING, evt.clipboard, evt.target as DisplayObject, true, true))
		}
		
		private function displayDockHandlesOnDrag(evt:NativeDragEvent):void 
		{
			//ignore events that are received by the currently dragging panel
			var currentTarget:Sprite = evt.target as Sprite
			hideAll()
			currentTarget.alpha = 1
			NativeDragManager.acceptDragDrop(currentTarget)
		}
		
		/**
		 * @inheritDoc
		 */
		public function getSideFrom(dropTarget:DisplayObject):int
		{
			switch(dropTarget)
			{
				case spr_bottomShape:
					return PanelContainerSide.BOTTOM;
				case spr_topShape:
					return PanelContainerSide.TOP;
				case spr_leftShape:
					return PanelContainerSide.LEFT;
				case spr_rightShape:
					return PanelContainerSide.RIGHT;
				case spr_centerShape:
				default:
					return PanelContainerSide.FILL;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function hideAll():void {
			spr_centerShape.alpha = spr_leftShape.alpha = spr_rightShape.alpha = spr_bottomShape.alpha = spr_topShape.alpha = 0
		}
		
		/**
		 * @inheritDoc
		 */
		public function showAll():void {
			spr_centerShape.alpha = spr_leftShape.alpha = spr_rightShape.alpha = spr_bottomShape.alpha = spr_topShape.alpha = 1
		}
		
		/**
		 * @inheritDoc
		 */
		public function draw(width:Number, height:Number):void
		{
			var currGraphics:Graphics;
			var squareSize:Number = width / 3
			currGraphics = spr_centerShape.graphics
			currGraphics.clear()
			currGraphics.beginFill(0, 1)
			currGraphics.drawRect(squareSize, squareSize, squareSize, squareSize)
			currGraphics.endFill()
			
			currGraphics = spr_topShape.graphics
			currGraphics.clear()
			currGraphics.beginFill(0xFFFFFF, 1)
			currGraphics.drawRect(squareSize, 0, squareSize, squareSize)
			currGraphics.endFill()
			
			currGraphics = spr_bottomShape.graphics
			currGraphics.clear()
			currGraphics.beginFill(0xFFFFFF, 1)
			currGraphics.drawRect(squareSize, squareSize * 2, squareSize, squareSize)
			currGraphics.endFill()
			
			currGraphics = spr_leftShape.graphics
			currGraphics.clear()
			currGraphics.beginFill(0xFFFFFF, 1)
			currGraphics.drawRect(0, squareSize, squareSize, squareSize)
			currGraphics.endFill()
			
			currGraphics = spr_rightShape.graphics
			currGraphics.clear()
			currGraphics.beginFill(0xFFFFFF, 1)
			currGraphics.drawRect(squareSize * 2, squareSize, squareSize, squareSize)
			currGraphics.endFill()
		}
		
		/**
		 * @inheritDoc
		 */
		public function getDefaultWidth():Number {
			return 64.0
		}
		
		/**
		 * @inheritDoc
		 */
		public function getDefaultHeight():Number {
			return 64.0
		}
	}
}