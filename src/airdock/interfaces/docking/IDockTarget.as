package airdock.interfaces.docking 
{
	import airdock.interfaces.display.IDisplayObject;
	import flash.display.DisplayObject;
	
	/**
	 * The interface defining the function to determine which side of a container a panel is to be attached to, at the end of a drag(-drop)-dock operation.
	 * @author Gimmick
	 */
	public interface IDockTarget extends IDisplayObject
	{
		/**
		 * Determines the side of the container to which the panel is to be added to, at the end of a drag-docking operation.
		 * Acceptable values are located in the PanelContainerSide enumeration class.
		 * @param	dropTarget	The target DisplayObject instance on which the user drops the panel just before the drag-docking operation is finished.
		 * @return	The side of the current container to which the panel should be added to, as an integer.
		 * @see airdock.enums.PanelContainerSide
		 */
		function getSideFrom(dropTarget:DisplayObject):int;
	}
	
}