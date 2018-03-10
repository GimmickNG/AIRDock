package airdock.interfaces.factories 
{
	import airdock.config.PanelConfig;
	import airdock.interfaces.docking.IPanel;
	
	/**
	 * An interface defining a factory which creates IPanel instances, which must be passed to the Docker instance when creating it.
	 * @author Gimmick
	 */
	public interface IPanelFactory extends IFactory
	{
		/**
		 * This method is used to create an IPanel instance, and is called by the Docker instance whenever the user creates a panel via the createPanel() method.
		 * @param	options	An instance of PanelConfig which describes the properties that the panel should have at the time of creation.
		 * @return	An IPanel instance.
		 */
		function createPanel(options:PanelConfig):IPanel
	}
	
}