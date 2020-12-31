package airdock.interfaces.strategies 
{
	import airdock.interfaces.docking.IContainer;
	import airdock.util.IDisposable;
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	/**
	 * Temporary companion interface to ThumbnailStrategy; to be removed after DockStrategy is implemented.
	 * @see airdock.impl.strategies.ThumbnailStrategy
	 * @author Gimmick
	 */
	public interface IThumbnailStrategy extends IStrategy, IDisposable
	{
		/**
		 * Creates the thumbnail for the given container, with a maximum size specified by thumbSize.
		 * @param	container	The container taking part in a drag-dock operation, for which the thumbnail is to be created.
		 * @param	thumbSize	The maximum size of the thumbnail as a Point instance.
		 */
		function createThumbnail(container:IContainer, thumbSize:Point):void
		/**
		 * @return	The thumbnail created by an earlier call to createThumbnail().
		 * 			To specify no thumbnail, null can be returned.
		 * 			Important: Always return a copy of the thumbnail image, as disposing it (via the dispose() method) will result in a crash.
		 */
		function get thumbnail():BitmapData
		/**
		 * @return	The offset point for the thumbnail.
		 * 			Can return null to indicate no offset.
		 * 			It is recommended to return a clone, but is not mandatory.
		 */
		function get offset():Point
	}
	
}