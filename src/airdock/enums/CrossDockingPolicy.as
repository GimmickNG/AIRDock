package airdock.enums 
{
	/**
	 * Enumeration class dictating the cross docking policy for a given Docker instance.
	 * A cross docking policy is that policy which decides whether a panel or container can:
	 * * Outgoing - Attach to another container which is not originating from (i.e. has not been created by) its Docker
	 * * Incoming - Have another panel or container, which is not originating from its Docker, be attached to it
	 * * Both - allow or forbid both actions.
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
		 * Prevents panels from the Docker with this policy from being attached to containers originating from other Dockers, regardless of their docking policies.
		 */
		public static const PREVENT_OUTGOING:int = 1;
		/**
		 * Prevents panels from other Dockers from being attached to containers originating from the Docker with this policy.
		 * This has a higher priority than PREVENT_OUTGOING; in effect, if one Docker has the PREVENT_OUTGOING policy and the other has the REJECT_INCOMING policy,
		 * then the second Docker will reject it before the first can prevent the action.
		 */
		public static const REJECT_INCOMING:int = 2;
		/**
		 * Alias for (PREVENT_OUTGOING | REJECT_INCOMIN);
		 * in effect, prevents panels from other Dockers being attached to containers originating from the current Docker 
		 * and prevents panels from this Docker from being attached to containers originating from other Dockers, regardless of their policies.
		 */
		public static const INTERNAL_ONLY:int = 3;
		
		public function CrossDockingPolicy() { }
	}

}