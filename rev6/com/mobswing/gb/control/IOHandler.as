package com.mobswing.gb.control
{
	import com.mobswing.gb.graphic.PPU;
	import com.mobswing.gb.model.ByteArrayAdvanced;
	import com.mobswing.gb.sound.SquareWaveGenerator;
	import com.mobswing.gb.view.Gameboy;
	
	/** This class handles all the memory mapped IO in the range
	 *  FF00 - FF4F.  It also handles high memory accessed by the
	 *  LDH instruction which is locted at FF50 - FFFF.
	 */
	public class IOHandler
	{
		 /** Data contained in the handled memory area */
		 public	var registers:ByteArrayAdvanced = new ByteArrayAdvanced(0x100);	//byte[]

		 /** Reference to the current CPU object */
		 private var cpu:CPU;
		
		 /** Current state of the button, true = pressed. */
		 public var padLeft:Boolean, padRight:Boolean, padUp:Boolean, padDown:Boolean, padA:Boolean, padB:Boolean, padStart:Boolean, padSelect:Boolean;
		
		 public var hdmaRunning:Boolean;

		/** Create an IoHandler for the specified CPU */
		public function IOHandler(d:CPU)
		{
			cpu = d;
			reset();
		}


		 /** Initialize IO to initial power on state */
		 public function reset():void {
		  trace("Hardware reset");
		  for (var r:int = 0; r < 0xFF; r++) {
		   ioWrite(r, 0x00);
		  }
		  ioWrite(0x40, 0x91);
		  ioWrite(0x0F, 0x01);
		  hdmaRunning = false;
		 }
		
		 /** Press/release a Gameboy button by name */
		 public function toggleKey(keyName:String):void {
		
		  if (keyName == "a") {
		   padA = !padA;
		   trace("- A is now " + padA);
		  } else if (keyName == "b") {
		   padB = !padB;
		   trace("- B is now " + padB);
		  } else if (keyName == "up") {
		   padUp = !padUp;
		   trace("- Up is now " + padUp);
		  } else if (keyName == "down") {
		   padDown = !padDown;
		   trace("- Down is now " + padDown);
		  } else if (keyName == "left") {
		   padLeft = !padLeft;
		   trace("- Left is now " + padLeft);
		  } else if (keyName == "right") {
		   padRight = !padRight;
		   trace("- Right is now " + padRight);
		  } else if (keyName == "select") {
		   padSelect = !padSelect;
		   trace("- Select is now " + padSelect);
		  } else if (keyName == "start") {
		   padStart = !padStart;
		   trace("- Start is now " + padStart);
		  } else {
		   trace("- Key name '" + keyName + "' not recognised");
		  }
		 }
		
		
		 public function performHdma():void {
		  var dmaSrc:int = (Gameboy.unsign(registers.read(0x51)) << 8) +
		               (Gameboy.unsign(registers.read(0x52)) & 0xF0);
		  var dmaDst:int = ((Gameboy.unsign(registers.read(0x53)) & 0x1F) << 8) +
		                (Gameboy.unsign(registers.read(0x54)) & 0xF0) + 0x8000;
		
		//  trace("Copied 16 bytes from " + Javaboy.hexWord(dmaSrc) + " to " + Javaboy.hexWord(dmaDst));
		
		  for (var r:int = 0; r < 16; r++) {
		   cpu.addressWrite(dmaDst + r, cpu.addressRead(dmaSrc + r));
		  }
		
		  dmaSrc += 16;
		  dmaDst += 16;
		  registers.write(0x51, (dmaSrc & 0xFF00) >> 8);
		  registers.write(0x52, dmaSrc & 0x00F0);
		  registers.write(0x53, (dmaDst & 0x1F00) >> 8);
		  registers.write(0x54, dmaDst & 0x00F0);
		
		  var len:int = Gameboy.unsign(registers.read(0x55));
		  if (len == 0x00) {
		   registers.write(0x55, 0xFF);
		   hdmaRunning = false;
		  } else {
		   len--;
		   registers.write(0x55, len);
		  }
		
		 }
		
		 /** Read data from IO Ram */
		 public function ioRead(num:int):int {	//@return short
		 	var palNumber:int;
		  if (num <= 0x4B) {
		//   trace("Read of register " + Javaboy.hexByte(num) + " at " + Javaboy.hexWord(cpu.pc));
		  }
		
		  switch (num) {
		   // Read Handlers go here
		//   case 0x00 :
		  // trace("Reading Joypad register");
		    //return registers[num];
		
		   case 0x41 :         // LCDSTAT
		
		    var output:int = 0;
		
		    if (registers.read(0x44) == registers.read(0x45)) {
		     output |= 4;
		    }
		
		    var cyclePos:int = cpu.instrCount % cpu.INSTRS_PER_HBLANK;
		    var sectionLength:int = cpu.INSTRS_PER_HBLANK / 6;
		
		    if (Gameboy.unsign(registers.read(0x44)) > 144) {
		     output |= 1;
		    } else {
		     if (cyclePos <= sectionLength * 3) {
		      // Mode 0
		     } else if (cyclePos <= sectionLength * 4) {
		      // Mode 2
		      output |= 2;
		     } else {
		      output |= 3;
		     }
		    }
		
		
		//    trace("Checking LCDSTAT");
		    return output | (registers.read(0x41) & 0xF8);
		
		//   case 0x44 :
		//    trace("Checking LCDY at " + Javaboy.hexWord(cpu.pc));
		//    return registers[num];
		
		   case 0x55 :
		    return registers.read(0x55);
		
		   case 0x69 :       // GBC BG Sprite palette
		
		    if (cpu.gbcFeatures) {
		     palNumber = (registers.read(0x68) & 0x38) >> 3;
		     return cpu.ppu.gbcBackground[palNumber].getGbcColours(
		       (Gameboy.unsign(registers.read(0x68)) & 0x06) >> 1,
		       (Gameboy.unsign(registers.read(0x68)) & 0x01) == 1);
		    } else {
		     return registers.read(num);
		    }
		
		
		   case 0x6B :       // GBC OBJ Sprite palette
		
		    if (cpu.gbcFeatures) {
		     palNumber = (registers.read(0x6A) & 0x38) >> 3;
		     return cpu.ppu.gbcSprite[palNumber].getGbcColours(
		       (Gameboy.unsign(registers.read(0x6A)) & 0x06) >> 1,
		       (Gameboy.unsign(registers.read(0x6A)) & 0x01) == 1);
		    } else {
		     return registers.read(num);
		    }
		
		   default:
		    return registers.read(num);
		  }
		 }
		
		 /** Write data to IO Ram */
		 public function ioWrite(num:int, data:int):void {	//@param data:short
		  var soundOn:Boolean = (cpu.apu != null);
		
		 if (num <= 0x4B) {
		//  trace("Write of register " + Javaboy.hexByte(num) + " to " + Javaboy.hexWord(data) + " at " + Javaboy.hexWord(cpu.pc));
		 }
		
		  switch (num) {
		   case 0x00 :           // FF00 - Joypad
		    var output:int = 0x0F;
		    if ((data & 0x10) == 0x00) {   // P14
		     if (padRight) {
		      output &= ~1;
		     }
		     if (padLeft) {
		      output &= ~2;
		     }
		     if (padUp) {
		      output &= ~4;
		     }
		     if (padDown) {
		      output &= ~8;
		     }
		    }
		    if ((data & 0x20) == 0x00) {   // P15
		     if (padA) {
		      output &= ~0x01;
		     }
		     if (padB) {
		      output &= ~0x02;
		     }
		     if (padSelect) {
		      output &= ~0x04;
		     }
		     if (padStart) {
		      output &= ~0x08;
		     }
		    }
			output |= (data & 0xF0);
		    registers.write(0x00, output);
		//    trace("Joypad port = " + Javaboy.hexByte(data) + " output = " + Javaboy.hexByte(output) + "(PC=" + Javaboy.hexWord(cpu.pc) + ")");
		    break;
		
		   case 0x02 :           // Serial
		    registers.write(0x02, data);
			if ((registers.read(0x02) & 0x01) == 1) {
		     registers.write(0x01, 0xFF); // when no LAN connection, always receive 0xFF from port.  Simulates empty socket.
		     if (cpu.running) cpu.triggerInterruptIfEnabled(cpu.INT_SER);
		     registers.write(0x02, registers.read(0x02) & 0x7F);
			}
		    break;
		
		   case 0x04 :           // DIV
		    registers.write(04, 0);
		    break;    
		
		   case 0x07 :           // TAC
		    if ((data & 0x04) == 0) {
		     cpu.timaEnabled = false;
		    } else {
		     cpu.timaEnabled = true;
		    }
		
		    var instrsPerSecond:int = cpu.INSTRS_PER_VBLANK * 60;
		    var clockFrequency:int = (data & 0x03);
		
		    switch (clockFrequency) {
		     case 0: cpu.instrsPerTima = (instrsPerSecond / 4096);
		             break;
		     case 1: cpu.instrsPerTima = (instrsPerSecond / 262144);
		             break;
		     case 2: cpu.instrsPerTima = (instrsPerSecond / 65536);
		             break;
		     case 3: cpu.instrsPerTima = (instrsPerSecond / 16384);
		             break;
		    }
		    break;
		
		   case 0x10 :           // Sound channel 1, sweep
		    if (soundOn)
		     cpu.apu.channel1.setSweep(
		        (Gameboy.unsign(data) & 0x70) >> 4,
		        (Gameboy.unsign(data) & 0x07),
		        (Gameboy.unsign(data) & 0x08) == 1);
		    registers.write(0x10, data);
		    break;
		
		   case 0x11 :           // Sound channel 1, length and wave duty
		    if (soundOn) {
		     cpu.apu.channel1.setDutyCycle((Gameboy.unsign(data) & 0xC0) >> 6);
		     cpu.apu.channel1.setLength(Gameboy.unsign(data) & 0x3F);
		    }
		    registers.write(0x11, data);
		    break;
		
		   case 0x12 :           // Sound channel 1, volume envelope
		    if (soundOn) {
		     cpu.apu.channel1.setEnvelope(
		      (Gameboy.unsign(data) & 0xF0) >> 4,
		      (Gameboy.unsign(data) & 0x07),
		      (Gameboy.unsign(data) & 0x08) == 8);
		    }
		    registers.write(0x12, data);
		    break;
		
		   case 0x13 :           // Sound channel 1, frequency low
		    registers.write(0x13, data);
		    if (soundOn) {
		     cpu.apu.channel1.setFrequency(((Gameboy.unsign(registers.read(0x14)) & 0x07) << 8) + Gameboy.unsign(registers.read(0x13)));
		    }
		    break;
		
		   case 0x14 :           // Sound channel 1, frequency high
		    registers.write(0x14, data);
		
		    if (soundOn) {
		     if ((registers.read(0x14) & 0x80) != 0) {
		      cpu.apu.channel1.setLength(Gameboy.unsign(registers.read(0x11)) & 0x3F);
		      cpu.apu.channel1.setEnvelope(
		       (Gameboy.unsign(registers.read(0x12)) & 0xF0) >> 4,
		       (Gameboy.unsign(registers.read(0x12)) & 0x07),
		       (Gameboy.unsign(registers.read(0x12)) & 0x08) == 8);
		     }
		     if ((registers.read(0x14) & 0x40) == 0) {
		      cpu.apu.channel1.setLength(-1);
		     }
		
		     cpu.apu.channel1.setFrequency(
		         ((int) (Gameboy.unsign(registers.read(0x14)) & 0x07) << 8) + Gameboy.unsign(registers.read(0x13)));
		    }
		    break;
		
		   case 0x17 :           // Sound channel 2, volume envelope
		    if (soundOn) {
		     cpu.apu.channel2.setEnvelope(
		      (Gameboy.unsign(data) & 0xF0) >> 4,
		      (Gameboy.unsign(data) & 0x07),
		      (Gameboy.unsign(data) & 0x08) == 8);
		    }
		    registers.write(0x17, data);
		    break;
		
		   case 0x18 :           // Sound channel 2, frequency low
		    registers.write(0x18, data);
		    if (soundOn) {
		     cpu.apu.channel2.setFrequency(
		        ((Gameboy.unsign(registers.read(0x19)) & 0x07) << 8) + Gameboy.unsign(registers.read(0x18)));
		    }
		    break;
		
		   case 0x19 :           // Sound channel 2, frequency high
		    registers.write(0x19, data);
		
		    if (soundOn) {
		     if ((registers.read(0x19) & 0x80) != 0) {
		      cpu.apu.channel2.setLength(Gameboy.unsign(registers.read(0x21)) & 0x3F);
		      cpu.apu.channel2.setEnvelope(
		       (Gameboy.unsign(registers.read(0x17)) & 0xF0) >> 4,
		       (Gameboy.unsign(registers.read(0x17)) & 0x07),
		       (Gameboy.unsign(registers.read(0x17)) & 0x08) == 8);
		     }
		     if ((registers.read(0x19) & 0x40) == 0) {
		      cpu.apu.channel2.setLength(-1);
		     }
		     cpu.apu.channel2.setFrequency(
		         ((Gameboy.unsign(registers.read(0x19)) & 0x07) << 8) + Gameboy.unsign(registers.read(0x18)));
		    }
		    break;
		
		   case 0x16 :           // Sound channel 2, length and wave duty
		    if (soundOn) {
		     cpu.apu.channel2.setDutyCycle((Gameboy.unsign(data) & 0xC0) >> 6);
		     cpu.apu.channel2.setLength(Gameboy.unsign(data) & 0x3F);
		    }
		    registers.write(0x16, data);
		    break;
		
		   case 0x1A :           // Sound channel 3, on/off
		    if (soundOn) {
		     if ((Gameboy.unsign(data) & 0x80) != 0) {
		      cpu.apu.channel3.setVolume((Gameboy.unsign(registers.read(0x1C)) & 0x60) >> 5);
		     } else {
		      cpu.apu.channel3.setVolume(0);
		     }
		    }
		//    trace("Channel 3 enable: " + data);
		    registers.write(0x1A, data);
		    break;
		
		   case 0x1B :           // Sound channel 3, length
		//    trace("D:" + data);
		    registers.write(0x1B, data);
		    if (soundOn) cpu.apu.channel3.setLength(Gameboy.unsign(data));
		    break;
		
		   case 0x1C :           // Sound channel 3, volume
		    registers.write(0x1C, data);
		    if (soundOn) cpu.apu.channel3.setVolume((Gameboy.unsign(registers.read(0x1C)) & 0x60) >> 5);
		    break;
		
		   case 0x1D :           // Sound channel 3, frequency lower 8-bit
		    registers.write(0x1D, data);
		    if (soundOn) cpu.apu.channel3.setFrequency(
		        ((int) (Gameboy.unsign(registers.read(0x1E)) & 0x07) << 8) + Gameboy.unsign(registers.read(0x1D)));
		    break;
		
		   case 0x1E :           // Sound channel 3, frequency higher 3-bit
		    registers.write(0x1E, data);
		    if (soundOn) {
		     if ((registers.read(0x19) & 0x80) != 0) {
		      cpu.apu.channel3.setLength(Gameboy.unsign(registers.read(0x1B)));
		     }
		     cpu.apu.channel3.setFrequency(
		         ((Gameboy.unsign(registers.read(0x1E)) & 0x07) << 8) + Gameboy.unsign(registers.read(0x1D)));
		    }
		    break;
		
		   case 0x20 :           // Sound channel 4, length
		    if (soundOn) cpu.apu.channel4.setLength(Gameboy.unsign(data) & 0x3F);
		    registers.write(0x20, data);
		    break;
		
		
		   case 0x21 :           // Sound channel 4, volume envelope
		    if (soundOn) cpu.apu.channel4.setEnvelope(
		      (Gameboy.unsign(data) & 0xF0) >> 4,
		      (Gameboy.unsign(data) & 0x07),
		      (Gameboy.unsign(data) & 0x08) == 8);
		    registers.write(0x21, data);
		    break;
		
		   case 0x22 :           // Sound channel 4, polynomial parameters
		    if (soundOn) cpu.apu.channel4.setParameters(
		      (Gameboy.unsign(data) & 0x07),
		      (Gameboy.unsign(data) & 0x08) == 8,
		      (Gameboy.unsign(data) & 0xF0) >> 4);
			registers.write(0x22, data);
		    break;
		
		   case 0x23 :          // Sound channel 4, initial/consecutive
		    registers.write(0x23, data);
		    if (soundOn) {
		     if ((registers.read(0x23) & 0x80) != 0) {
		      cpu.apu.channel4.setLength(Gameboy.unsign(registers.read(0x20)) & 0x3F);
		     }
		     if ((registers.read(0x23) & 0x40) == 0) {
		      cpu.apu.channel4.setLength(-1);
		     }
		    }
		    break;
		
		   case 0x25 :           // Stereo select
		    var chanData:int;
		
		    registers.write(0x25, data);
		
		    if (soundOn) {
		     chanData = 0;
		     if ((Gameboy.unsign(data) & 0x01) != 0) {
		      chanData |= SquareWaveGenerator.CHAN_LEFT;
		     }
		     if ((Gameboy.unsign(data) & 0x10) != 0) {
		      chanData |= SquareWaveGenerator.CHAN_RIGHT;
		     }
		     cpu.apu.channel1.setChannel(chanData);
		
		     chanData = 0;
		     if ((Gameboy.unsign(data) & 0x02) != 0) {
		      chanData |= SquareWaveGenerator.CHAN_LEFT;
		     }
		     if ((Gameboy.unsign(data) & 0x20) != 0) {
		      chanData |= SquareWaveGenerator.CHAN_RIGHT;
		     }
		     cpu.apu.channel2.setChannel(chanData);
		
		     chanData = 0;
		     if ((Gameboy.unsign(data) & 0x04) != 0) {
		      chanData |= SquareWaveGenerator.CHAN_LEFT;
		     }
		     if ((Gameboy.unsign(data) & 0x40) != 0) {
		      chanData |= SquareWaveGenerator.CHAN_RIGHT;
		     }
		     cpu.apu.channel3.setChannel(chanData);
		    }
		
		    break;
		
		   case 0x30 :
		   case 0x31 :
		   case 0x32 :
		   case 0x33 :
		   case 0x34 :
		   case 0x35 :
		   case 0x36 :
		   case 0x37 :
		   case 0x38 :
		   case 0x39 :
		   case 0x3A :
		   case 0x3B :
		   case 0x3C :
		   case 0x3D :
		   case 0x3E :
		   case 0x3F :
		    if (soundOn) cpu.apu.channel3.setSamplePair(num - 0x30, Gameboy.unsign(data));
		    registers.write(num, data);
		    break;
		
		
		   case 0x40 :           // LCDC
		//    trace("LCDC write at " + Javaboy.hexWord(cpu.pc) + " = " + Javaboy.hexWord(data));
		    cpu.ppu.bgEnabled = true;
		
		    if ((data & 0x20) == 0x20) {     // BIT 5
		     cpu.ppu.winEnabled = true;
		    } else {
		     cpu.ppu.winEnabled = false;
		    }
		
		    if ((data & 0x10) == 0x10) {     // BIT 4
		     cpu.ppu.bgWindowDataSelect = true;
		    } else {
		     cpu.ppu.bgWindowDataSelect = false;
		    }
		
		    if ((data & 0x08) == 0x08) {
		     cpu.ppu.hiBgTileMapAddress = true;
		    } else {
		     cpu.ppu.hiBgTileMapAddress = false;
		    }
		
		    if ((data & 0x04) == 0x04) {      // BIT 2
		     cpu.ppu.doubledSprites = true;
		    } else {
		     cpu.ppu.doubledSprites = false;
		    }
		
		    if ((data & 0x02) == 0x02) {     // BIT 1
		     cpu.ppu.spritesEnabled = true;
		    } else {
		     cpu.ppu.spritesEnabled = false;
		    }
		
		    if ((data & 0x01) == 0x00) {     // BIT 0
		     cpu.ppu.bgEnabled = false;
		     cpu.ppu.winEnabled = false;
		    }
		
		    registers.write(0x40, data);
		    break;
		
		   case 0x41 :
		//    trace("STAT set to " + data + " lcdc is " + Javaboy.unsign(registers[0x44]) + " pc is " + Javaboy.hexWord(cpu.pc));
			registers.write(0x41, data);
			break;
		
		   case 0x42 :           // SCY
		//    trace("SCY set to " + data + " lcdc is " + Javaboy.unsign(registers[0x44]) + " pc is " + Javaboy.hexWord(cpu.pc));
		    registers.write(0x42, data);
		    break;
		
		   case 0x43 :           // SCX
		//    trace("SCX set to " + data + " lcdc is " + Javaboy.unsign(registers[0x44]) + " pc is " + Javaboy.hexWord(cpu.pc));
		    registers.write(0x43, data);
		    break;
		
		   case 0x46 :           // DMA
		    var sourceAddress:int = (data << 8);
		//    trace("DMA Transfer initiated from " + Javaboy.hexWord(sourceAddress) + "!");
		
		    // This could be sped up using System.arrayCopy, but hey.
		    for (var i:int = 0x00; i < 0xA0; i++) {
		     cpu.addressWrite(0xFE00 + i, cpu.addressRead(sourceAddress + i));
		    }
		    // This is meant to be run at the same time as the CPU is executing
		    // instructions, but I don't think it's crucial.
		    break;
		   case 0x47 :           // FF47 - BKG and WIN palette
		//    trace("Palette created!");
		    cpu.ppu.backgroundPalette.decodePalette(data);
		    if (registers.read(num) != data) {
		     registers.write(num, data);
		     cpu.ppu.invalidateAllByAttribs(PPU.TILE_BKG);
		    }
		    break;
		   case 0x48 :           // FF48 - OBJ1 palette
		    cpu.ppu.obj1Palette.decodePalette(data);
		    if (registers.read(num) != data) {
		     registers.write(num, data);
		     cpu.ppu.invalidateAllByAttribs(PPU.TILE_OBJ1);
		    }
		    break;
		   case 0x49 :           // FF49 - OBJ2 palette
		    cpu.ppu.obj2Palette.decodePalette(data);
		    if (registers.read(num) != data) {
		     registers.write(num, data);
		     cpu.ppu.invalidateAllByAttribs(PPU.TILE_OBJ2);
		    }
		    break;
		
		   case 0x4F :
		    if (cpu.gbcFeatures) {
		     cpu.ppu.tileStart = (data & 0x01) * 384;
		     cpu.ppu.vidRamStart = (data & 0x01) * 0x2000;
		    }
		    registers.write(0x4F, data);
		    break;
		
		
		   case 0x55 :
		    if ((!hdmaRunning) && ((registers.read(0x55) & 0x80) == 0) && ((data & 0x80) == 0) ) {
		     var dmaSrc:int = (Gameboy.unsign(registers.read(0x51)) << 8) +
		                      (Gameboy.unsign(registers.read(0x52)) & 0xF0);
		     var dmaDst:int = ((Gameboy.unsign(registers.read(0x53)) & 0x1F) << 8) +
		                      (Gameboy.unsign(registers.read(0x54)) & 0xF0) + 0x8000;
		     var dmaLen:int = ((Gameboy.unsign(data) & 0x7F) * 16) + 16;
		
		     if (dmaLen > 2048) dmaLen = 2048;
		
		     for (var r:int = 0; r < dmaLen; r++) {
		      cpu.addressWrite(dmaDst + r, cpu.addressRead(dmaSrc + r));
		     }
		    } else {
		     if ((Gameboy.unsign(data) & 0x80) == 0x80) {
		      hdmaRunning = true;
		//      trace("HDMA started");
		      registers.write(0x55, (data & 0x7F));
		      break;
		     } else if ((hdmaRunning) && ((Gameboy.unsign(data) & 0x80) == 0)) {
		      hdmaRunning = false;
		//      trace("HDMA stopped");
		     }
		    }
		
		    registers.write(0x55, data);
		    break;
		
		   case 0x69 :           // FF69 - BCPD: GBC BG Palette data write
		
		    if (cpu.gbcFeatures) {
		     var palNumber:int = (registers.read(0x68) & 0x38) >> 3;
		     cpu.ppu.gbcBackground[palNumber].setGbcColours(
		       (Gameboy.unsign(registers.read(0x68)) & 0x06) >> 1,
		       (Gameboy.unsign(registers.read(0x68)) & 0x01) == 1, Gameboy.unsign(data));
		     cpu.ppu.invalidateAllByAttribs(palNumber * 4);
		 
		     if ((Gameboy.unsign(registers.read(0x68)) & 0x80) != 0) {
		      registers.write(0x68, registers.read(0x68) + 1);
		     }
		
		    }
		
		
		    registers.write(0x69, data);
		    break;
		
		   case 0x6B :           // FF6B - OCPD: GBC Sprite Palette data write
		
		    if (cpu.gbcFeatures) {
		     palNumber = (registers.read(0x6A) & 0x38) >> 3;
		//     System.out.print("Pal " + palNumber + "  ");
		     cpu.ppu.gbcSprite[palNumber].setGbcColours(
		       (Gameboy.unsign(registers.read(0x6A)) & 0x06) >> 1,
		       (Gameboy.unsign(registers.read(0x6A)) & 0x01) == 1, Gameboy.unsign(data));
		     cpu.ppu.invalidateAllByAttribs((palNumber * 4) + 32);
		
		     if ((Gameboy.unsign(registers.read(0x6A)) & 0x80) != 0) {
		      if ((registers.read(0x6A) & 0x3F) == 0x3F) {
		       registers.write(0x6A, 0x80);
		      } else {
		       registers.write(0x6A, registers.read(0x6A) + 1);
		      }
		     }
		    }
		
		    registers.write(0x6B, data);
		    break;
		
		   case 0x70 :           // FF70 - GBC Work RAM bank
		    if (cpu.gbcFeatures) {
		     if (((data & 0x07) == 0) || ((data & 0x07) == 1)) {
		      cpu.gbcRamBank = 1;
		     } else {
		      cpu.gbcRamBank = data & 0x07;
		     }
		    }
		    registers.write(0x70, data);
		    break;
		
		   default:
		
		    registers.write(num, data);
		    break;
		  }
		 }
	}
}