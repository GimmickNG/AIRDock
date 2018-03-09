package airdock.config 
{
	import airdock.interfaces.docking.IDockFormat;
	import airdock.interfaces.docking.ITreeResolver;
	import airdock.interfaces.factories.IContainerFactory;
	import airdock.interfaces.factories.IPanelFactory;
	import airdock.interfaces.factories.IPanelListFactory;
	import airdock.interfaces.ui.IDockHelper;
	import airdock.interfaces.ui.IResizer;
	import flash.display.DisplayObjectContainer;
	import flash.display.NativeWindowInitOptions;
	/**
	 * ...
	 * @author Gimmick
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
		private var dsp_mainContainer:DisplayObjectContainer
		private var cl_defaultWindowOptions:NativeWindowInitOptions
		private var cl_defaultContainerOptions:ContainerConfig;
		public function DockConfig() { }
		
		public function get mainContainer():DisplayObjectContainer {
			return dsp_mainContainer;
		}
		
		public function set mainContainer(value:DisplayObjectContainer):void {
			dsp_mainContainer = value;
		}
		
		public function set dockHelper(dockHelper:IDockHelper):void {
			cl_dockHelper = dockHelper
		}
		
		public function get dockHelper():IDockHelper {
			return cl_dockHelper;
		}
		
		public function get panelListFactory():IPanelListFactory {
			return cl_panelListFactory;
		}
		
		public function set panelListFactory(value:IPanelListFactory):void {
			cl_panelListFactory = value;
		}
		
		public function get dragImageHeight():Number 
		{
			return num_dragImageHeight;
		}
		
		public function set dragImageHeight(value:Number):void {
			num_dragImageHeight = value;
		}
		
		public function get dragImageWidth():Number {
			return num_dragImageWidth;
		}
		
		public function set dragImageWidth(value:Number):void {
			num_dragImageWidth = value;
		}
		
		public function get defaultWindowOptions():NativeWindowInitOptions {
			return cl_defaultWindowOptions;
		}
		
		public function set defaultWindowOptions(value:NativeWindowInitOptions):void {
			cl_defaultWindowOptions = value;
		}
		
		public function get panelFactory():IPanelFactory {
			return cl_panelFactory;
		}
		
		public function set panelFactory(value:IPanelFactory):void {
			cl_panelFactory = value;
		}
		
		public function get containerFactory():IContainerFactory {
			return cl_containerFactory;
		}
		
		public function set containerFactory(value:IContainerFactory):void {
			cl_containerFactory = value;
		}
		
		public function get defaultContainerOptions():ContainerConfig {
			return cl_defaultContainerOptions;
		}
		
		public function set defaultContainerOptions(value:ContainerConfig):void {
			cl_defaultContainerOptions = value;
		}
		
		public function get resizeHelper():IResizer {
			return cl_resizeHelper;
		}
		
		public function set resizeHelper(value:IResizer):void {
			cl_resizeHelper = value;
		}
		
		public function get dockFormat():IDockFormat {
			return cl_dockFormat;
		}
		
		public function set dockFormat(value:IDockFormat):void {
			cl_dockFormat = value;
		}
		
		public function get treeResolver():ITreeResolver {
			return cl_treeResolver;
		}
		
		public function set treeResolver(value:ITreeResolver):void {
			cl_treeResolver = value;
		}
		
		public function get crossDockingPolicy():int {
			return i_crossDockingPolicy;
		}
		
		public function set crossDockingPolicy(value:int):void {
			i_crossDockingPolicy = value;
		}
	}

}