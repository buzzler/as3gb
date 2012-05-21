package
{
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.sensors.Accelerometer;

	public class APU
	{
		public	var initialized:Boolean;
		public	var channels:int;
		public	var mono:Boolean;
		public	var sampleRate:Number;
		public	var minBufferSize:uint;
		public	var maxBufferSize:uint;
		public	var bufferSize:uint;
		public	var volume:Number;
		public	var samplesPerCallback:int;
		public	var outputConvert:Function;
		public	var audioContextSampleBuffer:Vector.<Number>;
		public	var resampled:Vector.<Number>;
		public	var resampleControl:Resampler;
		public	var resampleBufferStart:int;
		public	var resampleBufferEnd:int;
		public	var resampleBufferSize:uint;

		public	var channel:SoundChannel;
		public	var sound:Sound = null;
		
		public function APU(channels:int, sampleRate:int, minBufferSize:int, maxBufferSize:int, volume:Number)
		{
			this.initialized = false;
			this.samplesPerCallback = 2048;
			this.outputConvert = null;
			this.bufferSize = 0;
			this.resampleBufferStart = 0;
			this.resampleBufferEnd = 0;
			this.resampleBufferSize = 2;
			this.channels = (channels == 2) ? 2 : 1;
			this.mono = (this.channels == 1);
			this.sampleRate = (sampleRate > 0 && sampleRate <= 0xFFFFFF) ? sampleRate : 44100;
			this.minBufferSize = (minBufferSize >= (samplesPerCallback << 1) && minBufferSize < maxBufferSize) ? (minBufferSize & ((mono) ? 0xFFFFFFFF : 0xFFFFFFFE)) : (samplesPerCallback << 1);
			this.maxBufferSize = (Math.floor(maxBufferSize) > minBufferSize + this.channels) ? (maxBufferSize & ((mono) ? 0xFFFFFFFF : 0xFFFFFFFE)) : (minBufferSize << 1);
			this.volume = (volume >= 0 && volume <= 1) ? volume : 1;
		}
		
		public	function callbackBasedWriteAudioNoCallback(buffer:Vector.<Number>):void
		{
			var length:int = buffer.length;
			for (var bufferCounter:int = 0; bufferCounter < length && bufferSize < maxBufferSize;) {
				audioContextSampleBuffer[bufferSize++] = buffer[bufferCounter++];
			}
		}
		
		public	function writeAudioNoCallback(buffer:Vector.<Number>):void
		{
			if (this.checkInit()) {
				this.callbackBasedWriteAudioNoCallback(buffer);
			}
		}
		
		public	function remainingBuffer():Number
		{
			if (this.checkInit()) {
				return (((resampledSamplesLeft() * resampleControl.ratioWeight) >> (this.channels - 1)) << (this.channels - 1)) + bufferSize;
			}
			return 0;
		}

		public	function changeVolume(value:Number):void
		{
			if (value >= 0 && value <= 1) {
				volume = value;
				this.checkInit();
			}
		}

		public	function checkInit():Boolean
		{
			if (this.initialized!=true) {
				if (sound!=null) {
					sound.removeEventListener(SampleDataEvent.SAMPLE_DATA, soundCallback);
					if (channel!=null) {
						channel.stop();
					}
				}
				sound = new Sound();
				sound.addEventListener(SampleDataEvent.SAMPLE_DATA, soundCallback);
				channel = sound.play();
				
				resetCallbackAPIAudioBuffer(44100, samplesPerCallback);
				this.initialized = true;
			}
			return this.initialized;
		}
		
		public	function generateStereo(event:SampleDataEvent):void
		{
			for (var index:int = 0; index < samplesPerCallback && resampleBufferStart != resampleBufferEnd; ++index) {
				event.data.writeFloat(resampled[resampleBufferStart++]);
				event.data.writeFloat(resampled[resampleBufferStart++]);
				if (resampleBufferStart == resampleBufferSize) {
					resampleBufferStart = 0;
				}
			}
			while (++index < 2048) {
				event.data.writeFloat(0);
				event.data.writeFloat(0);
			}
		}
		
		public	function generateMono(event:SampleDataEvent):void
		{
			for (var index:int = 0; index < samplesPerCallback && resampleBufferStart != resampleBufferEnd; ++index) {
				event.data.writeFloat(resampled[resampleBufferStart++]);
				if (resampleBufferStart == resampleBufferSize) {
					resampleBufferStart = 0;
				}
			}
			while (++index < 2048) {
				event.data.writeFloat(0);
				event.data.writeFloat(0);
			}
		}

		public	function resampleRefill():void
		{
			if (bufferSize > 0) {
				var resampleLength:int = resampleControl.resampler(getBufferSamples());
				var resampledResult:Vector.<Number> = resampleControl.outputBuffer;
				for (var index:int = 0; index < resampleLength; ++index) {
					resampled[resampleBufferEnd++] = resampledResult[index];
					if (resampleBufferEnd == resampleBufferSize) {
						resampleBufferEnd = 0;
					}
					if (resampleBufferStart == resampleBufferEnd) {
						++resampleBufferStart;
						if (resampleBufferStart == resampleBufferSize) {
							resampleBufferStart = 0;
						}
					}
				}
				bufferSize = 0;
			}
		}
		
		public	function resampledSamplesLeft():int
		{
			return ((resampleBufferStart <= resampleBufferEnd) ? 0 : resampleBufferSize) + resampleBufferEnd - resampleBufferStart;
		}
		
		public	function getBufferSamples():Vector.<Number>
		{
			try {
				return audioContextSampleBuffer.slice(0, bufferSize);
			}
			catch (error:Error) {
				try {
					audioContextSampleBuffer.length = bufferSize;
					return audioContextSampleBuffer;
				}
				catch (error:Error) {
					return audioContextSampleBuffer.slice(0, bufferSize);
				}
			}
			return new Vector.<Number>();
		}
		
		public	function resetCallbackAPIAudioBuffer(APISampleRate:int, bufferAlloc:int):void
		{
			audioContextSampleBuffer = new Vector.<Number>(maxBufferSize);
			bufferSize = maxBufferSize;
			resampleBufferStart = 0;
			resampleBufferEnd = 0;
			resampleBufferSize = Math.max(maxBufferSize * Math.ceil(sampleRate / APISampleRate), samplesPerCallback) << 1;
			if (mono) {
				resampled = new Vector.<Number>(resampleBufferSize);
				resampleControl = new Resampler(sampleRate, APISampleRate, 1, resampleBufferSize, true);
				outputConvert = generateMono;
			}
			else {
				resampleBufferSize  <<= 1;
				resampled = new Vector.<Number>(resampleBufferSize);
				resampleControl = new Resampler(sampleRate, APISampleRate, 2, resampleBufferSize, true);
				outputConvert = generateStereo;
			}
		}

		public	function soundCallback(event:SampleDataEvent):void {
			var index:int = 0;

			resampleRefill();
			if (outputConvert == null) {
				while (++index <= 2048) {
					event.data.writeFloat(0);
					event.data.writeFloat(0);
				}
				return;
			}
			else {
				outputConvert(event);
			}
		}
	}
}