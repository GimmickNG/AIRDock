package airdock.util 
{
	/**
	 * ...
	 * @author Gimmick
	 */
	public class StaticPair implements IPair 
	{
		private var obj_key:Object;
		private var obj_value:Object
		public function StaticPair(key:Object, value:Object) { }
		
		public function get key():Object {
			return obj_key;
		}
		
		public function get value():Object {
			return obj_value;
		}
		
	}

}