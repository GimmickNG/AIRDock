package airdock.interfaces.docking 
{
	import airdock.interfaces.docking.IContainer;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public interface ITreeResolver 
	{
		function findRootContainer(container:IContainer):IContainer
		function findParentContainer(displayObj:DisplayObject):IContainer
		function serializeCode(targetContainerSpace:IContainer, displayObj:DisplayObject):String
		function findCommonParent(displayObj:DisplayObjectContainer, otherDisplayObj:DisplayObjectContainer):DisplayObjectContainer
	}
	
}