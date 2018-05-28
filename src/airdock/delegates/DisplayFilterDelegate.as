package airdock.delegates 
{
	import airdock.interfaces.display.IDisplayFilter;
	import airdock.interfaces.display.IFilterable;
	import airdock.util.PropertyChangeProxy;
	import flash.display.DisplayObject;
	/**
	 * ...
	 * @author Gimmick
	 */
	public class DisplayFilterDelegate 
	{
		private var cl_target:IFilterable
		public function DisplayFilterDelegate(target:IFilterable) {
			cl_target = target
		}
		
		/**
		 * Applies the given filters to the target.
		 * @param	filters	A Vector of IDisplayFilters which are to be applied to the target.
		 */
		public function applyFilters(filters:Vector.<IDisplayFilter>):void 
		{
			for (var i:int = int(filters && filters.length) - 1; i >= 0; --i) {
				filters[i].apply(cl_target);
			}
		}
		
		/**
		 * Removes the given filters from the target.
		 * @param	filters	A Vector of IDisplayFilters which are to be removed from the target.
		 */
		public function clearFilters(filters:Vector.<IDisplayFilter>):void 
		{
			for (var k:int = int(filters && filters.length) - 1; k >= 0; --k) {
				filters[k].remove(cl_target);
			}
		}
	}

}