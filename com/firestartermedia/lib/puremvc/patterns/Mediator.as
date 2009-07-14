/**
 * @author			Ahmed Nuaman (http://www.ahmednuaman.com)
 * @langversion		3
 * 
 * This work is licenced under the Creative Commons Attribution-Share Alike 2.0 UK: England & Wales License. 
 * To view a copy of this licence, visit http://creativecommons.org/licenses/by-sa/2.0/uk/ or send a letter 
 * to Creative Commons, 171 Second Street, Suite 300, San Francisco, California 94105, USA.
*/
package com.firestartermedia.lib.puremvc.patterns
{	
	import com.adobe.utils.ArrayUtil;
	import com.firestartermedia.lib.puremvc.events.SpriteEvent;
	
	import flash.utils.Dictionary;
	
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.mediator.Mediator;

	public class Mediator extends org.puremvc.as3.patterns.mediator.Mediator
	{
		protected var notificationInterests:Array				= [ ];
		protected var notificationHandlers:Dictionary			= new Dictionary();
		
		public function Mediator(name:String=null, viewComponent:Object=null)
		{
			super( name, viewComponent );
			
			trackEvent( 'Registered ' + name );
		}
		
		public function trackEvent(event:String):void
		{
			sendNotification( 'ApplicationFacadeTrack', event );
		}
				
		public function sendEvent(event:SpriteEvent):void
		{
			sendNotification( event.type, event.data );
		}
		
		public function declareNotificationInterest(notificationName:String, func:Function):void
		{
			notificationInterests.push( notificationName );
			
			notificationInterests = ArrayUtil.createUniqueCopy( notificationInterests );
			
			notificationHandlers[ notificationName ] = func;
		}
		
		override public function listNotificationInterests():Array
		{
			return notificationInterests;
		}
		
		override public function handleNotification(notification:INotification):void
		{
			notificationHandlers[ notification.getName() ].apply( null, [ notification ] );
		}
	}
}