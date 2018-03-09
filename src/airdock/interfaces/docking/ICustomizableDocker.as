package airdock.interfaces.docking 
{
	import airdock.interfaces.factories.IPanelListFactory;
	import airdock.interfaces.ui.IDockHelper;
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public interface ICustomizableDocker extends IBasicDocker
	{
		/**
		 * //TODO finish ASDoc
		 * Used to set the type of the container attachment interface. Setting this to a class will instantiate an instance of that class, which will allow docking a panel/container onto another. A null value unsets the class and removes the panel list from all containers.
		 * @param	containerAttachmentClass An object of type Class that represents the class of the container attacher. This is equivalent to the name of the container attachment class.
		 */
		function set dockHelper(helper:IDockHelper):void
		/**
		 * //TODO update ASDoc
		 * Used to set the type of the panel list interface. Setting this to a class will instantiate an instance of that class, which will allow dragging and other panel operations as defined in the panel list class, for each panel and/or the container. A null value unsets the class and removes the panel list from all containers.
		 * @param	panelListClass	An object of type Class that represents the class of the panel list. This is equivalent to the name of the panel list class.
		 */
		function setPanelListFactory(panelListFactory:IPanelListFactory):void;
		/**
		 * Convenience method for removing the panel list from all containers; functionally identical to passing null to the setPanelListClass function.
		 */
		function unsetPanelListFactory():void;
		/**
		 * Gets and sets the width of the dragging thumbnail. A value less than or equal to 1 represents a percentage of the container / panel size; values greater than 1 are rounded down to the nearest integer, and represent absolute sizes.
		 */
		function get dragImageWidth():Number;
		/**
		 * Gets and sets the height of the dragging thumbnail. A value less than or equal to 1 represents a percentage of the container / panel size; values greater than 1 are rounded down to the nearest integer, and represent absolute sizes.
		 */
		function get dragImageHeight():Number;
		/**
		 * Gets and sets the width of the dragging thumbnail. A value less than or equal to 1 represents a percentage of the container / panel size; values greater than 1 are rounded down to the nearest integer, and represent absolute sizes.
		 */
		function set dragImageWidth(value:Number):void;
		/**
		 * Gets and sets the height of the dragging thumbnail. A value less than or equal to 1 represents a percentage of the container / panel size; values greater than 1 are rounded down to the nearest integer, and represent absolute sizes.
		 */
		function set dragImageHeight(value:Number):void;
	}
	
}