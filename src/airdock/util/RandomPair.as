package airdock.util 
{
	import flash.crypto.generateRandomBytes;
	/**
	 * An IPair class which uses a random value retrieval method to retrieve values, where each value in the set of values has an equal probability of being selected.
	 * Use this class if the value to be retrieved is any of a set of random values for a given key.
	 * Uses cryptographically strong random number generators where possible, so it is not advised to use this class in performance-critical sections.
	 * If cryptographically strong numbers cannot be generated on the target operating system, then an error is thrown.
	 * 
	 * For example, a die-rolling mechanism can be implemented using this class.
	 * @author Gimmick
	 */
	public class RandomPair implements IPair
	{
		private var obj_key:Object;
		private var arr_values:Array;
		public function RandomPair(key:Object, value:Object, ...extraValues)
		{
			obj_key = key;
			arr_values = [value].concat(extraValues)
		}
		
		public function get key():Object {
			return obj_key
		}
		
		public function get value():Object {
			return arr_values[int((generateRandomBytes(4).readUnsignedInt() / (Number(uint.MAX_VALUE) + 1)) * arr_values.length)];
		}
	}

}