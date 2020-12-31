package airdock.interfaces.display 
{
	
	/**
	 * ...
	 * @author Gimmick
	 */
	public interface IDynamicSize 
	{
		/**
		 * Draws the contents of the displayObject, within the maximum allowed bounds.
		 * This is automatically set by the displayObject's parent IContainer, prior to its use.
		 * @param	maxWidth	The maximum width the displayObject can occupy.
		 * @param	maxHeight	The maximum height the displayObject can occupy.
		 */
		function draw(maxWidth:Number, maxHeight:Number):void;
	}
	
}