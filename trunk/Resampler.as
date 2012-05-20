package
{
	public class Resampler
	{
		public	var ratioWeight:Number;
		public	var resampler:Function;
		public	var outputBuffer:Vector.<Number>;
		public	var lastOutput:Vector.<Number>;
		public	var fromSampleRate:Number;
		public	var toSampleRate:Number;
		public	var channels:int;
		public	var outputBufferSize:uint;
		public	var noReturn:Boolean;
		
		public	var tailExists:Boolean;
		public	var lastWeight:Number;
		
		public	function Resampler(fromSampleRate:Number, toSampleRate:Number, channels:int, outputBufferSize:uint, noReturn:Boolean):void
		{
			this.fromSampleRate = fromSampleRate;
			this.toSampleRate = toSampleRate;
			this.channels = channels | 0;
			this.outputBufferSize = outputBufferSize;
			this.noReturn = noReturn;
			this.initialize();
		}
		
		public	function initialize():void
		{
			if (this.fromSampleRate > 0 && this.toSampleRate > 0 && this.channels > 0) {
				if (this.fromSampleRate == this.toSampleRate) {
					this.resampler = this.bypassResampler;
					this.ratioWeight = 1;
				}
				else {
					this.resampler = this.interpolate;
					this.ratioWeight = this.fromSampleRate / this.toSampleRate;
					this.tailExists = false;
					this.lastWeight = 0;
					this.initializeBuffers();
				}
			}
			else {
				throw(new Error("Invalid settings specified for the resampler."));
			}
		}
		
		public	function interpolate(buffer:Vector.<Number>):*
		{
			var bufferLength:uint = Math.min(buffer.length, this.outputBufferSize);
			if ((bufferLength % this.channels) == 0) {
				if (bufferLength > 0) {
					var weight:Number = 0;
					var output:Vector.<Number> = new Vector.<Number>(this.channels);
					for (var i:int = 0 ; i<output.length ; i++) {
						output[i] = 0;
					}
					var actualPosition:int = 0;
					var amountToNext:int = 0;
					var alreadyProcessedTail:Boolean = !this.tailExists;
					this.tailExists = false;
					var outputOffset:int = 0;
					var currentPosition:int = 0;
					do {
						if (alreadyProcessedTail) {
							weight = ratioWeight;
							for (i = 0 ; i<output.length ; i++) {
								output[i] = 0;
							}
						}
						else {
							weight = this.lastWeight;
							for (i = 0 ; i<output.length ; i++) {
								output[i] = this.lastOutput[i];
							}
							alreadyProcessedTail = true;
						}
						while (weight > 0 && actualPosition < bufferLength) {
							amountToNext = 1 + actualPosition - currentPosition;
							if (weight >= amountToNext) {
								for (i = 0 ; i<output.length ; i++) {
									output[i] += buffer[actualPosition++] * amountToNext;
								}
								currentPosition = actualPosition;
								weight -= amountToNext;
							}
							else {
								for (i = 0 ; i<output.length ; i++) {
									output[i] += buffer[actualPosition+i] * weight;
								}
								currentPosition += weight;
								weight = 0;
								break;
							}
						}
						if (weight == 0) {
							for (i = 0 ; i<output.length ; i++) {
								this.outputBuffer[outputOffset++] = output[i]  / ratioWeight;
							}
						}
						else {
							this.lastWeight = weight;
							for (i = 0 ; i<output.length ; i++) {
								this.lastOutput[i] = output[i];
							}
							this.tailExists = true;
							break;
						}
					} while (actualPosition < bufferLength);
					return this.bufferSlice(outputOffset);
				}
				else {
					return (this.noReturn) ? 0 : new Vector.<Number>;
				}
			}
			else {
				throw(new Error("Buffer was of incorrect sample length."));
			}
		}
		
		public	function bypassResampler(buffer:Vector.<Number>):*
		{
			if (this.noReturn) {
				this.outputBuffer = buffer;
				return buffer.length;
			}
			else {
				return buffer;
			}
		}
		
		public	function bufferSlice(sliceAmount:int):*
		{
			if (this.noReturn) {
				return sliceAmount;
			}
			else {
				try {
					return this.outputBuffer.slice(0, sliceAmount);
				}
				catch (error:Error) {
					try {
						this.outputBuffer.length = sliceAmount;
						return this.outputBuffer;
					}
					catch (error:Error) {
						return this.outputBuffer.slice(0, sliceAmount);
					}
				}
			}
		}
		
		public	function initializeBuffers ():void
		{
			try {
				this.outputBuffer = new Vector.<Number>(this.outputBufferSize);
				this.lastOutput = new Vector.<Number>(this.channels);
			}
			catch (error:Error) {
				this.outputBuffer = new Vector.<Number>();
				this.lastOutput = new Vector.<Number>();
			}
		}
	}
}