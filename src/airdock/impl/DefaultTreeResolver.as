package airdock.impl 
{
	import airdock.enums.ContainerSide;
	import airdock.interfaces.docking.IContainer;
	import airdock.interfaces.docking.ITreeResolver;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	/**
	 * Default ITreeResolver implementation. 
	 * 
	 * Uses the implicit display list to resolve relationships between containers and other display objects.
	 * An alternate implementation may involve using explicit parent references in IContainers for use by the resolver.
	 * For example, explicit parent references in IContainers, which are themselves IContainers.
	 * 
	 * @author	Gimmick
	 * @see	airdock.interfaces.docking.ITreeResolver
	 */
	public final class DefaultTreeResolver implements ITreeResolver
	{
		public function DefaultTreeResolver() { }
		
		/**
		 * @inheritDoc
		 */
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
		
		public function serializeCode(targetContainerSpace:IContainer, displayObject:DisplayObject):String
		{
			const STRING_FILL:String = ContainerSide.FILL;
			if(!(targetContainerSpace && displayObject && targetContainerSpace.contains(displayObject))) {
				return null;
			}
			else if(targetContainerSpace == displayObject || findParentContainer(displayObject) == targetContainerSpace) {
				return STRING_FILL;
			}
			
			var i:uint;
			var currSide:String, oppSide:String;
			var parent:IContainer, sideObj:IContainer;
			var result:Vector.<String> = new <String>[]
			for (parent = findParentContainer(displayObject); parent; parent = findParentContainer(parent as DisplayObject))
			{
				if (parent.hasSides)
				{
					for (i = 0, currSide = parent.sideCode, sideObj = parent.getSide(currSide); i < 2 && !(sideObj && sideObj.contains(displayObject)); ++i, currSide = ContainerSide.getComplementary(currSide), sideObj = parent.getSide(currSide)) {
						// check both containers to see if they contain the displayObject 
					}
					
					result.push(currSide)
				}
				else {
					result.push(STRING_FILL);
				}
			}
			
			return result.reverse().join('');
		}
		
		/**
		 * @inheritDoc
		 */
		public function findCommonParent(displayObjects:Vector.<DisplayObject>):DisplayObjectContainer
		{
			if(!(displayObjects && displayObjects.length)) {
				return null;
			}
			var commonParent:DisplayObjectContainer = (displayObjects.length && displayObjects[0]) as DisplayObjectContainer;
			displayObjects.forEach(function findCommonParentForEach(item:DisplayObject, index:int, array:Vector.<DisplayObject>):void {
				commonParent = findCommonParentInternal(item, commonParent);	//find common container of all panels
			});
			return commonParent
		}
		
		protected function findCommonParentInternal(displayObject:DisplayObject, otherDisplayObject:DisplayObject):DisplayObjectContainer
		{
			/**
			 * Case 1: otherDisplayObj is a parent of displayObj:
				* Keep finding displayObj's parent until it is either null, or it matches otherDisplayObj
			 */
			var temp:DisplayObjectContainer = displayObject as DisplayObjectContainer
			while(temp && temp != otherDisplayObject) {
				temp = temp.parent
			}
			if(temp == otherDisplayObject) {
				return temp
			}
			
			/**
			 * Case 2: displayObj is a parent of otherDisplayObj
				* Repeat as case 1, but with the order swapped
			 */
			temp = otherDisplayObject as DisplayObjectContainer
			while(temp && temp != displayObject) {
				temp = temp.parent
			}
			if(temp == displayObject) {
				return temp
			}
			
			/**
			 * Case 3: They both share a common parent
				* Check depths of both displayObjects, and equalize if necessary
				* Repeatedly find the parents of both displayObjects until they are equal
					* That is, they share a common parent
				* If no common parent found, return null
			 */
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