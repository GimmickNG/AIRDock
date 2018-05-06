package airdock.interfaces.display 
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.text.TextSnapshot;
	
	/**
	 * A convenience interface which signals an object is a DisplayObjectContainer, i.e. DisplayObjectContainers always implement this interface.
	 * However, the converse is not true - implementing this interface will not allow an object to behave like a DisplayObjectContainer.
	 * Taken from the DisplayObjectContainer class.
	 * @author	Gimmick
	 */
	public interface IDisplayObjectContainer extends IDisplayObject
	{
		function get mouseChildren () : Boolean;
		function set mouseChildren (enable:Boolean) : void;
		/**
		 * Returns the number of children of this object.
		 * @langversion	3.0
		 * @playerversion	Flash 9
		 * @playerversion	Lite 4
		 */
		function get numChildren () : int;

		/**
		 * Determines whether the children of the object are tab enabled. Enables or disables tabbing for the 
		 * children of the object. The default is true.
		 * Note: Do not use the tabChildren property with Flex.
		 * Instead, use the mx.core.UIComponent.hasFocusableChildren property.
		 * @langversion	3.0
		 * @playerversion	Flash 9
		 * @playerversion	Lite 4
		 * @throws	IllegalOperationError Calling this property of the Stage object 
		 *   throws an exception. The Stage object does not implement this property.
		 */
		function get tabChildren () : Boolean;
		function set tabChildren (enable:Boolean) : void;

		/**
		 * Returns a TextSnapshot object for this DisplayObjectContainer instance.
		 * @langversion	3.0
		 * @playerversion	Flash 9
		 */
		function get textSnapshot () : flash.text.TextSnapshot;
		
		/**
		 * Adds a child DisplayObject instance to this DisplayObjectContainer instance. The child is added
		 * to the front (top) of all other children in this DisplayObjectContainer instance. (To add a child to a 
		 * specific index position, use the addChildAt() method.)
		 * 
		 *   If you add a child object that already has a different display object container as
		 * a parent, the object is removed from the child list of the other display object container. Note: The command stage.addChild() can cause problems with a published SWF file,
		 * including security problems and conflicts with other loaded SWF files. There is only one Stage within a Flash runtime instance, 
		 * no matter how many SWF files you load into the runtime. So, generally, objects
		 * should not be added to the Stage, directly, at all. The only object the Stage should
		 * contain is the root object. Create a DisplayObjectContainer to contain all of the items on the
		 * display list. Then, if necessary, add that DisplayObjectContainer instance to the Stage.
		 * @param	child	The DisplayObject instance to add as a child of this DisplayObjectContainer instance.
		 * @return	The DisplayObject instance that you pass in the 
		 *   child parameter.
		 * @langversion	3.0
		 * @playerversion	Flash 9
		 * @playerversion	Lite 4
		 * @throws	ArgumentError Throws if the child is the same as the parent.  Also throws if
		 *   the caller is a child (or grandchild etc.) of the child being added.
		 */
		function addChild (child:DisplayObject) : flash.display.DisplayObject;

		/**
		 * Adds a child DisplayObject instance to this DisplayObjectContainer 
		 * instance.  The child is added
		 * at the index position specified. An index of 0 represents the back (bottom) 
		 * of the display list for this DisplayObjectContainer object.
		 * 
		 *   For example, the following example shows three display objects, labeled a, b, and c, at
		 * index positions 0, 2, and 1, respectively:If you add a child object that already has a different display object container as
		 * a parent, the object is removed from the child list of the other display object container.
		 * @param	child	The DisplayObject instance to add as a child of this 
		 *   DisplayObjectContainer instance.
		 * @param	index	The index position to which the child is added. If you specify a 
		 *   currently occupied index position, the child object that exists at that position and all
		 *   higher positions are moved up one position in the child list.
		 * @return	The DisplayObject instance that you pass in the 
		 *   child parameter.
		 * @langversion	3.0
		 * @playerversion	Flash 9
		 * @playerversion	Lite 4
		 * @throws	RangeError Throws if the index position does not exist in the child list.
		 * @throws	ArgumentError Throws if the child is the same as the parent.  Also throws if
		 *   the caller is a child (or grandchild etc.) of the child being added.
		 */
		function addChildAt (child:DisplayObject, index:int) : flash.display.DisplayObject;

		/**
		 * Indicates whether the security restrictions 
		 * would cause any display objects to be omitted from the list returned by calling
		 * the DisplayObjectContainer.getObjectsUnderPoint() method
		 * with the specified point point. By default, content from one domain cannot 
		 * access objects from another domain unless they are permitted to do so with a call to the 
		 * Security.allowDomain() method. For more information, related to security, 
		 * see the Flash Player Developer Center Topic: 
		 * Security.
		 * 
		 *   The point parameter is in the coordinate space of the Stage, 
		 * which may differ from the coordinate space of the display object container (unless the
		 * display object container is the Stage). You can use the globalToLocal() and 
		 * the localToGlobal() methods to convert points between these coordinate
		 * spaces.
		 * @param	point	The point under which to look.
		 * @return	true if the point contains child display objects with security restrictions.
		 * @langversion	3.0
		 * @playerversion	Flash 9
		 * @playerversion	Lite 4
		 */
		function areInaccessibleObjectsUnderPoint (point:Point) : Boolean;
		
		/**
		 * Determines whether the specified display object is a child of the DisplayObjectContainer instance or
		 * the instance itself. 
		 * The search includes the entire display list including this DisplayObjectContainer instance. Grandchildren, 
		 * great-grandchildren, and so on each return true.
		 * @param	child	The child object to test.
		 * @return	true if the child object is a child of the DisplayObjectContainer
		 *   or the container itself; otherwise false.
		 * @langversion	3.0
		 * @playerversion	Flash 9
		 * @playerversion	Lite 4
		 */
		function contains (child:DisplayObject) : Boolean;
		/**
		 * Returns the child display object instance that exists at the specified index.
		 * @param	index	The index position of the child object.
		 * @return	The child display object at the specified index position.
		 * @langversion	3.0
		 * @playerversion	Flash 9
		 * @playerversion	Lite 4
		 * @throws	RangeError Throws if the index does not exist in the child list.
		 * @throws	SecurityError This child display object belongs to a sandbox
		 *   to which you do not have access. You can avoid this situation by having
		 *   the child movie call Security.allowDomain().
		 */
		function getChildAt (index:int) : flash.display.DisplayObject;

		/**
		 * Returns the child display object that exists with the specified name.
		 * If more that one child display object has the specified name, 
		 * the method returns the first object in the child list.
		 * 
		 *   The getChildAt() method is faster than the 
		 * getChildByName() method. The getChildAt() method accesses 
		 * a child from a cached array, whereas the getChildByName() method
		 * has to traverse a linked list to access a child.
		 * @param	name	The name of the child to return.
		 * @return	The child display object with the specified name.
		 * @langversion	3.0
		 * @playerversion	Flash 9
		 * @playerversion	Lite 4
		 * @throws	SecurityError This child display object belongs to a sandbox
		 *   to which you do not have access. You can avoid this situation by having
		 *   the child movie call the Security.allowDomain() method.
		 */
		function getChildByName (name:String) : flash.display.DisplayObject;

		/**
		 * Returns the index position of a child DisplayObject instance.
		 * @param	child	The DisplayObject instance to identify.
		 * @return	The index position of the child display object to identify.
		 * @langversion	3.0
		 * @playerversion	Flash 9
		 * @playerversion	Lite 4
		 * @throws	ArgumentError Throws if the child parameter is not a child of this object.
		 */
		function getChildIndex (child:DisplayObject) : int;

		/**
		 * Returns an array of objects that lie under the specified point and are children 
		 * (or grandchildren, and so on) of this DisplayObjectContainer instance. Any child objects that
		 * are inaccessible for security reasons are omitted from the returned array. To determine whether 
		 * this security restriction affects the returned array, call the 
		 * areInaccessibleObjectsUnderPoint() method.
		 * 
		 *   The point parameter is in the coordinate space of the Stage, 
		 * which may differ from the coordinate space of the display object container (unless the
		 * display object container is the Stage). You can use the globalToLocal() and 
		 * the localToGlobal() methods to convert points between these coordinate
		 * spaces.
		 * @param	point	The point under which to look.
		 * @return	An array of objects that lie under the specified point and are children 
		 *   (or grandchildren, and so on) of this DisplayObjectContainer instance.
		 * @langversion	3.0
		 * @playerversion	Flash 9
		 * @playerversion	Lite 4
		 */
		function getObjectsUnderPoint (point:Point) : Array;

		/**
		 * Removes the specified child DisplayObject instance from the child list of the DisplayObjectContainer instance.  
		 * The parent property of the removed child is set to null
		 * , and the object is garbage collected if no other
		 * references to the child exist. The index positions of any display objects above the child in the 
		 * DisplayObjectContainer are decreased by 1.
		 * 
		 *   The garbage collector reallocates unused memory space. When a variable 
		 * or object is no longer actively referenced or stored somewhere, the garbage collector sweeps 
		 * through and wipes out the memory space it used to occupy if no other references to it exist.
		 * @param	child	The DisplayObject instance to remove.
		 * @return	The DisplayObject instance that you pass in the 
		 *   child parameter.
		 * @langversion	3.0
		 * @playerversion	Flash 9
		 * @playerversion	Lite 4
		 * @throws	ArgumentError Throws if the child parameter is not a child of this object.
		 */
		function removeChild (child:DisplayObject) : flash.display.DisplayObject;
		
		/**
		 * Removes a child DisplayObject from the specified index position in the child list of 
		 * the DisplayObjectContainer. The parent property of the removed child is set to 
		 * null, and the object is garbage collected if no other references to the child exist. The index  
		 * positions of any display objects above the child in the DisplayObjectContainer are decreased by 1.
		 * 
		 *   The garbage collector reallocates unused memory space. When a variable or
		 * object is no longer actively referenced or stored somewhere, the garbage collector sweeps 
		 * through and wipes out the memory space it used to occupy if no other references to it exist.
		 * @param	index	The child index of the DisplayObject to remove.
		 * @return	The DisplayObject instance that was removed.
		 * @langversion	3.0
		 * @playerversion	Flash 9
		 * @playerversion	Lite 4
		 * @throws	SecurityError This child display object belongs to a sandbox
		 *   to which the calling object does not have access. You can avoid this situation by having
		 *   the child movie call the Security.allowDomain() method.
		 * @throws	RangeError Throws if the index does not exist in the child list.
		 */
		function removeChildAt (index:int) : flash.display.DisplayObject;
		/**
		 * Removes all child DisplayObject instances from the child list of the DisplayObjectContainer instance.  
		 * The parent property of the removed children is set to null
		 * , and the objects are garbage collected if no other references to the children exist.
		 * 
		 *   The garbage collector reallocates unused memory space. When a variable 
		 * or object is no longer actively referenced or stored somewhere, the garbage collector sweeps 
		 * through and wipes out the memory space it used to occupy if no other references to it exist.
		 * @param	beginIndex	The beginning position. A value smaller than 0 throws a RangeError.
		 * @param	endIndex	The ending position. A value smaller than 0 throws a RangeError.
		 * @langversion	3.0
		 * @playerversion	AIR 3.0
		 * @playerversion	Flash 11
		 * @throws	RangeError Throws if the beginIndex or endIndex positions do not exist in the child list.
		 */
		function removeChildren (beginIndex:int=0, endIndex:int=2147483647) : void;

		/**
		 * Changes the  position of an existing child in the display object container.
		 * This affects the layering of child objects. For example, the following example shows three 
		 * display objects, labeled a, b, and c, at index positions 0, 1, and 2, respectively:
		 * 
		 *   When you use the setChildIndex() method and specify an index position
		 * that is already occupied, the only positions that change are those in between the display object's former and new position. 
		 * All others will stay the same. 
		 * If a child is moved to an index LOWER than its current index, all children in between will INCREASE by 1 for their index reference.
		 * If a child is moved to an index HIGHER than its current index, all children in between will DECREASE by 1 for their index reference.
		 * For example, if the display object container
		 * in the previous example is named container, you can swap the position 
		 * of the display objects labeled a and b by calling the following code:
		 * <codeblock>
		 * container.setChildIndex(container.getChildAt(1), 0);
		 * </codeblock>
		 * This code results in the following arrangement of objects:
		 * @param	child	The child DisplayObject instance for which you want to change
		 *   the index number.
		 * @param	index	The resulting index number for the child display object.
		 * @langversion	3.0
		 * @playerversion	Flash 9
		 * @playerversion	Lite 4
		 * @throws	RangeError Throws if the index does not exist in the child list.
		 * @throws	ArgumentError Throws if the child parameter is not a child of this object.
		 */
		function setChildIndex (child:DisplayObject, index:int) : void;
		
		/**
		 * Swaps the z-order (front-to-back order) of the two specified child objects.  All other child 
		 * objects in the display object container remain in the same index positions.
		 * @param	child1	The first child object.
		 * @param	child2	The second child object.
		 * @langversion	3.0
		 * @playerversion	Flash 9
		 * @playerversion	Lite 4
		 * @throws	ArgumentError Throws if either child parameter is not a child of this object.
		 */
		function swapChildren (child1:DisplayObject, child2:DisplayObject) : void;

		/**
		 * Swaps the z-order (front-to-back order) of the child objects at the two specified index positions in the 
		 * child list. All other child objects in the display object container remain in the same index positions.
		 * @param	index1	The index position of the first child object.
		 * @param	index2	The index position of the second child object.
		 * @langversion	3.0
		 * @playerversion	Flash 9
		 * @playerversion	Lite 4
		 * @throws	RangeError If either index does not exist in the child list.
		 */
		function swapChildrenAt (index1:int, index2:int) : void;
	}
}