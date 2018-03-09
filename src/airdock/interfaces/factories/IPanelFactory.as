package airdock.interfaces.factories 
{
	import airdock.config.PanelConfig;
	import airdock.interfaces.docking.IPanel;
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public interface IPanelFactory extends IFactory {
		function createPanel(options:PanelConfig):IPanel
	}
	
}