package airdock.enums 
{
	import airdock.config.ContainerConfig;
	import airdock.config.DockConfig;
	import airdock.config.PanelConfig;
	import airdock.impl.DefaultDockFormat;
	import airdock.impl.DefaultMultiFactory;
	import airdock.impl.DefaultTreeResolver;
	import airdock.impl.ui.DefaultDockHelper;
	import airdock.impl.ui.DefaultResizer;
	import airdock.interfaces.docking.IDockFormat;
	import airdock.interfaces.docking.ITreeResolver;
	import airdock.interfaces.factories.IContainerFactory;
	import airdock.interfaces.factories.IPanelFactory;
	import airdock.interfaces.factories.IPanelListFactory;
	import airdock.interfaces.ui.IDockHelper;
	import airdock.interfaces.ui.IResizer;
	import flash.display.DisplayObjectContainer;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.NativeWindowType;
	import flash.display.Stage;
	
	/**
	 * The default settings for a Docker. It is advised to use this in order to meet most (basic) use cases.
	 * @author	Gimmick
	 */
	public final class DockDefaults 
	{
		public static const TREE_RESOLVER:Class = DefaultTreeResolver
		public static const DOCK_FORMAT:Class = DefaultDockFormat
		public static const DOCK_HELPER_CLASS:Class = DefaultDockHelper
		public static const PANEL_LIST_FACTORY:Class = DefaultMultiFactory
		public static const CONTAINER_FACTORY:Class = DefaultMultiFactory
		public static const PANEL_FACTORY:Class = DefaultMultiFactory
		public static const RESIZER:Class = DefaultResizer
		
		public function DockDefaults() { }
		
		/**
		 * Creates the default options for a Docker instance.
		 * @param	mainContainer	The main container to which the Docker is to be attached to.
		 * @return	A DockConfig instance representing the set of (default) options for the Docker.
		 */
		public static function createDefaultOptions(mainContainer:DisplayObjectContainer):DockConfig
		{
			var options:DockConfig = new DockConfig()
			options.panelListFactory = new PANEL_LIST_FACTORY() as IPanelListFactory
			options.containerFactory = new CONTAINER_FACTORY() as IContainerFactory
			options.treeResolver = new TREE_RESOLVER() as ITreeResolver
			options.panelFactory = new PANEL_FACTORY() as IPanelFactory
			options.dockHelper = new DOCK_HELPER_CLASS() as IDockHelper
			options.dockFormat = new DOCK_FORMAT() as IDockFormat
			options.resizeHelper = new RESIZER() as IResizer
			options.mainContainer = mainContainer
			
			var nativeWindowOptions:NativeWindowInitOptions = new NativeWindowInitOptions()
			nativeWindowOptions.maximizable = nativeWindowOptions.minimizable = true
			nativeWindowOptions.systemChrome = NativeWindowSystemChrome.STANDARD
			nativeWindowOptions.type = NativeWindowType.UTILITY
			nativeWindowOptions.transparent = false;
			
			options.defaultContainerOptions = new ContainerConfig()
			options.defaultWindowOptions = nativeWindowOptions
			return options
		}
		
		public static function createDefaultContainerConfig(container:DisplayObjectContainer):ContainerConfig
		{
			var config:ContainerConfig = new ContainerConfig()
			var width:Number, height:Number;
			if (container is Stage)
			{
				width = (container as Stage).stageWidth;
				height = (container as Stage).stageHeight;
			}
			else
			{
				height = container.height;
				width = container.width;
			}
			config.height = height;
			config.width = width;
			return config;
		}
		
		public static function createDefaultPanelConfig(container:DisplayObjectContainer):PanelConfig
		{
			var config:PanelConfig = new PanelConfig()
			config.dockable = config.resizable = true;
			config.color = Math.random() * 0xFFFFFFFF;
			config.height = container.height;
			config.width = container.width;
			return config;
		}
	}
}