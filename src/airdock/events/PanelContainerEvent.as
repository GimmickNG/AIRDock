package airdock.events 
{
	import airdock.interfaces.docking.IContainer;
	import airdock.interfaces.docking.IPanel;
	import flash.events.Event;
	
	/**
	 * @eventType	airdock.events.PanelContainerEvent.PANEL_ADDED
	 */
	[Event(name="pcPanelAdded", type="airdock.events.PanelContainerEvent.PANEL_ADDED")]
	
	/**
	 * @eventType	airdock.events.PanelContainerEvent.DRAG_REQUESTED
	 */
	[Event(name="pcDragPanel", type="airdock.events.PanelContainerEvent.DRAG_REQUESTED")]
	
	/**
	 * @eventType	airdock.events.PanelContainerEvent.SHOW_REQUESTED
	 */
	[Event(name="pcShowPanel", type="airdock.events.PanelContainerEvent.SHOW_REQUESTED")]
	
	/**
	 * @eventType	airdock.events.PanelContainerEvent.PANEL_REMOVE_REQUESTED
	 */
	[Event(name="pcPanelRemoveRequested", type="airdock.events.PanelContainerEvent.PANEL_REMOVE_REQUESTED")]
	
	/**
	 * @eventType	airdock.events.PanelContainerEvent.CONTAINER_REMOVE_REQUESTED
	 */
	[Event(name="pcContainerRemoveRequested", type="airdock.events.PanelContainerEvent.CONTAINER_REMOVE_REQUESTED")]
	
	/**
	 * @eventType	airdock.events.PanelContainerEvent.STATE_TOGGLE_REQUESTED
	 */
	[Event(name="pcPanelStateToggleRequested", type="airdock.events.PanelContainerEvent.STATE_TOGGLE_REQUESTED")]
	
	/**
	 * @eventType	airdock.events.PanelContainerEvent.SETUP_REQUESTED
	 */
	[Event(name="pcSetupRequested", type="airdock.events.PanelContainerEvent.SETUP_REQUESTED")]
	
	/**
	 * @eventType	airdock.events.PanelContainerEvent.CONTAINER_CREATED
	 */
	[Event(name="pcContainerCreated", type="airdock.events.PanelContainerEvent.CONTAINER_CREATED")]
	
	/**
	 * ...
	 * @author	Gimmick
	 */
	public class PanelContainerEvent extends Event 
	{
		/**
		 * The constant used to define a panelAdded event. Is dispatched by a container whenever a panel is added directly to it, i.e. not to subcontainers.
		 */
		public static const PANEL_ADDED:String = "pcPanelAdded";
		
		/**
		 * The constant used to define a panelRemoved event. Is dispatched by a container whenever a panel is removed from a container.
		 */
		public static const PANEL_REMOVED:String = "pcPanelRemoved";
		
		/**
		 * The constant used to define a dragRequested event. 
		 * Is dispatched whenever a container's panelList has requested that a drag-dock sequence be initiated for a panel or the container it is a part of, usually as a result of user action.
		 * Since this is a request, it can be canceled to prevent default action.
		 */
		public static const DRAG_REQUESTED:String = "pcDragPanel";
		
		/**
		 * The constant used to define a showRequested event.
		 * Is dispatched whenever a container's panelList (or any other DisplayObject instance) has requested that a panel be shown, or activated, usually as a result of user action.
		 * Since this is a request, it can be canceled to prevent default action.
		 */
		public static const SHOW_REQUESTED:String = "pcShowPanel";
		
		/**
		 * The constant used to define a panelRemoveRequested event.
		 * Is dispatched whenever a container's panelList has requested it to remove a panel from the container.
		 * Since this is a request, it can be canceled to prevent default action.
		 */
		public static const PANEL_REMOVE_REQUESTED:String = "pcPanelRemoveRequested";
		
		/**
		 * The constant used to define a removeRequested event.
		 * Is dispatched whenever a container has requested its parent container (i.e. the container above it, which contains it) that it be removed.
		 * Since this is a request, it can be canceled to prevent default action.
		 */
		public static const CONTAINER_REMOVE_REQUESTED:String = "pcContainerRemoveRequested";
		
		/**
		 * The constant used to define a removed event.
		 * Is dispatched whenever a container (which has requested to be removed) has been removed from its parent container.
		 * Containers which are removed from their parent containers (and are not parked) are unreachable and can be safely disposed of.
		 */
		public static const CONTAINER_REMOVED:String = "pcContainerRemoved";
		
		/**
		 * The constant used to define a stateToggleRequested event.
		 * Is dispatched whenever a container's panelList (or any other DisplayObject instance) has requested that the state of either a panel or a container be changed.
		 * Since this is a request, it can be canceled to prevent default action.
		 */
		public static const STATE_TOGGLE_REQUESTED:String = "pcPanelStateToggleRequested";
		
		/**
		 * The constant used to define a setupRequested event.
		 * Is dispatched whenever a previously empty container has had panels added to it, and requires (re-)customization, such as adding an IPanelList instance to it.
		 * Since this is a request, it can be canceled to prevent default action.
		 */
		public static const SETUP_REQUESTED:String = "pcSetupRequested";
		
		/**
		 * The constant used to define a containerCreated event.
		 * Is dispatched whenever a container has been automatically created by another container, over the course of its lifetime.
		 */
		public static const CONTAINER_CREATED:String = "pcContainerCreated";
		
		/**
		 * The constant used to define a containerCreating event.
		 * Is dispatched whenever a container is about to be created and is requesting its parent Docker for a new container.
		 */
		public static const CONTAINER_CREATING:String = "pcContainerCreating";
		
		private var vec_relatedPanels:Vector.<IPanel>;
		private var plc_relatedContainer:IContainer;
		public function PanelContainerEvent(type:String, panels:Vector.<IPanel> = null, container:IContainer = null, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
			plc_relatedContainer = container;
			vec_relatedPanels = panels;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Event { 
			return new PanelContainerEvent(type, relatedPanels, relatedContainer, bubbles, cancelable);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function toString():String { 
			return formatToString("PanelContainerEvent", "type", "relatedPanels", "relatedContainer", "bubbles", "cancelable", "eventPhase"); 
		}
		
		/**
		 * The related container that is involved in some action that caused the event. This may be null if the event concerns only the panel.
		 * However, the container is usually included, based on the IContainer implementation.
		 */
		public function get relatedContainer():IContainer {
			return plc_relatedContainer;
		}
		
		/**
		 * The related panel that is involved in some action that caused the event. May be null if the event concerns only the container.
		 * Unlike the relatedContainer property, there is no guarantee that it will not be null, especially when there are multiple panels involved.
		 * For example, when the entire container's contents are involved, instead of just one panel, the panel property is null, but not the container..
		 */
		public function get relatedPanels():Vector.<IPanel> {
			return vec_relatedPanels;
		}
	}
}