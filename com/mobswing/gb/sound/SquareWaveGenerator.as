package com.mobswing.gb.sound
{
	import com.mobswing.gb.model.ByteArrayAdvanced;
	
	/** This class can mix a square wave signal with a sound buffer.
	 *  It supports all features of the Gameboys sound channels 1 and 2.
	 */
	public class SquareWaveGenerator
	{
		 /** Sound is to be played on the left channel of a stereo sound */
		 public static var CHAN_LEFT:int = 1;
		
		 /** Sound is to be played on the right channel of a stereo sound */
		 public static var CHAN_RIGHT:int = 2;
		
		 /** Sound is to be played back in mono */
		 public static var CHAN_MONO:int = 4;
		
		 /** Length of the sound (in frames) */
		 private var totalLength:int;
		
		 /** Current position in the waveform (in samples) */
		 private var cyclePos:int;
		
		 /** Length of the waveform (in samples) */
		 private var cycleLength:int;
		
		 /** Amplitude of the waveform */
		 private var amplitude:int;
		
		 /** Amount of time the sample stays high in a single waveform (in eighths) */
		 private var dutyCycle:int;
		
		 /** The channel that the sound is to be played back on */
		 private var channel:int;
		
		 /** Sample rate of the sound buffer */
		 private var sampleRate:int;
		
		 /** Initial amplitude */
		 private var initialEnvelope:int;
		
		 /** Number of envelope steps */
		 private var numStepsEnvelope:int;
		
		 /** If true, envelope will increase amplitude of sound, false indicates decrease */
		 private var increaseEnvelope:Boolean;
		
		 /** Current position in the envelope */
		 private var counterEnvelope:int;
		
		 /** Frequency of the sound in internal GB format */
		 private var gbFrequency:int;
		
		 /** Amount of time between sweep steps. */
		 private var timeSweep:int;
		
		 /** Number of sweep steps */
		 private var numSweep:int;
		
		 /** If true, sweep will decrease the sound frequency, otherwise, it will increase */
		 private var decreaseSweep:Boolean;
		
		 /** Current position in the sweep */
		 private var counterSweep:int;

		
		public function SquareWaveGenerator(...params):void
		{
			if  (params.length > 1)
			{
				cycleLength = params[0];
				amplitude = params[1];
				cyclePos = 0;
				dutyCycle = params[2];
				channel = params[3];
				sampleRate = params[4];
			}
			else
			{
				dutyCycle = 4;
				cyclePos = 0;
				channel = CHAN_LEFT | CHAN_RIGHT;
				cycleLength = 2;
				totalLength = 0;
				sampleRate = params[0];
				amplitude = 32;
				counterSweep = 0;
			}
		}


		 /** Set the sound buffer sample rate */
		 public function setSampleRate(sr:int):void {
		  sampleRate = sr;
		 }
		
		 /** Set the duty cycle */
		 public function setDutyCycle(duty:int):void {
		  switch (duty) {
		   case 0 : dutyCycle = 1;
		            break;
		   case 1 : dutyCycle = 2;
		            break;
		   case 2 : dutyCycle = 4;
		            break;
		   case 3 : dutyCycle = 6;
		            break;
		  }
		//  trace(dutyCycle);
		 }
		
		 /** Set the sound frequency, in internal GB format */
		 public function setFrequency(gbFrequency:int):void {
		  try {
		  var frequency:Number = 131072 / 2048;
		
		  if (gbFrequency != 2048) {
		   frequency = (131072 / (2048 - gbFrequency));
		  }
		//  trace("gbFrequency: " + gbFrequency + "");
		  this.gbFrequency = gbFrequency;
		  if (frequency != 0) {
		   cycleLength = (256 * sampleRate) / frequency;
		  } else {
		   cycleLength = 65535;
		  }
		  if (cycleLength == 0) cycleLength = 1;
		//  trace("Cycle length : " + cycleLength + " samples");
		  } catch (e:Error) {
		   // Skip ip
		  }
		 }
		
		 /** Set the channel for playback */
		 public function setChannel(chan:int):void {
		  channel = chan;
		 }
		
		 /** Set the envelope parameters */
		 public function setEnvelope(initialValue:int, numSteps:int, increase:Boolean):void {
		  initialEnvelope = initialValue;
		  numStepsEnvelope = numSteps;
		  increaseEnvelope = increase;
		  amplitude = initialValue * 2;
		 }
		
		 /** Set the frequency sweep parameters */
		 public function setSweep(time:int, num:int, decrease:Boolean):void {
		  timeSweep = (time + 1) / 2;
		  numSweep = num;
		  decreaseSweep = decrease;
		  counterSweep = 0;
		//  trace("Sweep: " + time + ", " + num + ", " + decrease);
		 }
		
		 public function setLength(gbLength:int):void {
		  if (gbLength == -1) {
		   totalLength = -1;
		  } else {
		   totalLength = (64 - gbLength) / 4;
		  }
		 }
		
		 public function setLength3(gbLength:int):void {
		  if (gbLength == -1) {
		   totalLength = -1;
		  } else {
		   totalLength = (256 - gbLength) / 4;
		  }
		 }
		
		 public function setVolume3(volume:int):void {
		  switch (volume) {
		   case 0 : amplitude = 0;
		            break;
		   case 1 : amplitude = 32;
		            break;
		   case 2 : amplitude = 16;
		            break;
		   case 3 : amplitude = 8;
		            break;
		  }
		//  trace("A:"+volume);
		 }
		
		 /** Output a frame of sound data into the buffer using the supplied frame length and array offset. */
		 public function play(b:ByteArrayAdvanced, length:int, offset:int):void {	//@param b:byte[]
		  var val:int = 0;

		  if (totalLength != 0) {
		   totalLength--;
		
		   if (timeSweep != 0) {
		    counterSweep++;
		    if (counterSweep > timeSweep) {
		     if (decreaseSweep) {
		      setFrequency(gbFrequency - (gbFrequency >> numSweep));
		     } else {
		      setFrequency(gbFrequency + (gbFrequency >> numSweep));
		     }
		     counterSweep = 0;
		    }
		   }
		
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
		   for (var r:int = offset; r < offset + length; r++) {
		
		    if (cycleLength != 0) {
		     if (((8 * cyclePos) / cycleLength) >= dutyCycle) {
		      val = amplitude;
		     } else {
		      val = -amplitude;
		     }
		    }
		
		/*    if (cyclePos >= (cycleLength / 2)) {
		     val = amplitude;
		    } else {
		     val = -amplitude;
		    }*/
		
		
		    if ((channel & CHAN_LEFT) != 0)
		    {
		    	b.write(r * 2, b.read(r*2) + val);
		    }
		    if ((channel & CHAN_RIGHT) != 0)
		    {
		    	b.write(r * 2 + 1, b.read(r*2+1) + val);
		    }
		    if ((channel & CHAN_MONO) != 0)
		    {
		    	b.write(r, b.read(r) + val);
		    }
		
		 //   System.out.print(val + " ");
		
		    cyclePos = (cyclePos + 256) % cycleLength;
		   }
		  }
		 }


	}
}