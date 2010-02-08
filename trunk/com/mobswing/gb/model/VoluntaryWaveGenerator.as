package com.mobswing.gb.model
{
	import com.mobswing.gb.view.Javaboy;
	
	/*
	
	JavaBoy
	                                  
	COPYRIGHT (C) 2001 Neil Millstone and The Victoria University of Manchester
	                                                                         ;;;
	This program is free software; you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the Free
	Software Foundation; either version 2 of the License, or (at your option)
	any later version.        
	
	This program is distributed in the hope that it will be useful, but WITHOUT
	ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
	FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
	more details.
	
	
	You should have received a copy of the GNU General Public License along with
	this program; if not, write to the Free Software Foundation, Inc., 59 Temple
	Place - Suite 330, Boston, MA 02111-1307, USA.
	
	*/
	public class VoluntaryWaveGenerator
	{
		public static var CHAN_LEFT:int = 1;
		public static var CHAN_RIGHT:int = 2;
		public static var CHAN_MONO:int = 4;
		
		private var totalLength:int;
		private var cyclePos:int;
		private var cycleLength:int;
		private var amplitude:int;
		private var channel:int;
		private var sampleRate:int;
		private var volumeShift:int;
		
		private var waveform:ByteArrayAdvanced = new ByteArrayAdvanced(32);	//byte[32]
		
		public function VoluntaryWaveGenerator(...params)
		{
			if (params.length > 1)
			{
				cycleLength = params[0];
				amplitude = params[1];
				cyclePos = 0;
				channel = params[3];
				sampleRate = params[4];
			}
			else
			{
				cyclePos = 0;
				channel = CHAN_LEFT | CHAN_RIGHT;
				cycleLength = 2;
				totalLength = 0;
				sampleRate = params[0];
				amplitude = 32;
			}
		}


		 public function setSampleRate(sr:int):void {
		  sampleRate = sr;
		 }
		
		 public function setFrequency(gbFrequency:int):void {
		//  cyclePos = 0;
		  var frequency:Number = int(65536 / (2048 - gbFrequency));
		//  trace("gbFrequency: " + gbFrequency + "");
		  cycleLength = int((256 * sampleRate) / frequency);
		  if (cycleLength == 0) cycleLength = 1;
		//  trace("Cycle length : " + cycleLength + " samples");
		 }
		
		 public function setChannel(chan:int):void {
		  channel = chan;
		 }
		
		 public function setLength(gbLength:int):void {
		  if (gbLength == -1) {
		   totalLength = -1;
		  } else {
		   totalLength = (256 - gbLength) / 4;
		  }
		 }
		
		 public function setSamplePair(address:int, value:int):void {
		  waveform.write(address * 2, (value & 0xF0) >> 4);
		  waveform.write(address * 2 + 1, value & 0x0F);
		 }
		
		 public function setVolume(volume:int):void {
		  switch (volume) {
		   case 0 : volumeShift = 5;
		            break;
		   case 1 : volumeShift = 0;
		            break;
		   case 2 : volumeShift = 1;
		            break;
		   case 3 : volumeShift = 2;
		            break;
		  }
		//  trace("A:"+volume);
		 }
		
		 public function play(b:ByteArrayAdvanced, length:int, offset:int):void {
		  var val:int;
		
		  if (totalLength != 0) {
		   totalLength--;
		
		   for (var r:int = offset; r < offset + length; r++) {
		
		    var samplePos:int = (31 * cyclePos) / cycleLength;
		    val = Javaboy.unsign(waveform.read(samplePos % 32)) >> volumeShift << 1;
		//    System.out.print(" " + val);
		
		    if ((channel & CHAN_LEFT) != 0)
		    {
		    	b.write(r * 2, b.read(r*2) +val);
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