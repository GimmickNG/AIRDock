package airdock.interfaces.factories 
{
	import airdock.interfaces.ui.IPanelList;
	
	/**
	 * An interface defining a factory which creates IPanelList instances, and may optionally be passed to the Docker instance when creating it.
	 * @author	Gimmick
	 */
	public interface IPanelListFactory extends IFactory
	{
		/**
		 * Used to create an IPanelList instance.
		 * Called automatically by the Docker instance whenever panels are attached to a previously empty IContainer (with no subcontainers).
		 * @return	An IPaneList instance.
		 */
		function createPanelList():IPanelList
	}
	
}