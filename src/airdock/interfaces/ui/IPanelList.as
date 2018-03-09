package airdock.interfaces.ui 
{
	import airdock.interfaces.docking.IPanel;
	import flash.events.IEventDispatcher;	
	/**
	 * ...
	 * @author Gimmick
	 */
	public interface IPanelList extends IEventDispatcher
	{
		function addPanelAt(panel:IPanel, index:int):void;
		function addPanel(panel:IPanel):void;
		function removePanelAt(index:int):void;
		function removePanel(panel:IPanel):void;
		function updatePanel(panel:IPanel):void;
		function showPanel(panel:IPanel):void;
	}
	
}