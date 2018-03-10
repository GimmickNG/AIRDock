package airdock.interfaces.ui 
{
	import airdock.interfaces.display.IDisplayObjectContainer;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * An interface defining the methods that a display object must implement in order to act as the visible counterpart of the IPanelList interface.
	 * Additional methods involving placement and sizing of the panel list are included here.
	 * @author Gimmick
	 */
	public interface IDisplayablePanelList extends IPanelList, IDisplayObjectContainer
	{
		/**
		 * A Point indicating the preferred location of the current panel list, based on the max width and height specified for it.
		 */
		function get preferredLocation():Point;
		
		/**
		 * The maximum height available to the panel list. This is automatically set by the current panel list's container, prior to calling its other methods.
		 * Other methods, such as preferredLocation and visibleRegion, are derived from this attribute.
		 */
		function get maxHeight():Number;
		
		/**
		 * The maximum height available to the panel list. This is automatically set by the current panel list's container, prior to calling its other methods.
		 * Other methods, such as preferredLocation and visibleRegion, are derived from this attribute.
		 */
		function set maxHeight(value:Number):void;
		
		/**
		 * The maximum width available to the panel list. This is automatically set by the current panel list's container, prior to calling its other methods.
		 * Other methods, such as preferredLocation and visibleRegion, are derived from this attribute.
		 */
		function get maxWidth():Number;
		
		/**
		 * The maximum width available to the panel list. This is automatically set by the current panel list's container, prior to calling its other methods.
		 * Other methods, such as preferredLocation and visibleRegion, are derived from this attribute.
		 */
		function set maxWidth(value:Number):void;
		
		/**
		 * A Rectangle indicating the region that is available for the panels in the container to take up.
		 * Each panel in the container has its x, y, width and height set to match that of the visibleRegion attribute.
		 * This is helpful when the panel list has graphical content visible both at the top and bottom of the container, and the panels need to fit in between without having parts of them being occluded from view.
		 * This is derived from the maxWidth and maxHeight attributes, that is, the maximum x + width, y + height, width, or height, cannot be greater than the maxWidth and maxHeight respectively.
		 * Values greater than the maxWidth and maxHeight can cause the panel list's container to function improperly when resizing.
		 */
		function get visibleRegion():Rectangle;
	}
	
}