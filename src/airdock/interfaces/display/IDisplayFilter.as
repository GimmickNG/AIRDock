package airdock.interfaces.display 
{
	/**
	 * The interface that identifies a class as a display filter.
	 * Display filters are executed by classes which support runtime display filtering.
	 * For identifying and creating classes which support runtime display filtering, please see the IFilterable interface.
	 * @see airdock.interfaces.display.IFilterable
	 * @author	Gimmick
	 */
	public interface IDisplayFilter 
	{
		/**
		 * Executes the filter on the supplied filterable instance.
		 * @param	filterable	The IFilterable instance which is to have display filters added to it.
		 */
		function apply(filterable:IFilterable):void;
		
		/**
		 * Removes the filter from the supplied filterable instance.
		 * @param	filterable	The IFilterable instance which is to have display filters removed from it.
		 */
		function remove(filterable:IFilterable):void;
	}
	
}