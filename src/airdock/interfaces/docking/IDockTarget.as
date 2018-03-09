package airdock.interfaces.docking 
{
	import airdock.interfaces.display.IDisplayObject;
	import flash.display.DisplayObject;
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public interface IDockTarget extends IDisplayObject
	{
		function getSideFrom(dropTarget:DisplayObject):int;
	}
	
}