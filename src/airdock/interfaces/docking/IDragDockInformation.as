package airdock.interfaces.docking 
{
	import flash.display.DisplayObject;
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public interface IDragDockInformation 
	{
		function get destinationContainer():IContainer;
		function set destinationContainer(dropTarget:IContainer):void;
		
		function get sideSequence():String;
		function set sideSequence(value:String):void;
	}
	
}