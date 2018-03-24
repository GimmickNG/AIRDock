package airdock.util 
{
	/**
	 * An IPair class which uses a dynamic value retrieval method to retrieve values.
	 * Use this class if the value to be retrieved requires computation which may be expensive (more expensive than the overhead of the function call), or if the value is not known ahead of time, except through a function.
	 * The main difference between this and the lazy pair is that values are not cached upon retrieval in this class.
	 * 
	 * For example, an iterator may be implemented using this class, since the value retrieved by calling the function is not cached (since the function is called each time.)
	 * @author Gimmick
	 * @see StaticPair
	 */
	public class DynamicPair implements IPair
	{		
		private var obj_key:Object;
		private var arr_arguments:Array;
		private var fn_valueFunction:Function;
		/**
		 * Creates a Pair which uses a lazy value retrieval method.
		 * This can be used for key-value retrievals which are computationally expensive.
		 * @param	key	The object acting as the key in the pair.
		 * @param	valueFunction	The function which is evaluated with parameter args, in order to retrieve the value.
		 * @param	...args	The set of arguments passed to the valueFunction.
		 */
		public function DynamicPair(key:Object, valueFunction:Function, ...args) 
		{
			obj_key = key;
			arr_arguments = [key].concat(args)
			fn_valueFunction = valueFunction;
		}
		
		public function get key():Object {
			return obj_key
		}
		
		public function get value():Object {
			return fn_valueFunction.apply(null, arr_arguments)
		}
	}

}