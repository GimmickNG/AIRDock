package airdock.enums 
{
	/**
	 * The enumeration class which dictates the sides to which containers attach to.
	 * @author	Gimmick
	 */
	public final class ContainerSide
	{
		/**
		 * Gets the current container.
		 */
		public static const FILL:String = "F";
		
		/**
		 * Gets the left side of the current container. 
		 */
		public static const LEFT:String = "L"
		
		/**
		 * Gets the right side of the current container. 
		 */
		public static const RIGHT:String = "R";
		
		/**
		 * Gets the top side of the current container. 
		 */
		public static const TOP:String = "T";
		
		/**
		 * Gets the bottom side of the current container. 
		 */
		public static const BOTTOM:String = "B";
		
		public function ContainerSide() { }
		
		/**
		 * Checks whether two sides are equal or complementary. Does not support checking multiple sides at the same time.
		 * Note: to check whether two sides are exclusively complementary (i.e. not equal), an additional inequality check has to be performed.
		 * Has the capability to handle side sequences, and check if all the sides in the sequence are complementary to each other.
		 * 
		 * @param	side	The string of the current side(s).
		 * @param	otherSide	The string of the other side(s).
		 * @return	A Boolean indicating whether the two side string(s) are complementary.
		 */
		public static function isComplementary(side:String, otherSide:String):Boolean
		{
			if(!(side && otherSide && side.length == otherSide.length)) {
				return false;
			}
			else for (var i:uint = 0; i < side.length; ++i)
			{
				var sideChar:String = side.charAt(i), otherSideChar:String = otherSide.charAt(i);
				if(sideChar == otherSideChar) {
					continue;
				}
				var complementary:Boolean = (sideChar == FILL && otherSideChar == FILL)		||	(sideChar == LEFT && otherSideChar == RIGHT)	||
											(otherSideChar == LEFT && sideChar == RIGHT)	||	(sideChar == TOP && otherSideChar == BOTTOM)	||
											(otherSideChar == TOP && sideChar == BOTTOM);
				if(!complementary) {
					return false;
				}
			}
			return true;
		}
		
		/**
		 * Gets the complementary side for the supplied side(s).
		 * Has the capability to handle side sequences, returning a string with all the sides complementary to the original.
		 * 
		 * @param	side	The side string(s) to get the complementary of, in string representation.
		 * @return	The complementary side(s), in string representation.
		 */
		public static function getComplementary(side:String):String
		{
			var complementary:String = "";
			if(!side) {
				return null;
			}
			else for (var i:uint = 0; i < side.length; ++i)
			{
				switch(side.charAt(i))
				{
					case LEFT:
						complementary += RIGHT;
						break;
					case RIGHT:
						complementary += LEFT;
						break;
					case TOP:
						complementary += BOTTOM;
						break;
					case BOTTOM:
						complementary += TOP;
						break;
					case FILL:
					default:
						complementary += FILL;
						break;
				}
			}
			return complementary
		}
		
		/**
		 * Inclusive removes everything after the first occurrence of side FILL in the given side sequence.
		 * For example, assuming (F -> FILL), (T -> TOP), (R -> RIGHT), (B -> BOTTOM) and (L -> LEFT):
		 * 1. RTRLF	->	RTRL	(since everything after the last F - including the F - is removed)
		 * 2. LLLLF	->	LLLL	(same as #1)
		 * 3. LFFFF	->	L		(since multiple Fs are removed)
		 * 4. LFRTF	->	L		(since F is the ending point of a side sequence, all sides after the F are invalid and thus removed)
		 * 5. null	->	''		(Empty string, for easier comparison)
		 * @param	side	The side sequence to strip FILLs from.
		 * @return	The side sequence with FILLs removed from the sequence.
		 */
		public static function stripFills(side:String):String
		{
			const fillString:String = (side || "") + FILL;
			return fillString.slice(0, fillString.indexOf(FILL))
		}
		
		/**
		 * Determines which of the two side sequences are deeper than the other.
		 * If the two are of equal levels, 0 is returned; if the first sequence is deeper, 1 is returned, else 0.
		 * @param	sequenceA	The first side sequence to compare.
		 * @param	sequenceB	The second side sequence to compare.
		 * @return	An integer denoting the relative nesting order of the two:
		 * 			*  0 is returned if the two sequences are on the same level, or if they are both null,
		 * 			*  1 is returned if sequenceA is deeper than sequenceB, and
		 * 			* -1 is returned if sequenceA is shallower than sequenceB.
		 */
		public static function compareCode(sequenceA:String, sequenceB:String):int
		{
			var first:String = ContainerSide.stripFills(sequenceA), second:String = ContainerSide.stripFills(sequenceB)
			return int(first.length > second.length) - int(second.length > first.length)
		}
	}

}