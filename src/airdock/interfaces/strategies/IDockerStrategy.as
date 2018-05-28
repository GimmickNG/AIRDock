package airdock.interfaces.strategies 
{
	import airdock.interfaces.docking.IBasicDocker;
	
	/**
	 * The IDockerStrategy interface is (intended to be) used in IBasicDocker implementations for dynamically modifying the method of docking.
	 * @author Gimmick
	 */
	public interface IDockerStrategy {
		function setup(baseDocker:IBasicDocker):void;
	}
	
}