package com.mobswing.gb.graphic
{
	import __AS3__.vec.Vector;
	

	/** This class represents a palette.  There can be three
	 *  palettes, one for the background and window, and two
	 *  for sprites. 
	 */
	public class Palette
	{
		/** Data for which colour maps to which RGB value */
		 private var data:Vector.<int> = new Vector.<int>(4);	//short [4]
		
		 private var gbcData:Vector.<int> = new Vector.<int>(4);	//int [4]
		
		 /** Default RGB colour values */
		 private var colours:Vector.<int> = Vector.<int>([0xFFFFFFFF, 0xFFAAAAAA, 0xFF555555, 0xFF000000]);	//int[]

		/** Create a palette with the specified colour mappings */
		public function Palette(...params)
		{
			if (params.length == 4)
			{
				data[0] = params[0];
				data[1] = params[1];
				data[2] = params[2];
				data[3] = params[3];
			}
			else
			{
				decodePalette(params[0]);
			}
		}

		/** Change the colour mappings */
		 public function setColours(c1:int, c2:int, c3:int, c4:int):void {
		  colours[0] = c1;
		  colours[1] = c2;
		  colours[2] = c3;
		  colours[3] = c4;
		 }
		
		 /** Get the palette from the internal Gameboy Color format */
		 public function getGbcColours(entryNo:int, high:Boolean):int {	//@return byte
		  if (high) {
		   return gbcData[entryNo] >> 8;
		
		  } else {
		   return gbcData[entryNo] & 0x00FF;
		  }
		 }
		
		
		 /** Set the palette from the internal Gameboy Color format */
		 public function setGbcColours(entryNo:int, high:Boolean, dat:int):void {
		  if (high) {
		   gbcData[entryNo] = (gbcData[entryNo] & 0x00FF) | (dat << 8);
		
		  } else {
		   gbcData[entryNo] = (gbcData[entryNo] & 0xFF00) | dat;
		
		  }
		
		  var red:int = (gbcData[entryNo] & 0x001F) << 3;
		  var green:int = (gbcData[entryNo] & 0x03E0) >> 2;
		  var blue:int = (gbcData[entryNo] & 0x7C00) >> 7;
		
		  data[0] = 0;
		  data[1] = 1;
		  data[2] = 2;
		  data[3] = 3;
		
		  colours[entryNo] = (0xFF << 24) | ((red&0xFF) << 16) | ((green&0xFF) << 8) | (blue & 0xFF);
		//  trace("Colour " + entryNo + " set to " + red + ", " + green + ", " + blue);
		 }
		  
		 /** Set the palette from the internal Gameboy format */
		 public function decodePalette(pal:int):void {
		  data[0] = pal & 0x03;
		  data[1] = (pal & 0x0C) >> 2;
		  data[2] = (pal & 0x30) >> 4;
		  data[3] = (pal & 0xC0) >> 6;
		 }
		
		 /** Get the RGB colour value for a specific colour entry */
		 public function getRgbEntry(e:int):int {
		  return colours[data[e]];
		 }

		 /** Get the colour number for a specific colour entry */
		 public function getEntry(e:int):int {		//@return short
		  return data[e];
		 }

	}
}