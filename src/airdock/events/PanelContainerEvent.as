package airdock.events 
{
	import airdock.interfaces.docking.IContainer;
	import airdock.interfaces.docking.IPanel;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public class PanelContainerEvent extends Event 
	{
		public static const PANEL_ADDED:String = "pcPanelAdded";
		public static const DRAG_REQUESTED:String = "pcDragPanel";
		public static const SHOW_REQUESTED:String = "pcShowPanel";
		public static const REMOVE_REQUESTED:String = "pcPanelRemoveRequested";
		public static const STATE_TOGGLED:String = "pcPanelStateToggled";
		public static const SETUP_REQUESTED:String = "pcSetupRequested";
		public static const RESIZED:String = "pcContainerResized";
		public static const CONTAINER_CREATED:String = "pcContainerCreated";
		public static const MERGING:String = "pcContainerMerging";
		public static const MERGED:String = "pcContainerMerged";
		private var plc_relatedContainer:IContainer;
		private var pl_relatedPanel:IPanel;
		public function PanelContainerEvent(type:String, panel:IPanel = null, container:IContainer = null, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
			plc_relatedContainer = container;
			pl_relatedPanel = panel;
		}
		
		public override function clone():Event 
		{ 
			return new PanelContainerEvent(type, relatedPanel, relatedContainer, bubbles, cancelable);
		}
		
		public override function toString():String { 
			return formatToString("PanelContainerEvent", "type", "relatedPanel", "relatedContainer", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get relatedContainer():IContainer {
			return plc_relatedContainer;
		}
		
		public function get relatedPanel():IPanel {
			return pl_relatedPanel;
		}
		
	}
	
}