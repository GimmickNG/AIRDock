package airdock.interfaces.docking 
{
	import airdock.interfaces.display.IDisplayObjectContainer;
	
	/**
	 * The interface defining the set of methods that a (display)object must fulfil in order to participate in docking and other features offered by the Docker instance.
	 * @author Gimmick
	 */
	public interface IPanel extends IDisplayObjectContainer
	{		
		/**
		 * The default width of the panel instance; parked containers and their windows are initially created with this width.
		 * @return	The default width of the panel.
		 */
		function getDefaultWidth():Number;
		
		/**
		 * The default height of the panel instance; parked containers and their windows are initially created with this height.
		 * @return	The default height of the panel.
		 */
		function getDefaultHeight():Number;
		
		/**
		 * The name of the panel. Tabs in IPanelList instances of the container which this is part of, and the window corresponding to this, take this value.
		 * @return	The name of the panel.
		 */
		function set panelName(value:String):void
		
		/**
		 * The name of the panel. Tabs in IPanelList instances of the container which this is part of, and the window corresponding to this, take this value.
		 * @return	The name of the panel.
		 */
		function get panelName():String
		
		/**
		 * A Boolean indicating whether the panel is resizable or not. Panels which are not resizable cannot have their windows resized; any container which it is a part of cannot be resized either.
		 */
		function set resizable(value:Boolean):void
		
		/**
		 * A Boolean indicating whether the panel is resizable or not.
		 * Panels which are not resizable cannot have their windows resized; any container which it is a part of cannot be resized either.
		 * However, it is up to the IContainer instance which it is a part of, to either respect this attribute or ignore it.
		 */
		function get resizable():Boolean
		
		/**
		 * A Boolean indicating whether the panel is dockable or not.
		 * Non-dockable panels cannot be removed from the root container which they are a part of, by the user.
		 */
		function set dockable(value:Boolean):void
		
		/**
		 * A Boolean indicating whether the panel is dockable or not.
		 * Non-dockable panels cannot be removed from the root container which they are a part of, by the user.
		 */
		function get dockable():Boolean
	}
	
}