package airdock.impl.ui 
{
	import airdock.delegates.DockHelperDelegate;
	import airdock.enums.PanelContainerSide;
	import airdock.events.DockEvent;
	import airdock.interfaces.docking.IDockTarget;
	import airdock.interfaces.ui.IDockHelper;
	import airdock.util.IPair;
	import airdock.util.StaticPair;
	import flash.desktop.NativeDragManager;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.NativeDragEvent;

	/**
	 * Dispatched when the user has dropped the panel or container onto the dock target, and the Docker is to decide what action to take.
	 * @eventType	airdock.events.DockEvent.DRAG_COMPLETING
	 */
	[Event(name="deDragCompleting", type="airdock.events.DockEvent")]
	
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
			
			cl_helperDelegate = new DockHelperDelegate(this)
			cl_helperDelegate.addTargets(new <IPair>[
				new StaticPair(spr_leftShape, PanelContainerSide.LEFT), new StaticPair(spr_rightShape, PanelContainerSide.RIGHT), 
				new StaticPair(spr_topShape, PanelContainerSide.TOP), new StaticPair(spr_bottomShape, PanelContainerSide.BOTTOM), new StaticPair(spr_centerShape, PanelContainerSide.FILL)
			]);
		}
		
		/**
		 * @inheritDoc
		 */
		public function getSideFrom(dropTarget:DisplayObject):int {
			return cl_helperDelegate.getSideFrom(dropTarget);
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function hide(targets:Vector.<DisplayObject> = null):void
		{
			if (!targets) {
				spr_centerShape.alpha = spr_leftShape.alpha = spr_rightShape.alpha = spr_bottomShape.alpha = spr_topShape.alpha = 0
			}
			else for (var i:uint = 0; i < targets.length; ++i) {
				targets[i].alpha = 0.0;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function show(targets:Vector.<DisplayObject> = null):void
		{
			if (!targets) {
				spr_centerShape.alpha = spr_leftShape.alpha = spr_rightShape.alpha = spr_bottomShape.alpha = spr_topShape.alpha = 1
			}
			else for (var i:uint = 0; i < targets.length; ++i) {
				targets[i].alpha = 1.0;
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