package airdock.interfaces.ui 
{
	import airdock.interfaces.display.IDisplayObjectContainer;
	import airdock.interfaces.docking.IDockTarget;
	import flash.display.DisplayObject;
	import flash.events.IEventDispatcher;
	
	/**
	 * An interface defining the methods that a display object must implement in order to participate in the drag-docking mechanism of the Docker.
	 * A dock helper is a display object container which contains dock targets; this appears whenever the user drags a panel or container over another container.
	 * The dock helper of the target Docker's containers (be it the same, or a foreign, Docker) will have its methods called by the target Docker.
	 * To complete the dock operation, the dock helper must report the dock target on which the panel or container has been dropped, at which point responsibility is passed to the respective IDockTarget instance.
	 * @author Gimmick
	 * @see airdock.interfaces.docking.IDockTarget
	 */
	public interface IDockHelper extends IDisplayObjectContainer, IEventDispatcher, IDockTarget
	{
		/**
		 * Hides all the IDockTarget instances. This is usually called when a user drags a panel or container outside the target container, or when it is outside the bounds of the dock helper.
		 */
		function hideAll():void;
		
		/**
		 * Shows all the IDockTarget instances. This is usually called when a user drags a panel or container over another container.
		 */
		function showAll():void;
		
		/**
		 * Gets the default width of the dock helper. The Docker uses this information to set the width of the current dock helper.
		 * @return	The default width of the current dock helper.
		 */
		function getDefaultWidth():Number;
		
		/**
		 * Gets the default height of the dock helper. The Docker uses this information to set the height of the current dock helper.
		 * @return	The default height of the current dock helper.
		 */
		function getDefaultHeight():Number;
		
		/**
		 * Draws the dock helper's graphical content. This is automatically called by the Docker when the dock helper is being set up, i.e. (usually) at the time of creation of the Docker.
		 * @param	width	The maximum width which the content can occupy.
		 * @param	height	The maximum height which the content can occupy.
		 */
		function draw(width:Number, height:Number):void;
	}
	
}