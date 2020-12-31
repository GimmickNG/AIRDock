package airdock.interfaces.ui 
{
	import airdock.interfaces.display.IDynamicSize;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * An interface defining the methods that a display object must implement in order to act as the visible counterpart of the IPanelList interface.
	 * Additional methods involving placement and sizing of the panel list are included here.
	 * @author	Gimmick
	 */
	public interface IDisplayablePanelList extends IPanelList, IDynamicSize
	{
		/**
		 * A Rectangle indicating the region that is available for the panels in the container to take up.
		 * Each panel in the container has its x, y, width and height set to match that of the visibleRegion attribute.
		 * Helpful when the panelList has graphical content visible both at the top and bottom of the container, and the panels need to fit in between without being occluded.
		 * This is derived from the maxWidth and maxHeight attributes, that is, the maximum x + width, y + height, width, or height, cannot be greater than the maxWidth and maxHeight respectively.
		 * Values greater than the maxWidth and maxHeight can cause the panel list's container to function improperly when resizing.
		 */
		function get visibleRegion():Rectangle;
	}
	
}