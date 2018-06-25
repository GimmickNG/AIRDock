package airdock.delegates 
{
	import airdock.enums.ContainerSide;
	import airdock.interfaces.ui.IDockHelper;
	import flash.desktop.NativeDragManager;
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.NativeDragEvent;
	import flash.utils.Dictionary;
	
	/**
	 * ...
	 * @author	Gimmick
	 */
	public class DockHelperDelegate implements IEventDispatcher
	{
		private var str_panelFormat:String;
		private var cl_dockHelper:IDockHelper;
		private var dct_dockTargets:Dictionary;
		private var str_containerFormat:String;
		public function DockHelperDelegate(dockHelper:IDockHelper)
		{
			cl_dockHelper = dockHelper;
			dct_dockTargets = new Dictionary(true)
			dockHelper.addEventListener(NativeDragEvent.NATIVE_DRAG_OVER, displayTargetsOnDrag, false, 0, true)
			dockHelper.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, displayTargetsOnDrag, false, 0, true)
		}
		
		/**
		 * Adds the target specified to the list of all dock helper candidates/targets.
		 * Each target is the target DisplayObject associated with the side it represents.
		 * The side is the side that a container or panel will be attached to when dropped on the target.
		 * @param	target	The target DisplayObject instance.
		 * @param	side	The side(s) which the target is associated with as a String.
		 * 					Multiple sides can be added as a string sequence of sides.
		 */
		public function addTarget(target:DisplayObject, side:String):void {
			dct_dockTargets[target] = side;
		}
		
		public function removeTarget(target:DisplayObject):void {
			delete dct_dockTargets[target];
		}
		
		public function getSideFrom(dropTarget:DisplayObject):String {
			return dct_dockTargets[dropTarget] || ContainerSide.FILL
		}
		
		public function get targets():Vector.<DisplayObject>
		{
			var targets:Vector.<DisplayObject> = new Vector.<DisplayObject>()
			for (var obj:Object in dct_dockTargets) {
				targets.push(obj)
			}
			return targets;
		}
		
		private function displayTargetsOnDrag(evt:NativeDragEvent):void 
		{
			var currentTarget:InteractiveObject = evt.target as InteractiveObject
			if ((currentTarget in dct_dockTargets && (evt.clipboard.hasFormat(str_panelFormat) || evt.clipboard.hasFormat(str_containerFormat))))
			{
				cl_dockHelper.hide()	//show only the current target
				cl_dockHelper.show(new <DisplayObject>[currentTarget])
				NativeDragManager.acceptDragDrop(currentTarget)
			}
		}
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			cl_dockHelper.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function dispatchEvent(event:Event):Boolean {
			return cl_dockHelper.dispatchEvent(event);
		}
		
		public function hasEventListener(type:String):Boolean {
			return cl_dockHelper.hasEventListener(type);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			cl_dockHelper.removeEventListener(type, listener, useCapture);
		}
		
		public function willTrigger(type:String):Boolean {
			return cl_dockHelper.willTrigger(type);
		}
		
		public function setDockFormat(panelFormat:String, containerFormat:String):void 
		{
			str_panelFormat = panelFormat;
			str_containerFormat = containerFormat;
		}
	}

}