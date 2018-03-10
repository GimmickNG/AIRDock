package airdock.enums 
{
	import flash.utils.Dictionary;
	
	/**
	 * The enumeration class which dictates the sides to which containers attach to.
	 * @author Gimmick
	 */
	public final class PanelContainerSide
	{
		/**
		 * Gets the current container.
		 */
		public static const FILL:int = 0;		//0000000
		/**
		 * Gets the left side of the current container. 
		 */
		public static const LEFT:int = 1;		//0000001
		/**
		 * Gets the right side of the current container. 
		 */
		public static const RIGHT:int = 3;		//0000011
		/**
		 * Gets the top side of the current container. 
		 */
		public static const TOP:int = 4;		//0000100
		/**
		 * Gets the bottom side of the current container. 
		 */
		public static const BOTTOM:int = 12;	//0001100
		
		/**
		 * String representation of FILL.
		 */
		public static const STRING_FILL:String = "F";
		/**
		 * String representation of LEFT.
		 */
		public static const STRING_LEFT:String = "L"
		/**
		 * String representation of RIGHT.
		 */
		public static const STRING_RIGHT:String = "R";
		/**
		 * String representation of TOP.
		 */
		public static const STRING_TOP:String = "T";
		/**
		 * String representation of BOTTOM.
		 */
		public static const STRING_BOTTOM:String = "B";
		
		/**
		 * Internal integer to string associative array.
		 */
		private static const INT_TO_STRING:Array = new Array()
		
		/**
		 * Internal string to integer associative array.
		 */
		private static const STRING_TO_INT:Array = new Array()
		
		static:
		{
			//set up the integer to string associative array
			INT_TO_STRING[FILL] = STRING_FILL
			INT_TO_STRING[LEFT] = STRING_LEFT
			INT_TO_STRING[RIGHT] = STRING_RIGHT
			INT_TO_STRING[TOP] = STRING_TOP
			INT_TO_STRING[BOTTOM] = STRING_BOTTOM
			
			//set up the string to integer associative array
			STRING_TO_INT[STRING_FILL] = FILL
			STRING_TO_INT[STRING_LEFT] = LEFT
			STRING_TO_INT[STRING_RIGHT] = RIGHT
			STRING_TO_INT[STRING_TOP] = TOP
			STRING_TO_INT[STRING_BOTTOM] = BOTTOM
		}
		
		public function PanelContainerSide() { }
		
		/**
		 * String equivalent of isComplementary(). This also has the capability to handle multiple sides at the same time, and check if all the sides are complementary to each other.
		 * @param	side	The string representation of the current side(s).
		 * @param	otherSide	The string representation of the other side(s).
		 * @return	A Boolean indicating whether the two side string(s) are complementary.
		 */
		public static function isComplementaryString(side:String, otherSide:String):Boolean
		{
			if(!(side && otherSide && side.length == otherSide.length)) {
				return false
			}
			else if (side.length == 1) {
				return (side == STRING_LEFT && otherSide == STRING_RIGHT) || (side == STRING_TOP && otherSide == STRING_BOTTOM) || (side == STRING_FILL && otherSide == STRING_FILL)
			}
			else
			{
				for (var i:uint = 0; i < side.length; ++i)
				{
					if(!isComplementaryString(side.charAt(i), otherSide.charAt(i))) {
						return false;
					}
				}
				return true;
			}
		}
		
		/**
		 * String equivalent to getComplementary(). This also has the capability to handle multiple sides at the same time, and retrieves a string with all the sides complementary to the original.
		 * @param	side	The side string(s) to get the complementary of, in string representation.
		 * @return	The complementary side(s), in string representation.
		 */
		public static function getComplementaryString(side:String):String
		{
			if(!side) {
				return null;
			}
			else if (side.length > 1)
			{
				var complementary:String = "";
				for (var i:uint = 0; i < side.length; ++i) {
					complementary += getComplementaryString(side.charAt(i));
				}
				return complementary
			}
			
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
		
		/**
		 * Gets an associative array with keys as integers and the values as their string counterparts.
		 * Useful when calling toString() in a loop, or any place where repeated calls to static methods proves costly.
		 * @return	An associative array with keys as sides in integer format and the values as their string counterparts.
		 */
		[Inline]
		public static function getIntegerToStringMap():Array {
			return INT_TO_STRING
		}
		
		/**
		 * Gets an associative array with strings as integers and the values as their integer counterparts.
		 * Useful when calling toString() in a loop, or any place where repeated calls to static methods proves costly.
		 * @return	An associative array with keys as sides in string format and the values as their integer counterparts.
		 */
		[Inline]
		public static function getStringToIntegerMap():Array {
			return STRING_TO_INT
		}
		
		/**
		 * Checks whether two sides are equal or complementary. Does not support checking multiple sides at the same time.
		 * Note: to check whether two sides are exclusively complementary (i.e. not equal), an additional XOR (inequality) check has to be performed.
		 * @param	side	The first side to compare.
		 * @param	otherSide	The second side to compare.
		 * @return	A Boolean indicating whether the supplied sides are equal, or complementary, or neither.
		 */
		[Inline]
		public static function isComplementary(side:int, otherSide:int):Boolean {
			return ((side & otherSide) != 0);
		}
		
		/**
		 * Gets the complementary side for the supplied side.
		 * @param	side	The side to get the complementary of, as an integer.
		 * @return	An integer denoting the side complementary to that supplied.
		 */
		[Inline]
		public static function getComplementary(side:int):int
		{
			if(side == LEFT || side == TOP) {
				return (side * 3)	//equiv. to (side << 1) + side
			}
			return (side / 3)
		}
		
		/**
		 * Convert a side, in integer format, to a string. Invalid values return STRING_FILL, by default.
		 * @param	side	The side to get the string representation of, as an integer.
		 * @return	The string representation of the side, as listed in this enumeration.
		 */
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
		
		/**
		 * Convert a side, in string format, to an integer. Invalid values return FILL, by default.
		 * @param	side	The side to get the integer representation of, as a string.
		 * @return	The integer representation of the side, as listed in this enumeration.
		 */
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