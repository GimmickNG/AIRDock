package airdock.enums 
{
	/**
	 * ...
	 * @author Gimmick
	 */
	public class CrossDockingPolicy 
	{
		/**
		 * No restrictions on docking. 
		 * Panels from the Docker with this policy can be attached to Dockers which allow incoming panels;
		 * panels from other Dockers can be attached to containers originating from the Docker with this policy.
		 */
		public static const UNRESTRICTED:int = 0;
		/**
		 * Prevents panels from other Dockers from being attached to containers originating from the Docker with this policy.
		 */
		public static const REJECT_INCOMING:int = 1;
		/**
		 * Prevents panels from the Docker with this policy from being attached to containers originating from other Dockers, regardless of their docking policies.
		 */
		public static const PREVENT_OUTGOING:int = 2;
		/**
		 * Alias for (REJECT_INCOMING | PREVENT_OUTGOING);
		 * in effect, prevents panels from other Dockers being attached to containers originating from the current Docker 
		 * and prevents panels from this Docker from being attached to containers originating from other Dockers, regardless of their policies.
		 */
		public static const INTERNAL_ONLY:int = 3;
		public function CrossDockingPolicy() { }
		
	}

}