package airdock.util 
{
	/**
	 * An IPair class which uses a lazy value retrieval method to retrieve values.
	 * Use this class if the value to be retrieved requires computation which may be expensive (more expensive than the overhead of the function call), or if the value is not known ahead of time, except through a function.
	 * This is computationally cheaper than the DynamicPair class since the computation for the value field is performed only once.
	 * 
	 * @author	Gimmick
	 * @see	airdock.util.StaticPair
	 */
	public class LazyPair implements IPair
	{
		private var obj_key:Object;
		private var obj_value:Object;
		private	var b_computed:Boolean;
		private var arr_arguments:Array;
		private var fn_valueFunction:Function;
		/**
		 * Creates a Pair which uses a lazy value retrieval method.
		 * This can be used for key-value retrievals which are computationally expensive.
		 * @param	key	The object acting as the key in the pair.
		 * @param	valueFunction	The function which is evaluated with parameter args, in order to retrieve the value.
		 * @param	...args	The set of arguments passed to the valueFunction.
		 */
		public function LazyPair(key:Object, valueFunction:Function, ...args) 
		{
			obj_key = key;
			b_computed = false;
			fn_valueFunction = valueFunction;
			arr_arguments = [key].concat(args);
		}
		
		public function get key():Object {
			return obj_key
		}
		
		public function get value():Object
		{
			if(b_computed) {
				return obj_value;
			}
			b_computed = true;
			return obj_value = fn_valueFunction.apply(null, arr_arguments);
		}
	}

}