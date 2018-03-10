package airdock.interfaces.factories 
{
	import airdock.config.ContainerConfig;
	import airdock.interfaces.docking.IContainer;
	
	/**
	 * An interface defining a factory which creates IContainer instances, and must be passed to the Docker instance when creating it.
	 * @author Gimmick
	 */
	public interface IContainerFactory extends IFactory
	{
		/**
		 * This method is used to create an IContainer instance, and is called automatically by the Docker instance when setting up a panel.
		 * The default ContainerConfig options which are passed in the DockConfig instance at the time of creation of the Docker instance is supplied as a parameter to this function.
		 * @param	options	The default ContainerConfig options passed in the DockConfig instance when creating the Docker instance.
		 * @return	An IContainer instance.
		 */
		function createContainer(options:ContainerConfig):IContainer
	}
	
}