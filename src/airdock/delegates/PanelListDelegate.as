package airdock.delegates 
{
	import airdock.events.PanelContainerEvent;
	import airdock.interfaces.docking.IPanel;
	import airdock.interfaces.ui.IPanelList;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	/**
	 * ...
	 * @author	Gimmick
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
		
		public function requestShow(panels:Vector.<IPanel>):Boolean {
			return panels && dispatchEvent(new PanelContainerEvent(PanelContainerEvent.SHOW_REQUESTED, panels, null, true, true))
		}
		
		/**
		 * Requests the panelList's container to start a drag-dock operation for the given panel.
		 * If no panel is supplied (i.e. a null panel) then the drag-dock operation is started for the entire container.
		 * @param	panel	An (optional) IPanel instance which is to take part in a drag-dock operation.
		 * 					A null IPanel instance indicates the entire container should take part in the drag-dock operation.
		 * @return	A Boolean indicating whether the operation was a success. If the event was prevented via preventDefault(), false is returned.
		 */
		public function requestDrag(panels:Vector.<IPanel>):Boolean {
			return dispatchEvent(new PanelContainerEvent(PanelContainerEvent.DRAG_REQUESTED, panels, null, true, true))
		}
		
		public function requestRemove(panels:Vector.<IPanel>):Boolean {
			return panels && dispatchEvent(new PanelContainerEvent(PanelContainerEvent.PANEL_REMOVE_REQUESTED, panels, null, true, true))
		}
		
		/**
		 * Requests the panelList's container to toggle the state (docked to integrated and vice versa) for the given panel
		 * If no panel is supplied (i.e. a null panel) then the state toggle operation is applied to the entire container.
		 * @param	panel	An (optional) IPanel instance whose state is to be toggled (from docked to integrated and vice versa)
		 * 					A null IPanel instance indicates the state toggle operation is to be applied to the entire container.
		 * @return	A Boolean indicating whether the operation was a success. If the event was prevented via preventDefault(), false is returned.
		 */
		public function requestStateToggle(panels:Vector.<IPanel>):Boolean {
			return dispatchEvent(new PanelContainerEvent(PanelContainerEvent.STATE_TOGGLE_REQUESTED, panels, null, true, true))
		}
		
		public function removePanelAt(index:int):IPanel {
			return vec_panels.splice(index, 1).pop()
		}
		
		public function removePanel(panel:IPanel):IPanel
		{
			var result:IPanel;
			var index:int = getPanelIndex(panel);
			if(index != -1) {
				result = removePanelAt(index);
			}
			return result;
		}
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			cl_dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			cl_dispatcher.removeEventListener(type, listener, useCapture);
		}
		
		public function dispatchEvent(event:Event):Boolean {
			return cl_dispatcher.dispatchEvent(event);
		}
		
		public function hasEventListener(type:String):Boolean {
			return cl_dispatcher.hasEventListener(type);
		}
		
		public function willTrigger(type:String):Boolean {
			return cl_dispatcher.willTrigger(type);
		}
	}

}