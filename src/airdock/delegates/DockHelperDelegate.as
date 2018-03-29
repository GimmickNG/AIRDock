package airdock.delegates 
{
	import airdock.enums.PanelContainerSide;
	import airdock.events.DockEvent;
	import airdock.interfaces.ui.IDockHelper;
	import airdock.util.IPair;
	import flash.desktop.NativeDragManager;
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.NativeDragEvent;
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Gimmick
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
			dockHelper.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, acceptDragDrop, false, 0, true)
			dockHelper.addEventListener(NativeDragEvent.NATIVE_DRAG_OVER, displayTargetsOnDrag, false, 0, true)
		}
		
		public function addTarget(target:DisplayObject, side:int):void {
			dct_dockTargets[target] = side;
		}
		
		/**
		 * Adds the targets specified to the list of all dock helper candidates/targets.
		 * Each target is a key-value pair with the key as the target displayObject and the value as the side which it represents, or the side that a container or panel will be attached to when dropped on that target.
		 * @param	targets	A Vector of key-value pairs with the key as the target displayObject and the value as the side which it represents.
		 * @see	airdock.util.IPair
		 */
		public function addTargets(targets:Vector.<IPair>):void
		{
			for (var i:uint = 0; i < targets.length; ++i)
			{
				var target:IPair = targets[i];
				if (target && target.key is DisplayObject && target.value !== null) {
					addTarget(target.key as DisplayObject, int(target.value));
				}
			}
		}
		
		public function removeTarget(target:DisplayObject):void {
			delete dct_dockTargets[target];
		}
		
		public function removeTargets(targets:Vector.<DisplayObject>):void
		{
			for (var i:uint = 0; i < targets.length; ++i)
			{
				var target:DisplayObject = targets[i] as DisplayObject
				if(target) {
					removeTarget(target)
				}
			}
		}
		
		public function getSideFrom(dropTarget:DisplayObject):int
		{
			if(dropTarget in dct_dockTargets) {
				return int(dct_dockTargets[dropTarget])
			}
			return PanelContainerSide.FILL
		}
		
		public function get targets():Vector.<DisplayObject>
		{
			var targets:Vector.<DisplayObject> = new Vector.<DisplayObject>()
			for(var obj:Object in dct_dockTargets) {
				targets.push(obj)
			}
			return targets;
		}
		
		/**
		 * Dispatches a DockEvent when the user has dropped the panel or container on any of the sprites of this object, prior to the end of the drag-dock action.
		 */
		private function acceptDragDrop(evt:NativeDragEvent):void
		{
			if (evt.clipboard.hasFormat(str_panelFormat) && evt.clipboard.hasFormat(str_containerFormat)) {
				dispatchEvent(new DockEvent(DockEvent.DRAG_COMPLETING, evt.clipboard, evt.target as DisplayObject, true, true))
			}
		}
		
		private function displayTargetsOnDrag(evt:NativeDragEvent):void 
		{
			var currentTarget:InteractiveObject = evt.target as InteractiveObject
			if (!(currentTarget in dct_dockTargets && evt.clipboard.hasFormat(str_panelFormat) && evt.clipboard.hasFormat(str_containerFormat))) {
				return;
			}
			cl_dockHelper.hide();									//hides all the targets
			cl_dockHelper.show(new <DisplayObject>[currentTarget])	//except the current one
			NativeDragManager.acceptDragDrop(currentTarget)
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