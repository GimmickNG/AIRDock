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
	 * @eventType	airdock.events.PanelContainerEvent.REMOVE_REQUESTED
	 */
	[Event(name="pcPanelRemoveRequested", type="airdock.events.PanelContainerEvent.REMOVE_REQUESTD")]
	
	/**
	 * @eventType	airdock.events.PanelContainerEvent.STATE_TOGGLE_REQUESTED
	 */
	[Event(name="pcPanelStateToggleRequested", type="airdock.events.PanelContainerEvent.STATE_TOGGLE_REQUESTED")]
	
	/**
	 * @eventType	airdock.events.PanelContainerEvent.SETUP_REQUESTED
	 */
	[Event(name="pcSetupRequested", type="airdock.events.PanelContainerEvent.SETUP_REQUESTED")]
	
	/**
	 * @eventType	airdock.events.PanelContainerEvent.RESIZED
	 */
	[Event(name="pcContainerResized", type="airdock.events.PanelContainerEvent.RESIZED")]
	
	/**
	 * @eventType	airdock.events.PanelContainerEvent.RESIZING
	 */
	[Event(name = "pcContainerResizing", type = "airdock.events.PanelContainerEvent.RESIZING")]
	
	/**
	 * @eventType	airdock.events.PanelContainerEvent.CONTAINER_CREATED
	 */
	[Event(name="pcContainerCreated", type="airdock.events.PanelContainerEvent.CONTAINER_CREATED")]
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public class PanelContainerEvent extends Event 
	{
		/**
		 * The constant used to define a panelAdded event. Is dispatched by a container whenever a panel is added directly to it, i.e. not to subcontainers.
		 */
		public static const PANEL_ADDED:String = "pcPanelAdded";
		
		/**
		 * The constant used to define a dragRequested event. Is dispatched whenever a container's panelList has requested that a drag-dock sequence be initiated for a panel or the container it is a part of, usually as a result of user action.
		 * Since this is a request, it can be canceled to prevent default action.
		 */
		public static const DRAG_REQUESTED:String = "pcDragPanel";
		
		/**
		 * The constant used to define a showRequested event. Is dispatched whenever a container's panelList (or any other DisplayObject instance) has requested that a panel be shown, or activated, usually as a result of user action.
		 * Since this is a request, it can be canceled to prevent default action.
		 */
		public static const SHOW_REQUESTED:String = "pcShowPanel";
		
		/**
		 * The constant used to define a removeRequested event. Is dispatched whenever a container has requested its parent container (i.e. the container above it, which contains it) that it be removed.
		 * Since this is a request, it can be canceled to prevent default action.
		 */
		public static const REMOVE_REQUESTED:String = "pcPanelRemoveRequested";
		
		/**
		 * The constant used to define a stateToggleRequested event. Is dispatched whenever a container's panelList (or any other DisplayObject instance) has requested that the state of either a panel or a container be changed.
		 * Since this is a request, it can be canceled to prevent default action.
		 */
		public static const STATE_TOGGLE_REQUESTED:String = "pcPanelStateToggleRequested";
		
		/**
		 * The constant used to define a setupRequested event. Is dispatched whenever a previously empty container has had panels added to it, and requires (re-)customization, such as adding an IPanelList instance to it.
		 * Since this is a request, it can be canceled to prevent default action.
		 */
		public static const SETUP_REQUESTED:String = "pcSetupRequested";
		/**
		 * The constant used to define a resized event. Is dispatched whenever a panel or container has been resized.
		 */
		public static const RESIZED:String = "pcContainerResized";
		/**
		 * The constant used to define a resizing event. Is dispatched whenever a panel or container is going to be resized.
		 */
		public static const RESIZING:String = "pcContainerResizing";
		/**
		 * The constant used to define a containerCreated event. Is dispatched whenever a container has been automatically created by another container, over the course of its lifetime.
		 */
		public static const CONTAINER_CREATED:String = "pcContainerCreated";
		
		public static const CONTAINER_CREATING:String = "pcContainerCreating";
		private var pl_relatedPanel:IPanel;
		private var plc_relatedContainer:IContainer;
		public function PanelContainerEvent(type:String, panel:IPanel = null, container:IContainer = null, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
			plc_relatedContainer = container;
			pl_relatedPanel = panel;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Event { 
			return new PanelContainerEvent(type, relatedPanel, relatedContainer, bubbles, cancelable);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function toString():String { 
			return formatToString("PanelContainerEvent", "type", "relatedPanel", "relatedContainer", "bubbles", "cancelable", "eventPhase"); 
		}
		
		/**
		 * The related container that is involved in some action that caused the event.
		 * This may be null if the event concerns only the panel; however, the container is usually included, based on the IContainer implementation.
		 */
		public function get relatedContainer():IContainer {
			return plc_relatedContainer;
		}
		
		/**
		 * The related panel that is involved in some action that caused the event. May be null if the event concerns only the container.
		 * Unlike the relatedContainer property, there is no assurance that it will not be null, especially when there are multiple panels involved (as in the case of when the entire container's contents are involved, instead of just one panel)
		 */
		public function get relatedPanel():IPanel {
			return pl_relatedPanel;
		}
	}
}