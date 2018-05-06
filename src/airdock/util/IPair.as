package airdock.util 
{
	
	/**
	 * An interface defining a key-value pair.
	 * No guarantees are made about the types of the key and value.
	 * @author	Gimmick
	 * @see	airdock.util.StaticPair
	 * @see	airdock.util.DynamicPair
	 */
	public interface IPair 
	{
		/**
		 * The key in the pair.
		 */
		function get key():Object;
		/**
		 * The value in the pair.
		 */
		function get value():Object;
	}
	
}