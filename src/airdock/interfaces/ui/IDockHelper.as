package airdock.interfaces.ui 
{
	import airdock.interfaces.display.IDisplayObjectContainer;
	import airdock.interfaces.docking.IDockTarget;
	import flash.display.DisplayObject;
	import flash.events.IEventDispatcher;
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public interface IDockHelper extends IDisplayObjectContainer, IEventDispatcher, IDockTarget
	{
		function hideAll():void;
		function showAll():void;
		function getDefaultWidth():Number;
		function getDefaultHeight():Number;
		function draw(width:Number, height:Number):void;
	}
	
}