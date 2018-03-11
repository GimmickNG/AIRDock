package airdock.impl 
{
	import airdock.interfaces.docking.IContainer;
	import airdock.enums.PanelContainerSide;
	import airdock.interfaces.docking.IPanel;
	import airdock.interfaces.docking.ITreeResolver;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	/**
	 * Default ITreeResolver implementation. 
	 * 
	 * Uses the implicit display list to resolve the relationships between containers and other display objects; 
	 * an alternate implementation may involve using explicit parent references in IContainers for use by the resolver.
	 * 
	 * @author Gimmick
	 * @see	airdock.interfaces.docking.ITreeResolver
	 */
	public final class DefaultTreeResolver implements ITreeResolver
	{
		public function DefaultTreeResolver() { }
		
		/**
		 * @inheritDoc
		 */
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
		
		/**
		 * @inheritDoc
		 */
		[Inline]
		public function findParentContainer(displayObject:DisplayObject):IContainer
		{
			var currParent:DisplayObjectContainer
			if (displayObject)
			{
				currParent = displayObject.parent
				while (currParent && !(currParent is IContainer)) {
					currParent = currParent.parent
				}
			}
			return currParent as IContainer
		}
		
		/**
		 * @inheritDoc
		 */
		public function serializeCode(targetContainerSpace:IContainer, displayObject:DisplayObject):String
		{
			const STRING_FILL:String = PanelContainerSide.STRING_FILL;
			if(!(targetContainerSpace && displayObject)) {
				return null;
			}
			else if(targetContainerSpace == displayObject) {
				return STRING_FILL;
			}
			else for (var child:DisplayObject = displayObject; child && child != targetContainerSpace; child = child.parent) { }
			if(!child) {
				return null;
			}
			const SIDE_TO_STRING:Array = PanelContainerSide.getIntegerToStringMap()
			var resultArr:Vector.<String> = new Vector.<String>();
			var parent:IContainer, sideObj:IContainer;
			var currSide:int, oppSide:int;
			
			for (parent = findParentContainer(displayObject); parent; parent = findParentContainer(parent as DisplayObject))
			{
				if (parent.hasSides)
				{
					currSide = parent.sideCode
					sideObj = parent.getSide(currSide)
					if(sideObj && sideObj.contains(displayObject)) {
						resultArr.push(SIDE_TO_STRING[currSide])
					}
					else
					{
						currSide = PanelContainerSide.getComplementary(currSide)
						sideObj = parent.getSide(currSide)
						if(sideObj && sideObj.contains(displayObject)) {
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
		
		/**
		 * @inheritDoc
		 */
		public function findCommonParent(displayObject:DisplayObject, otherDisplayObject:DisplayObject):DisplayObjectContainer
		{
			//case 1: otherDisplayObj is a parent of displayObj
			var temp:DisplayObjectContainer = displayObject as DisplayObjectContainer
			while(temp && temp != otherDisplayObject) {
				temp = temp.parent
			}
			if(temp == otherDisplayObject) {
				return temp
			}
			//case 2: displayObj is a parent of otherDisplayObj
			temp = otherDisplayObject as DisplayObjectContainer
			while(temp && temp != displayObject) {
				temp = temp.parent
			}
			if(temp == displayObject) {
				return temp
			}
			//case 3: they share a common parent
			var parent:DisplayObject;
			var dispDepth:int, otherDispDepth:int;
			var tempDisp:DisplayObjectContainer = displayObject as DisplayObjectContainer;
			var otherTempDisp:DisplayObjectContainer = otherDisplayObject as DisplayObjectContainer;
			for (parent = displayObject; parent; parent = findParentContainer(parent) as DisplayObject, ++dispDepth) { }
			for (parent = otherDisplayObject; parent; parent = findParentContainer(parent) as DisplayObject, ++otherDispDepth) { }
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