package airdock.interfaces.docking 
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	/**
	 * An interface which is used to define and retrieve the relationships between different containers and their children, which are including, but not limited to, panels.
	 * @author	Gimmick
	 */
	public interface ITreeResolver 
	{
		/**
		 * Finds the root IContainer instance which contains the supplied container. This may either be parked (automatic) or a manually created root.
		 * @param	container	The container to find the root container of. If a container is not contained by any other container above it, then it is taken as the root.
		 * @return	The root container that contains the supplied container. If the container supplied does not have any containers above it, then the same container is returned instead.
		 */
		function findRootContainer(container:IContainer):IContainer
		
		/**
		 * Finds the IContainer instance which contains the supplied DisplayObject instance.
		 * @param	displayObj	The DisplayObject instance to find the parent container of.
		 * @return	The parent container that contains the supplied DisplayObject instance. If there are no containers above it, then null is returned.
		 */
		function findParentContainer(displayObj:DisplayObject):IContainer
		
		/**
		 * Returns a string representation of the displayObject's relation with the target IContainer instance, as a sequence of side additions as defined in the ContainerSide enumeration class.
		 * For example, suppose a panel (or any other object, such as a Sprite or another container) in the given tree (sides not important):
		 *     A
		 *   B   C
		 *     D   E
		 *       F   G
		 *           p
		 * Where p is the panel and C, E, and G are the left containers of A, C, and E respectively.
		 * In this case, the code for p with respect to A is: 
		 * * Root (parked) container -> left container -> left container -> left container -> panel
		 * Then the code returned, assuming the root container is passed to this function is LLLF.
		 * That is, when read from left to right, going from higher to lower in the display hierarchy, the root's left's left's left's side contains the panel.
		 * Note that all codes can end with FILL (F), as FILL returns the same container. Removing this character does not affect the outcome, but can be used to identify serialized codes.
		 * 
		 * In some cases, if a container is used as the targetContainerSpace such that the DisplayObject instance is in another container above it, then may return null, depending on the implementation.
		 * In that case, call findCommonParent() or its equivalent to determine the new targetContainerSpace to be supplied for this method.
		 * @param	targetContainerSpace	The container with respect to which the side sequence of the DisplayObject instance is to be found.
		 * @param	displayObject	The DisplayObject instance whose side sequence is to be found, with respect to the targetContainerSpace.
		 * @return	A sequence of side codes in string representation for the DisplayObject instance, with respect to the targetContainerSpace.
		 * 			A null value may be returned, if the targetContainerSpace does not contain the DisplayObject instance.
		 */
		function serializeCode(targetContainerSpace:IContainer, displayObject:DisplayObject):String
		
		/**
		 * Finds the common DisplayObjectContainer instance for all the given DisplayObject instances in the list.
		 * Note that this can be used for non-panels and non-containers, and as such, does not guarantee that it will return an IContainer instance.
		 * @param	displayObjects	A Vector of DisplayObject instances to find the common parent of.
		 * @return	The DisplayObjectContainer instance which contains the two instances supplied, which may be at different levels with respect to each other.
		 */
		function findCommonParent(displayObjects:Vector.<DisplayObject>):DisplayObjectContainer
	}
	
}