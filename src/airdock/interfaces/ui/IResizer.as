package airdock.interfaces.ui 
{
	import airdock.interfaces.display.IDisplayObject;
	import airdock.interfaces.docking.IContainer;
	import flash.geom.Rectangle;
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public interface IResizer extends IDisplayObject
	{
		function getSideCode():int;
		function setSideCode(sideCode:int):void
		function getContainer():IContainer;
		function setContainer(container:IContainer):void;
		function set maxSize(size:Rectangle):void
		function get preferredXPercentage():Number;
		function get preferredYPercentage():Number;
		function get isDragging():Boolean
		function get tolerance():Number;
	}
}