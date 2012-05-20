package
{
	import flash.events.Event;
	import flash.sensors.Accelerometer;

	public class XAudioServer
	{
		public	var audioChannels:int;
		public	var webAudioMono:Boolean;
		public	var XAudioJSSampleRate:Number;
		public	var webAudioMinBufferSize:uint;
		public	var webAudioMaxBufferSize:uint;
		public	var underRunCallback:Function;
		public	var XAudioJSVolume:Number;
		public	var audioType:int;
		public	var audioHandleMoz:Object;
		public	var audioHandleFlash:XAudioJS;
		public	var flashInitialized:Boolean;
		public	var mozAudioFound:Boolean;
		public	var samplesPerCallback:int;
		public	var outputConvert:Function;
		public	var launchedContext:Boolean;
		public	var audioContextSampleBuffer:Vector.<Number>;
		public	var resampled:Vector.<Number>;
		public	var resampleControl:Resampler;
		public	var audioBufferSize:uint;
		public	var resampleBufferStart:int;
		public	var resampleBufferEnd:int;
		public	var resampleBufferSize:uint;
		public	var samplesAlreadyWritten:int;
		
		public function XAudioServer(channels:int, sampleRate:int, minBufferSize:int, maxBufferSize:int, underRunCallback:Function, volume:Number)
		{
			this.audioType = -1;
			this.audioHandleMoz = null;
			this.audioHandleFlash = null;
			this.flashInitialized = false;
			this.mozAudioFound = false;
			this.samplesPerCallback = 2048;
			this.outputConvert = null;
			this.launchedContext = true;
			this.audioBufferSize = 0;
			this.resampleBufferStart = 0;
			this.resampleBufferEnd = 0;
			this.resampleBufferSize = 2;
			
			this.audioChannels = (channels == 2) ? 2 : 1;
			webAudioMono = (this.audioChannels == 1);
			XAudioJSSampleRate = (sampleRate > 0 && sampleRate <= 0xFFFFFF) ? sampleRate : 44100;
			webAudioMinBufferSize = (minBufferSize >= (samplesPerCallback << 1) && minBufferSize < maxBufferSize) ? (minBufferSize & ((webAudioMono) ? 0xFFFFFFFF : 0xFFFFFFFE)) : (samplesPerCallback << 1);
			webAudioMaxBufferSize = (Math.floor(maxBufferSize) > webAudioMinBufferSize + this.audioChannels) ? (maxBufferSize & ((webAudioMono) ? 0xFFFFFFFF : 0xFFFFFFFE)) : (minBufferSize << 1);
			this.underRunCallback = (underRunCallback != null) ? underRunCallback : function ():void {};
			XAudioJSVolume = (volume >= 0 && volume <= 1) ? volume : 1;
			
			this.initializeFlashAudio();
		}
		
		public	function callbackBasedWriteAudioNoCallback(buffer:Vector.<Number>):void
		{
			var length:int = buffer.length;
			for (var bufferCounter:int = 0; bufferCounter < length && audioBufferSize < webAudioMaxBufferSize;) {
				audioContextSampleBuffer[audioBufferSize++] = buffer[bufferCounter++];
			}
		}
		
		public	function writeAudioNoCallback(buffer:Vector.<Number>):void
		{
			if (this.audioType == 2) {
				if (this.checkFlashInit() || launchedContext) {
					this.callbackBasedWriteAudioNoCallback(buffer);
				}
			}
		}
		
		public	function remainingBuffer():Number
		{
			if (this.audioType == 2) {
				if (this.checkFlashInit() || launchedContext) {
					return (((resampledSamplesLeft() * resampleControl.ratioWeight) >> (this.audioChannels - 1)) << (this.audioChannels - 1)) + audioBufferSize;
				}
			}
			return 0;
		}

		public	function initializeFlashAudio():void
		{
			this.audioHandleFlash = new XAudioJS(this);
			this.audioType = 2;
		}
		
		public	function changeVolume(value:Number):void
		{
			if (value >= 0 && value <= 1) {
				XAudioJSVolume = value;
				if (this.checkFlashInit()) {
					this.audioHandleFlash.changeVolume(XAudioJSVolume);
				}
			}
		}

		public	function checkFlashInit():Boolean
		{
			if (!this.flashInitialized && this.audioHandleFlash) {
				this.flashInitialized = true;
				this.audioHandleFlash.initialize(this.audioChannels, XAudioJSVolume);
				resetCallbackAPIAudioBuffer(44100, samplesPerCallback);
			}
			return this.flashInitialized;
		}
		
		public	function getFloat32(size:int):Vector.<Number>
		{
			return new Vector.<Number>(size);
		}
		
		public	function getFloat32Flat(size:int):Vector.<Number>
		{
			return new Vector.<Number>(size);
		}
		
		public	function audioOutputFlashEvent():String
		{
			resampleRefill();
			if (outputConvert != null)
				return outputConvert();
			return "";
		}
		
		public	function generateFlashStereoString():String
		{
			var copyBinaryStringLeft:String = "";
			var copyBinaryStringRight:String = "";
			for (var index:int = 0; index < samplesPerCallback && resampleBufferStart != resampleBufferEnd; ++index) {
				copyBinaryStringLeft += String.fromCharCode(((Math.min(Math.max(resampled[resampleBufferStart++] + 1, 0), 2) * 0x3FFF) | 0) + 0x3000);
				copyBinaryStringRight += String.fromCharCode(((Math.min(Math.max(resampled[resampleBufferStart++] + 1, 0), 2) * 0x3FFF) | 0) + 0x3000);
				if (resampleBufferStart == resampleBufferSize) {
					resampleBufferStart = 0;
				}
			}
			return copyBinaryStringLeft + copyBinaryStringRight;
		}
		
		public	function generateFlashMonoString():String
		{
			var copyBinaryString:String = "";
			for (var index:int = 0; index < samplesPerCallback && resampleBufferStart != resampleBufferEnd; ++index) {
				copyBinaryString += String.fromCharCode(((Math.min(Math.max(resampled[resampleBufferStart++] + 1, 0), 2) * 0x3FFF) | 0) + 0x3000);
				if (resampleBufferStart == resampleBufferSize) {
					resampleBufferStart = 0;
				}
			}
			return copyBinaryString;
		}
		
		public	function resampleRefill():void
		{
			if (audioBufferSize > 0) {
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
				audioBufferSize = 0;
			}
		}
		
		public	function resampledSamplesLeft():int
		{
			return ((resampleBufferStart <= resampleBufferEnd) ? 0 : resampleBufferSize) + resampleBufferEnd - resampleBufferStart;
		}
		
		public	function getBufferSamples():Vector.<Number>
		{
			try {
				return audioContextSampleBuffer.slice(0, audioBufferSize);
			}
			catch (error:Error) {
				try {
					audioContextSampleBuffer.length = audioBufferSize;
					return audioContextSampleBuffer;
				}
				catch (error:Error) {
					return audioContextSampleBuffer.slice(0, audioBufferSize);
				}
			}
			return new Vector.<Number>();
		}
		
		public	function resetCallbackAPIAudioBuffer(APISampleRate:int, bufferAlloc:int):void
		{
			audioContextSampleBuffer = getFloat32(webAudioMaxBufferSize);
			audioBufferSize = webAudioMaxBufferSize;
			resampleBufferStart = 0;
			resampleBufferEnd = 0;
			resampleBufferSize = Math.max(webAudioMaxBufferSize * Math.ceil(XAudioJSSampleRate / APISampleRate), samplesPerCallback) << 1;
			if (webAudioMono) {
				resampled = getFloat32Flat(resampleBufferSize);
				resampleControl = new Resampler(XAudioJSSampleRate, APISampleRate, 1, resampleBufferSize, true);
				outputConvert = generateFlashMonoString;
			}
			else {
				resampleBufferSize  <<= 1;
				resampled = getFloat32Flat(resampleBufferSize);
				resampleControl = new Resampler(XAudioJSSampleRate, APISampleRate, 2, resampleBufferSize, true);
				outputConvert = generateFlashStereoString;
			}
		}
	}
}