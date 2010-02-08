package com.mobswing.gb.model
{
	import __AS3__.vec.Vector;
	
	/** This is a white noise generator.  It is used to emulate
	 *  channel 4.
	 */
	public class NoiseGenerator
	{
		 /** Indicates sound is to be played on the left channel of a stereo sound */
		 public static var CHAN_LEFT:int = 1;
		
		 /** Indictaes sound is to be played on the right channel of a stereo sound */
		 public static var CHAN_RIGHT:int = 2;
		
		 /** Indicates that sound is mono */
		 public static var CHAN_MONO:int = 4;
		
		 /** Indicates the length of the sound in frames */
		 private var totalLength:int;
		 private var cyclePos:int;
		
		 /** The length of one cycle, in samples */
		 private var cycleLength:int;
		
		 /** Amplitude of the wave function */
		 private var amplitude:int;
		
		 /** Channel being played on.  Combination of CHAN_LEFT and CHAN_RIGHT, or CHAN_MONO */
		 private var channel:int;
		
		 /** Sampling rate of the output channel */
		 private var sampleRate:int;
		
		 /** Initial value of the envelope */
		 private var initialEnvelope:int;
		
		 private var numStepsEnvelope:int;
		
		 /** Whether the envelope is an increase/decrease in amplitude */
		 private var increaseEnvelope:Boolean;
		
		 private var counterEnvelope:int;
		
		 /** Stores the random values emulating the polynomial generator (badly!) */
		 private var randomValues:Vector.<Boolean>;
		
		 private var dividingRatio:int;
		 private var polynomialSteps:int;
		 private var shiftClockFreq:int;
		 private var finalFreq:int;
		 private var cycleOffset:int;

		/** Creates a white noise generator with the specified wavelength, amplitude, channel, and sample rate */
		public function NoiseGenerator(...params):void
		{
			var r:int;
			if (params.length > 1)
			{
				cycleLength = params[0];
				amplitude = params[1];
				cyclePos = 0;
				channel = params[2];
				sampleRate = params[3];
				cycleOffset = 0;
				
				randomValues = new Vector.<Boolean>(32767);
				
				for (r = 0; r < 32767; r++) {
					randomValues[r] = (Math.random() < 0.5) ? true:false;
				}
				
				cycleOffset = 0;
			}
			else
			{
				cyclePos = 0;
				channel = CHAN_LEFT | CHAN_RIGHT;
				cycleLength = 2;
				totalLength = 0;
				sampleRate = params[0];
				amplitude = 32;
				
				randomValues = new Vector.<Boolean>(32767);
				
				for (r = 0; r < 32767; r++) {
					randomValues[r] = (Math.random() < 0.5) ? true:false;
				}
				
				cycleOffset = 0;
			}
		}

 public function setSampleRate(sr:int):void {
  sampleRate = sr;
 }

 /** Set the channel that the white noise is playing on */
 public function setChannel(chan:int):void {
  channel = chan;
 }

 /** Setup the envelope, and restart it from the beginning */
 public function setEnvelope(initialValue:int, numSteps:int, increase:Boolean):void {
  initialEnvelope = initialValue;
  numStepsEnvelope = numSteps;
  increaseEnvelope = increase;
  amplitude = initialValue * 2;
 }

 /** Set the length of the sound */
 public function setLength(gbLength:int):void {
  if (gbLength == -1) {
   totalLength = -1;
  } else {
   totalLength = (64 - gbLength) / 4;
  }
 }

 public function setParameters(dividingRatio:Number, polynomialSteps:Boolean, shiftClockFreq:int):void {	//@param divisingRatio:Float
  this.dividingRatio = int(dividingRatio);
  if (!polynomialSteps) {
   this.polynomialSteps = 32767;
   cycleLength = 32767 << 8;
   cycleOffset = 0;
  } else {
   this.polynomialSteps = 63;
   cycleLength = 63 << 8;

   cycleOffset = int(Math.random() * 1000);
  }
  this.shiftClockFreq = shiftClockFreq;

  if (dividingRatio == 0) dividingRatio = 0.5;

  finalFreq = (int(4194304 / 8 / dividingRatio)) >> (shiftClockFreq + 1);
//  System.out.println("dr:" + dividingRatio + "  steps: " + this.polynomialSteps + "  shift:" + shiftClockFreq + "  = Freq:" + finalFreq);
 }

 /** Output a single frame of samples, of specified length.  Start at position indicated in the
  *  output array.
  */
 public function play(b:ByteArrayAdvanced, length:int, offset:int):void {		//@param b:byte[]
  var val:int;

  if (totalLength != 0) {
   totalLength--;

   counterEnvelope++;
   if (numStepsEnvelope != 0) {
    if (((counterEnvelope % numStepsEnvelope) == 0) && (amplitude > 0)) {
     if (!increaseEnvelope) {
      if (amplitude > 0) amplitude-=2;
     } else {
      if (amplitude < 16) amplitude+=2;
     }
    }
   }


   var step:int = ((finalFreq) / (sampleRate >> 8));
  // System.out.println("Step=" + step);

   for (var r:int = offset; r < offset + length; r++) {
	var value:Boolean = randomValues[((cycleOffset ) + (cyclePos >> 8)) & 0x7FFF];
	var v:int = value ? (amplitude / 2): (-amplitude / 2);

    if ((channel & CHAN_LEFT) != 0)
    {
    	b.write(r * 2, b.read(r*2) + v);
    }
    if ((channel & CHAN_RIGHT) != 0)
    {
    	b.write(r * 2 + 1, b.read(r*2+1) + v);
    }
    if ((channel & CHAN_MONO) != 0)
    {
    	b.write(r, b.read(r) + v);
    }
   
    cyclePos = (cyclePos + step) % cycleLength;
  }

   /*
   for (int r = offset; r < offset + length; r++) {
    val = (int) ((Math.random() * amplitude * 2) - amplitude);

    if ((channel & CHAN_LEFT) != 0) b[r * 2] += val;
    if ((channel & CHAN_RIGHT) != 0) b[r * 2 + 1] += val;
    if ((channel & CHAN_MONO) != 0) b[r] += val;

 //   System.out.print(val + " ");

    cyclePos = (cyclePos + 256) % cycleLength;

   }*/
  }
 }

	}
}