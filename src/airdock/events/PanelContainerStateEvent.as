package airdock.events 
{
	import airdock.enums.ContainerState;
	import airdock.interfaces.docking.IContainer;
	import airdock.interfaces.docking.IPanel;
	import flash.events.Event;
	
	/**
	 * @eventType	airdock.events.PanelContainerStateEvent.VISIBILITY_TOGGLED
	 */
	[Event(name="pcPanelVisibilityToggled", type="airdock.events.PanelContainerStateEvent")]
	
	/**
	 * @eventType	airdock.events.PanelContainerStateEvent.STATE_TOGGLED
	 */
	[Event(name="pcPanelStateToggled", type="airdock.events.PanelContainerStateEvent")]
	
	/**
	 * A PanelContainerStateEvent is dispatched by a Docker whenever a panel's or container's visibility or state is changed.
	 * The visibility is said to be changed either when it was not part of any stage and has been added to a container on the stage, or vice versa.
	 * The state is said to be changed for a panel when it is moved from a non-parked container to the panel's own parked container, or vice versa.
	 * For a container, it is said to be changed when the container, or the contents of the container, are moved from a non-parked parent container to a parked parent container, or vice versa.
	 * @author	Gimmick
	 */
	public class PanelContainerStateEvent extends PanelContainerEvent
	{
		/**
		 * The constant used to define a visibilityToggling event. Is dispatched whenever a panel's, or container's, visibility is about to change.
		 * This event is dispatched before the visibilityToggled event; preventing this event prevents default action.
		 */
		public static const VISIBILITY_TOGGLING:String = "pcPanelVisibilityToggling";
		/**
		 * The constant used to define a visibilityToggled event. Is dispatched whenever a panel's, or container's, visibility has changed.
		 */
		public static const VISIBILITY_TOGGLED:String = "pcPanelVisibilityToggled";
		/**
		 * The constant used to define a stateToggled event. Is dispatched whenever a panel's, or container's, state has changed.
		 */
		public static const STATE_TOGGLED:String = "pcPanelStateToggled";
		
		private var b_afterState:Boolean;
		private var b_beforeState:Boolean;
		public function PanelContainerStateEvent(type:String, panels:Vector.<IPanel> = null, container:IContainer = null, beforeDisplayState:Boolean = false /*ContainerState.INTEGRATED*/, afterDisplayState:Boolean = false /*ContainerState.INTEGRATED*/, bubbles:Boolean = false, cancelable:Boolean = false) 
		{ 
			super(type, panels, container, bubbles, cancelable);
			b_beforeState = beforeDisplayState
			b_afterState = afterDisplayState
		} 
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Event {
			return new PanelContainerStateEvent(type, relatedPanels, relatedContainer, beforeDisplayState, afterDisplayState, bubbles, cancelable);
		} 
		
		/**
		 * @inheritDoc
		 */
		override public function toString():String { 
			return formatToString("PanelContainerStateEvent", "type", "relatedPanels", "relatedContainer", "beforeDisplayState", "afterDisplayState", "bubbles", "cancelable", "eventPhase"); 
		}
		
		/**
		 * The display state of the panel or container involved, before the event had occurred.
		 * Valid values are enumerated in the ContainerState enumeration class.
		 * @see	airdock.enums.ContainerState
		 */
		public function get beforeDisplayState():Boolean {
			return b_beforeState;
		}
		
		/**
		 * The display state of the panel or container involved, after the event has occurred.
		 * Valid values are enumerated in the ContainerState enumeration class.
		 * @see	airdock.enums.ContainerState
		 */
		public function get afterDisplayState():Boolean {
			return b_afterState;
		}
	}
}