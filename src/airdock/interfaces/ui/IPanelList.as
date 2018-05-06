package airdock.interfaces.ui 
{
	import airdock.interfaces.docking.IPanel;
	import flash.events.IEventDispatcher;	
	
	/**
	 * An interface which defines the methods which an object must fulfil in order to act as a container's panel list.
	 * A panel list is essentially a collections class which tracks all the panels which are directly part of a container (i.e. not part of the container's subcontainers' panels)
	 * Instances of this interface are created automatically by the Docker's panelListFactory.
	 * It is worth noting that instances of this interface are almost entirely managed by the Docker instance and the containers which these are a part of.
	 * The panelList instances are not generally available to the programmer, except from reference tracking via the Docker's panelListFactory.
	 * As such, all the methods listed in this interface can be assumed to be called automatically by the container.
	 * For an interface which is graphical and can be interacted with by the user, see the IDisplayablePanelList interface.
	 * The IDisplayablePanelList interface defines additional responsibilities for the panel list, in order to effectively communicate with the user.
	 * @author	Gimmick
	 * @see	airdock.interfaces.ui.IDisplayablePanelList
	 * @see	airdock.interfaces.factories.IPanelListFactory
	 */
	public interface IPanelList extends IEventDispatcher
	{
		/**
		 * Adds a panel to the current panel list, at the given position.
		 * @param	panel	The panel which is added to the container, and is to be added to the panel list.
		 * @param	index	The index in the list at which the panel is to be added to.
		 */
		function addPanelAt(panel:IPanel, index:int):void;
		
		/**
		 * Adds a panel to the current panel list, at the end.
		 * @param	panel	The panel which is added to the container, and is to be added to the panel list.
		 */
		function addPanel(panel:IPanel):void;
		
		/**
		 * Removes a panel from the current panel list, based on the given position.
		 * @param	index	The index whose panel is to be removed from the panel list.
		 */
		function removePanelAt(index:int):void;
		
		/**
		 * Removes a panel from the current panel list.
		 * @param	panel	The panel which is to be removed from the panel list.
		 */
		function removePanel(panel:IPanel):void;
		
		/**
		 * Updates the panel's information, such as its name.
		 * This method is intended to notify the panel list, and is called whenever there is a change in the panel's attributes, and changes may have to be reflected in the panel list.
		 * @param	panel	The panel whose information (in the panel list, such as tab text) is to be updated.
		 */
		function updatePanel(panel:IPanel):void;
		
		/**
		 * Called whenever the current panel has been activated automatically.
		 * This method is intended to notify the panel list, which updates the list to show the currently active panel.
		 * @param	panel	The panel which has been activated and is to be reflected in the panel list.
		 */
		function showPanel(panel:IPanel):void;
	}
	
}