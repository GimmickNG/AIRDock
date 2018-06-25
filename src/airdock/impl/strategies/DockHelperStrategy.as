package airdock.impl.strategies 
{
	import airdock.events.PanelContainerEvent;
	import airdock.events.PropertyChangeEvent;
	import airdock.interfaces.docking.IBasicDocker;
	import airdock.interfaces.docking.IContainer;
	import airdock.interfaces.docking.ICustomizableDocker;
	import airdock.interfaces.docking.IDockFormat;
	import airdock.interfaces.docking.IDragDockFormat;
	import airdock.interfaces.docking.ITreeResolver;
	import airdock.interfaces.strategies.IDockerStrategy;
	import airdock.interfaces.ui.IDockHelper;
	import airdock.util.IDisposable;
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardTransferMode;
	import flash.display.DisplayObject;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.NativeWindowType;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.NativeDragEvent;
	import flash.events.NativeWindowBoundsEvent;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	/**
	 * The resizer manager class decides when to display and hide the resizer of the Docker whose resizer it manages.
	 * It also handles the resizing of containers as per the resizer's actions.
	 * @author Gimmick
	 */
	public class DockHelperStrategy implements IDockerStrategy, IEventDispatcher, IDisposable
	{
		private var dct_containers:Dictionary;
		private var nwnd_dockerWindow:NativeWindow;
		private var cl_hostDocker:ICustomizableDocker;
		public function DockHelperStrategy() {
			dct_containers = new Dictionary(true);
		}
		
		public function setup(baseDocker:IBasicDocker):void
		{
			if (cl_hostDocker)
			{
				removeDockerListeners(cl_hostDocker)
				if (dct_containers)
				{
					for (var container:Object in dct_containers) {
						removeContainerListeners(container as IContainer)	//also clears dictionary
					}
				}
			}
			
			if(!(baseDocker && baseDocker is ICustomizableDocker)) {
				throw new ArgumentError("Error: Argument baseDocker must be a non-null ICustomizableDocker instance.");
			}
			var customizableDocker:ICustomizableDocker = ICustomizableDocker(baseDocker);
			cl_hostDocker = customizableDocker;
			addDockerListeners(baseDocker);
			createWindow(baseDocker)
		}
		
		private function createWindow(baseDocker:IBasicDocker):void 
		{
			var mainContainer:DisplayObject = baseDocker.mainContainer
			var lightWeightOptions:NativeWindowInitOptions = new NativeWindowInitOptions()
			lightWeightOptions.maximizable = lightWeightOptions.minimizable = lightWeightOptions.resizable = false;
			lightWeightOptions.systemChrome = NativeWindowSystemChrome.NONE
			lightWeightOptions.type = NativeWindowType.LIGHTWEIGHT;
			lightWeightOptions.transparent = true;
			if(mainContainer && mainContainer.stage) {
				lightWeightOptions.owner = mainContainer.stage.nativeWindow
			}
			
			nwnd_dockerWindow = new NativeWindow(lightWeightOptions)
			nwnd_dockerWindow.stage.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, changeDockHelperState, false, 0, true)
		}
		
		public function dispose():void
		{
			removeDockerListeners(cl_hostDocker)
			for (var container:Object in dct_containers) {
				removeContainerListeners(container as IContainer)	//also clears dictionary
			}
			nwnd_dockerWindow.stage.removeEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, changeDockHelperState)
			nwnd_dockerWindow.close();
			cl_hostDocker = null;
		}
		
		private function removeDockerListeners(docker:IBasicDocker):void
		{
			docker.removeEventListener(PanelContainerEvent.CONTAINER_REMOVED, removeContainerListenersOnEvent)
			docker.removeEventListener(PanelContainerEvent.CONTAINER_CREATED, addContainerListenersOnEvent)
			docker.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGED, changeDockHelperListeners)
		}
		
		private function changeDockHelperListeners(evt:PropertyChangeEvent):void 
		{
			if (evt.fieldName == "mainContainer")
			{
				var prevContainer:DisplayObject = evt.oldValue as DisplayObject
				var newContainer:DisplayObject = evt.newValue as DisplayObject
				if (newContainer) {
					newContainer.addEventListener(NativeDragEvent.NATIVE_DRAG_COMPLETE, changeDockHelperState, false, 0, true)
				}
				if (prevContainer) {
					prevContainer.removeEventListener(NativeDragEvent.NATIVE_DRAG_COMPLETE, changeDockHelperState)
				}
			}
			else if(evt.fieldName == "dockHelper")
			{
				var prevHelper:DisplayObject = evt.oldValue as DisplayObject
				var dockHelper:IDockHelper = evt.newValue as IDockHelper
				nwnd_dockerWindow.stage.removeChildren()
				removeDockHelperListeners(prevHelper)
				addDockHelperListeners(dockHelper)
				if (dockHelper)
				{
					dockHelper.setDockFormat(dockFormat.panelFormat, dockFormat.containerFormat)
					dockHelper.draw(dockHelper.getDefaultWidth(), dockHelper.getDefaultHeight());
					
					nwnd_dockerWindow.stage.stageWidth = dockHelper.width
					nwnd_dockerWindow.stage.stageHeight = dockHelper.height
					nwnd_dockerWindow.stage.addChild(dockHelper as DisplayObject)
				}
			}
		}
		
		private function addDockHelperListeners(dockHelper:IDockHelper):void 
		{
			if (dockHelper)
			{
				dockHelper.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, changeDockHelperState, false, 0, true)
				dockHelper.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, changeDockHelperState, false, 0, true)
			}
		}
		
		private function removeDockHelperListeners(dockHelper:DisplayObject):void 
		{
			if (dockHelper)
			{
				dockHelper.removeEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, changeDockHelperState)
				dockHelper.removeEventListener(NativeDragEvent.NATIVE_DRAG_DROP, changeDockHelperState)
			}
		}
		
		private function addDockerListeners(docker:IBasicDocker):void
		{
			docker.addEventListener(PropertyChangeEvent.PROPERTY_CHANGED, changeDockHelperListeners, false, 0, true)
			docker.addEventListener(PanelContainerEvent.CONTAINER_CREATED, addContainerListenersOnEvent, false, 0, true)
			docker.addEventListener(PanelContainerEvent.CONTAINER_REMOVED, removeContainerListenersOnEvent, false, 0, true)
		}
		
		private function removeContainerListenersOnEvent(evt:PanelContainerEvent):void {
			removeContainerListeners(evt.relatedContainer);
		}
		
		private function addContainerListenersOnEvent(evt:PanelContainerEvent):void {
			addContainerListeners(evt.relatedContainer);
		}
		
		private function addContainerListeners(container:IContainer):void 
		{
			if(container in dct_containers) {
				return;
			}
			container.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, changeDockHelperState, false, 0, true)
			container.addEventListener(NativeDragEvent.NATIVE_DRAG_EXIT, changeDockHelperState, false, 0, true)
			dct_containers[container] = true;	//value does not matter as much as key
		}
		
		private function removeContainerListeners(container:IContainer):void 
		{
			if(!(container in dct_containers)) {
				return;
			}
			delete dct_containers[container];
			container.removeEventListener(NativeDragEvent.NATIVE_DRAG_EXIT, changeDockHelperState)
			container.removeEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, changeDockHelperState)
		}
		
		private function changeDockHelperState(evt:NativeDragEvent):void 
		{
			var type:String = evt.type
			var clipBoard:Clipboard = evt.clipboard;
			if (!(dockHelper && isCompatibleClipboard(clipBoard))) {
				return;
			}
			else if (type == NativeDragEvent.NATIVE_DRAG_ENTER)
			{
				var targetContainer:IContainer = (evt.target as IContainer) || treeResolver.findParentContainer(evt.target as DisplayObject)
				var clipboardContainer:IContainer = clipBoard.getData(dockFormat.containerFormat, ClipboardTransferMode.ORIGINAL_ONLY) as IContainer;
				var dropContainerInfo:IDragDockFormat = clipBoard.getData(dockFormat.destinationFormat, ClipboardTransferMode.ORIGINAL_ONLY) as IDragDockFormat
				if (evt.currentTarget == dockHelper) {
					dropContainerInfo.sideSequence = dockHelper.getSideFrom(evt.target as DisplayObject)
				}
				else if (targetContainer && !targetContainer.hasSides)
				{
					var targetWindow:NativeWindow = targetContainer.stage.nativeWindow
					var centerPoint:Point = new Point(0.5 * (targetContainer.width - dockHelper.width), 0.5 * (targetContainer.height - dockHelper.height))
					var stageCoordinates:Point = targetWindow.globalToScreen(targetContainer.localToGlobal(centerPoint))
					
					dockHelper.show()
					stageCoordinates.x = int(stageCoordinates.x)
					stageCoordinates.y = int(stageCoordinates.y)
					if (stageCoordinates.equals(nwnd_dockerWindow.bounds.topLeft)) {
						showDockHelperOnMove(null)
					}
					else
					{
						nwnd_dockerWindow.addEventListener(NativeWindowBoundsEvent.MOVE, showDockHelperOnMove, false, 0, true);
						nwnd_dockerWindow.x = stageCoordinates.x
						nwnd_dockerWindow.y = stageCoordinates.y
					}
					dropContainerInfo.destinationContainer = targetContainer
				}
			}
			else if(evt.type == NativeDragEvent.NATIVE_DRAG_DROP || evt.type == NativeDragEvent.NATIVE_DRAG_COMPLETE || !evt.relatedObject || nwnd_dockerWindow.stage.contains(evt.relatedObject)) {
				nwnd_dockerWindow.visible = false;
			}
		}
		
		private function showDockHelperOnMove(evt:Event):void
		{
			nwnd_dockerWindow.visible = true;
			nwnd_dockerWindow.orderToFront();
			nwnd_dockerWindow.removeEventListener(NativeWindowBoundsEvent.MOVE, showDockHelperOnMove)
		}
		
		private function get dockHelper():IDockHelper {
			return cl_hostDocker.dockHelper as IDockHelper
		}
		
		private function get dockFormat():IDockFormat {
			return cl_hostDocker.dockFormat as IDockFormat
		}
		
		private function get treeResolver():ITreeResolver {
			return cl_hostDocker.treeResolver as ITreeResolver;
		}
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			cl_hostDocker.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function dispatchEvent(event:Event):Boolean {
			return cl_hostDocker.dispatchEvent(event);
		}
		
		public function hasEventListener(type:String):Boolean {
			return cl_hostDocker.hasEventListener(type);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			cl_hostDocker.removeEventListener(type, listener, useCapture);
		}
		
		public function willTrigger(type:String):Boolean {
			return cl_hostDocker.willTrigger(type);
		}
		
		[Inline]
		private function isCompatibleClipboard(clipboard:Clipboard):Boolean {
			return clipboard.hasFormat(dockFormat.panelFormat) || clipboard.hasFormat(dockFormat.containerFormat)
		}
	}

}