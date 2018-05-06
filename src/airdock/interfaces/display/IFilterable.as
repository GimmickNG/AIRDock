package airdock.interfaces.display 
{
	
	/**
	 * The interface indicating a class supports runtime display filtering.
	 * Classes which support runtime filtering can have IDisplayFilter instances executed on them.
	 * @author	Gimmick
	 */
	public interface IFilterable extends IDisplayObjectContainer
	{
		/**
		 * The set of IDisplayFilter instances which are applied to the current IContainer instance at runtime.
		 * Display filters can be used to apply effects like masking, blurring and others on any supporting displayObject.
		 * @see	airdock.interfaces.display.IDisplayFilter
		 */
		function get displayFilters():Vector.<IDisplayFilter>;
		function set displayFilters(filters:Vector.<IDisplayFilter>):void;
	}
	
}