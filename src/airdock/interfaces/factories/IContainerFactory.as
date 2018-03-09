package airdock.interfaces.factories 
{
	import airdock.config.ContainerConfig;
	import airdock.interfaces.docking.IContainer;
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public interface IContainerFactory extends IFactory {
		function createContainer(options:ContainerConfig):IContainer
	}
	
}