package airdock.util 
{
	
	/**
	 * The interface declaring the methods which an implementing class must define to qualify as disposable.
	 * A class which is disposable must be manually disposed of by calling its dispose() method.
	 * This is because such classes cannot automatically clear themselves when all references to them are lost.
	 * In some cases, they may even persist, extending the active lifetime of the application.
	 * @author Gimmick
	 */
	public interface IDisposable {
		function dispose():void;
	}
	
}