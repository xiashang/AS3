/**
 * @author			Ahmed Nuaman (http://www.ahmednuaman.com)
 * @langversion		3
 * 
 * This work is licenced under the Creative Commons Attribution-Share Alike 2.0 UK: England & Wales License. 
 * To view a copy of this licence, visit http://creativecommons.org/licenses/by-sa/2.0/uk/ or send a letter 
 * to Creative Commons, 171 Second Street, Suite 300, San Francisco, California 94105, USA.
*/
package com.firestartermedia.lib.as3.display.component.video
{
	import com.firestartermedia.lib.as3.events.WebCamEvent;
	import com.firestartermedia.lib.as3.utils.BitmapUtil;
	import com.firestartermedia.lib.as3.utils.DateUtil;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.NetStatusEvent;
	import flash.events.StatusEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;

	public class WebCam extends Sprite
	{
		public var recordingName:String							= 'Recording' + DateUtil.toNumericalTimestamp( new Date() );
		
		private var hasBeenDenyed:Boolean						= false;
		private var isRecording:Boolean							= false;
		
		public var captureURL:String;
		
		private var _reflect:Boolean;
		private var bandwidth:Number;
		private var camera:Camera;
		private var cameraHeight:Number;
		private var cameraWidth:Number;
		private var connection:NetConnection;
		private var microphone:Microphone;
		private var quality:Number;
		private var stream:NetStream;
		private var video:Video;
		
		public function WebCam(width:Number=320, height:Number=240, bandwidth:Number=0, quality:Number=90)
		{
			cameraHeight	= height;
			cameraWidth		= width;
			
			this.bandwidth	= bandwidth;
			this.quality	= quality;
		}
		
		public function init():void
		{
			var index:int = 0;
			
			for ( var i:int = 0; i < Camera.names.length; i++ ) 
			{
				if ( Camera.names[ i ] == 'USB Video Class Video' ) 
				{
					index = i;
				}
			}
			
			camera = Camera.getCamera( index.toString() );
			
			if ( camera == null )
			{
				dispatchEvent( new WebCamEvent( WebCamEvent.NO_WEBCAM ) );
				
				return;
			}
			
			if ( camera.muted && hasBeenDenyed )
			{
				dispatchEvent( new WebCamEvent( WebCamEvent.NO_WEBCAM ) );
				
				return;
			}
			
			camera.addEventListener( StatusEvent.STATUS, handleCameraStatus );
			
			camera.setMode( cameraWidth, cameraHeight, 20, true );
			camera.setQuality( bandwidth, quality );
			
			microphone = Microphone.getMicrophone();
			
			video = new Video( cameraWidth, cameraHeight );
			
			video.smoothing		= true;
			
			video.attachCamera( camera );
			
			addChild( video );
		}
		
		private function handleCameraStatus(e:StatusEvent):void
		{
			switch ( e.code )
			{
				case 'Camera.Muted':
					hasBeenDenyed	= true;
					
					dispatchEvent( new WebCamEvent( WebCamEvent.NO_WEBCAM ) );
				
				break;
				
				case 'Camera.Unmuted':
					dispatchEvent( new WebCamEvent( WebCamEvent.READY ) );
					
				break;
			}
		}
		
		public function captureImage():Bitmap
		{
			var image:Bitmap = new Bitmap( bitmapData );
			
			return image;
		}
		
		public function captureVideo():void
		{
			if ( captureURL )
			{
				connection = new NetConnection();
				
				connection.addEventListener( NetStatusEvent.NET_STATUS, handleNetStatus );
				
				dispatchEvent( new WebCamEvent( WebCamEvent.CONNECTING ) );
				
				connection.connect( captureURL );
			}
			else
			{
				throw new ArgumentError( 'You need to specify the captureURL before you start recording' );
			}
		}
		
		private function handleNetStatus(e:NetStatusEvent):void
		{
			var name:String = e.info.code;
			
			switch ( name )
			{
				case 'NetConnection.Connect.Failed':
				case 'NetConnection.Connect.Rejected':
				case 'NetConnection.Connect.InvalidApp':
				case 'NetConnection.Connect.AppShutdown':
				throw new Error( 'Can\'t connect to the application!' );
				
				break;
				
				case 'NetConnection.Connect.Success':
				dispatchEvent( new WebCamEvent( WebCamEvent.CONNECTED ) );
				
				startRecording();
				
				break;
				
				case 'NetConnection.Connect.Closed':
				dispatchEvent( new WebCamEvent( WebCamEvent.CONNECTION_FAILED ) );
				
				break;
				
				case 'NetStream.Record.NoAccess':
				case 'NetStream.Record.Failed':
				throw new Error( 'Can\'t record stream!' );
				
				break;
				
				case 'NetStream.Record.Start':
				dispatchEvent( new WebCamEvent( WebCamEvent.RECORDING_STARTED ) );
				
				isRecording = true;
				
				break;
				
				case 'NetStream.Record.Stop':
				dispatchEvent( new WebCamEvent( WebCamEvent.RECORDING_STOPPED ) );
				
				isRecording = false;
				
				break;
				
				case 'NetStream.Unpublish.Success':
				dispatchEvent( new WebCamEvent( WebCamEvent.RECORDING_FINISHED ) );				
				
				break;
			}
		}
		
		private function startRecording():void
		{
			stream = new NetStream( connection );
			
			stream.addEventListener( NetStatusEvent.NET_STATUS, handleNetStatus );
			
			stream.attachAudio( microphone );
			stream.attachCamera( camera );
			
			stream.publish( recordingName, 'record' );
		}
		
		public function captureVideoStop():void
		{
			if ( isRecording )
			{
				stream.close();
			}
			else
			{
				throw new Error( 'Nothing\'s recording!' );
			}
		}
		
		public function disconnect():void
		{
			try
			{
				video.attachCamera( null );
			}
			catch (e:*)
			{
				throw new Error( 'Nothing to disconnect' );
			}
		}
		
		public function getStatus():Boolean
		{
			try
			{
				return !camera.muted;
			}
			catch (e:*)
			{}
			
			return false;
		}
		
		public function set reflect(b:Boolean):void
		{
			var matrix:Matrix		= new Matrix();
			
			_reflect				= b;
			
			if ( b )
			{
				matrix.translate( -cameraWidth, 0 ); 
				matrix.scale( -1, 1 );
			}
			
			video.transform.matrix	= matrix;
		}
		
		public function get bitmapData():BitmapData
		{
			return BitmapUtil.grab( this, new Rectangle( 0, 0, cameraWidth, cameraHeight ), true );
		}
		
		public function get recording():Boolean
		{
			return isRecording;
		}
		
		public function get filename():String
		{
			return recordingName + '.flv';
		}
		
		override public function get height():Number
		{
			return cameraHeight;
		}
		
		override public function get width():Number
		{
			return cameraWidth;
		}
	}
}