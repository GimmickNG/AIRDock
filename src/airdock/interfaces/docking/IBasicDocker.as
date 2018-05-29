package airdock.interfaces.docking 
{
	import airdock.config.ContainerConfig;
	import airdock.config.PanelConfig;
	import flash.display.DisplayObjectContainer;
	import flash.display.NativeWindow;
	import flash.events.IEventDispatcher;
	
	/**
	 * The interface defining the set of methods that a basic Docker must fulfil.
	 * Additional responsibilities like tabbing and customization are left to ICustomizableDocker instances.
	 * @author	Gimmick
	 * @see	airdock.interfaces.docking.ICustomizableDocker
	 */
	public interface IBasicDocker extends IEventDispatcher
	{
		/**
		 * Integrates a panel into the given side sequence for a container.
		 * Replaced the movePanelToContainer() method since v0.3.
		 * 
		 * @param	panel		The panel to move into a container.
		 * @param	container	The container to move the panel into.
		 * 						If the side is FILL, this must not have any containers below it, or else it may cease to function correctly.
		 * @param	sideCode	The side sequence to which the panel must be attached to.
		 * 						Any containers which do not exist are automatically created.
		 * 						This is similar to the side sequence returned by the Docker's treeResolver's serializeCode() method.
		 * @return	The container into which it has been integrated into.
		 */
		function addPanelToSideSequence(panel:IPanel, container:IContainer, sideCode:String):IContainer;
		
		/**
		 * Docks the panels supplied into the first panel's parked container.
		 * 
		 * @param	panels		The list of panels which are to be docked (by moving into the first panel's parked container.)
		 * @param	container	The parent container of all the panels.
		 * 						Can be null, if all the panels are to be added to the same level.
		 * @return	The IContainer instance into which the panels supplied have been moved into.
		 * 			This is (usually) the first panel's parked container, or null if no panels were passed.
		 */
		function dockPanels(panels:Vector.<IPanel>, container:IContainer):IContainer;
		
		/**
		 * Integrates a set of panels to the first panel's previous non-parked root container.
		 * 
		 * Integrating a panel is defined as moving a panel to a non-parked root container.
		 * Such containers are usually those which have been created manually, by the user, on the Docker.
		 * As a result, it is possible a panel may have never been integrated into such a container.
		 * For example, if no containers were created manually, or if no panels were ever attached to such a container.
		 * 
		 * @param	panels		The list of panels which are to be integrated.
		 * @param	container	The	(current) parent container of any of the panels, or all the panels (if they belong to the same container)
		 * 						Can be null, if all the panels are to be added to the same level.
		 * @return	The non-parked root container into which it has been shifted into.
		 * 			It is possible that this may be null, if it were never added to a non-parked root container.
		 */
		function integratePanels(panels:Vector.<IPanel>, container:IContainer):IContainer;
		
		/**
		 * Sets up the panel (by adding listeners and creating a window for it.)
		 * Do not call this method for a panel created via the createPanel() method, as this is primarily intended for user-defined IPanel implementations.
		 * @param	panel	An IPanel instance which is to be set up. Use this if you have created an instance of an IPanel that is not made via the createPanel() function.
		 */
		function setupPanel(panel:IPanel):void;
		
		/**
		 * Unlinks the panel from this Docker instance. For this panel, any parked containers, windows, and listeners, if present, are disposed of.
		 * After unlinking a panel from the Docker instance, it is regarded as foreign with respect to the Docker, and will follow the cross docking policy attributed to it.
		 * @param	panel	The panel which is to be unlinked from this Docker instance.
		 */
		function unhookPanel(panel:IPanel):void;
		
		/**
		 * Sets up basic listeners for a window. Some listeners which are attached include, but are not limited to:
		 * * Automatically resizing any containers which may be present in the window's stage, and
		 * * Preventing the window from being disposed of when the user closes it.
		 * @param	window	The window which is to have listeners attached to it.
		 */
		function setupWindow(window:NativeWindow):void
		
		/**
		 * Removes any listeners set up by this Docker instance for the given window, as dictated by the setupWindow() method.
		 * @param	window	The window whose listeners, previously added by this Docker instance, are to be removed from it.
		 */
		function unhookWindow(window:NativeWindow):void
		
		/**
		 * Removes a panel from its parent container, effectively hiding it.
		 * 
		 * Returns a Boolean indicating whether the panel was hidden successfully or not.
		 * The return value does not have the same meaning as the event dispatched; the event is dispatched if and only if there is a change in the visibility status of the panel.
		 * The return value is more in line with that of the IContainer interface's removePanel() method.
		 
		 * @param	panel	The panel to hide/remove from its container.
		 * @return	A Boolean indicating whether the panel was hidden successfully or not.
		 * 			If a panel is foreign to the Docker, or a null panel is supplied, then false is returned.
		 */
		function hidePanel(panel:IPanel):Boolean;
		
		/**
		 * Makes a group of panels visible.
		 * This is done by:
			* Docking the panels to the parked container of the first panel in the group, (or)
			* Integrating the panels to the previous non-parked root container of the first panel in the group.
		 * In the first case, the window is activated; this is done if there is no parent container of the panels in the beginning.
		 * Panels shown via this method are always brought in front of other panels (so as to not be obscured.)
		 * (Usually) dispatches a PanelContainerStateEvent if the panel was previously not part of any visible container.
			* This depends on the implementation used.
		 * 
		 * Returns a Boolean indicating whether the panel was shown successfully or not.
		 * The return value does not have the same meaning as the event dispatched; the event is dispatched if and only if there is a change in the visibility status of the panels.
		 * The return value is more in line with that of the IContainer interface's showPanel() method.
		 * 
		 * @param	panels	The list of panels to show, as a group.
		 * 					Panels in a group are added to the same container.
		 * 					This is regardless of whether they occupy different containers prior to calling this method or not.
		 * @return	A Boolean indicating whether the panels were shown successfully or not.
		 */
		function showPanels(panels:Vector.<IPanel>):Boolean;
		
		/**
		 * Returns the parked container for the given panel.
		 * @param	panel	The panel to get the container of.
		 * @return	The corresponding parked container for the panel.
		 */
		function getPanelContainer(panel:IPanel):IContainer;
		
		/**
		 * Gets the window corresponding to a panel, as defined during the creation of a window, either automatically or when the createWindow() method was called.
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
		 * @see	airdock.enums.PanelContainerState
		 */
		function isPanelVisible(panel:IPanel):Boolean;
		
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
		 * Creates a basic IPanel instance with the given color, width and height, which can be used immediately.
		 * The setupPanel() method does not need to, and should not, be called for a Panel created via this method.
		 * @param	options	Initialization options for the instance to be created.
		 * @return	A new object of type IPanel. Objects created via this method should not, and do not need to, have setupPanel() called on them.
		 */
		function createPanel(options:PanelConfig):IPanel
		
		/**
		 * Gets and sets the main container for the Docker instance. 
		 * The main container should never be removed from the stage, or else certain functionality (like dragging containers) will cease to work effectively.
		 * Usually, this is the stage of the main application, as it is most often never hidden from view.
		 */
		function get mainContainer():DisplayObjectContainer;
		function set mainContainer(value:DisplayObjectContainer):void;
		
		/**
		 * Gets and sets the cross docking policy for this Docker instance, as defined in the CrossDockingPolicy enumeration.
		 * The cross docking policy decides what is to be done when a panel or container, 
		 * which is foreign to the current Docker instance, is attached to a local (i.e. originating from the current Docker instance) panel or container, or has a panel attached to a local panel or container.
		 * 
		 * For more details, please refer to the CrossDockingPolicy enumeration class.
		 * @see	airdock.enums.CrossDockingPolicy
		 */
		function get crossDockingPolicy():int;
		function set crossDockingPolicy(policyFlags:int):void;
		
		/**
		 * The default tree resolver for this Docker.
		 * Used to retrieve the relationships between different containers and their children, which are including, but not limited to, panels.
		 * 
		 * For more details, please refer tothe ITreeResolver interface.
		 * @see	airdock.interfaces.docking.ITreeResolver
		 */
		function get treeResolver():ITreeResolver
		function set treeResolver(value:ITreeResolver):void;
		
		/**
		 * Gets and sets the dock format used during a drag-dock operation.
		 * The dock format specifies the format strings used in a drag-dock operation's Clipboard instance.
		 * 
		 * For more details, please refer to the IDockFormat interface.
		 * @see	airdock.interfaces.docking.IDockformat
		 */
		function get dockFormat():IDockFormat;
		function set dockFormat(value:IDockFormat):void
	}
	
}