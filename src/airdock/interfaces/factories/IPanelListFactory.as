package airdock.interfaces.factories 
{
	import airdock.interfaces.factories.IFactory;
	import airdock.interfaces.ui.IPanelList;
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public interface IPanelListFactory extends IFactory {
		function createPanelList():IPanelList
	}
	
}