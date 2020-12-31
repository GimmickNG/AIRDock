package airdock.interfaces.ui 
{
	import airdock.interfaces.display.IDisplayObject;
	import airdock.interfaces.docking.IContainer;
	import flash.geom.Rectangle;
	
	/**
	 * An interface defining the methods that a (display)object must fulfil in order to be able to resize containers of a Docker.
	 * @author	Gimmick
	 */
	public interface IResizer extends IDisplayObject
	{
		/**
		 * The preferred percentage of the container's width where the resizer is to lie within. Read-only.
		 * For example, a value of 0 is the leftmost side of the container, a value of 0.5 is the horizontal center of the container, and a value of 1 is the rightmost side of the container.
		 */
		function get preferredXPercentage():Number;
		
		/**
		 * The preferred percentage of the container's height where the resizer is to lie within. Read-only.
		 * For example, a value of 0 is the topmost side of the container, a value of 0.5 is the vertical center of the container, and a value of 1 is the bottommost side of the container.
		 */
		function get preferredYPercentage():Number;
		
		/**
		 * Indicates whether a drag-to-resize operation, i.e. a resize,  is taking place or not.
		 * This is not set automatically by the Docker instance, since it is up to the resizer to handle drag operations.
		 */
		function get isDragging():Boolean
		
		/**
		 * The minimum percentage of the container's size within which the user's cursor must be within, in order to activate the resizer and start a possible resize operation.
		 * The size depends on the current side of the container, and by extension, the resizer as well; a side of LEFT or RIGHT takes the width as the size, and TOP or BOTTOM takes the height as the size.
		 * @see	airdock.enums.ContainerSide
		 */
		function get tolerance():Number;
		
		/**
		 * The maximum visible size available, as a rectangle, to the resizer to draw its graphical content.
		 */
		function set maxSize(size:Rectangle):void
		
		/**
		 * The side of the container that the resizer is to be, and will be, resized to.
		 * This is automatically set by the Docker whenever the resize is to take place.
		 */
		function get sideCode():String;
		function set sideCode(sideCode:String):void
		
		/**
		 * The container which is to be resized. This is automatically set by the Docker whenever the resize is to take place.
		 */
		function get container():IContainer;
		function set container(container:IContainer):void;
	}
}