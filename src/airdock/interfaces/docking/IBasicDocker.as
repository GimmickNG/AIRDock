package airdock.interfaces.docking 
{
	import airdock.config.ContainerConfig;
	import airdock.config.PanelConfig;
	import airdock.interfaces.docking.IPanel;
	import airdock.interfaces.docking.IContainer;
	import flash.display.DisplayObjectContainer;
	import flash.display.NativeWindow;
	import flash.display.Stage;
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public interface IBasicDocker 
	{
		/**
		 * Integrates a panel into the given side of a container.
		 * @param	panel
		 * @param	container
		 * @param	side
		 */
		function integratePanel(panel:IPanel, container:IContainer, side:int):IContainer
		/**
		 * Docks a given panel to its original window.
		 * @param	panel	The panel to dock.
		 */
		function dockPanel(panel:IPanel):void;
		/**
		 * Sets up the panel (by adding listeners and creating a window for it.) Do not call this method for a panel created via the createPanel function; this is intended for user-defined IPanel implementations.
		 * @param	panel	The panel to set up of type IPanel. Use this if you have created an instance of an IPanel that is not made via the createPanel function.
		 */
		function setupPanel(panel:IPanel):void;
		
		function unhookPanel(panel:IPanel):void;
		//TODO finish ASDoc
		
		function get crossDockingPolicy():int;
		function set crossDockingPolicy(policyFlags:int):void;
		
		function createWindow(panel:IPanel):NativeWindow
		/**
		 * Creates a container with the given width and height.
		 * @param	options	Initialization options for the container to be created.
		 * @return	A new object of type IContainer.
		 */
		function createContainer(options:ContainerConfig):IContainer
		/**
		 * Creates a basic IPanel instance with the given color, width and height, which can be used immediately (i.e. setupPanel should not, and does not need to, be called for a Panel created via this method.)
		 * @param options	Initialization options for the instance to be created.
		 * @return	A new object of type IPanel. Objects created via this method should not (and do not need to) have setupPanel called on them.
		 */
		function createPanel(options:PanelConfig):IPanel
		/**
		 * Gets and sets the main container for the docker. The main container should never be removed from the stage, otherwise certain functionality (like dragging containers) will cease to work effectively. Usually, this is the 
		 */
		function set mainContainer(value:DisplayObjectContainer):void;
		/**
		 * Gets and sets the main container for the docker. The main container should never be removed from the stage, otherwise certain functionality (like dragging containers) will cease to work effectively. Usually, this is the stage of the main window.
		 */
		function get mainContainer():DisplayObjectContainer;
	}
	
}