package airdock.interfaces.docking 
{
	import airdock.interfaces.display.IDisplayObjectContainer;
	import airdock.interfaces.ui.IPanelList;
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public interface IContainer extends IDisplayObjectContainer
	{
		function getSide(side:int):IContainer
		function addContainer(side:int, container:IContainer):IContainer
		function addToSide(side:int, panel:IPanel):IContainer
		function removePanel(panel:IPanel):IContainer
		function removeContainer(panelContainer:IContainer):IContainer
		function resetContainer():void
		/**
		 * Gets the given side from the container. Creates it if it does not exist.
		 * @param	side
		 * @return
		 */
		function fetchSide(side:int):IContainer
		function setContainers(sideCode:int, currentSide:IContainer, otherSide:IContainer):void;
		/**
		 * Merges the contents of the current container into the destination container, and empties the current container in the process.
		 * In effect, it empties the container (node) into another container by transferring all its children and its branches into the other container.
		 * @param	container
		 */
		function mergeIntoContainer(container:IContainer):void;
		function getPanelCount(recursive:Boolean):int;
		function hasPanels(recursive:Boolean):Boolean;
		
		function get hasSides():Boolean
		function get panels():Vector.<IPanel>
		function get currentSideCode():int
		
		function get panelList():IPanelList
		function set panelList(panelList:IPanelList):void
		
		function get sideSize():Number
		function set sideSize(size:Number):void
		
		function get sideRatio():Number
		function set sideRatio(ratio:Number):void
		
		function get maxSideRatio():Number;
		function set maxSideRatio(value:Number):void;
		
		function get minSideRatio():Number;
		function set minSideRatio(value:Number):void;
		
		function get containerState():Boolean
		function set containerState(value:Boolean):void
	}
	
}