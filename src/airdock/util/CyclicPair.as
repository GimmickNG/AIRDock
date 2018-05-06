package airdock.util 
{
	import flash.crypto.generateRandomBytes;
	/**
	 * An IPair class which uses a cyclically increasing value retrieval method to retrieve values.
	 * Use this class if the value to be retrieved alternates between a set of values in a stepwise manner.
	 * 
	 * For example, an iterator may be implemented using this class, since the value retrieved by calling the function varies, stepping through each element in the set.
	 * @author	Gimmick
	 */
	public class CyclicPair implements IPair
	{
		private var obj_key:Object;
		private var i_currCycle:int;
		private var arr_values:Array;
		public function CyclicPair(key:Object, value:Object, ...extraValues)
		{
			obj_key = key;
			arr_values = [value].concat(extraValues)
		}
		
		public function get key():Object {
			return obj_key
		}
		
		public function get value():Object
		{
			if(++i_currCycle >= arr_values.length) {
				i_currCycle = 0;
			}
			return arr_values[i_currCycle];
		}
	}

}