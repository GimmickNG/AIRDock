package airdock.events 
{
	import airdock.enums.PanelContainerState;
	import airdock.interfaces.docking.IContainer;
	import airdock.interfaces.docking.IPanel;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public class PanelContainerStateEvent extends PanelContainerEvent
	{
		public static const VISIBILITY_TOGGLED:String = "pcPanelVisibilityToggled";
		public static const STATE_TOGGLED:String = "pcPanelStateToggled";
		
		private var b_beforeState:Boolean;
		private var b_afterState:Boolean
		public function PanelContainerStateEvent(type:String, panel:IPanel = null, container:IContainer = null, beforeDisplayState:Boolean = PanelContainerState.INTEGRATED, afterDisplayState:Boolean = PanelContainerState.INTEGRATED, bubbles:Boolean = false, cancelable:Boolean = false) 
		{ 
			super(type, panel, container, bubbles, cancelable);
			b_beforeState = beforeDisplayState
			b_afterState = afterDisplayState
		} 
		
		public override function clone():Event {
			return new PanelContainerStateEvent(type, relatedPanel, relatedContainer, beforeDisplayState, afterDisplayState, bubbles, cancelable);
		} 
		
		public override function toString():String { 
			return formatToString("PanelContainerStateEvent", "type", "relatedPanel", "relatedContainer", "beforeDisplayState", "afterDisplayState", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get beforeDisplayState():Boolean {
			return b_beforeState;
		}
		
		public function get afterDisplayState():Boolean {
			return b_afterState;
		}
		
	}
	
}