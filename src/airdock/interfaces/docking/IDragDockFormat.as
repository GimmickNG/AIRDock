package airdock.interfaces.docking 
{
	/**
	 * ...
	 * @author Gimmick
	 */
	public interface IDragDockFormat 
	{
		function get destinationContainer():IContainer;
		function set destinationContainer(dropTarget:IContainer):void;
		
		function get sideSequence():String;
		function set sideSequence(value:String):void;
	}
	
}