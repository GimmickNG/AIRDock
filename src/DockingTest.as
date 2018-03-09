package
{
	import airdock.AIRDock;
	import airdock.config.ContainerConfig;
	import airdock.config.DockConfig;
	import airdock.impl.DefaultContainer;
	import airdock.enums.DockDefaults;
	import airdock.enums.PanelContainerSide;
	import airdock.enums.CrossDockingPolicy;
	import airdock.events.PanelContainerEvent;
	import airdock.config.PanelConfig;
	import airdock.impl.DefaultTreeResolver;
	import airdock.interfaces.docking.IBasicDocker;
	import airdock.interfaces.docking.IPanel;
	import airdock.interfaces.docking.IContainer;
	import airdock.interfaces.docking.ICustomizableDocker;
	import airdock.interfaces.factories.IContainerFactory;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.NativeWindowBoundsEvent;
	import flash.text.TextField;
	import flash.utils.getTimer;
	
	/**
	 * Sample class showing how to use AIRDock. This class creates two Dockers, 
	 * @author Gimmick
	 */
	public class DockingTest extends Sprite 
	{
		private var plc_local:IContainer;
		private var cl_localDocker:ICustomizableDocker;
		private var cl_foreignDocker:ICustomizableDocker;
		private var plc_foreign:IContainer;
		public function DockingTest() 
		{
			var localEnvironment:Sprite = new Sprite(), foreignEnvironment:Sprite = new Sprite()
			var rootContainerOptions:ContainerConfig = new ContainerConfig()
			var options:DockConfig;
			addChild(localEnvironment)
			addChild(foreignEnvironment)
			
			options.dragImageWidth = options.dragImageHeight = 100;
			rootContainerOptions.height = stage.stageHeight / 2;
			rootContainerOptions.width = stage.stageWidth / 2;
			stage.scaleMode = StageScaleMode.NO_SCALE
			stage.align = StageAlign.TOP_LEFT
			
			options = DockDefaults.createDefaultOptions(localEnvironment)
			cl_localDocker = AIRDock.create(options);
			cl_localDocker.crossDockingPolicy = CrossDockingPolicy.UNRESTRICTED
			
			options = DockDefaults.createDefaultOptions(foreignEnvironment)
			options.dockHelper = new GreenDockHelper()
			cl_foreignDocker = AIRDock.create(options);
			
			plc_local = cl_localDocker.createContainer(rootContainerOptions)
			plc_local.name = "local";
			
			plc_foreign = cl_foreignDocker.createContainer(rootContainerOptions)
			plc_foreign.y = stage.stageHeight / 2;
			plc_foreign.x = stage.stageWidth / 2;
			plc_foreign.name = "foreign";
			
			populateRoot(cl_foreignDocker, plc_foreign, 'foreign_');
			populateRoot(cl_localDocker, plc_local, 'local_')
			addChild(plc_local as DisplayObject)
			addChild(plc_foreign as DisplayObject)
			stage.nativeWindow.addEventListener(NativeWindowBoundsEvent.RESIZE, changeContainerSize)
		}
		
		private function populateRoot(docker:IBasicDocker, rootContainer:IContainer, prefix:String):void
		{
			const reps:int = 6;
			
			var paneOptions:PanelConfig = new PanelConfig()
			paneOptions.width = paneOptions.height = 300
			var pane:IPanel = docker.createPanel(paneOptions)
			for (var R:int, i:int = reps, prevContainer:IContainer = rootContainer; i >= 0; --i)
			{
				paneOptions.color = Math.random() * 0xFFFFFFFF;
				pane = docker.createPanel(paneOptions)
				
				pane.panelName = 'panel ' + prefix + i;
				
				//creates a top-left-top-left sequence
				R = PanelContainerSide.RIGHT
				if(i == reps) {
					R = PanelContainerSide.FILL
				}
				else if(!(i & 1)) {
					R = PanelContainerSide.BOTTOM
				}
				prevContainer = prevContainer.addToSide(R, pane)
			}
		}
		
		private function changeContainerSize(evt:NativeWindowBoundsEvent):void
		{
			plc_foreign.x = plc_foreign.width = plc_local.width = stage.stageWidth / 2;
			plc_foreign.y = plc_foreign.height = plc_local.height = stage.stageHeight / 2;
		}
	}
	
}

import flash.display.*;
import airdock.interfaces.ui.IDockHelper;
import flash.events.*;
import airdock.events.*;
import flash.desktop.*;
import airdock.enums.*;
internal class GreenDockHelper extends Sprite implements IDockHelper
{
	private var spr_centerShape:Sprite
	private var spr_leftShape:Sprite;
	private var spr_rightShape:Sprite;
	private var spr_topShape:Sprite;
	private var spr_bottomShape:Sprite;
	public function GreenDockHelper() 
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
		dispatchEvent(new DockEvent(DockEvent.DRAG_COMPLETED, evt.clipboard, evt.target as DisplayObject, true, false))
	}
	
	private function displayDockHandlesOnDrag(evt:NativeDragEvent):void 
	{
		//ignore events that are received by the currently dragging panel
		var currentTarget:Sprite = evt.target as Sprite
		hideAll()
		currentTarget.alpha = 1
		NativeDragManager.acceptDragDrop(currentTarget)
	}
	
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
	
	public function hideAll():void {
		spr_centerShape.alpha = spr_leftShape.alpha = spr_rightShape.alpha = spr_bottomShape.alpha = spr_topShape.alpha = 0
	}
	
	public function showAll():void {
		spr_centerShape.alpha = spr_leftShape.alpha = spr_rightShape.alpha = spr_bottomShape.alpha = spr_topShape.alpha = 1
	}
	
	public function draw(width:Number, height:Number):void
	{
		var currGraphics:Graphics;
		var squareSize:Number = width / 3
		currGraphics = spr_centerShape.graphics
		currGraphics.clear()
		currGraphics.beginFill(0xFF0000, 1)
		currGraphics.drawRect(squareSize, squareSize, squareSize, squareSize)
		currGraphics.endFill()
		
		currGraphics = spr_topShape.graphics
		currGraphics.clear()
		currGraphics.beginFill(0x00FF00, 1)
		currGraphics.drawRect(squareSize, 0, squareSize, squareSize)
		currGraphics.endFill()
		
		currGraphics = spr_bottomShape.graphics
		currGraphics.clear()
		currGraphics.beginFill(0x00FF00, 1)
		currGraphics.drawRect(squareSize, squareSize * 2, squareSize, squareSize)
		currGraphics.endFill()
		
		currGraphics = spr_leftShape.graphics
		currGraphics.clear()
		currGraphics.beginFill(0x00FF00, 1)
		currGraphics.drawRect(0, squareSize, squareSize, squareSize)
		currGraphics.endFill()
		
		currGraphics = spr_rightShape.graphics
		currGraphics.clear()
		currGraphics.beginFill(0x00FF00, 1)
		currGraphics.drawRect(squareSize * 2, squareSize, squareSize, squareSize)
		currGraphics.endFill()
	}
	
	public function getDefaultWidth():Number {
		return 64.0
	}
	
	public function getDefaultHeight():Number {
		return 64.0
	}
}