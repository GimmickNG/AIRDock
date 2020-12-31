package airdock.impl.filters 
{
	import airdock.interfaces.display.IDisplayFilter;
	import airdock.interfaces.display.IFilterable;
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	
	/**
	 * Mask filter which masks the content of the filterable within its bounds.
	 * For example, if this filter is applied on an IContainer, objects outside the visible bounds of the IContainer will be hidden.
	 * This filter has no extra parameters and so supports multiple targets.
	 * 
	 * @see airdock.interfaces.display.IDisplayFilter
	 * @see airdock.interfaces.display.IFilterable
	 * @author Gimmick
	 */
	public class MaskFilter implements IDisplayFilter
	{	
		private var dct_targets:Dictionary
		public function MaskFilter() {
			dct_targets = new Dictionary(true)
		}
		
		public function apply(filterable:IFilterable):void 
		{
			if(!(filterable in dct_targets)) {
				dct_targets[filterable] = new Sprite()
			}
			const sprite:Sprite = dct_targets[filterable];
			sprite.graphics.clear()
			sprite.graphics.beginFill(0)
			sprite.graphics.drawRect(0, 0, filterable.width, filterable.height)
			sprite.graphics.endFill()
			
			filterable.addChild(sprite)
			filterable.mask = sprite;
		}
		
		public function remove(filterable:IFilterable):void 
		{
			if(!(filterable in dct_targets)) {
				return
			}
			const sprite:Sprite = dct_targets[filterable];
			if (sprite.parent == filterable) {
				filterable.removeChild(sprite);
			}
			delete dct_targets[filterable];
		}
	}

}