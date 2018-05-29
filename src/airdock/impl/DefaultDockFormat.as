package airdock.impl 
{
	import airdock.interfaces.docking.IDockFormat;
	
	/**
	 * Default IDockFormat implementation.
	 * @author	Gimmick
	 * @see	airdock.interfaces.docking.IDockFormat
	 */
	public final class DefaultDockFormat implements IDockFormat 
	{
		public function DefaultDockFormat() { }
		
		/**
		 * @inheritDoc
		 */
		public function get panelFormat():String {
			return "dps:panel";
		}
		
		/**
		 * @inheritDoc
		 */
		public function get containerFormat():String {
			return "dps:container";
		}
		
		/**
		 * @inheritDoc
		 */
		public function get destinationFormat():String {
			return "dps:destination";
		}
	}

}