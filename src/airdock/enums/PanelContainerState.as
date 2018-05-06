package airdock.enums 
{
	/**
	 * Enumeration class indicating the possible states a panel or container can occupy.
	 * Each panel or container is either integrated or docked, and visible or invisible.
	 * 
	 * An integrated panel (or container) is one belonging to a container whose root is not parked.
	 * A docked panel (or container) is one belonging to a container whose root is a parked container.
	 * 
	 * A visible panel (or container) is that which is visible on the screen; a panel is visible if it belongs to a visible container.
	 * A container is visible if it is either part of a visible integrated container, or if it is part of a parked container whose window is visible.
	 * 
	 * @author	Gimmick
	 */
	public final class PanelContainerState 
	{
		/**
		 * The state which a container has when it is, or is part of, a container which is not parked.
		 */
		public static const INTEGRATED:Boolean = false;
		/**
		 * The state which a container has when it is, or is part of, a parked container.
		 */
		public static const DOCKED:Boolean = true;
		
		/**
		 * The state which a container has when it is not part of any container.
		 * This necessarily implies that it is neither INTEGRATED nor DOCKED.
		 */
		public static const VISIBLE:Boolean = true;
		
		/**
		 * The state which a container has when it is part of some container.
		 * This necessarily implies that it is either INTEGRATED or DOCKED.
		 */
		public static const INVISIBLE:Boolean = false;
		
		public function PanelContainerState() { }
		
	}

}