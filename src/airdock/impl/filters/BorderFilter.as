package airdock.impl.filters 
{
	import airdock.interfaces.display.IDisplayFilter;
	import airdock.interfaces.display.IFilterable;
	import flash.display.LineScaleMode;
	import flash.display.Shape;
	import flash.utils.Dictionary;
	
	/**
	 * Border filter which draws a border around the filterable instance.
	 * Takes three extra parameters:
		* The color of the border as an unsigned integer
		* The thickness of the border as a number
		* The sides of the border as a bitmask
	 * Like the MaskFilter class, this class also supports multiple targets.
	 * However, modifying the border options is not possible once it has been created.
	 * 
	 * @see airdock.interfaces.display.IDisplayFilter
	 * @see airdock.interfaces.display.IFilterable
	 * @author Gimmick
	 */
	public class BorderFilter implements IDisplayFilter
	{
		public static const LEFT:int = 1;
		public static const RIGHT:int = 2;
		public static const TOP:int = 4;
		public static const BOTTOM:int = 8;
		public static const ALL:int = 15;
		
		private var i_sides:int;
		private var u_color:uint;
		private var num_thickness:Number;
		private var num_colorAlpha:Number;
		private var dct_targets:Dictionary;
		public function BorderFilter(thickness:Number, color:uint, sides:int)
		{
			i_sides = sides;
			u_color = color;
			num_thickness = thickness;
			num_colorAlpha = ((color >>> 24) & 0xFF) / 0xFF;
			dct_targets = new Dictionary(true)
		}
		
		public function apply(filterable:IFilterable):void 
		{
			if(!(filterable in dct_targets)) {
				dct_targets[filterable] = new Shape()
			}
			const shape:Shape = dct_targets[filterable];
			shape.graphics.clear()
			shape.graphics.beginFill(color, num_colorAlpha)
			shape.graphics.lineStyle(num_thickness, u_color, num_colorAlpha, false, LineScaleMode.NONE)
			if (i_sides & TOP)
			{
				shape.graphics.moveTo(0, 0)
				shape.graphics.lineTo(filterable.width, 0)
			}
			if (i_sides & RIGHT)
			{
				shape.graphics.moveTo(filterable.width, 0)
				shape.graphics.lineTo(filterable.width, filterable.height)
			}
			if (i_sides & BOTTOM)
			{
				shape.graphics.moveTo(filterable.width, filterable.height)
				shape.graphics.lineTo(0, filterable.height)
			}
			if (i_sides & LEFT)
			{
				shape.graphics.moveTo(0, filterable.height)
				shape.graphics.lineTo(0, 0)
			}
			filterable.addChild(shape)
		}
		
		public function remove(filterable:IFilterable):void 
		{
			if(!(filterable in dct_targets)) {
				return
			}
			const shape:Shape = dct_targets[filterable];
			if (shape.parent == filterable) {
				filterable.removeChild(shape);
			}
			delete dct_targets[filterable];
		}
		
		public function get sides():int {
			return i_sides;
		}
		
		public function get color():uint {
			return u_color;
		}
		
		public function get thickness():Number {
			return num_thickness;
		}
	}

}