package airdock.util 
{
	import airdock.interfaces.docking.IBasicDocker;
	import airdock.interfaces.docking.IContainer;
	import airdock.interfaces.docking.IPanel;
	import flash.display.NativeWindow;
	
	/**
	 * Adaptor class which simplifies the IBasicDocker and other I*Docker interfaces.
	 * @author Gimmick
	 */
	public class DockerFacilitator 
	{
		private var cl_targetDocker:IBasicDocker;
		public function DockerFacilitator() { }
		
		public function get targetDocker():IBasicDocker {
			return cl_targetDocker;
		}
		
		public function set targetDocker(value:IBasicDocker):void {
			cl_targetDocker = value;
		}
		
		public function dockPanels(parentContainer:IContainer, ...panels):IContainer
		{
			if(panels.length == 1 && panels[0] is Vector.<IPanel>) {
				return cl_targetDocker.dockPanels(panels[0] as Vector.<IPanel>, parentContainer)
			}
			return cl_targetDocker.dockPanels(Vector.<IPanel>(panels), parentContainer)
		}
		
		public function integratePanels(parentContainer:IContainer, ...panels):IContainer
		{
			if(panels.length == 1 && panels[0] is Vector.<IPanel>) {
				return cl_targetDocker.integratePanels(panels[0] as Vector.<IPanel>, parentContainer)
			}
			return cl_targetDocker.integratePanels(Vector.<IPanel>(panels), parentContainer)
		}
		
		public function hidePanels(...panels):Vector.<IPanel>
		{
			if(panels.length == 1 && panels[0] is Vector.<IPanel>) {
				return cl_targetDocker.hidePanels(panels[0] as Vector.<IPanel>)
			}
			return cl_targetDocker.hidePanels(Vector.<IPanel>(panels))
		}
		
		public function showPanels(...panels):Vector.<IPanel>
		{
			if(panels.length == 1 && panels[0] is Vector.<IPanel>) {
				return cl_targetDocker.showPanels(panels[0] as Vector.<IPanel>)
			}
			return cl_targetDocker.showPanels(Vector.<IPanel>(panels))
		}
		
		public function setupPanels(...panels):void
		{
			function setupPanel(item:IPanel, ...rest):void {
				cl_targetDocker.setupPanel(item);
			}
			
			if (panels.length == 1 && panels[0] is Vector.<IPanel>) {
				(panels[0] as Vector.<IPanel>).forEach(setupPanel, cl_targetDocker);
			}
			else {
				panels.forEach(setupPanel, cl_targetDocker)
			}
		}
		
		public function unhookPanels(...panels):void
		{
			function unhookPanel(item:IPanel, ...rest):void {
				cl_targetDocker.unhookPanel(item);
			}
			
			if (panels.length == 1 && panels[0] is Vector.<IPanel>) {
				(panels[0] as Vector.<IPanel>).forEach(unhookPanel, cl_targetDocker);
			}
			else {
				panels.forEach(unhookPanel, cl_targetDocker)
			}
		}
		
		public function addPanelsToSideSequence(container:IContainer, sideCode:String, ...panels):IContainer
		{
			var newContainer:IContainer;
			function addToSideSequence(item:IPanel, ...rest):void
			{
				if (item && container) {
					newContainer = cl_targetDocker.addPanelToSideSequence(item, container, sideCode);	//re-add to same position; note this approach means they will not be part of the same container
				}
			}
			if (panels.length == 1 && panels[0] is Vector.<IPanel>) {
				(panels[0] as Vector.<IPanel>).forEach(addToSideSequence, cl_targetDocker);
			}
			else {
				panels.forEach(addToSideSequence, cl_targetDocker)
			}
			
			return newContainer
		}
	}

}