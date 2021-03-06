/**
 * @author			Ahmed Nuaman (http://www.ahmednuaman.com)
 * @langversion		3
 * 
 * This work is licenced under the Creative Commons Attribution-Share Alike 2.0 UK: England & Wales License. 
 * To view a copy of this licence, visit http://creativecommons.org/licenses/by-sa/2.0/uk/ or send a letter 
 * to Creative Commons, 171 Second Street, Suite 300, San Francisco, California 94105, USA.
*/
package com.firestartermedia.lib.as3.utils
{
	import flash.external.ExternalInterface;
	
	public class GoogleUtil
	{
		public static function trackClick(page:String):void
		{
			try 
			{
				ExternalInterface.call( '_gaq.push', [ '_trackPageview', page ] );
			} catch (e:*) { }
		}
	}
}