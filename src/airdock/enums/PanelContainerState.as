package airdock.enums 
{
	/**
	 * ...
	 * @author Gimmick
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