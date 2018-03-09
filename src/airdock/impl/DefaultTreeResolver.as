package airdock.impl 
{
	import airdock.interfaces.docking.IContainer;
	import airdock.enums.PanelContainerSide;
	import airdock.interfaces.docking.IPanel;
	import airdock.interfaces.docking.ITreeResolver;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	/**
	 * ...
	 * @author Gimmick
	 */
	public final class DefaultTreeResolver implements ITreeResolver
	{
		public function DefaultTreeResolver() { }
		
		[Inline]
		public function findRootContainer(container:IContainer):IContainer
		{
			var parent:DisplayObject = container as DisplayObject;
			var root:IContainer;
			do
			{
				root = parent as IContainer
				parent = findParentContainer(parent) as DisplayObject;
			} while (parent);
			return root;
		}
		
		[Inline]
		public function findParentContainer(displayObj:DisplayObject):IContainer
		{
			var currParent:DisplayObjectContainer
			if (displayObj)
			{
				currParent = displayObj.parent
				while (currParent && !(currParent is IContainer)) {
					currParent = currParent.parent
				}
			}
			return currParent as IContainer
		}
		
		public function serializeCode(targetContainerSpace:IContainer, displayObj:DisplayObject):String
		{
			const STRING_FILL:String = PanelContainerSide.STRING_FILL;
			if(!(targetContainerSpace && displayObj)) {
				return null;
			}
			else if(targetContainerSpace == displayObj) {
				return STRING_FILL;
			}
			else for (var child:DisplayObject = displayObj; child && child != targetContainerSpace; child = child.parent) { }
			if(!child) {
				return null;
			}
			const SIDE_TO_STRING:Array = PanelContainerSide.getIntegerToStringMap()
			var resultArr:Vector.<String> = new Vector.<String>();
			var parent:IContainer, sideObj:IContainer;
			var currSide:int, oppSide:int;
			
			for (parent = findParentContainer(displayObj); parent; parent = findParentContainer(parent as DisplayObject))
			{
				if (parent.hasSides)
				{
					currSide = parent.currentSideCode
					sideObj = parent.getSide(currSide)
					if(sideObj && sideObj.contains(displayObj)) {
						resultArr.push(SIDE_TO_STRING[currSide])
					}
					else
					{
						currSide = PanelContainerSide.getComplementary(currSide)
						sideObj = parent.getSide(currSide)
						if(sideObj && sideObj.contains(displayObj)) {
							resultArr.push(SIDE_TO_STRING[currSide])
						}
					}
				}
				else {
					resultArr.push(STRING_FILL);
				}
				
				if(parent == targetContainerSpace) {
					break;
				}
			}
			
			return resultArr.reverse().join('');
		}
		
		public function findCommonParent(displayObj:DisplayObjectContainer, otherDisplayObj:DisplayObjectContainer):DisplayObjectContainer
		{
			//case 1: otherDisplayObj is a parent of displayObj
			var temp:DisplayObject = displayObj
			while(temp && temp != otherDisplayObj) {
				temp = temp.parent
			}
			if(temp == otherDisplayObj) {
				return otherDisplayObj
			}
			//case 2: displayObj is a parent of otherDisplayObj
			temp = otherDisplayObj
			while(temp && temp != displayObj) {
				temp = temp.parent
			}
			if(temp == displayObj) {
				return displayObj
			}
			//case 3: they share a common parent
			var parent:DisplayObject;
			var dispDepth:int, otherDispDepth:int;
			var tempDisp:DisplayObjectContainer = displayObj;
			var otherTempDisp:DisplayObjectContainer = otherDisplayObj;
			for (parent = displayObj; parent; parent = findParentContainer(parent) as DisplayObject, ++dispDepth) { }
			for (parent = otherDisplayObj; parent; parent = findParentContainer(parent) as DisplayObject, ++otherDispDepth) { }
			while (dispDepth != otherDispDepth)
			{
				if (dispDepth > otherDispDepth)
				{
					tempDisp = findParentContainer(tempDisp) as DisplayObjectContainer
					--dispDepth;
				}
				else
				{
					otherTempDisp = findParentContainer(otherTempDisp) as DisplayObjectContainer
					--otherDispDepth;
				}
			}
			while (tempDisp != otherTempDisp)
			{
				tempDisp = findParentContainer(tempDisp) as DisplayObjectContainer
				otherTempDisp = findParentContainer(otherTempDisp) as DisplayObjectContainer
			}
			return tempDisp
		}
	}

}