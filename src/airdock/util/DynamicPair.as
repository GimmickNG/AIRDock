package airdock.util 
{
	/**
	 * ...
	 * @author Gimmick
	 */
	public class DynamicPair implements IPair
	{		
		private var obj_key:Object;
		private var obj_value:Object;
		private var arr_arguments:Array;
		private var fn_valueFunction:Function
		/**
		 * Creates a Pair which uses a lazy value retrieval method. 
		 * @param	key
		 * @param	valueFunction
		 * @param	...args
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