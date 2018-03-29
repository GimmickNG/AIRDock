package airdock.decorators 
{
	import airdock.interfaces.docking.IContainer;
	import airdock.interfaces.docking.IPanel;
	import airdock.interfaces.ui.IPanelList;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	
	/**
	 * A decorator IContainer implementation which masks the content (panels and subcontainers) of the IContainer instance which it decorates.
	 * Use this when contents of one IContainer implementation is not guaranteed to fit within its bounds, and needs to be masked
	 * However, a slight overhead is incurred, mainly due to delegation and masking.
	 * 
	 * To use this decorator along with the Docker implementation, 
	 * (re)implement the default IContainerFactory implementation to create a decorator around the container 
	 * which is returned by the createContainer() method.
	 * @author Gimmick
	 */
	public class ContainerMask extends Sprite implements IContainer 
	{
		private var shp_mask:Shape;
		private var cl_container:IContainer;
		public function ContainerMask(container:IContainer) 
		{
			super();
			
			shp_mask = new Shape()
			createMask()
			
			cl_container = container
			container.mask = shp_mask
			
			addChild(container as DisplayObject)
			addChild(shp_mask)
		}
		
		private function createMask():void 
		{
			shp_mask.graphics.clear()
			shp_mask.graphics.beginFill(0xFF0000, 0.55)
			shp_mask.graphics.drawRect(0, 0, 100, 100)
			shp_mask.graphics.endFill()
		}
		
		override public function get width():Number {
			return cl_container.width
		}
		
		override public function get height():Number {
			return cl_container.height
		}
		
		override public function set width(value:Number):void {
			cl_container.width = shp_mask.width = value;
		}
		
		override public function set height(value:Number):void {
			cl_container.height = shp_mask.height = value;
		}
		
		public function addContainer(side:int, container:IContainer):IContainer {
			return cl_container.addContainer(side, container);
		}
		
		public function addToSide(side:int, panel:IPanel):IContainer {
			return cl_container.addToSide(side, panel);
		}
		
		public function get containerState():Boolean {
			return cl_container.containerState;
		}
		
		public function set containerState(value:Boolean):void {
			cl_container.containerState = value;
		}
		
		public function fetchSide(side:int):IContainer {
			return cl_container.fetchSide(side);
		}
		
		public function findPanel(panel:IPanel):IContainer {
			return cl_container.findPanel(panel);
		}
		
		public function flattenContainer():Boolean {
			return cl_container.flattenContainer();
		}
		
		public function getPanelCount(recursive:Boolean):int {
			return cl_container.getPanelCount(recursive);
		}
		
		public function getPanels(recursive:Boolean):Vector.<IPanel> {
			return cl_container.getPanels(recursive);
		}
		
		public function getSide(side:int):IContainer {
			return cl_container.getSide(side);
		}
		
		public function hasPanels(recursive:Boolean):Boolean {
			return cl_container.hasPanels(recursive);
		}
		
		public function get hasSides():Boolean {
			return cl_container.hasSides;
		}
		
		public function get maxSideSize():Number {
			return cl_container.maxSideSize;
		}
		
		public function set maxSideSize(value:Number):void {
			cl_container.maxSideSize = value;
		}
		
		public function mergeIntoContainer(container:IContainer):void {
			cl_container.mergeIntoContainer(container);
		}
		
		public function get minSideSize():Number {
			return cl_container.minSideSize;
		}
		
		public function set minSideSize(value:Number):void {
			cl_container.minSideSize = value;
		}
		
		public function get panelList():IPanelList {
			return cl_container.panelList;
		}
		
		public function set panelList(value:IPanelList):void {
			cl_container.panelList = value;
		}
		
		public function removeContainer(container:IContainer):IContainer {
			return cl_container.removeContainer(container);
		}
		
		public function removePanel(panel:IPanel):IContainer {
			return cl_container.removePanel(panel);
		}
		
		public function removePanels(recursive:Boolean):int {
			return cl_container.removePanels(recursive);
		}
		
		public function setContainers(sideCode:int, currentSide:IContainer, otherSide:IContainer):void {
			cl_container.setContainers(sideCode, currentSide, otherSide);
		}
		
		public function get sideCode():int {
			return cl_container.sideCode;
		}
		
		public function get sideSize():Number {
			return cl_container.sideSize;
		}
		
		public function set sideSize(value:Number):void {
			cl_container.sideSize = value;
		}
	}

}