package airdock.config 
{
	/**
	 * ...
	 * @author Gimmick
	 */
	public class ContainerConfig extends Object
	{
		private var num_width:Number;
		private var num_height:Number;
		public function ContainerConfig() { }
		
		public function get width():Number {
			return num_width;
		}
		
		public function set width(value:Number):void {
			num_width = value;
		}
		
		public function get height():Number {
			return num_height;
		}
		
		public function set height(value:Number):void {
			num_height = value;
		}
		
	}

}