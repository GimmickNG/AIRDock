package airdock.config 
{
	/**
	 * ...
	 * @author Gimmick
	 */
	public class PanelConfig extends Object
	{
		private var u_color:uint;
		private var num_width:Number;
		private var num_height:Number;
		private var b_resizable:Boolean;
		public function PanelConfig() { }
		
		public function get color():uint {
			return u_color;
		}
		
		public function set color(value:uint):void {
			u_color = value;
		}
		
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
		
		public function get resizable():Boolean {
			return b_resizable;
		}
		
		public function set resizable(value:Boolean):void 
		{
			b_resizable = value;
		}
		
	}

}