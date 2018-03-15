package airdock.config 
{
	/**
	 * Base configuration class for creating a panel. 
	 * Extra attributes can be added for customizability, subject to the instance of the PanelFactory used by the Docker.
	 * @author Gimmick
	 */
	public class PanelConfig extends Object
	{
		private var u_color:uint;
		private var num_width:Number;
		private var num_height:Number;
		private var b_resizable:Boolean;
		private var b_dockable:Boolean;
		/**
		 * Creates a new panel configuration instance.
		 * By default, panels are resizable and dockable unless explicitly set otherwise.
		 */
		public function PanelConfig() {
			b_resizable = b_dockable = true;
		}
		
		/**
		 * The default background color of the panel, when it is created.
		 */
		public function get color():uint {
			return u_color;
		}
		
		/**
		 * The default background color of the panel, when it is created.
		 */
		public function set color(value:uint):void {
			u_color = value;
		}
		
		/**
		 * The default width of the panel, when it is created.
		 */
		public function get width():Number {
			return num_width;
		}
		
		/**
		 * The default width of the panel, when it is created.
		 */
		public function set width(value:Number):void {
			num_width = value;
		}
		
		/**
		 * The default height of the panel, when it is created.
		 */
		public function get height():Number {
			return num_height;
		}
		
		/**
		 * The default height of the panel, when it is created.
		 */
		public function set height(value:Number):void {
			num_height = value;
		}
		
		/**
		 * This attribute determines whether the panel is intended to be resizable, or not.
		 * However, it is up to the container whether to respect this attribute or to override it.
		 */
		public function get resizable():Boolean {
			return b_resizable;
		}
		
		/**
		 * This attribute determines whether the panel is intended to be resizable, or not.
		 * However, it is up to the container whether to respect this attribute or to override it.
		 */
		public function set resizable(value:Boolean):void {
			b_resizable = value;
		}
		/**
		 * A Boolean indicating whether the panel is dockable or not.
		 * Non-dockable panels cannot be removed from the root container which they are a part of, by the user.
		 */
		public function set dockable(value:Boolean):void {
			b_dockable = value;
		}
		
		/**
		 * A Boolean indicating whether the panel is dockable or not.
		 * Non-dockable panels cannot be removed from the root container which they are a part of, by the user.
		 */
		public function get dockable():Boolean {
			return b_dockable;
		}
	}

}