package airdock.interfaces.ui 
{
	import airdock.interfaces.display.IDynamicSize;
	import airdock.interfaces.ui.IDockTarget;
	import flash.display.DisplayObject;
	import flash.events.IEventDispatcher;
	
	/**
	 * An interface defining the methods that a display object must implement in order to participate in the drag-docking mechanism of the Docker.
	 * A dock helper is a display object container which contains dock targets; this appears whenever the user drags a panel or container over another container.
	 * The dock helper of the target Docker's containers (be it the same, or a foreign, Docker) will have its methods called by the target Docker.
	 * To complete the dock operation, the dock helper must report the dock target onto which the panel or container has been dropped.
	 * The responsibility of docking is then passed to the respective IDockTarget instance.
	 * @author	Gimmick
	 * @see	airdock.interfaces.docking.IDockTarget
	 */
	public interface IDockHelper extends IDockTarget, IDynamicSize, IEventDispatcher
	{
		/**
		 * Hides the candidate instances specified in the list.
		 * This is usually called when a user drags a panel or container outside the target container, or when it is outside the bounds of the dock helper.
		 * If no list is specified, then it hides all the candidate instances which are part of the current dock helper.
		 */
		function hide(targets:Vector.<DisplayObject> = null):void;
		
		/**
		 * Shows all the candidate instances specified in the list.
		 * This is usually called when a user drags a panel or container over another container.
		 * If no list is specified, then it shows all the candidate instances which are part of the current dock helper.
		 */
		function show(targets:Vector.<DisplayObject> = null):void;
		
		/**
		 * Sets the dock format to let the dock helper decide whether to accept or reject any native drag/drop events occurring over it.
		 * @param	panelFormat	The clipboard format string for a panel.
		 * @param	containerFormat	The clipboard format string for a container.
		 */
		function setDockFormats(panelFormat:String, containerFormat:String):void;
	}
	
}