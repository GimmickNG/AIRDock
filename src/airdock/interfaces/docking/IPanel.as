package airdock.interfaces.docking 
{
	import airdock.interfaces.display.IDisplayObjectContainer;
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public interface IPanel extends IDisplayObjectContainer
	{
		function getDefaultWidth():Number;
		function getDefaultHeight():Number;
		function set panelName(value:String):void
		function get panelName():String
		function set resizable(value:Boolean):void
		function get resizable():Boolean
		function set dockable(value:Boolean):void
		function get dockable():Boolean
	}
	
}