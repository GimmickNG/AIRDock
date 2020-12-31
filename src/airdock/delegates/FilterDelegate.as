package airdock.delegates 
{
	import airdock.interfaces.display.IDisplayFilter;
	import airdock.interfaces.display.IFilterable;
	/**
	 * ...
	 * @author Gimmick
	 */
	public class FilterDelegate 
	{
		private var cl_target:IFilterable
		public function FilterDelegate(target:IFilterable) {
			cl_target = target
		}
		
		/**
		 * Applies the given filters to the target.
		 * @param	filters	A Vector of IDisplayFilters which are to be applied to the target.
		 */
		public function applyFilters(filters:Vector.<IDisplayFilter>):void 
		{
			const target:IFilterable = cl_target;
			filters && filters.forEach(function applyAll(item:IDisplayFilter, index:int, array:Vector.<IDisplayFilter>):void {
				item.apply(target)
			});
		}
		
		/**
		 * Removes the given filters from the target.
		 * @param	filters	A Vector of IDisplayFilters which are to be removed from the target.
		 */
		public function clearFilters(filters:Vector.<IDisplayFilter>):void 
		{
			const target:IFilterable = cl_target;
			filters && filters.forEach(function clearAll(item:IDisplayFilter, index:int, array:Vector.<IDisplayFilter>):void {
				item.remove(target)
			});
		}
	}

}