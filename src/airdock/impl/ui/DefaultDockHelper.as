package airdock.impl.ui 
{
	import airdock.delegates.DockHelperDelegate;
	import airdock.enums.PanelContainerSide;
	import airdock.interfaces.ui.IDockTarget;
	import airdock.interfaces.ui.IDockHelper;
	import flash.desktop.NativeDragManager;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.NativeDragEvent;

	/**
	 * Default IDockHelper implementation. 
	 * 
	 * Provides a cross-shaped interface which allows the user to integrate panels or containers onto the left, right, top and bottom.
	 * 
	 * @author	Gimmick
	 * @see	airdock.interfaces.ui.IDockHelper
	 */
	public class DefaultDockHelper extends Sprite implements IDockHelper
	{
		private var spr_centerShape:Sprite;
		private var spr_leftShape:Sprite;
		private var spr_rightShape:Sprite;
		private var spr_topShape:Sprite;
		private var spr_bottomShape:Sprite;
		private var cl_helperDelegate:DockHelperDelegate;
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
			
			cl_helperDelegate = new DockHelperDelegate(this);
			var targets:Vector.<DisplayObject> = new <DisplayObject>[spr_topShape, spr_leftShape, spr_rightShape, spr_bottomShape, spr_centerShape];
			var sides:Vector.<String> = new <String>[PanelContainerSide.STRING_TOP, PanelContainerSide.STRING_LEFT, PanelContainerSide.STRING_RIGHT, PanelContainerSide.STRING_BOTTOM, PanelContainerSide.STRING_FILL];
			targets.forEach(function addTargetsToDelegate(target:DisplayObject, index:int, array:Vector.<DisplayObject>):void {
				cl_helperDelegate.addTarget(target, sides[index]);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function getSideFrom(dropTarget:DisplayObject):String {
			return cl_helperDelegate.getSideFrom(dropTarget);
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function hide(targets:Vector.<DisplayObject> = null):void
		{
			if (targets)
			{
				targets.forEach(function hideAllTargets(item:DisplayObject, index:int, array:Vector.<DisplayObject>):void {
					item.alpha = 0.0;
				});
			}
			else {
				spr_centerShape.alpha = spr_leftShape.alpha = spr_rightShape.alpha = spr_bottomShape.alpha = spr_topShape.alpha = 0
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function show(targets:Vector.<DisplayObject> = null):void
		{
			if (targets)
			{
				targets.forEach(function showAllTargets(item:DisplayObject, index:int, array:Vector.<DisplayObject>):void {
					item.alpha = 1.0;
				});
			}
			else {
				spr_centerShape.alpha = spr_leftShape.alpha = spr_rightShape.alpha = spr_bottomShape.alpha = spr_topShape.alpha = 1
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function draw(width:Number, height:Number):void
		{
			var currGraphics:Graphics;
			var squareSize:Number = (width + height) / 6
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
		
		/**
		 * @inheritDoc
		 */
		public function setDockFormat(panelFormat:String, containerFormat:String):void {
			cl_helperDelegate.setDockFormat(panelFormat, containerFormat)
		}
	}
}