package airdock.interfaces.ui 
{
	import airdock.interfaces.display.IDisplayObjectContainer;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public interface IDisplayablePanelList extends IPanelList, IDisplayObjectContainer
	{
		function get preferredLocation():Point;
		function set maxWidth(value:Number):void;
		function set maxHeight(value:Number):void;
		function get visibleRegion():Rectangle;
		function get maxHeight():Number;
		function get maxWidth():Number;
	}
	
}