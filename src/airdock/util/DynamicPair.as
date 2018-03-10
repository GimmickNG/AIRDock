package airdock.util 
{
	/**
	 * An IPair class which uses a lazy value retrieval method to retrieve values.
	 * Use this class if the value to be retrieved requires computation which may be expensive (more expensive than the overhead of the function call), or if the value is not known ahead of time, except through a function.
	 * @author Gimmick
	 * @see StaticPair
	 */
	public class DynamicPair implements IPair
	{		
		private var obj_key:Object;
		private var obj_value:Object;
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
			return obj_value ||= fn_valueFunction.apply(null, arr_arguments)
		}
	}

}