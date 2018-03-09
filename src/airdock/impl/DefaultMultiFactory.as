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
	 * ...
	 * @author Gimmick
	 */
	public final class DefaultMultiFactory implements IContainerFactory, IPanelFactory, IPanelListFactory, IFactory
	{
		public function DefaultMultiFactory() { }
		
		public function createPanelList():IPanelList {
			return new DefaultPanelList()
		}
		
		public function createPanel(options:PanelConfig):IPanel 
		{
			var defaultPanel:DefaultPanel = new DefaultPanel()
			defaultPanel.draw(options.color, options.width, options.height)
			defaultPanel.resizable = options.resizable;
			return defaultPanel
		}
		
		public function createContainer(options:ContainerConfig):IContainer 
		{
			var defaultContainer:DefaultContainer = new DefaultContainer()
			defaultContainer.height = options.height
			defaultContainer.width = options.width
			return defaultContainer
		}
		
	}

}