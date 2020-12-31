package airdock.interfaces.docking 
{
	import airdock.interfaces.factories.IPanelListFactory;
	import airdock.interfaces.strategies.IThumbnailStrategy;
	import airdock.interfaces.ui.IDockHelper;
	import airdock.interfaces.ui.IResizer;
	
	/**
	 * The interface defining the set of methods that a customizable Docker must fulfil.
	 * Customizable responsibilities not handled by the basic Docker interface, like tabbing and customization, are handled by this interface.
	 * @author	Gimmick
	 * @see	airdock.interfaces.docking.IBasicDocker
	 */
	public interface ICustomizableDocker extends IBasicDocker
	{
		/**
		 * An IPanelListFactory instance which determines the factory used to create IPanelList instances for IContainers which were previously empty and have had panels added to them.
		 * Setting this to null prevents creating panel list instances whenever panels are attached to a container.
		 * @param	panelListFactory	An IPanelListFactory instance which is used to create IPanelList instances for the IContainers which are part of this Docker.
		 */
		function setPanelListFactory(panelListFactory:IPanelListFactory):void;
		
		function get thumbnailStrategy():IThumbnailStrategy;
		
		/**
		 * An IDockHelper instance which determines the user interface for docking. Setting this to null prevents the user from docking panels.
		 * @param	helper	An IDockHelper instance which determines the user interface used for docking panels by the user.
		 */
		function get dockHelper():IDockHelper;
		function set dockHelper(helper:IDockHelper):void;
		
		/**
		 * Gets and sets the width of the thumbnail of the panel or container being dragged by the user.
		 * A value less than or equal to 1 represents a percentage of the container / panel width; values greater than 1 are rounded down to the nearest integer, and represent absolute sizes.
		 */
		function get dragImageWidth():Number;
		function set dragImageWidth(value:Number):void;
		
		/**
		 * Gets and sets the height of the thumbnail of the panel or container being dragged by the user.
		 * A value less than or equal to 1 represents a percentage of the container / panel height; values greater than 1 are rounded down to the nearest integer, and represent absolute sizes.
		 */
		function get dragImageHeight():Number;
		function set dragImageHeight(value:Number):void;
		
		/**
		 * The resize helper instance. This is used to let the user resize containers, when they activate this - usually by hovering at the border of two containers.
		 * Setting this to null prevents the user from resizing panels, and can hence be used to enforce strict panel sizes for a given Docker instance.
		 */
		function get resizeHelper():IResizer;
		function set resizeHelper(value:IResizer):void;
	}
	
}