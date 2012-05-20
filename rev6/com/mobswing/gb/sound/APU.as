package com.mobswing.gb.sound
{
	import com.mobswing.gb.model.ByteArrayAdvanced;
	
	/** This is the central controlling class for the sound.
	 *  It interfaces with the Java Sound API, and handles the
	 *  calsses for each sound channel.
	 */
	public class APU
	{
		 /** The DataLine for outputting the sound */
		 private var soundLine:SourceDataLine;
		
		 public var channel1:SquareWaveGenerator;
		 public var channel2:SquareWaveGenerator;
		 public var channel3:VoluntaryWaveGenerator;
		 public var channel4:NoiseGenerator;
		 private var soundEnabled:Boolean = false;
		
		 /** If true, channel is enabled */
		 public var channel1Enable:Boolean = true, channel2Enable:Boolean = true, channel3Enable:Boolean = true, channel4Enable:Boolean = true;
		
		 /** Current sampling rate that sound is output at */
		 private var sampleRate:int = 44100;
		
		 /** Amount of sound data to buffer before playback */
		 private var bufferLengthMsec:int = 200;

		/** Initialize sound emulation, and allocate sound hardware */
		public function APU()
		{
			soundLine = initSoundHardware();
			channel1 = new SquareWaveGenerator(sampleRate);
			channel2 = new SquareWaveGenerator(sampleRate);
			channel3 = new VoluntaryWaveGenerator(sampleRate);
			channel4 = new NoiseGenerator(sampleRate);
		}

 /** Initialize sound hardware if available */
 public function initSoundHardware():SourceDataLine {

  try {
    var line:SourceDataLine = new SourceDataLine();
    line.start();
//    trace("Initialized audio successfully.");
    soundEnabled = true;
    return line;
  } catch (e:Error) {
   trace("Error: Audio system busy!");
   soundEnabled = false;
  }

  return null;
 }

 /** Change the sample rate of the playback */
 public function setSampleRate(sr:int):void {
  sampleRate = sr;

  soundLine.close();

  soundLine = initSoundHardware();

  channel1.setSampleRate(sr);
  channel2.setSampleRate(sr);
  channel3.setSampleRate(sr);
  channel4.setSampleRate(sr);
 }

 /** Change the sound buffer length */
 public function setBufferLength(time:int):void {
  bufferLengthMsec = time;

  soundLine.close();

  soundLine = initSoundHardware();
 }

 /** Adds a single frame of sound data to the buffer */
 public function outputSound():void {
  if (soundEnabled) {
   var numSamples:int;

   if (sampleRate / 28 >= soundLine.available() * 2) {
    numSamples = soundLine.available() * 2;
   } else {
    numSamples = (sampleRate / 28) & 0xFFFE;
   }

   var b:ByteArrayAdvanced = new ByteArrayAdvanced(numSamples);	//byte[]
   if (channel1Enable) channel1.play(b, numSamples / 2, 0);
   if (channel2Enable) channel2.play(b, numSamples / 2, 0);
   if (channel3Enable) channel3.play(b, numSamples / 2, 0);
   if (channel4Enable) channel4.play(b, numSamples / 2, 0);
   soundLine.write(b, 0, numSamples, true);
  }
 }


	}
}