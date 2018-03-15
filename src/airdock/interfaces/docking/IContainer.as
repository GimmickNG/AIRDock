package airdock.interfaces.docking 
{
	import airdock.interfaces.display.IDisplayObjectContainer;
	import airdock.interfaces.ui.IPanelList;
	
	/**
	 * The interface defining the set of methods that a (display)object must fulfil in order to allow the Docker to attach panels to it and participate in docking.
	 * @author Gimmick
	 */
	public interface IContainer extends IDisplayObjectContainer
	{
		/**
		 * Gets the IContainer instance for a given side, as an integer.
		 * This method does not guarantee that the container will be created, if it does not exist.
		 * For the method that automatically creates a side if it does not exist, see the fetchSide() function.
		 * @param	side	The side to get the container of, as an integer.
		 * @return	The container for the given side. May be null if the side does not exist for the container.
		 * @see #fetchSide()
		 */
		function getSide(side:int):IContainer
		
		/**
		 * Adds a container to the side specified. The container may automatically create the complementary side, depending on the implementation.
		 * @param	side	The side to attach the container to.
		 * @param	container	The container to attach as a child of (i.e. below) this container.
		 * @return	The container supplied in the container parameter, or the container into which it is merged, if it already exists in the current container. This can be used to chain operations, or to get the new container if merges are used instead of direct child additions.
		 */
		function addContainer(side:int, container:IContainer):IContainer
		
		/**
		 * Adds the panel to the side specified. The container automatically creates the container if it does not exist.
		 * @param	side	The side to attach the panel to.
		 * @param	panel	The panel to attach as a part of (i.e. in) this container, or as a side underneath, if it does not exist.
		 * @return	The container to which the panel is attached. This may be the same container (if the side is FILL), or a container below it otherwise.
		 */
		function addToSide(side:int, panel:IPanel):IContainer
		
		/**
		 * Recursively searches for the container which contains the supplied panel.
		 * @param	panel	The panel to search for, within the container or subcontainers of this container (if any).
		 * @return	The container which contains the supplied panel. If the panel is not found, null is returned.
		 */
		function findPanel(panel:IPanel):IContainer;
		
		/**
		 * Recursively searches for, and removes, the panel supplied from the current container, and returns the container which previously contained it.
		 * If the panel is not part of this container or any container below it, null is returned.
		 * @param	panel	The panel to remove from the container or any subcontainer which contains the panel.
		 * @return	The container which previously contained the panel, prior to its removal. If the panel was not found, null is returned.
		 */
		function removePanel(panel:IPanel):IContainer
		
		/**
		 * Recursively searches for, and removes, the supplied container from the current container, and returns the container which previously contained it.
		 * @param	container	The container to remove from the container or any subcontainer which contains it.
		 * @return	The container which contained the supplied container, prior to its removal. If the container was not found, null is returned.
		 */
		function removeContainer(container:IContainer):IContainer
		
		/**
		 * Gets the given side from the container. Creates it if it does not exist.
		 * @param	side
		 * @return
		 */
		function fetchSide(side:int):IContainer
		
		/**
		 * Sets the containers for the current container, and sets the side code of the current container to match that of the side supplied.
		 * Any containers which were previously part of the current container are removed.
		 * @param	sideCode	The new side for the container.
		 * @param	currentSide	The new current side for the container.
		 * @param	otherSide	The new (complementary) side for the container.
		 */
		function setContainers(sideCode:int, currentSide:IContainer, otherSide:IContainer):void;
		
		/**
		 * Merges the contents of the current container into the destination container, and empties the current container in the process.
		 * In effect, it empties the container (node) into another container, by transferring all its children and its branches into the other container.
		 * @param	container	The container into which the current container should be merged into.
		 */
		function mergeIntoContainer(container:IContainer):void;
		
		/**
		 * Removes all the panels in this container. If recursive is set to true, then all panels in subcontainers (i.e. containers below the current container) are also removed.
		 * @param	recursive	A Boolean indicating whether subcontainers are to have their panels removed as well.
		 * @return	An integer corresponding to the number of panels removed.
		 */
		function removePanels(recursive:Boolean):int;
		
		/**
		 * Recursively flattens the structure of the current container by merging its subcontainers into it.
		 * Effectively moves all the panels in containers which are below it, into the current container.
		 * @return	A Boolean indicating whether the operation was a success or not. If there were no subcontainers to flatten, then this returns false.
		 */
		function flattenContainer():Boolean;
		
		/**
		 * Gets the number of panels that this container has directly under it.
		 * If recursive is true, then the number of panels of all the subcontainers below it is also counted.
		 * @param	recursive	A Boolean indicating whether the current container's subcontainers' panels should also be counted or not.
		 * @return	The number of panels in this container, and/or the containers below it (if recursive.)
		 */
		function getPanelCount(recursive:Boolean):int;
		
		/**
		 * Checks whether there are any panels directly contained by the current container.
		 * If recursive is true, then it checks whether any of the current container's subcontainers have any panels.
		 * @param	recursive	A Boolean indicating whether the current container's subcontainers' panels should also be checked or not.
		 * @return	A Boolean indicating whether the current container has any panels, or if the containers below it have any (if recursive.)
		 */
		function hasPanels(recursive:Boolean):Boolean;
		
		/**
		 * Returns a vector of all the panels directly under this container.
		 * If recursive is specified, then the vector of panels which are in the current container's subcontainers are also retrieved, in preorder form.
		 * @param	recursive	A Boolean indicating whether the current container's subcontainers' panels should also be checked or not.
		 * @return	A Vector of IPanel instances, all of which are contained directly by this container and/or indirectly (i.e. by subcontainers of the current container), if recursive search is specified.
		 */
		function getPanels(recursive:Boolean):Vector.<IPanel>
		
		/**
		 * Indicates whether the current container has any containers directly below it or not. Read-only.
		 */
		function get hasSides():Boolean
		
		/**
		 * The current side for this container. Read-only.
		 * A container can have any of the sides mentioned in the PanelContainerSide enumeration class.
		 * Some implementations also have a complementary container created as well, which is complementary to the current side code.
		 * @see airdock.enums.PanelContainerSide
		 */
		function get sideCode():int
		
		/**
		 * An IPanelList instance created by the Docker's IPanelListFactory for this container.
		 * May or may not be graphical (i.e. may or may not be part of the display list.)
		 * @see airdock.interfaces.ui.IPanelList
		 */
		function get panelList():IPanelList
		
		/**
		 * An IPanelList instance created by the Docker's IPanelListFactory for this container.
		 * May or may not be graphical (i.e. may or may not be part of the display list.)
		 * @see airdock.interfaces.ui.IPanelList
		 */
		function set panelList(panelList:IPanelList):void
		
		/**
		 * The size of the current side, if it has sides, or the size that the container corresponding to the current side will take, if it is created at any point in the future.
		 * This can be either width or height based, depending on whether the side is LEFT or RIGHT, or TOP or BOTTOM respectively.
		 * Values less than 1 are taken as a percentage of the total side width or height.
		 * @see airdock.enums.PanelContainerSide
		 */
		function get sideSize():Number
		
		/**
		 * The size of the current side, if it has sides, or the size that the container corresponding to the current side will take, if it is created at any point in the future.
		 * This can be either width or height based, depending on whether the side is LEFT or RIGHT, or TOP or BOTTOM respectively.
		 * Values less than 1 are taken as a percentage of the total side width or height.
		 * @see airdock.enums.PanelContainerSide
		 */
		function set sideSize(size:Number):void
		
		/**
		 * The maximum size the current container's current side container can take, if specified. Setting this to NaN clears the restriction.
		 * This can be either width or height based, depending on whether the side is LEFT or RIGHT, or TOP or BOTTOM respectively.
		 * Values less than 1 are taken as a percentage of the total side width or height.
		 * 
		 * If the maximum is greater than the size of the container, then it is ignored in favor of the size of the container.
		 * @see airdock.enums.PanelContainerSide
		 */
		function get maxSideSize():Number;
		
		/**
		 * The maximum size the current container's current side container can take, if specified. Setting this to NaN clears the restriction.
		 * This can be either width or height based, depending on whether the side is LEFT or RIGHT, or TOP or BOTTOM respectively.
		 * Values less than 1 are taken as a percentage of the total side width or height.
		 * 
		 * If the maximum is greater than the size of the container, then it is ignored in favor of the size of the container.
		 * @see airdock.enums.PanelContainerSide
		 */
		function set maxSideSize(value:Number):void;
		
		/**
		 * The minimum size the current container's current side container can take, if specified. Setting this to NaN clears the restriction.
		 * This can be either width or height based, depending on whether the side is LEFT or RIGHT, or TOP or BOTTOM respectively.
		 * Values less than 1 are taken as a percentage of the total side width or height.
		 * 
		 * Values lesser than 0 are interpreted as 0.
		 * @see airdock.enums.PanelContainerSide
		 */
		function get minSideSize():Number;
		
		/**
		 * The minimum size the current container's current side container can take, if specified. Setting this to NaN clears the restriction.
		 * This can be either width or height based, depending on whether the side is LEFT or RIGHT, or TOP or BOTTOM respectively.
		 * Values less than 1 are taken as a percentage of the total side width or height.
		 * 
		 * Values lesser than 0 are interpreted as 0.
		 * @see airdock.enums.PanelContainerSide
		 */
		function set minSideSize(value:Number):void;
		
		/**
		 * The state of the container, as defined in the PanelContainerState enumeration class.
		 * Automatically generated parked containers are always set as DOCKED; containers which are created by the user, or by the createContainer() method are always set as INTEGRATED.
		 * Containers which are part of a parked container may not always have the correct state value, as they are independent of their parent containers (i.e. they may not have any knowledge of their parent containers, depending on the implementation.)
		 * In that case, use the tree resolver of the Docker instance to find the root container, whose container state is the actual container state.
		 * 
		 * While this value can be changed, it is advised not to do so, as changing it without caution can result in unexpected behavior.
		 */
		function get containerState():Boolean;
		
		/**
		 * The state of the container, as defined in the PanelContainerState enumeration class.
		 * Automatically generated parked containers are always set as DOCKED; containers which are created by the user, or by the createContainer() method are always set as INTEGRATED.
		 * Containers which are part of a parked container may not always have the correct state value, as they are independent of their parent containers (i.e. they may not have any knowledge of their parent containers, depending on the implementation.)
		 * In that case, use the tree resolver of the Docker instance to find the root container, whose container state is the actual container state.
		 * 
		 * While this value can be changed, it is advised not to do so, as changing it without caution can result in unexpected behavior.
		 * @private
		 */
		function set containerState(value:Boolean):void
	}
	
}