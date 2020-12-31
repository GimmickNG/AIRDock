package airdock.impl.strategies 
{
	import airdock.interfaces.docking.IContainer;
	import airdock.interfaces.strategies.IThumbnailStrategy;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	/**
	 * Temporary delegate to draw custom thumbnails for a drag-dock operation.
	 * To be removed after implementation of DockStrategy related classes and interfaces.
	 * @see airdock.interfaces.strategies.IThumbnailStrategy
	 * @author Gimmick
	 */
	public class ThumbnailStrategy implements IThumbnailStrategy
	{
		private var pt_offset:Point
		private var bmd_thumbnail:BitmapData
		
		public function ThumbnailStrategy() { }
		
		/**
		 * @inheritDoc
		 */
		public function createThumbnail(container:IContainer, thumbSize:Point):void 
		{
			const wholeThumbWidth:int = int(thumbSize.x), wholeThumbHeight:int = int(thumbSize.y);
			var maxWidth:Number = container.width, maxHeight:Number = container.height;
			if (!(maxWidth && maxHeight && thumbSize.length && !isNaN(thumbSize.x) && !isNaN(thumbSize.y))) {
				return;
			}
			//draw the thumbnail preview if the size is not 0 or NaN for either dimension
			var aspect:Number, widthRatio:Number, heightRatio:Number;
			maxWidth = container.width
			maxHeight = container.height
			if (container.width < maxWidth) {
				maxWidth = container.width
			}
			if (container.height < maxHeight) {
				maxHeight = container.height
			}
			
			widthRatio = 1.0 / maxWidth;	//preliminary ratio calculation
			heightRatio = 1.0 / maxHeight;	//for drawing the thumbnail
			aspect = maxHeight / maxWidth;
			if (thumbSize.x <= 1.0) {
				maxWidth *= thumbSize.x;
			}
			else if (maxWidth > wholeThumbWidth) {
				maxWidth = wholeThumbWidth;
			}
			maxHeight = aspect * maxWidth;
			if (maxHeight < 1.0) {
				maxHeight = 1.0;
			}
			
			if (thumbSize.y <= 1.0) {
				maxHeight *= thumbSize.y;
			}
			else if (maxHeight > wholeThumbHeight) {
				maxHeight = wholeThumbHeight;
			}
			maxWidth = maxHeight / aspect;
			if (maxWidth < 1.0) {
				maxWidth = 1.0;
			}
			
			const proxyImage:BitmapData = new BitmapData(maxWidth, maxHeight, false)
			const transform:Matrix = new Matrix(maxWidth * widthRatio, 0, 0, maxHeight * heightRatio)
			const offsetPoint:Point = new Point( -container.mouseX * transform.a, -container.mouseY * transform.d)
			
			proxyImage.draw(container, transform)
			bmd_thumbnail = proxyImage
			pt_offset = offsetPoint
		}
		
		/**
		 * @inheritDoc
		 */
		public function get thumbnail():BitmapData {
			return bmd_thumbnail.clone()
		}
		
		/**
		 * @inheritDoc
		 */
		public function get offset():Point {
			return pt_offset.clone()
		}
		
		/**
		 * @inheritDoc
		 */
		public function dispose():void
		{
			pt_offset = null
			if (bmd_thumbnail) {
				bmd_thumbnail.dispose()
			}
		}
		
	}

}