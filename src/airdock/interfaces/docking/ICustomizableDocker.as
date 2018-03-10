package airdock.interfaces.docking 
{
	import airdock.interfaces.factories.IPanelListFactory;
	import airdock.interfaces.ui.IDockHelper;
	
	/**
	 * The interface defining the set of methods that a customizable Docker must fulfil.
	 * Customizable responsibilities not handled by the basic Docker interface, like tabbing and customization, are handled by this interface.
	 * @author Gimmick
	 * @see IBasicDocker
	 */
	public interface ICustomizableDocker extends IBasicDocker
	{
		/**
		 * An IDockHelper instance which determines the user interface for docking. Setting this to null prevents the user from docking panels.
		 * @param	helper	An IDockHelper instance which determines the user interface used for docking panels by the user.
		 */
		function set dockHelper(helper:IDockHelper):void
		
		/**
		 * An IPanelListFactory instance which determines the factory used to create IPanelList instances for IContainers which were previously empty and have had panels added to them.
		 * Setting this to null prevents creating panel list instances whenever panels are attached to a container.
		 * @param	panelListFactory	An IPanelListFactory instance which is used to create IPanelList instances for the IContainers which are part of this Docker.
		 */
		function setPanelListFactory(panelListFactory:IPanelListFactory):void;
		
		/**
		 * Gets and sets the width of the thumbnail of the panel or container being dragged by the user.
		 * A value less than or equal to 1 represents a percentage of the container / panel width; values greater than 1 are rounded down to the nearest integer, and represent absolute sizes.
		 */
		function get dragImageWidth():Number;
		
		/**
		 * Gets and sets the height of the thumbnail of the panel or container being dragged by the user.
		 * A value less than or equal to 1 represents a percentage of the container / panel height; values greater than 1 are rounded down to the nearest integer, and represent absolute sizes.
		 */
		function get dragImageHeight():Number;
		
		/**
		 * Gets and sets the width of the thumbnail of the panel or container being dragged by the user.
		 * A value less than or equal to 1 represents a percentage of the container / panel width; values greater than 1 are rounded down to the nearest integer, and represent absolute sizes.
		 */
		function set dragImageWidth(value:Number):void;
		
		/**
		 * Gets and sets the height of the thumbnail of the panel or container being dragged by the user.
		 * A value less than or equal to 1 represents a percentage of the container / panel height; values greater than 1 are rounded down to the nearest integer, and represent absolute sizes.
		 */
		function set dragImageHeight(value:Number):void;
	}
	
}