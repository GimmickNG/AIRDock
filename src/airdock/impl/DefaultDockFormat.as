package airdock.impl 
{
	import airdock.interfaces.docking.IDockFormat;
	
	/**
	 * ...
	 * @author Gimmick
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
	}

}