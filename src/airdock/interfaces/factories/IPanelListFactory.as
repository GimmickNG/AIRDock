package airdock.interfaces.factories 
{
	import airdock.interfaces.factories.IFactory;
	import airdock.interfaces.ui.IPanelList;
	
	/**
	 * An interface defining a factory which creates IPanelList instances, and may optionally be passed to the Docker instance when creating it.
	 * @author Gimmick
	 */
	public interface IPanelListFactory extends IFactory
	{
		/**
		 * This method is used to create an IPanelList instance, and is called automatically by the Docker instance whenever panels are attached to a previously empty IContainer, which does not have any containers below it.
		 * @return	An IPaneList instance.
		 */
		function createPanelList():IPanelList
	}
	
}