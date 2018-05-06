package airdock.util 
{
	/**
	 * An IPair class which uses a static (i.e. non-changing) value retrieval method to retrieve values.
	 * Use this class if the value to be retrieved is computationally cheap, or if the value is known ahead of time.
	 * This is usually cheaper than DynamicPair since no computation is required once an instance is created.
	 * @author	Gimmick
	 * @see	airdock.util.DynamicPair
	 */
	public class StaticPair implements IPair
	{
		private var obj_key:Object;
		private var obj_value:Object
		public function StaticPair(key:Object, value:Object)
		{
			obj_key = key;
			obj_value = value;
		}
		
		public function get key():Object {
			return obj_key;
		}
		
		public function get value():Object {
			return obj_value;
		}
		
	}

}