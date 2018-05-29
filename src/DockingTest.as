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
	import airdock.impl.DefaultPanel;
	import airdock.impl.DefaultTreeResolver;
	import airdock.impl.filters.BorderFilter;
	import airdock.util.IDisposable;
	import airdock.interfaces.display.IDisplayFilter;
	import airdock.interfaces.docking.IBasicDocker;
	import airdock.interfaces.docking.IPanel;
	import airdock.interfaces.docking.IContainer;
	import airdock.interfaces.docking.ICustomizableDocker;
	import airdock.interfaces.factories.IContainerFactory;
	import airdock.util.IPair;
	import flash.desktop.NativeApplication;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.NativeDragEvent;
	import flash.events.NativeWindowBoundsEvent;
	import flash.text.TextField;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	/**
	 * ...
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
			//cl_foreignDocker.crossDockingPolicy = CrossDockingPolicy.REJECT_INCOMING
			cl_localDocker.crossDockingPolicy = CrossDockingPolicy.PREVENT_OUTGOING
			stage.nativeWindow.addEventListener(Event.CLOSING, closeAll)
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
		
		private function closeAll(evt:Event):void 
		{
			(cl_localDocker as IDisposable).dispose();
			(cl_foreignDocker as IDisposable).dispose()
		}
	}
}

import airdock.delegates.DockHelperDelegate;
import airdock.enums.PanelContainerSide;
import airdock.interfaces.ui.IDockTarget;
import airdock.interfaces.ui.IDockHelper;
import flash.desktop.NativeDragManager;
import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.events.NativeDragEvent;

internal class GreenDockHelper extends Sprite implements IDockHelper
{
	private var spr_centerShape:Sprite;
	private var spr_leftShape:Sprite;
	private var spr_rightShape:Sprite;
	private var spr_topShape:Sprite;
	private var spr_bottomShape:Sprite;
	private var cl_helperDelegate:DockHelperDelegate;
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
		
		cl_helperDelegate = new DockHelperDelegate(this)
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
		currGraphics.beginFill(0xFFFFFF, 1)
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