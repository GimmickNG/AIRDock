package airdock.interfaces.docking 
{
	
	/**
	 * The class defining the strings keys used for storing the panel and container in clipboards during a drag-docking operation.
	 * This is useful when intercepting drag events and capturing the panel and/or container instances.
	 * @author	Gimmick
	 */
	public interface IDockFormat 
	{
		/**
		 * The string key for storing panels in the clipboard.
		 */
		function get panelFormat():String;
		/**
		 * The string key for storing the panels' container in the clipboard.
		 */
		function get containerFormat():String;
		/**
		 * The string key for storing the destination container in the clipboard.
		 */
		function get destinationFormat():String;
	}
	
}