package airdock.interfaces.docking 
{
	import airdock.config.ContainerConfig;
	import airdock.config.PanelConfig;
	import airdock.interfaces.docking.IPanel;
	import airdock.interfaces.docking.IContainer;
	import airdock.util.IPair;
	import flash.display.DisplayObjectContainer;
	import flash.display.NativeWindow;
	import flash.display.Stage;
	import flash.events.IEventDispatcher;
	
	/**
	 * The interface defining the set of methods that a basic Docker must fulfil.
	 * Additional responsibilities like tabbing and customization are left to ICustomizableDocker instances.
	 * @author Gimmick
	 * @see ICustomizableDocker
	 */
	public interface IBasicDocker extends IEventDispatcher
	{
		/**
		 * Integrates a panel into the given side of a container.
		 * @param	panel	The panel to move into a container.
		 * @param	container	The container to move the panel into. This must not have any containers below it, or else it may cease to function correctly.
		 * @param	side	The side to which the panel should be attached to. If it is not FILL, or is not equal or complementary to the container's current side (if it has any), then a new container is automatically created for this panel.
		 * @return	The container into which it has been integrated into.
		 */
		function integratePanelToContainer(panel:IPanel, container:IContainer, side:int):IContainer
		
		/**
		 * Docks a given panel to its parked container.
		 * @param	panel	The panel to dock.
		 * @return	The parked container into which it has been shifted into.
		 */
		function dockPanel(panel:IPanel):IContainer;
		
		/**
		 * Sets up the panel (by adding listeners and creating a window for it); do not call this method for a panel created via the createPanel function, as this is primarily intended for user-defined IPanel implementations.
		 * @param	panel	An IPanel instance which is to be set up. Use this if you have created an instance of an IPanel that is not made via the createPanel() function.
		 */
		function setupPanel(panel:IPanel):void;
		
		/**
		 * Unlinks the panel from this Docker instance. For this panel, any parked containers, windows, and listeners, if present, are unloaded.
		 * After unlinking a panel from the Docker instance, it is regarded as foreign with respect to the Docker, and will follow the cross docking policy attributed to it.
		 * @param	panel	The panel which is to be unlinked from this Docker instance.
		 */
		function unhookPanel(panel:IPanel):void;
		
		/**
		 * Sets up basic listeners for a window. Some listeners which are attached include, but are not limited to:
		 * * Automatically resizing any containers which may be present in the window's stage, and
		 * * Preventing the window from being unloaded when the user closes it.
		 * @param	window	The window which is to have listeners attached to it.
		 */
		function setupWindow(window:NativeWindow):void
		
		/**
		 * Removes any listeners set up by this Docker instance for the given window, as dictated by the setupWindow() method.
		 * @param	window	The window whose listeners, previously added by this Docker instance, are to be removed from it.
		 */
		function unhookWindow(window:NativeWindow):void
		
		/**
		 * Removes a panel with the effect of hiding it. This is accomplished by:
		 * * Removing it from any container which is not parked, or part of a non-parked container,
		 * * Removing it from any container which is parked, but is not its own parked container, or
		 * * Hiding the window of its own parked container (assuming it is a part of its own parked container), if, and only if,
		 * 	* There are no other panels in its parked container, in which case it is treated as if it were part of another panel's parked container.
		 * @param	panel	The panel to hide/remove from view.
		 */
		function hidePanel(panel:IPanel):void;
		
		/**
		 * Adds a panel to the original window or container it was once part of.
		 * If it is already part of its parked container, but its window is hidden, then it activates the window.
		 * @param	panel	The panel to show.
		 */
		function showPanel(panel:IPanel):void;
		
		/**
		 * Returns a vector of pairs, where each key in the pair is a panel, and the corresponding value is the panel's original window.
		 * @return	A vector of pairs, with keys as a panel and values as the panel's window, for each pair in the vector.
		 */
		function getPanelWindows():Vector.<IPair>
		
		/**
		 * Returns a vector of pairs, where each key in the pair is a panel, and the corresponding value is the panel's parked container.
		 * @return	A vector of pairs, with keys as a panel and values as the panel's parked container, for each pair in the vector.
		 */
		function getPanelContainers():Vector.<IPair>
		
		/**
		 * Gets the window corresponding to a panel, as defined during the creation of a window, either automatically or when createWindow() was called.
		 * @param	panel	The panel to get the window of.
		 * @return	The corresponding window for the panel.
		 */
		function getPanelWindow(panel:IPanel):NativeWindow;
		
		/**
		 * Gets the originally occupied (or occupying, assuming it has not been moved) window for a container which is either parked, or is part of, a parked container.
		 * @param	container	The container to get the window of. Supplying non-parked containers may return different windows based on which window was containing the supplied container at the time.
		 * @return	A window which contains the container.
		 */
		function getContainerWindow(container:IContainer):NativeWindow;
		
		/**
		 * Gets the window which originally contained (or is containing, assuming it has not been moved) the parked container for a panel.
		 * @param	window	The window to get the parked container of.
		 * @return	A parked container whose original window is the same as that supplied.
		 */
		function getWindowContainer(window:NativeWindow):IContainer;
		
		/**
		 * Counterpart of getPanelWindow(). Gets the panel for the given window, as defined by the createWindow() method, either automatically or manually.
		 * @param	window	The window to get the panel of.
		 * @return	The corresponding panel for the window.
		 */
		function getWindowPanel(window:NativeWindow):IPanel;
		
		/**
		 * Checks whether a panel is visible or not. A panel is visible if it is currently on any Stage instance.
		 * @param	panel	The panel to check whether it is visible or not.
		 * @return	A Boolean indicating whether the panel is visible or not. Values are also enumerated in the PanelContainerState enumeration class.
		 * @see airdock.enums.PanelContainerState
		 */
		function isPanelVisible(panel:IPanel):Boolean;
		
		/**
		 * Gets or sets the cross docking policy for this Docker instance, as defined in the CrossDockingPolicy enumeration.
		 * The cross docking policy decides what is to be done when a panel or container, 
		 * which is foreign to the current Docker instance, is attached to a local (i.e. originating from the current Docker instance) panel or container, or has a panel attached to a local panel or container.
		 * 
		 * For more details, please refer to the CrossDockingPolicy enumeration class.
		 * @see airdock.enums.CrossDockingPolicy
		 */
		function get crossDockingPolicy():int;
		
		/**
		 * Gets or sets the cross docking policy for this Docker instance, as defined in the CrossDockingPolicy enumeration.
		 * The cross docking policy decides what is to be done when a panel or container, 
		 * which is foreign to the current Docker instance, is attached to a local (i.e. originating from the current Docker instance) panel or container, or has a panel attached to a local panel or container.
		 * 
		 * For more details, please refer to the CrossDockingPolicy enumeration class.
		 * @see airdock.enums.CrossDockingPolicy
		 */
		function set crossDockingPolicy(policyFlags:int):void;
		
		/**
		 * Creates a window for the given panel, unless a window has already been created for this panel, in which case it is returned instead.
		 * This is usually done automatically when setting up a panel.
		 * @param	panel	The panel to create a window for.
		 * @return	A window for the panel.
		 */
		function createWindow(panel:IPanel):NativeWindow
		
		/**
		 * Creates a container with the given width and height as specified in the ContainerConfig passed into this method.
		 * @param	options	Initialization options for the container to be created. This is not the same as the default ContainerConfig instance passed in the DockConfig when creating the Docker instance.
		 * @return	A new object of type IContainer.
		 */
		function createContainer(options:ContainerConfig):IContainer
		/**
		 * Creates a basic IPanel instance with the given color, width and height, which can be used immediately (i.e. setupPanel should not, and does not need to, be called for a Panel created via this method.)
		 * @param options	Initialization options for the instance to be created.
		 * @return	A new object of type IPanel. Objects created via this method should not, and do not need to, have setupPanel() called on them.
		 */
		function createPanel(options:PanelConfig):IPanel
		/**
		 * Gets and sets the main container for the Docker instance. The main container should never be removed from the stage, otherwise certain functionality (like dragging containers) will cease to work effectively.
		 * Usually, this is the stage of the main application, as it is most often never hidden from view.
		 */
		function set mainContainer(value:DisplayObjectContainer):void;
		/**
		 * Gets and sets the main container for the Docker instance. The main container should never be removed from the stage, otherwise certain functionality (like dragging containers) will cease to work effectively.
		 * Usually, this is the stage of the main application, as it is most often never hidden from view.
		 */
		function get mainContainer():DisplayObjectContainer;
	}
	
}