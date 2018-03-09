package airdock.enums 
{
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Gimmick
	 */
	public final class PanelContainerSide
	{
		public static const FILL:int = 0;		//0000000
		public static const LEFT:int = 1;		//0000001
		public static const RIGHT:int = 3;		//0000011
		public static const TOP:int = 4;		//0000100
		public static const BOTTOM:int = 12;	//0001100
		
		public static const STRING_FILL:String = "F"
		public static const STRING_LEFT:String = "L"
		public static const STRING_RIGHT:String = "R"
		public static const STRING_TOP:String = "T"
		public static const STRING_BOTTOM:String = "B"
		
		private static const INT_TO_STRING:Array = new Array()
		private static const STRING_TO_INT:Array = new Array()
		static:
		{
			INT_TO_STRING[FILL] = STRING_FILL
			INT_TO_STRING[LEFT] = STRING_LEFT
			INT_TO_STRING[RIGHT] = STRING_RIGHT
			INT_TO_STRING[TOP] = STRING_TOP
			INT_TO_STRING[BOTTOM] = STRING_BOTTOM
			
			STRING_TO_INT[STRING_FILL] = FILL
			STRING_TO_INT[STRING_LEFT] = LEFT
			STRING_TO_INT[STRING_RIGHT] = RIGHT
			STRING_TO_INT[STRING_TOP] = TOP
			STRING_TO_INT[STRING_BOTTOM] = BOTTOM
		}
		
		public function PanelContainerSide() { }
		
		[Inline]
		public static function isComplementaryString(side:String, otherSide:String):Boolean {
			return (side == STRING_LEFT && otherSide == STRING_RIGHT) || (side == STRING_TOP && otherSide == STRING_BOTTOM)
		}
		
		[Inline]
		public static function getComplementaryString(side:String):String
		{
			switch(side)
			{
				case STRING_LEFT:
					return STRING_RIGHT;
				case STRING_RIGHT:
					return STRING_LEFT;
				case STRING_TOP:
					return STRING_BOTTOM;
				case STRING_BOTTOM:
					return STRING_TOP;
				case STRING_FILL:
				default:
					return STRING_FILL;	
			}
		}
		
		[Inline]
		public static function getIntegerToStringMap():Array {
			return INT_TO_STRING
		}
		
		[Inline]
		public static function getStringToIntegerMap():Array {
			return STRING_TO_INT
		}
		
		[Inline]
		public static function isComplementary(side:int, otherSide:int):Boolean {
			return ((side & otherSide) != 0);
		}
		
		[Inline]
		public static function getComplementary(side:int):int
		{
			if(side == LEFT || side == TOP) {
				return (side * 3)	//equiv. to (side << 1) + side
			}
			return (side / 3)
		}
		
		[Inline]
		public static function toString(side:int):String
		{
			switch(side)
			{
				case LEFT:
					return STRING_LEFT;
				case RIGHT:
					return STRING_RIGHT;
				case BOTTOM:
					return STRING_BOTTOM;
				case TOP:
					return STRING_TOP;
				case FILL:
				default:
					return STRING_FILL;	
			}
		}
		
		[Inline]
		public static function toInteger(side:String):int
		{
			switch(side)
			{
				case STRING_LEFT:
					return LEFT;
				case STRING_RIGHT:
					return RIGHT;
				case STRING_TOP:
					return TOP;
				case STRING_BOTTOM:
					return BOTTOM;
				case STRING_FILL:
				default:
					return FILL;	
			}
		}
	}

}