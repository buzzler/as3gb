package com.mobswing.gb.model
{
	import flash.events.Event;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	
	public class SourceDataLine
	{
		private	static const BUFFER_MIN:int = 2048;
		private	static const BUFFER_MAX:int = 8192;
		
		private var _speaker	:Sound;
		private var _channel	:SoundChannel;
		private var _running	:Boolean;
		private var _active		:Boolean;
		private var _available	:int;
		private var _bufferData	:ByteArrayAdvanced;
		private var _bufferLen	:int;
		private var _stereo		:Boolean
		private var _flushed	:Boolean;
		
		public function SourceDataLine()
		{
			this._speaker	= new Sound();
			this._running	= false;
			this._active	= false;
			this._available	= 0;
			this._flushed	= true;
		}


		public	function start():void
		{
			if (!this._running)
			{
				this._speaker.addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
				this._channel = this._speaker.play();
				this._channel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
				this._running = true;
			}
		}
		
		public	function close():void
		{
			if (this._running)
			{
				this._speaker.removeEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
				this._channel.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
				this._channel.stop();
				this._channel = null;
				this._running = false;
				this._available = 0;
				this._flushed	= true;
				this._bufferData= null;
				this._bufferLen = 0;
			}
		}
		
		public	function available():int
		{
			return this._available;
		}

		public	function getBufferSize():int
		{
			return BUFFER_MAX;
		}
		
		public	function isActive():Boolean
		{
			return this._active;
		}
		
		public	function isOpen():Boolean
		{
			return this._running;
		}
		
		public	function write(b:ByteArrayAdvanced, off:int, len:int, stereo:Boolean):int
		{
			if (this._bufferData == null)
			{
				this._bufferData = new ByteArrayAdvanced(b.length);
			}
			if (len > 0)
			{
				b.readBytes(this._bufferData, off, len);
				this._bufferLen = len;
				this._flushed = false;
				this._stereo = stereo;
			}
			return len;
		}
		
		private	function onSampleData(event:SampleDataEvent):void
		{
			var i:int, r:Number;
			this._active = true;
			this._available = event.position;

			if (this._bufferData == null)
			{
				for (i = 0 ; i < BUFFER_MIN ; i++)
				{
					event.data.writeFloat(0);
					event.data.writeFloat(0);
				}
				return;
			}

			if (this._stereo)
			{
				r =  this._bufferLen / (BUFFER_MIN * 2);
				for (i = 0 ; i < (BUFFER_MIN*2) ; i++)
				{
					event.data.writeFloat(this._bufferData.read(Math.floor(i*r)));
				}
			}
 			else
			{
				r =  this._bufferLen / BUFFER_MIN;

				for (i = 0 ; i < BUFFER_MIN ; i++)
				{
					event.data.writeFloat(this._bufferData.read(Math.floor(i*r)));
					event.data.writeFloat(this._bufferData.read(Math.floor(i*r)));
				}
			}
			
			this._available = event.position;
			this._flushed = true;
			this._active = false;
		}
		
		private	function onSoundComplete(event:Event):void
		{
			this._speaker.removeEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
			this._channel.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
			this._channel = null;
			this._running = false;
			this._available = 0;
			this._flushed	= true;
			this._bufferData= null;
			this._bufferLen = 0;
		}
	}
}