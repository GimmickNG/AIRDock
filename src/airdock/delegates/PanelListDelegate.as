package airdock.delegates 
{
	import airdock.events.PanelContainerEvent;
	import airdock.impl.ui.DefaultPanelList;
	import airdock.interfaces.docking.IPanel;
	import airdock.interfaces.ui.IPanelList;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	/**
	 * ...
	 * @author Gimmick
	 */
	public class PanelListDelegate implements IEventDispatcher
	{
		private var vec_panels:Vector.<IPanel>;
		private var cl_dispatcher:IEventDispatcher;
		public function PanelListDelegate(panelList:IPanelList)
		{
			cl_dispatcher = panelList;
			vec_panels = new Vector.<IPanel>()
		}
		
		public function get numPanels():uint {
			return vec_panels.length
		}
		
		public function addPanelAt(panel:IPanel, index:int):void {
			vec_panels.splice(index, 0, panel)
		}
		
		public function addPanel(panel:IPanel):void {
			addPanelAt(panel, vec_panels.length)
		}
		
		public function getPanelIndex(panel:IPanel):int {
			return vec_panels.indexOf(panel)
		}
		
		public function getPanelAt(index:int):IPanel {
			return vec_panels[index];
		}
		
		public function requestShow(panel:IPanel):Boolean {
			return panel && cl_dispatcher.dispatchEvent(new PanelContainerEvent(PanelContainerEvent.SHOW_REQUESTED, panel, null, true, true))
		}
		
		public function requestStateToggle(panel:IPanel):Boolean {
			return cl_dispatcher.dispatchEvent(new PanelContainerEvent(PanelContainerEvent.STATE_TOGGLE_REQUESTED, panel, null, true, true))
		}
		
		public function removePanelAt(index:int):IPanel {
			return vec_panels.splice(index, 1)[0]
		}
		
		public function removePanel(panel:IPanel):IPanel
		{
			var result:IPanel;
			var index:int = getPanelIndex(panel);
			if(index != -1) {
				result = removePanelAt(index)
			}
			return result;
		}
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			cl_dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function dispatchEvent(event:Event):Boolean {
			return cl_dispatcher.dispatchEvent(event);
		}
		
		public function hasEventListener(type:String):Boolean {
			return cl_dispatcher.hasEventListener(type);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			cl_dispatcher.removeEventListener(type, listener, useCapture);
		}
		
		public function willTrigger(type:String):Boolean {
			return cl_dispatcher.willTrigger(type);
		}
	}

}