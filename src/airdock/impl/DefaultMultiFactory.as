package airdock.impl 
{
	import airdock.config.ContainerConfig;
	import airdock.config.PanelConfig;
	import airdock.impl.ui.DefaultPanelList;
	import airdock.interfaces.docking.IContainer;
	import airdock.interfaces.docking.IPanel;
	import airdock.interfaces.factories.IContainerFactory;
	import airdock.interfaces.factories.IFactory;
	import airdock.interfaces.factories.IPanelFactory;
	import airdock.interfaces.factories.IPanelListFactory;
	import airdock.interfaces.ui.IPanelList;
	
	/**
	 * Default implementation for the IContainerFactory, IPanelFactory, and IPanelListFactory interfaces.
	 * 
	 * @author Gimmick
	 * @see	airdock.interfaces.factories.IPanelFactory
	 * @see	airdock.interfaces.factories.IContainerFactory
	 * @see	airdock.interfaces.factories.IPanelListFactory
	 */
	public final class DefaultMultiFactory implements IContainerFactory, IPanelFactory, IPanelListFactory, IFactory
	{
		public function DefaultMultiFactory() { }
		
		/**
		 * @inheritDoc
		 */
		public function createPanelList():IPanelList {
			return new DefaultPanelList()
		}
		
		/**
		 * @inheritDoc
		 */
		public function createPanel(options:PanelConfig):IPanel 
		{
			var defaultPanel:DefaultPanel = new DefaultPanel()
			defaultPanel.draw(options.color, options.width, options.height)
			defaultPanel.resizable = options.resizable;
			defaultPanel.dockable = options.dockable;
			return defaultPanel
		}
		
		/**
		 * @inheritDoc
		 */
		public function createContainer(options:ContainerConfig):IContainer 
		{
			var defaultContainer:IContainer = new DefaultContainer()
			defaultContainer.height = options.height
			defaultContainer.width = options.width
			return defaultContainer
		}
		
	}

}