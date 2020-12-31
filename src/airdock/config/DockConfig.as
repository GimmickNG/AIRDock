package airdock.config 
{
	import airdock.interfaces.docking.IDockFormat;
	import airdock.interfaces.docking.ITreeResolver;
	import airdock.interfaces.factories.IContainerFactory;
	import airdock.interfaces.factories.IPanelFactory;
	import airdock.interfaces.factories.IPanelListFactory;
	import airdock.interfaces.strategies.IThumbnailStrategy;
	import airdock.interfaces.ui.IDockHelper;
	import airdock.interfaces.ui.IResizer;
	import flash.display.DisplayObjectContainer;
	import flash.display.NativeWindowInitOptions;
	
	/**
	 * Base configuration class for creating a Docker instance.
	 * @author	Gimmick
	 */
	public class DockConfig extends Object
	{
		private var cl_treeResolver:ITreeResolver;
		private var cl_dockFormat:IDockFormat;
		private var num_dragImageHeight:Number;
		private var num_dragImageWidth:Number;
		private var i_crossDockingPolicy:int;
		private var cl_resizeHelper:IResizer;
		private var cl_dockHelper:IDockHelper;
		private var cl_panelFactory:IPanelFactory
		private var cl_containerFactory:IContainerFactory
		private var cl_panelListFactory:IPanelListFactory
		private var cl_thumbnailStrategy:IThumbnailStrategy;
		private var dsp_mainContainer:DisplayObjectContainer
		private var cl_defaultWindowOptions:NativeWindowInitOptions
		private var cl_defaultContainerOptions:ContainerConfig;
		public function DockConfig() { }
		
		/**
		 * The main container to which the Docker instance is attached to.
		 * This can be any container which extends DisplayObjectContainer, provided the following conditions are met:
		 * * It is always present on the stage, either within the viewport or somewhere outside the visible stage bounds
		 * * The nativeWindow of the container's stage is always visible, either off the user's Screen or as a transparent NativeWindow
		 * If the above conditions are not met, then certain features, like docking windows to the user's mouse location, will cease to function correctly.
		 */
		public function get mainContainer():DisplayObjectContainer {
			return dsp_mainContainer;
		}
		
		/**
		 * The main container to which the Docker instance is attached to.
		 * This can be any container which extends DisplayObjectContainer, provided the following conditions are met:
		 * * It is always present on the stage, either within the viewport or somewhere outside the visible stage bounds
		 * * The nativeWindow of the container's stage is always visible, either off the user's Screen or as a transparent NativeWindow
		 * If the above conditions are not met, then certain features, like docking windows to the user's mouse location, will cease to function correctly.
		 */
		public function set mainContainer(value:DisplayObjectContainer):void {
			dsp_mainContainer = value;
		}
		
		/**
		 * Any instance of a dock helper.
		 * A dock helper is a visual which appears whenever the user drags a panel, or a container, over another;
		 * the user can then drop the panel or container onto the dock helper, which then reports back to the Docker to finish docking the panel or container.
		 * Setting this to null prevents the user from docking panels or containers, unless another component (e.g. the container's panelList) accepts the drop.
		 */
		public function set dockHelper(dockHelper:IDockHelper):void {
			cl_dockHelper = dockHelper
		}
		
		/**
		 * Any instance of a dock helper.
		 * A dock helper is a visual which appears whenever the user drags a panel, or a container, over another;
		 * the user can then drop the panel or container onto the dock helper, which then reports back to the Docker to finish docking the panel or container.
		 * Setting this to null prevents the user from docking panels or containers, unless another component (e.g. the container's panelList) accepts the drop.
		 */
		public function get dockHelper():IDockHelper {
			return cl_dockHelper;
		}
		
		/**
		 * The factory responsible for creating panelList instances for a given container.
		 */
		public function get panelListFactory():IPanelListFactory {
			return cl_panelListFactory;
		}
		
		/**
		 * The factory responsible for creating panelList instances for a given container.
		 */
		public function set panelListFactory(value:IPanelListFactory):void {
			cl_panelListFactory = value;
		}
		
		/**
		 * The height of the thumbnail of the panel or container being dragged by the user.
		 * A value less than or equal to 1 represents a percentage of the container / panel height; values greater than 1 are rounded down to the nearest integer, and represent absolute sizes.
		 */
		public function get dragImageHeight():Number {
			return num_dragImageHeight;
		}
		
		/**
		 * The height of the thumbnail of the panel or container being dragged by the user.
		 * A value less than or equal to 1 represents a percentage of the container / panel height; values greater than 1 are rounded down to the nearest integer, and represent absolute sizes.
		 */
		public function set dragImageHeight(value:Number):void {
			num_dragImageHeight = value;
		}
		
		/**
		 * The width of the thumbnail of the panel or container being dragged by the user.
		 * A value less than or equal to 1 represents a percentage of the container / panel width; values greater than 1 are rounded down to the nearest integer, and represent absolute sizes.
		 */
		public function get dragImageWidth():Number {
			return num_dragImageWidth;
		}
		
		/**
		 * The width of the thumbnail of the panel or container being dragged by the user.
		 * A value less than or equal to 1 represents a percentage of the container / panel width; values greater than 1 are rounded down to the nearest integer, and represent absolute sizes.
		 */
		public function set dragImageWidth(value:Number):void {
			num_dragImageWidth = value;
		}
		
		/**
		 * The default options to be used when creating a NativeWindow for a given container.
		 * Note: The resizable attribute is ignored, and the resizable attribute of the respective panel is used instead.
		 */
		public function get defaultWindowOptions():NativeWindowInitOptions {
			return cl_defaultWindowOptions;
		}
		
		/**
		 * The default options to be used when creating a NativeWindow for a given container.
		 * Note: The resizable attribute is ignored, and the resizable attribute of the respective panel is used instead.
		 */
		public function set defaultWindowOptions(value:NativeWindowInitOptions):void {
			cl_defaultWindowOptions = value;
		}
		
		/**
		 * The factory used to create panels as requested through the createPanel() method of the Docker instance.
		 */
		public function get panelFactory():IPanelFactory {
			return cl_panelFactory;
		}
		
		/**
		 * The factory used to create panels as requested through the createPanel() method of the Docker instance.
		 */
		public function set panelFactory(value:IPanelFactory):void {
			cl_panelFactory = value;
		}
		
		/**
		 * The factory used to create container as requested through the createContainer() method of the Docker instance.
		 * By default, containers created this way are regarded as "root" containers - that is, until they are added directly to another container (and not merged)
		 */
		public function get containerFactory():IContainerFactory {
			return cl_containerFactory;
		}
		
		/**
		 * The factory used to create container as requested through the createContainer() method of the Docker instance.
		 * By default, containers created this way are regarded as "root" containers - that is, until they are added directly to another container (and not merged)
		 */
		public function set containerFactory(value:IContainerFactory):void {
			cl_containerFactory = value;
		}
		
		/**
		 * The default container options used when automatically creating the parked containers for a panel's NativeWindow.
		 * This is separate from the ContainerConfig instance supplied in the createContainer() method of the Docker instance.
		 */
		public function get defaultContainerOptions():ContainerConfig {
			return cl_defaultContainerOptions;
		}
		
		/**
		 * The default container options used when automatically creating the parked containers for a panel's NativeWindow.
		 * This is separate from the ContainerConfig instance supplied in the createContainer() method of the Docker instance.
		 */
		public function set defaultContainerOptions(value:ContainerConfig):void {
			cl_defaultContainerOptions = value;
		}
		
		/**
		 * The resize helper instance. This is used to let the user resize containers, when they activate this - usually by hovering at the border of two containers.
		 * Setting this to null prevents the user from resizing panels, and can hence be used to enforce strict panel sizes for a given Docker instance.
		 */
		public function get resizeHelper():IResizer {
			return cl_resizeHelper;
		}
		
		/**
		 * The resize helper instance. This is used to let the user resize containers, when they activate this - usually by hovering at the border of two containers.
		 * Setting this to null prevents the user from resizing panels, and can hence be used to enforce strict panel sizes for a given Docker instance.
		 */
		public function set resizeHelper(value:IResizer):void {
			cl_resizeHelper = value;
		}
		
		/**
		 * The default dock format string key used to indicate panel and container clipboard data.
		 * Useful when intercepting drag events and capturing the panel and/or container instances.
		 */
		public function get dockFormat():IDockFormat {
			return cl_dockFormat;
		}
		
		/**
		 * The default dock format string key used to indicate panel and container clipboard data.
		 * Useful when intercepting drag events and capturing the panel and/or container instances.
		 */
		public function set dockFormat(value:IDockFormat):void {
			cl_dockFormat = value;
		}
		
		/**
		 * The default tree resolver for this Docker.
		 * Used to retrieve the relationships between different containers and their children, which are including, but not limited to, panels.
		 */
		public function get treeResolver():ITreeResolver {
			return cl_treeResolver;
		}
		
		/**
		 * The default tree resolver for this Docker.
		 * Used to retrieve the relationships between different containers and their children, which are including, but not limited to, panels.
		 */
		public function set treeResolver(value:ITreeResolver):void {
			cl_treeResolver = value;
		}
		
		/**
		 * The cross docking policy for this Docker instance; acceptable values are enumerated in the CrossDockingPolicy class.
		 * Change this value to achieve finer control over which containers are allowed out or in, from or to this Docker instance.
		 */
		public function get crossDockingPolicy():int {
			return i_crossDockingPolicy;
		}
		
		/**
		 * The cross docking policy for this Docker instance; acceptable values are enumerated in the CrossDockingPolicy class.
		 * Change this value to achieve finer control over which containers are allowed out or in, from or to this Docker instance.
		 */
		public function set crossDockingPolicy(value:int):void {
			i_crossDockingPolicy = value;
		}
		
		/**
		 * Temporary thumbnail strategy implementation.
		 * @see airdock.interfaces.strategies.IThumbnailStrategy
		 */
		public function get thumbnailStrategy():IThumbnailStrategy {
			return cl_thumbnailStrategy;
		}
		
		public function set thumbnailStrategy(value:IThumbnailStrategy):void {
			cl_thumbnailStrategy = value;
		}
	}

}