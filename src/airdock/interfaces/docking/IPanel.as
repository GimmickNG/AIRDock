package airdock.interfaces.docking 
{
	import airdock.interfaces.display.IDisplayObject;
	import airdock.interfaces.display.IFilterable;
	
	/**
	 * The interface defining the set of methods that a (display)object must fulfil in order to participate in docking and other features offered by the Docker instance.
	 * @author	Gimmick
	 */
	public interface IPanel extends IFilterable, IDisplayObject
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
		 * The name of the panel.
		 * Tabs in IPanelList instances of the container which this is part of, and the window corresponding to this, take this value.
		 */
		function get panelName():String
		function set panelName(value:String):void
		
		/**
		 * A Boolean indicating whether the panel is resizable or not.
		 * Panels which are not resizable cannot have their windows resized; 
		 * however, it is up to the IContainer implementation to decide whether to prevent the panel which it contains, from being resized, or not.
		 */
		function get resizable():Boolean
		function set resizable(value:Boolean):void
		
		/**
		 * A Boolean indicating whether the panel is dockable or not.
		 * Non-dockable panels cannot be removed from the root container which they are a part of, by the user.
		 */
		function get dockable():Boolean
		function set dockable(value:Boolean):void
	}
	
}