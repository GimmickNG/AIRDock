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
		function get containerFormat():String;
	}
	
}