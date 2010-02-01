package com.mobswing.gb
{
	import __AS3__.vec.Vector;
	
	import flash.errors.IOError;
	import flash.system.System;
	import flash.utils.ByteArray;

	public class CPU
	{
		private	static const cyclesPerInstr:Vector.<int> = Vector.<int>([
			1, 3, 2, 2, 1, 1, 2, 1,  5, 2, 2, 2, 1, 1, 2, 1,
			1, 3, 2, 2, 1, 1, 2, 1,  3, 2, 2, 2, 1, 1, 2, 1,
			3, 3, 2, 2, 1, 1, 2, 1,  3, 2, 2, 2, 1, 1, 2, 1,
			3, 3, 2, 2, 3, 3, 3, 1,  3, 2, 2, 2, 1, 1, 2, 1,
			
			1, 1, 1, 1, 1, 1, 2, 1,  1, 1, 1, 1, 1, 1, 2, 1,
			1, 1, 1, 1, 1, 1, 2, 1,  1, 1, 1, 1, 1, 1, 2, 1,
			1, 1, 1, 1, 1, 1, 2, 1,  1, 1, 1, 1, 1, 1, 2, 1,
			2, 2, 2, 2, 2, 2, 1, 2,  1, 1, 1, 1, 1, 1, 2, 1,
			
			1, 1, 1, 1, 1, 1, 2, 1,  1, 1, 1, 1, 1, 1, 2, 1,
			1, 1, 1, 1, 1, 1, 2, 1,  1, 1, 1, 1, 1, 1, 2, 1,
			1, 1, 1, 1, 1, 1, 2, 1,  1, 1, 1, 1, 1, 1, 2, 1,
			1, 1, 1, 1, 1, 1, 2, 1,  1, 1, 1, 1, 1, 1, 2, 1,
			
			5, 3, 4, 4, 6, 4, 2, 4,  5, 4, 4, 0, 6, 6, 2, 4,
			5, 3, 4, 0, 6, 4, 2, 4,  5, 4, 4, 0, 6, 0, 2, 4,
			3, 3, 2, 0, 0, 4, 2, 4,  4, 1, 4, 0, 0, 0, 2, 4,
			3, 3, 2, 1, 0, 4, 2, 4,  3, 2, 4, 1, 0, 0, 2, 4,
		]);
		private	static const cyclesPerInstrShift:Vector.<int> = Vector.<int>([
			2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
			2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
			2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
			2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
			
			2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2,
			2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2,
			2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2,
			2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2,
			
			2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
			2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
			2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
			2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
			
			2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
			2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
			2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
			2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
		]);
		private static var midiLookup:Vector.<int>;
		
		private	const F_ZERO				:int = 0x80;
		private const F_SUBTRACT			:int = 0x40;
		private const F_HALFCARRY			:int = 0x20;
		private const F_CARRY				:int = 0x10;
		private	const BASE_INSTRS_IN_MODE_0	:int = 51;
		private	const BASE_INSTRS_IN_MODE_2	:int = 20;
		private	const BASE_INSTRS_IN_MODE_3	:int = 43;
		private	const INSTRS_PER_DIV		:int = 64;
		private	var INSTRS_IN_MODE_0		:int = BASE_INSTRS_IN_MODE_0;
		private	var INSTRS_IN_MODE_2		:int = BASE_INSTRS_IN_MODE_2;
		private	var INSTRS_IN_MODE_3		:int = BASE_INSTRS_IN_MODE_3;
		public	const INT_VBLANK			:int = 0x01;
		public	const INT_LCDC				:int = 0x02;
		public	const INT_TIMA				:int = 0x04;
		public	const INT_SER				:int = 0x08;
		public	const INT_P10				:int = 0x10;
		private	const MASTER_VOLUME			:int = 8;
		
		private	var a:int, b:int, c:int, d:int, e:int, f:int;
		private	var sp:int, hl:int;
		private	var newf:int;
		private var b1:int, b2:int, offset:int, b3:int;

		private	var decoderMemory			:ByteArrayAdvanced;		// byte array
		private	var localPC					:int;
		private	var globalPC				:int;
		private	var decoderMaxCruise		:int;
		private	var instrCount				:int;
		private	var graphicsChipMode		:int;
		private	var nextModeTime			:int;
		private	var nextTimaOverflow		:int;
		private	var nextTimedInterrupt		:int;
		public	var interruptsEnabled		:Boolean = false;
		public	var interruptsArmed			:Boolean = false;
		private	var timaActive				:Boolean;
		private	var interruptEnableRequested:Boolean;
		private	var p10Requested			:Boolean;
		public	var gbcFeatures				:Boolean;
		private	var gbcRamBank				:int;
		private	var hdmaRunning				:Boolean;
		public	var ppu						:PPU;
		public	var gb						:As3gb;
		public	var terminated				:Boolean;
		public	var cartName				:String;
		private	var cartType				:int;
		private	var rom						:Vector.<ByteArrayAdvanced>;	//2d byte array
		private	var cartRam					:Vector.<ByteArrayAdvanced>;	//2d byte array
		private	var divReset				:int;
		private	var instrsPerTima			:int = 256;
		private	var buttonState				:int;
		public	var memory					:Vector.<ByteArrayAdvanced> = new Vector.<ByteArrayAdvanced>(8);	//2d byte array
		private	var mainRam					:ByteArrayAdvanced;				//byte array
		public	var oam						:ByteArrayAdvanced = new ByteArrayAdvanced(0x100);	// byte[0x100];
		public	var registers				:ByteArrayAdvanced = new ByteArrayAdvanced(0x100);	// byte[0x100];
		private	var currentRomBank			:int = 1;
		private	var loadedRomBanks			:int;
		private	var romTouch				:Vector.<int>;
		private	var currentRamBank			:int;
		private	var mbc1LargeRamMode		:Boolean;
		private	var cartRamEnabled			:Boolean;
		private	var rtcReg					:ByteArrayAdvanced = new ByteArrayAdvanced(5);	// byte[5];
		private	var lastRtcUpdate			:int;
		private	var incflags				:Vector.<int> = new Vector.<int>(256);
		private	var decflags				:Vector.<int> = new Vector.<int>(256);
		private	var soundLength				:Vector.<int> = new Vector.<int>(3);
		private	var soundVolume				:Vector.<int> = new Vector.<int>(3);
		private	var soundFrequency			:Vector.<int> = new Vector.<int>(3);
		private	var soundStartVolume		:Vector.<int> = new Vector.<int>(2);
		private	var soundVolumeDelta		:Vector.<int> = new Vector.<int>(3);
		private	var soundVolumeDeltaPeriod	:Vector.<int> = new Vector.<int>(3);
		private	var soundVolumeDeltaStep	:Vector.<int> = new Vector.<int>(2);
		
		public function CPU()
		{
			if (midiLookup == null)
			{
				midiLookup = new Vector.<int>(2048);
				var cutoff:Array = [
					100,  210,  313,  410,  502,  589,  671,  748,  821,  890,  955,
					1016, 1074, 1129, 1181, 1229, 1275, 1319, 1360, 1398, 1435, 1469,
					1502, 1532, 1561, 1589, 1615, 1639, 1662, 1684, 1704, 1723, 1742,
					1759, 1775, 1790, 1805, 1819, 1832, 1844, 1855, 1866, 1876, 1886,
					1895, 1904, 1912, 1919, 1927, 1934, 1940, 1946, 1952, 1957, 1962,
					1967, 1972, 1976, 1980, 1984, 1988, 1991, 1994, 1997, 2000, 2003,
					2005, 2008, 2010, 2012, 2014, 2016, 2018, 2020, 2021, 2023, 2024,
					2026, 2027, 2028, 2029, 2048
				];
				var ix:int = 0;
				for (var i:int = 0; i < 2048; i++)
				{
					if (i == cutoff[ix])
						ix++;
					midiLookup[i] = 36+ix;
				}
			}
			
			this.gb = Globals.gb;
			Globals.cpu = this;
			initCartridge(Globals.cartridge);
			if (Globals.advancedGraphics)
				Globals.ppu = new PPUAdvance(this);
			else
				Globals.ppu = new PPUSimple();
			this.ppu = Globals.ppu;
			
			memory[6] = mainRam;
			memory[7] = mainRam;
			
			interruptsEnabled = false;
			
			a = gbcFeatures ? 0x11 : 0x01;
			b = 0x00;
			c = 0x13;
			d = 0x00;
			e = 0xd8;
			f = 0xB0;
			hl = 0x014D;
			setPC(0x0100);
			sp = 0xFFFE;
	
			graphicsChipMode = 0;
			nextModeTime = 0;
			timaActive = false;
			interruptEnableRequested = false;
			nextTimedInterrupt = 0;
			
			initIncDecFlags();
	
			ioHandlerReset();
			
			if (Globals.enableSound)
				initSound();
		}
		
		private	function initSound():void
		{
/* 			try {
				player = Manager.createPlayer(Manager.MIDI_DEVICE_LOCATOR);
				player.realize();
				player.start();
				synth = (MIDIControl) player.getControl("MIDIControl");
				if (MeBoy.advancedSound) {
					synth.shortMidiEvent(0xC0, 81, 0);
					synth.shortMidiEvent(0xC1, 81, 0);
					synth.shortMidiEvent(0xC2, 81, 0);
				}
			} catch (Exception ex) {
				ex.printStackTrace();
			} */
		}
		
		private	function initIncDecFlags():void
		{
			var i:int;
			incflags[0] = F_ZERO + F_HALFCARRY;
			for (i = 0x10; i < 0x100; i += 0x10)
				incflags[i] = F_HALFCARRY;
			
			decflags[0] = F_ZERO + F_SUBTRACT;
			for (i = 1; i < 0x100; i++)
				decflags[i] = F_SUBTRACT + (((i & 0x0f) == 0x0f) ? F_HALFCARRY : 0);
		}

		public	function addressRead(addr:int):int
		{
			if (addr < 0xa000)
			{
				return memory[addr >> 13].read(addr & 0x1fff);
			}
			else if (addr < 0xc000)
			{
				if (currentRamBank >= 8)
				{
					rtcSync();
					return rtcReg.read(currentRamBank - 8);
				}
				else
				{
					return memory[addr >> 13].read(addr & 0x1fff);
				}
			}
			else if ((addr & 0x1000) == 0)
			{
				return mainRam.read(addr & 0x0fff);
			}
			else if (addr < 0xfe00)
			{
				return mainRam.read((addr & 0x0fff) + gbcRamBank * 0x1000);
			}
			else if (addr < 0xFF00)
			{
				if (addr > 0xFEA0)
					return 0xff;
				return (oam.read(addr - 0xFE00) & 0xFF);
			}
			else
			{
				return ioRead(addr - 0xFF00);
			}
		}
		
		public	function addressWrite(addr:int, data:int):void
		{
			var bank:int = addr >> 12;
			switch (bank)
			{
			case 0x0:
			case 0x1:
			case 0x2:
			case 0x3:
			case 0x4:
			case 0x5:
			case 0x6:
			case 0x7:
				cartridgeWrite(addr, data);
				break;
			case 0x8:
			case 0x9:
				ppu.addressWrite(addr - 0x8000, data);
				break;
			case 0xA:
			case 0xB:
				cartridgeWrite(addr, data);
				break;
			case 0xC:
				mainRam.write(addr - 0xC000, data);
				break;
			case 0xD:
				mainRam.write(addr - 0xD000 + gbcRamBank * 0x1000, data);
				break;
			case 0xE:
				mainRam.write(addr - 0xE000, data);
				break;
			case 0xF:
				if (addr < 0xFE00)
					mainRam.write(addr - 0xF000 + gbcRamBank * 0x1000, data);
				else if (addr < 0xFF00)
					oam.write(addr - 0xFE00, data);
				else
					ioWrite(addr - 0xFF00, data);
				break;
			}
		}
		
		private	function pushPC():void
		{
			var pc:int = globalPC + localPC;
			if ((sp >> 13) == 6)
			{
				mainRam.write(--sp - 0xC000, (pc >> 8));
				mainRam.write(--sp - 0xC000, pc);
			}
			else
			{
				addressWrite(--sp, pc >> 8);
				addressWrite(--sp, pc & 0xFF);
			}
		}
		
		private	function popPC():void
		{
			if (sp >> 13 == 6)
				setPC((mainRam.read(sp++ - 0xc000) & 0xff) + ((mainRam.read(sp++ - 0xc000) & 0xff) << 8));
			else
				setPC((addressRead(sp++) & 0xff) + ((addressRead(sp++) & 0xff) << 8));
		}
		
		private	function registerRead(regNum:int):int
		{
			switch (regNum)
			{
			case 0:
				return b;
			case 1:
				return c;
			case 2:
				return d;
			case 3:
				return e;
			case 4:
				return (hl >> 8);
			case 5:
				return (hl & 0xFF);
			case 6:
				return addressRead(hl) & 0xff;
			case 7:
				return a;
			default:
				return -1;
			}
		}
		
		private	function registerWrite(regNum:int, data:int):void
		{
			switch (regNum)
			{
			case 0:
				b = data;
				return;
			case 1:
				c = data;
				return;
			case 2:
				d = data;
				return;
			case 3:
				e = data;
				return;
			case 4:
				hl = (hl & 0x00FF) | (data << 8);
				return;
			case 5:
				hl = (hl & 0xFF00) | data;
				return;
			case 6:
				addressWrite(hl, data);
				return;
			case 7:
				a = data;
				return;
			default:
				return;
			}
		}
		
		private	function performHdma():void
		{
			var dmaSrc:int = ((registers.read(0x51) & 0xff) << 8) + ((registers.read(0x52) & 0xff) & 0xF0);
			var dmaDst:int = ((registers.read(0x53) & 0x1F) << 8) + (registers.read(0x54) & 0xF0) + 0x8000;
		
			for (var r:int = 0; r < 16; r++)
			{
				addressWrite(dmaDst + r, addressRead(dmaSrc + r));
			}
		
			dmaSrc += 16;
			dmaDst += 16;
			registers.write(0x51, (dmaSrc & 0xFF00) >> 8);
			registers.write(0x52, dmaSrc & 0x00F0);
			registers.write(0x53, (dmaDst & 0x1F00) >> 8);
			registers.write(0x54, dmaDst & 0x00F0);
		
			if (registers.read(0x55) == 0)
				hdmaRunning = false;
			registers.write(0x55, registers.read(0x55) + 1);
		}
		
		public	function playSound(channel:int, volume:int):void
		{
/* 			if (player == null)
				return;
			
			try {
				// first (interesting) sound register
				int basereg = 0x12 + channel * 5;
				
				int frequency = ((registers[basereg + 2] & 0x07) << 8) + (registers[basereg + 1] & 0xff);
				int n = midiLookup[frequency];
				
				if ((registers[basereg + 2] & 0x40) == 0) {
					soundLength[channel] = Integer.MAX_VALUE;
				}
		
				if (channel < 2) {
					soundStartVolume[channel] = volume;
					
					soundVolumeDelta[channel] = (registers[basereg] & 0x08) != 0 ? 1 : -1;
					soundVolumeDeltaPeriod[channel] = registers[basereg] & 0x07;
					soundVolumeDeltaStep[channel] = 0;
					if (soundVolumeDeltaPeriod[channel] == 0)
						soundVolumeDelta[channel] = 0;
				}
		
				if (channel == 2)
					n -= 12;
		
				if (MeBoy.advancedSound) {
					if (soundFrequency[channel] > 0) {
						synth.shortMidiEvent(0x80 + channel, soundFrequency[channel], 127);
					}
		
					soundFrequency[channel] = n;
		
					synth.shortMidiEvent(0xB0 + channel, 7, volume * MASTER_VOLUME);
		
					if (channel == 0) {
						// reset pitch wheel
						synth.shortMidiEvent(0xE0, 0x2000 & 127, 0x2000 >> 7);
					}
		
					synth.shortMidiEvent(0x90 + channel, n, 127);
				} else {
					if (soundFrequency[channel] > 0) {
						synth.shortMidiEvent(0x80 + channel, soundFrequency[channel], soundVolume[channel] * MASTER_VOLUME);
					}
		
					soundFrequency[channel] = n;
					synth.shortMidiEvent(0x90 + channel, n, volume * MASTER_VOLUME);
				}
				soundVolume[channel] = volume;
			} catch (Exception ex) {
				ex.printStackTrace();
			} */
		}
		
		public	function updateSoundFrequency():void
		{
/* 			if (player == null)
				return;
		
			if (soundFrequency[0] <= 0 || !MeBoy.advancedSound)
				return;
		
			int frequency = ((registers[0x14] & 0x07) << 8) + (registers[0x13] & 0xff);
			int n = midiLookup[frequency];
		
			try {
				int wheel = 0x2000 + 1000 * (n - soundFrequency[0]);
				if (wheel < 0)
					wheel = 0;
				if (wheel > 16383)
					wheel = 16383;
				
				synth.shortMidiEvent(0xE0, wheel & 127, wheel >> 7);
			} catch (Exception ex) {
				ex.printStackTrace();
			} */
		}
		
		public	function updateSound(channel:int):void
		{
/* 			if (player == null)
				return;
			
			if (soundFrequency[channel] <= 0)
				return;
			
			try {
				soundLength[channel] -= 4;
		
				if (soundLength[channel] <= 0) {
					stopSound(channel);
				}
		
				if (channel < 2 && soundVolumeDelta[channel] != 0) {
					if (++soundVolumeDeltaStep[channel] >= soundVolumeDeltaPeriod[channel]) {
						soundVolumeDeltaStep[channel] = 0;
						soundVolume[channel] = (soundVolume[channel] + soundVolumeDelta[channel]) & 0x0f;
		
						if (soundVolume[channel] == 0) {
							stopSound(channel);
						} else if (MeBoy.advancedSound) {
							synth.shortMidiEvent(0xB0 + channel, 7, soundVolume[channel] * MASTER_VOLUME);
						}
					}
				}
			} catch (Exception ex) {
				ex.printStackTrace();
			} */
		}
		
		public	function stopSound(channel:int):void
		{
/* 			if (player == null)
				return;
			
			try {
				if (soundFrequency[channel] > 0) {
					if (MeBoy.advancedSound) {
						synth.shortMidiEvent(0x80 + channel, soundFrequency[channel], 127);
					} else {
						synth.shortMidiEvent(0x80 + channel, soundFrequency[channel], soundVolume[channel] * MASTER_VOLUME);
					}
				}
		
				soundFrequency[channel] = -1;
			} catch (Exception ex) {
				ex.printStackTrace();
			} */
		}

		private	function checkInterrupts():void
		{
			pushPC();
			
			var mask:int = registers.read(0xff) & registers.read(0x0f);
			
			if ((mask & INT_VBLANK) != 0)
			{
				setPC(0x40);
				registers.write(0x0f, registers.read(0x0f) - INT_VBLANK);
			}
			else if ((mask & INT_LCDC) != 0)
			{
				setPC(0x48);
				registers.write(0x0f, registers.read(0x0f) - INT_LCDC);
			}
			else if ((mask & INT_TIMA) != 0)
			{
				setPC(0x50);
				registers.write(0x0f, registers.read(0x0f) - INT_TIMA);
			}
			else if ((mask & INT_SER) != 0)
			{
				setPC(0x58);
				registers.write(0x0f, registers[0x0f] - INT_SER);
			}
			else if ((mask & INT_P10) != 0)
			{
				setPC(0x60);
				registers.write(0x0f, registers[0x0f] - INT_P10);
			}
			
			interruptsEnabled = false;
			interruptsArmed = (registers.read(0xff) & registers.read(0x0f)) != 0;
		}
		
		private	function initiateInterrupts():void
		{
			var line:int;
			if (instrCount - nextModeTime >= 0)
			{
				if (graphicsChipMode == 3)
				{
					graphicsChipMode = 0;
					nextModeTime += INSTRS_IN_MODE_0;
					
					line = registers.read(0x44) & 0xff;
					
					if (line < 144)
					{
						if (gbcFeatures && hdmaRunning)
						{
							performHdma();
						}
							
						if (((registers.read(0x40) & 0x80) != 0) && ((registers.read(0xff) & INT_LCDC) != 0))
						{
							if (((registers.read(0x41) & 0x08) != 0))
							{
								interruptsArmed = true;
								registers.write(0x0f, registers.read(0x0f) | INT_LCDC);
							}
						}
					}
				}
				else if (graphicsChipMode == 0)
				{
					graphicsChipMode = 2;
					nextModeTime += INSTRS_IN_MODE_2;
					
					registers.write(0x44, registers.read(0x44) + 1);
					if ((registers.read(0x44) & 0xff) == 154)
					{
						registers.write(0x44, 0);
					}
					
					line = registers.read(0x44) & 0xff;
					
					if (line < 144)
					{
						if (((registers.read(0x41) & 0x20) != 0))
						{
							interruptsArmed = true;
							registers.write(0x0f, registers.read(0x0f) | INT_LCDC);
						}
					}
					
					if (((registers.read(0x40) & 0x80) != 0) && ((registers.read(0xff) & INT_LCDC) != 0))
					{
						if (((registers.read(0x41) & 0x40) != 0) && ((registers.read(0x45) & 0xff) == line))
						{
							interruptsArmed = true;
							registers.write(0x0f, registers.read(0x0f) | INT_LCDC);
						}
					}
					
					if (line == 144)
					{
						ppu.vBlank();
		
						if (((registers.read(0x40) & 0x80) != 0) && ((registers.read(0xff) & INT_VBLANK) != 0))
						{
							interruptsArmed = true;
							registers.write(0x0f, registers.read(0x0f) | INT_VBLANK);
		
							if (((registers.read(0x41) & 0x10) != 0) && ((registers.read(0xff) & INT_LCDC) != 0))
							{
								registers.write(0x0f, registers.read(0x0f) | INT_LCDC);
							}
						}
						
						for (var i:int = 0; i < 3; i++)
							updateSound(i);
					}
					
					if (line == 0)
					{
						if (p10Requested) {
							p10Requested = false;
							
							if ((registers.read(0xff) & INT_P10) != 0)
							{
								registers.write(0x0f, registers.read(0x0f) | INT_P10);
							}
			
							interruptsArmed = (registers.read(0xff) & registers.read(0x0f)) != 0;
						}
					}
				}
				else
				{
					graphicsChipMode = 3;
					nextModeTime += INSTRS_IN_MODE_3;
					
					line = registers.read(0x44) & 0xff;
					if (line < 144)
					{
						ppu.notifyScanline(line);
					}
				}
			}
			
			if (timaActive && instrCount - nextTimaOverflow >= 0)
			{
				nextTimaOverflow += instrsPerTima * (0x100 - (registers.read(0x06) & 0xff));
				
				if ((registers.read(0xff) & INT_TIMA) != 0)
				{
					interruptsArmed = true;
					registers.write(0x0f, registers.read(0x0f) | INT_TIMA);
				}
			}
	
			if (interruptEnableRequested)
			{
				interruptsEnabled = true;
				interruptEnableRequested = false;
			}
			
			nextTimedInterrupt = nextModeTime;
			if (timaActive && nextTimaOverflow < nextTimedInterrupt)
				nextTimedInterrupt = nextTimaOverflow;
		}
		
		public	function setPC(pc:int):void
		{
			if (pc < 0xff00)
			{
				decoderMemory = memory[pc >> 13];
				localPC = pc & 0x1fff;
				globalPC = pc & 0xe000;
				decoderMaxCruise = (pc < 0xe000) ? 0x1ffd : 0x1dfd;
				if (gbcFeatures)
				{
					if (gbcRamBank > 1 && pc >= 0xC000)
						decoderMaxCruise &= 0x0fff;
				}
			}
			else
			{
				decoderMemory = registers;
				localPC = pc & 0xff;
				globalPC = 0xff00;
				decoderMaxCruise = 0xfd;
			}
		}
		
		private	function executeShift(b2:int):void
		{
			var regNum:int = b2 & 0x07;
			var data:int = registerRead(regNum);
			var newf:int;
			
			instrCount += cyclesPerInstrShift[b2];
			
			if ((b2 & 0xC0) == 0)
			{
				switch ((b2 & 0xF8))
				{
				case 0x00: // RLC A
					f = 0;
					if (data >= 0x80)
						f = F_CARRY;
					data = (data << 1) & 0xff;
					if ((f & F_CARRY) != 0)
						data |= 1;
					break;
				case 0x08: // RRC A
					f = 0;
					if ((data & 0x01) != 0)
						f = F_CARRY;
					data >>= 1;
					if ((f & F_CARRY) != 0)
						data |= 0x80;
					break;
				case 0x10: // RL r
					if (data >= 0x80)
						newf = F_CARRY;
					else
						newf = 0;
					data = (data << 1) & 0xff;
					
					if ((f & F_CARRY) != 0)
						data |= 1;
					f = newf;
					break;
				case 0x18: // RR r
					if ((data & 0x01) != 0)
						newf = F_CARRY;
					else
						newf = 0;
					data >>= 1;
					
					if ((f & F_CARRY) != 0)
						data |= 0x80;
					f = newf;
					break;
				case 0x20: // SLA r
					f = 0;
					if ((data & 0x80) != 0)
						f = F_CARRY;
					data = (data << 1) & 0xff;
					break;
				case 0x28: // SRA r
					f = 0;
					if ((data & 0x01) != 0)
						f = F_CARRY;
					data = (data & 0x80) + (data >> 1);
					break;
				case 0x30: // SWAP r
					data = (((data & 0x0F) << 4) | (data >> 4));
					f = 0;
					break;
				case 0x38: // SRL r
					f = 0;
					if ((data & 0x01) != 0)
						f = F_CARRY;
					data >>= 1;
					break;
				}
				
				if (data == 0)
					f |= F_ZERO;
				registerWrite(regNum, data);
			}
			else
			{
				var bitMask:int = 1 << ((b2 & 0x38) >> 3);
				
				if ((b2 & 0xC0) == 0x40)		 // BIT n, r
				{
					f = ((f & F_CARRY) | F_HALFCARRY);
					if ((data & bitMask) == 0)
					{
						f |= F_ZERO;
					}
				} 
				else if ((b2 & 0xC0) == 0x80)	// RES n, r
				{
					registerWrite(regNum, (data & (0xFF - bitMask)));
				}
				else if ((b2 & 0xC0) == 0xC0)	// SET n, r
				{
					registerWrite(regNum, (data | bitMask));
				}
			}
		}
		
		private	function executeDAA():void
		{
			var upperNibble:int = (a >> 4) & 0x0f;
			var lowerNibble:int = a & 0x0f;
			
			var newf:int = f & (F_SUBTRACT | F_CARRY);
			
			if ((f & F_SUBTRACT) == 0)
			{
				if ((f & F_CARRY) == 0)
				{
					if ((upperNibble <= 8) && (lowerNibble >= 0xA) && ((f & F_HALFCARRY) == 0))
						a += 0x06;
					
					if ((upperNibble <= 9) && (lowerNibble <= 0x3) && ((f & F_HALFCARRY) != 0))
						a += 0x06;
					
					if ((upperNibble >= 0xA) && (lowerNibble <= 0x9) && ((f & F_HALFCARRY) == 0))
					{
						a += 0x60;
						newf |= F_CARRY;
					}
					
					if ((upperNibble >= 0x9) && (lowerNibble >= 0xA) && ((f & F_HALFCARRY) == 0))
					{
						a += 0x66;
						newf |= F_CARRY;
					}
					
					if ((upperNibble >= 0xA) && (lowerNibble <= 0x3) && ((f & F_HALFCARRY) != 0))
					{
						a += 0x66;
						newf |= F_CARRY;
					}
					
				} 
				else
				{
					if ((upperNibble <= 0x2) && (lowerNibble <= 0x9) && ((f & F_HALFCARRY) == 0))
						a += 0x60;
					
					if ((upperNibble <= 0x2) && (lowerNibble >= 0xA) && ((f & F_HALFCARRY) == 0))
						a += 0x66;
					
					if ((upperNibble <= 0x3) && (lowerNibble <= 0x3) && ((f & F_HALFCARRY) != 0))
						a += 0x66;
				}
			}
			else
			{
				if ((f & F_CARRY) == 0)
				{
					if ((upperNibble <= 0x8) && (lowerNibble >= 0x6) && ((f & F_HALFCARRY) != 0))
						a += 0xFA;
				}
				else 
				{
					if ((upperNibble >= 0x7) && (lowerNibble <= 0x9) && ((f & F_HALFCARRY) == 0))
						a += 0xA0;
					
					if ((upperNibble >= 0x6) && (lowerNibble >= 0x6) && ((f & F_HALFCARRY) != 0))
						a += 0x9A;
				}
			}
				
			a &= 0xff;
			if (a == 0)
				newf |= F_ZERO;
			f = newf;
		}

		private	function executeALU(b1:int):void
		{
			var operand:int = registerRead(b1 & 0x07);
			switch ((b1 & 0x38) >> 3)
			{
			case 1: // ADC A, r
				if ((f & F_CARRY) != 0)
					operand++;
				// Note!  No break!
			case 0: // ADD A, r
				if ((a & 0x0F) + (operand & 0x0F) >= 0x10)
					f = F_HALFCARRY;
				else
					f = 0;
				
				a += operand;
				
				if (a > 0xff)
				{
					f |= F_CARRY;
					a &= 0xff;
				}
				
				if (a == 0)
					f |= F_ZERO;
				break;
			case 3: // SBC A, r
				if ((f & F_CARRY) != 0)
					operand++;
				// Note! No break!
			case 2: // SUB A, r
				f = F_SUBTRACT;
				if ((a & 0x0F) < (operand & 0x0F))
					f |= F_HALFCARRY;
				a -= operand;
				
				if (a < 0)
				{
					f |= F_CARRY;
					a &= 0xff;
				}
				if (a == 0)
					f |= F_ZERO;
				break;
			case 4: // AND A, r
				a &= operand;
				if (a == 0)
					f = F_HALFCARRY + F_ZERO;
				else
					f = F_HALFCARRY;
				break;
			case 5: // XOR A, r
				a ^= operand;
				f = (a == 0) ? F_ZERO : 0;
				break;
			case 6: // OR A, r
				a |= operand;
				f = (a == 0) ? F_ZERO : 0;
				break;
			case 7: // CP A, r (compare)
				f = F_SUBTRACT;
				if (a == operand)
					f |= F_ZERO;
				else if (a < operand)
					f |= F_CARRY;
			
				if ((a & 0x0F) < (operand & 0x0F))
					f |= F_HALFCARRY;
				break;
			}
		}
		
		public	function beforeLoop():void
		{
			terminated = false;

			newf = 0;
			b1 = 0;
			b2 = 0;
			offset = 0;
			b3 = 0;
			
			System.gc();
			ppu.timer = SystemTimer.getCurrentTimeMillis();
		}
		
		public	function loop(obj:Object = null):Boolean
		{
			if (terminated)
				return false;
			
			if (localPC <= decoderMaxCruise)
			{
				b1 = decoderMemory.read(localPC++) & 0xff;
				offset = decoderMemory.read(localPC);
				b2 = offset & 0xff;
				b3 = decoderMemory.read(localPC + 1);
			}
			else
			{
				var pc:int = localPC + globalPC;
				b1 = addressRead(pc++) & 0xff;
				offset = addressRead(pc);
				b2 = offset & 0xff;
				b3 = addressRead(pc + 1);
				setPC(pc);
			}

			switch (b1)
			{
				case 0x00: // NOP
					break;
				case 0x01: // LD BC, nn
					localPC += 2;
					b = b3 & 0xff;
					c = b2;
					break;
				case 0x02: // LD (BC), A
					addressWrite((b << 8) | c, a);
					break;
				case 0x03: // INC BC
					c++;
					if (c == 0x0100)
					{
						c = 0;
						b = (b + 1) & 0xff;
					}
					break;
				case 0x04: // INC B
					b = (b + 1) & 0xff;
					f = (f & F_CARRY) | incflags[b];
					break;
				case 0x05: // DEC B
					b = (b - 1) & 0xff;
					f = (f & F_CARRY) | decflags[b];
					break;
				case 0x06: // LD B, nn
					localPC++;
					b = b2;
					break;
				case 0x07: // RLC A
					if (a >= 0x80)
					{
						f = F_CARRY;
						a = ((a << 1) + 1) & 0xff;
					}
					else if (a == 0)
					{
						f = F_ZERO;
					}
					else
					{
						a <<= 1;
						f = 0;
					}
					break;
				case 0x08: // LD (nnnn), SP
					localPC += 2;
					newf = ((b3 & 0xff) << 8) + b2;
					addressWrite(newf, sp);
					addressWrite(newf + 1, sp >> 8);
					break;
				case 0x09: // ADD HL, BC
					hl = (hl + ((b << 8) + c));
					if ((hl & 0xffff0000) != 0)
					{
						f = (f & F_ZERO) | F_CARRY; // halfcarry is wrong
						hl &= 0xFFFF;
					}
					else
					{
						f &= F_ZERO; // halfcarry is wrong
					}
					break;
				case 0x0A: // LD A, (BC)
					a = addressRead((b << 8) + c) & 0xff;
					break;
				case 0x0B: // DEC BC
					c--;
					if (c < 0)
					{
						c = 0xFF;
						b = (b - 1) & 0xff;
					}
					break;
				case 0x0C: // INC C
					c = (c + 1) & 0xff;
					f = (f & F_CARRY) | incflags[c];
					break;
				case 0x0D: // DEC C
					c = (c - 1) & 0xff;
					f = (f & F_CARRY) | decflags[c];
					break;
				case 0x0E: // LD C, nn
					localPC++;
					c = b2;
					break;
				case 0x0F: // RRC A
					if ((a & 0x01) == 0x01)
						f = F_CARRY;
					else
						f = 0;
					a >>= 1;
					if ((f & F_CARRY) != 0)
						a |= 0x80;
					if (a == 0)
						f |= F_ZERO;
					break;
				case 0x10: // STOP
					localPC++;
					if (gbcFeatures)
					{
						if ((registers.read(0x4D) & 0x01) != 0)
						{
							var newKey1Reg:int = registers.read(0x4D) & 0xFE;
							var multiplier:int = 1;
							if ((newKey1Reg & 0x80) != 0)
							{
								newKey1Reg &= 0x7F;
							}
							else
							{
								multiplier = 2;
								newKey1Reg |= 0x80;
							}
							INSTRS_IN_MODE_0 = BASE_INSTRS_IN_MODE_0 * multiplier;
							INSTRS_IN_MODE_2 = BASE_INSTRS_IN_MODE_2 * multiplier;
							INSTRS_IN_MODE_3 = BASE_INSTRS_IN_MODE_3 * multiplier;
							registers.write(0x4D, newKey1Reg);
						}
					}
					break;
				case 0x11: // LD DE, nnnn
					localPC += 2;
					d = b3 & 0xff;
					e = b2;
					break;
				case 0x12: // LD (DE), A
					addressWrite((d << 8) + e, a);
					break;
				case 0x13: // INC DE
					e++;
					if (e == 0x0100)
					{
						e = 0;
						d = (d + 1) & 0xff;
					}
					break;
				case 0x14: // INC D
					d = (d + 1) & 0xff;
					f = (f & F_CARRY) | incflags[d];
					break;
				case 0x15: // DEC D
					d = (d - 1) & 0xff;
					f = (f & F_CARRY) | decflags[d];
					break;
				case 0x16: // LD D, nn
					localPC++;
					d = b2;
					break;
				case 0x17: // RL A
					if ((a & 0x80) != 0)
						newf = F_CARRY;
					else
						newf = 0;
					a <<= 1;
					if ((f & F_CARRY) != 0)
						a |= 1;
					
					a &= 0xFF;
					if (a == 0)
						newf |= F_ZERO;
					f = newf;
					break;
				case 0x18: // JR nn
					localPC += 1 + offset;
					if (localPC < 0 || localPC > decoderMaxCruise)
						setPC(localPC + globalPC);
					break;
				case 0x19: // ADD HL, DE
					hl += ((d << 8) + e);
					if ((hl & 0xFFFF0000) != 0)
					{
						f = ((f & F_ZERO) | F_CARRY); // halfcarry is wrong
						hl &= 0xFFFF;
					}
					else
					{
						f &= F_ZERO; // halfcarry is wrong
					}
					break;
				case 0x1A: // LD A, (DE)
					a = (addressRead((d << 8) + e)) & 0xff;
					break;
				case 0x1B: // DEC DE
					e--;
					if (e < 0)
					{
						e = 0xFF;
						d = (d - 1) & 0xff;
					}
					break;
				case 0x1C: // INC E
					e = (e + 1) & 0xff;
					f = (f & F_CARRY) | incflags[e];
					break;
				case 0x1D: // DEC E
					e = (e - 1) & 0xff;
					f = (f & F_CARRY) | decflags[e];
					break;
				case 0x1E: // LD E, nn
					localPC++;
					e = b2;
					break;
				case 0x1F: // RR A
					if ((a & 0x01) != 0)
						newf = F_CARRY;
					else
						newf = 0;
					a >>= 1;

					if ((f & F_CARRY) != 0)
						a |= 0x80;

					if (a == 0)
						newf |= F_ZERO;
					f = newf;
					break;
				case 0x20: // JR NZ, nn
					if (f < F_ZERO)
					{
						localPC += 1 + offset;
						if (localPC < 0 || localPC > decoderMaxCruise)
							setPC(localPC + globalPC);
					}
					else
					{
						localPC++;
					}
					break;
				case 0x21: // LD HL, nnnn
					localPC += 2;
					hl = ((b3 & 0xff) << 8) + b2;
					break;
				case 0x22: // LD (HL+), A
					addressWrite(hl++, a);
					break;
				case 0x23: // INC HL
					hl = (hl + 1) & 0xFFFF;
					break;
				case 0x24: // INC H
					b2 = ((hl >> 8) + 1) & 0xff;
					f = (f & F_CARRY) | incflags[b2];
					hl = (hl & 0xff) + (b2 << 8);
					break;
				case 0x25: // DEC H
					b2 = ((hl >> 8) - 1) & 0xff;
					f = (f & F_CARRY) | decflags[b2];
					hl = (hl & 0xff) + (b2 << 8);
					break;
				case 0x26: // LD H, nn
					localPC++;
					hl = (hl & 0xFF) | (b2 << 8);
					break;
				case 0x27: // DAA
					executeDAA();
					break;
				case 0x28: // JR Z, nn
					if (f >= F_ZERO)
					{
						localPC += 1 + offset;
						if (localPC < 0 || localPC > decoderMaxCruise)
							setPC(localPC + globalPC);
					}
					else
					{
						localPC++;
					}
					break;
				case 0x29: // ADD HL, HL
					hl *= 2;
					if ((hl & 0xFFFF0000) != 0)
					{
						f = (f & F_ZERO) | F_CARRY; // halfcarry is wrong
						hl &= 0xFFFF;
					}
					else
					{
						f &= F_ZERO; // halfcarry is wrong
					}
					break;
				case 0x2A: // LDI A, (HL)
					a = addressRead(hl++) & 0xff;
					break;
				case 0x2B: // DEC HL
					hl = (hl - 1) & 0xffff;
					break;
				case 0x2C: // INC L
					b2 = (hl + 1) & 0xff;
					f = (f & F_CARRY) | incflags[b2];
					hl = (hl & 0xff00) + b2;
					break;
				case 0x2D: // DEC L
					b2 = (hl - 1) & 0xff;
					f = (f & F_CARRY) | decflags[b2];
					hl = (hl & 0xff00) + b2;
					break;
				case 0x2E: // LD L, nn
					localPC++;
					hl = (hl & 0xFF00) | b2;
					break;
				case 0x2F: // CPL A
					a = ((~a) & 0x00FF);
					f |= F_SUBTRACT | F_HALFCARRY;
					break;
				case 0x30: // JR NC, nn
					if ((f & F_CARRY) == 0)
					{
						localPC += 1 + offset;
						if (localPC < 0 || localPC > decoderMaxCruise)
							setPC(localPC + globalPC);
					}
					else
					{
						localPC++;
					}
					break;
				case 0x31: // LD SP, nnnn
					localPC += 2;
					sp = ((b3 & 0xff) << 8) + b2;
					break;
				case 0x32:
					addressWrite(hl--, a); // LD (HL-), A
					break;
				case 0x33: // INC SP
					sp = (sp + 1) & 0xFFFF;
					break;
				case 0x34: // INC (HL)
					b2 = (addressRead(hl) + 1) & 0xff;
					f = (f & F_CARRY) | incflags[b2];
					addressWrite(hl, b2);
					break;
				case 0x35: // DEC (HL)
					b2 = (addressRead(hl) - 1) & 0xff;
					f = (f & F_CARRY) | decflags[b2];
					addressWrite(hl, b2);
					break;
				case 0x36: // LD (HL), nn
					localPC++;
					addressWrite(hl, b2);
					break;
				case 0x37: // SCF
					f = (f & F_ZERO) | F_CARRY;
					break;
				case 0x38: // JR C, nn
					if ((f & F_CARRY) != 0)
					{
						localPC += 1 + offset;
						if (localPC < 0 || localPC > decoderMaxCruise)
							setPC(localPC + globalPC);
					}
					else
					{
						localPC += 1;
					}
					break;
				case 0x39: // ADD HL, SP
					hl += sp;
					if (hl > 0x0000FFFF)
					{
						f = (f & F_ZERO) | F_CARRY; // halfcarry is wrong
						hl &= 0xFFFF;
					}
					else
					{
						f &= F_ZERO; // halfcarry is wrong
					}
					break;
				case 0x3A: // LD A, (HL-)
					a = addressRead(hl--) & 0xff;
					break;
				case 0x3B: // DEC SP
					sp = (sp - 1) & 0xFFFF;
					break;
				case 0x3C: // INC A
					a = (a + 1) & 0xff;
					f = (f & F_CARRY) | incflags[a];
					break;
				case 0x3D: // DEC A
					a = (a - 1) & 0xff;
					f = (f & F_CARRY) | decflags[a];
					break;
				case 0x3E: // LD A, nn
					localPC++;
					a = b2;
					break;
				case 0x3F: // CCF
					f = (f & (F_CARRY | F_ZERO)) ^ F_CARRY;
					break;
					
					// B = r
				case 0x40: break;
				case 0x41: b = c; break;
				case 0x42: b = d; break;
				case 0x43: b = e; break;
				case 0x44: b = hl >> 8; break;
				case 0x45: b = hl & 0xFF; break;
				case 0x46: b = addressRead(hl) & 0xff; break;
				case 0x47: b = a; break;
					
					// C = r
				case 0x48: c = b; break;
				case 0x49: break;
				case 0x4a: c = d; break;
				case 0x4b: c = e; break;
				case 0x4c: c = hl >> 8; break;
				case 0x4d: c = hl & 0xFF; break;
				case 0x4e: c = addressRead(hl) & 0xff; break;
				case 0x4f: c = a; break;
					
					// D = r
				case 0x50: d = b; break;
				case 0x51: d = c; break;
				case 0x52: break;
				case 0x53: d = e; break;
				case 0x54: d = hl >> 8; break;
				case 0x55: d = hl & 0xFF; break;
				case 0x56: d = addressRead(hl) & 0xff; break;
				case 0x57: d = a; break;
					
					// E = r
				case 0x58: e = b; break;
				case 0x59: e = c; break;
				case 0x5a: e = d; break;
				case 0x5b: break;
				case 0x5c: e = hl >> 8; break;
				case 0x5d: e = hl & 0xFF; break;
				case 0x5e: e = addressRead(hl) & 0xff; break;
				case 0x5f: e = a; break;
					
					// h = r
				case 0x60: hl = (hl & 0xFF) | (b << 8); break;
				case 0x61: hl = (hl & 0xFF) | (c << 8); break;
				case 0x62: hl = (hl & 0xFF) | (d << 8); break;
				case 0x63: hl = (hl & 0xFF) | (e << 8); break;
				case 0x64: break;
				case 0x65: hl = (hl & 0xFF) * 0x0101; break;
				case 0x66: hl = (hl & 0xFF) | ((addressRead(hl) & 0xff) << 8); break;
				case 0x67: hl = (hl & 0xFF) | (a << 8); break;
					
					// l = r
				case 0x68: hl = (hl & 0xFF00) | b; break;
				case 0x69: hl = (hl & 0xFF00) | c; break;
				case 0x6a: hl = (hl & 0xFF00) | d; break;
				case 0x6b: hl = (hl & 0xFF00) | e; break;
				case 0x6c: hl = (hl >> 8) * 0x0101; break;
				case 0x6d: break;
				case 0x6e: hl = (hl & 0xFF00) | (addressRead(hl) & 0xff); break;
				case 0x6f: hl = (hl & 0xFF00) | a; break;
					
					// (hl) = r
				case 0x70: addressWrite(hl, b); break;
				case 0x71: addressWrite(hl, c); break;
				case 0x72: addressWrite(hl, d); break;
				case 0x73: addressWrite(hl, e); break;
				case 0x74: addressWrite(hl, hl >> 8); break;
				case 0x75: addressWrite(hl, hl); break;
				case 0x76: // HALT
					interruptsEnabled = true;
					if (interruptsArmed)
					{
						nextTimedInterrupt = instrCount;
					}
					else
					{
						while (!interruptsArmed)
						{
							instrCount = nextTimedInterrupt;
							initiateInterrupts();
						}
						instrCount++;
						nextTimedInterrupt = instrCount;
					}
					break;
				case 0x77: addressWrite(hl, a); break;
					
					// LD A, n:
				case 0x78: a = b; break;
				case 0x79: a = c; break;
				case 0x7a: a = d; break;
				case 0x7b: a = e; break;
				case 0x7c: a = (hl >> 8); break;
				case 0x7d: a = (hl & 0xFF); break;
				case 0x7e: a = addressRead(hl) & 0xff; break;
				case 0x7f: break;
					
				// ALU, 0x80 - 0xbf
					
				case 0xA7: // AND A, A
					if (a == 0)
						f = F_HALFCARRY + F_ZERO;
					else
						f = F_HALFCARRY;
					break;
				case 0xAF: // XOR A, A (== LD A, 0)
					a = 0;
					f = F_ZERO;
					break;
				case 0xC0: // RET NZ
					if (f < F_ZERO)
						popPC();
					break;
				case 0xC1: // POP BC
					c = addressRead(sp++) & 0xff;
					b = addressRead(sp++) & 0xff;
					break;
				case 0xC2: // JP NZ, nnnn
					if (f < F_ZERO)
						setPC(((b3 & 0xff) << 8) + b2);
					else
						localPC += 2;
					break;
				case 0xC3: // JP nnnn
					setPC(((b3 & 0xff) << 8) + b2);
					break;
				case 0xC4: // CALL NZ, nnnn
					localPC += 2;
					if (f < F_ZERO)
					{
						pushPC();
						setPC(((b3 & 0xff) << 8) + b2);
					}
					break;
				case 0xC5: // PUSH BC
					addressWrite(--sp, b);
					addressWrite(--sp, c);
					break;
				case 0xC6: // ADD A, nn
					localPC++;
					if ((a & 0x0F) + (b2 & 0x0F) >= 0x10)
						f = F_HALFCARRY;
					else
						f = 0;
					
					a += b2;
					
					if (a > 0xff)
					{
						f |= F_CARRY;
						a &= 0xff;
					}
					
					if (a == 0)
						f |= F_ZERO;
					break;
				case 0xC7: // RST 00
					pushPC();
					setPC(0x00);
					break;
				case 0xC8: // RET Z
					if (f >= F_ZERO)
						popPC();
					break;
				case 0xC9: // RET
					popPC();
					break;
				case 0xCA: // JP Z, nnnn
					if (f >= F_ZERO)
						setPC(((b3 & 0xff) << 8) + b2);
					else
						localPC += 2;
					break;
				case 0xCB: // Shift/bit test
					localPC++;
					executeShift(b2);
					break;
				case 0xCC: // CALL Z, nnnn
					localPC += 2;
					if (f >= F_ZERO)
					{
						pushPC();
						setPC(((b3 & 0xff) << 8) + b2);
					}
					break;
				case 0xCD: // CALL nnnn
					localPC += 2;
					pushPC();
					setPC(((b3 & 0xff) << 8) + b2);
					break;
				case 0xCE: // ADC A, nn
					localPC++;
					if ((f & F_CARRY) != 0)
						b2++;
					if ((a & 0x0F) + (b2 & 0x0F) >= 0x10)
						f = F_HALFCARRY;
					else
						f = 0;
					
					a += b2;
				
					if (a > 0xff)
					{
						f |= F_CARRY;
						a &= 0xff;
					}
					
					if (a == 0)
						f |= F_ZERO;
					break;
				case 0xCF: // RST 08
					pushPC();
					setPC(0x08);
					break;
				case 0xD0: // RET NC
					if ((f & F_CARRY) == 0)
						popPC();
					break;
				case 0xD1: // POP DE
					e = addressRead(sp++) & 0xff;
					d = addressRead(sp++) & 0xff;
					break;
				case 0xD2: // JP NC, nnnn
					if ((f & F_CARRY) == 0)
						setPC(((b3 & 0xff) << 8) + b2);
					else
						localPC += 2;
					break;
				case 0xD4: // CALL NC, nnnn
					localPC += 2;
					if ((f & F_CARRY) == 0)
					{
						pushPC();
						setPC(((b3 & 0xff) << 8) + b2);
					}
					break;
				case 0xD5: // PUSH DE
					addressWrite(--sp, d);
					addressWrite(--sp, e);
					break;
				case 0xD6: // SUB A, nn
					localPC++;
					
					f = F_SUBTRACT;
					
					if ((a & 0x0F) < (b2 & 0x0F))
						f |= F_HALFCARRY;
					
					a -= b2;
					
					if (a < 0)
					{
						f |= F_CARRY;
						a &= 0xff;
					}
					else if (a == 0)
					{
						f |= F_ZERO;
					}
					break;
				case 0xD7: // RST 10
					pushPC();
					setPC(0x10);
					break;
				case 0xD8: // RET C
					if ((f & F_CARRY) != 0)
						popPC();
					break;
				case 0xD9: // RETI
					interruptsEnabled = true;
					if (interruptsArmed)
						nextTimedInterrupt = instrCount;
					popPC();
					break;
				case 0xDA: // JP C, nnnn
					if ((f & F_CARRY) != 0)
						setPC(((b3 & 0xff) << 8) + b2);
					else
						localPC += 2;
					break;
				case 0xDC: // CALL C, nnnn
					localPC += 2;
					if ((f & F_CARRY) != 0)
					{
						pushPC();
						setPC(((b3 & 0xff) << 8) + b2);
					}
					break;
				case 0xDE: // SBC A, nn
					localPC++;
					if ((f & F_CARRY) != 0)
						b2++;
					
					f = F_SUBTRACT;
					if ((a & 0x0F) < (b2 & 0x0F))
						f |= F_HALFCARRY;
					
					a -= b2;
					
					if (a < 0)
					{
						f |= F_CARRY;
						a &= 0xff;
					}
					else if (a == 0)
					{
						f |= F_ZERO;
					}
					break;
				case 0xDF: // RST 18
					pushPC();
					setPC(0x18);
					break;
				case 0xE0: // LDH (FFnn), A
					localPC++;
					ioWrite(b2, a);
					break;
				case 0xE1: // POP HL
					hl = ((addressRead(sp + 1) & 0xff) << 8) + (addressRead(sp) & 0xff);
					sp += 2;
					break;
				case 0xE2: // LDH (FF00 + C), A
					ioWrite(c, a);
					break;
				case 0xE5: // PUSH HL
					addressWrite(--sp, hl >> 8);
					addressWrite(--sp, hl);
					break;
				case 0xE6: // AND nn
					localPC++;
					a &= b2;
					if (a == 0)
						f = F_ZERO;
					else
						f = 0;
					break;
				case 0xE7: // RST 20
					pushPC();
					setPC(0x20);
					break;
				case 0xE8: // ADD SP, nn
					localPC++;
					
					sp += offset;
					f = 0;
					if (sp > 0xffff || sp < 0)
					{
						sp &= 0xffff;
						f = F_CARRY;
					}
					break;
				case 0xE9: // JP (HL)
					setPC(hl);
					break;
				case 0xEA: // LD (nnnn), A
					localPC += 2;
					addressWrite(((b3 & 0xff) << 8) + b2, a);
					break;
				case 0xEE: // XOR A, nn
					localPC++;
					a ^= b2;
					f = 0;
					if (a == 0)
						f = F_ZERO;
					break;
				case 0xEF: // RST 28
					pushPC();
					setPC(0x28);
					break;
				case 0xF0: // LDH A, (FFnn)
					localPC++;
					a = ioRead(b2) & 0xff; // fixme, direct access?
					
					break;
				case 0xF1: // POP AF
					f = addressRead(sp++) & 0xff; // fixme, f0 or ff?
					a = addressRead(sp++) & 0xff;
					break;
				case 0xF2: // LD A, (FF00 + C)
					a = ioRead(c) & 0xff; // fixme, direct access?
					break;
				case 0xF3: // DI
					interruptsEnabled = false;
					break;
				case 0xF5: // PUSH AF
					addressWrite(--sp, a);
					addressWrite(--sp, f);
					break;
				case 0xF6: // OR A, nn
					localPC++;
					a |= b2;
					f = 0;
					if (a == 0)
						f = F_ZERO;
					break;
				case 0xF7: // RST 30
					pushPC();
					setPC(0x30);
					break;
				case 0xF8: // LD HL, SP + nn  ** HALFCARRY FLAG NOT SET ***
					localPC++;
					hl = (sp + offset);
					f = 0;
					if ((hl & 0xffff0000) != 0)
					{
						f = F_CARRY;
						hl &= 0xFFFF;
					}
					break;
				case 0xF9: // LD SP, HL
					sp = hl;
					break;
				case 0xFA: // LD A, (nnnn)
					localPC += 2;
					a = addressRead(((b3 & 0xff) << 8) + b2) & 0xff;
					break;
				case 0xFB: // EI
					interruptEnableRequested = true;
					nextTimedInterrupt = instrCount + cyclesPerInstr[b1] + 1; // fixme, this is an ugly hack
					break;
				case 0xFE: // CP nn
					localPC++;
					f = ((a & 0x0F) < (b2 & 0x0F)) ? F_HALFCARRY | F_SUBTRACT : F_SUBTRACT;
					if (a == b2)
						f |= F_ZERO;
					else if (a < b2)
						f |= F_CARRY;
					break;
				case 0xFF: // RST 38
					pushPC();
					setPC(0x38);
					break;
					
				default:
					if ((b1 & 0xC0) == 0x80)
						executeALU(b1);
					else
						throw new IOError(b1.toString(16));
			}
			
			instrCount += cyclesPerInstr[b1];
				
			if (instrCount - nextTimedInterrupt >= 0)
			{
				initiateInterrupts();
				if (interruptsArmed && interruptsEnabled)
				{
					checkInterrupts();
				}
			}
			
			return true;
		}

		private	function ioHandlerReset():void
		{
			ioWrite(0x0F, 0x01);
			ioWrite(0x26, 0xf1);
			ioWrite(0x40, 0x91);
			ioWrite(0x47, 0xFC);
			ioWrite(0x48, 0xFF);
			ioWrite(0x49, 0xFF);
			registers.write(0x55, 0x80);
			hdmaRunning = false;
		}
		
		private	function ioRead(num:int):int
		{
			if (num == 0x41)
			{
				// LCDSTAT
				var output:int = registers.read(0x41);
				
				if (registers.read(0x44) == registers.read(0x45))
				{
					output |= 4;
				}
				
				if ((registers.read(0x44) & 0xff) >= 144)
				{
					output |= 1; // mode 1
				}
				else
				{
					output |= graphicsChipMode;
				}
				return output;
			}
			else if (num == 0x04)
			{
				// DIV
				return int((instrCount - divReset - 1) / INSTRS_PER_DIV);
			}
			else if (num == 0x05)
			{
				// TIMA
				if (!timaActive)
					return registers.read(num);
				return ((instrCount + instrsPerTima * 0x100 - nextTimaOverflow) / instrsPerTima);
			}
			
			return registers.read(num);
		}
		
		public	function ioWrite(num:int, data:int):void
		{
			var next:int;

			switch (num)
			{
			case 0x00: // FF00 - Joypad
				var output:int = 0;
				if ((data & 0x10) == 0)
				{
					// P14
					output |= buttonState & 0x0f;
				}
			
				if ((data & 0x20) == 0)
				{
					// P15
					output |= buttonState >> 4;
				}
				// the high nybble is unused for reading (according to gbcpuman), but Japanese Pokemon
				// seems to require it to be set to f
				registers.write(0x00, int(0xf0 | (~output & 0x0f)));
				break;
			case 0x02: // Serial
				registers.write(0x02, data);
				
				if ((registers.read(0x02) & 0x01) == 1)
				{
					registers.write(0x01, 0xFF); // when no LAN connection, always receive 0xFF from port.  Simulates empty socket.
					if ((registers.read(0xff) & INT_SER) != 0)
					{
						interruptsArmed = true;
						registers.write(0x0f, registers.read(0x0f) | INT_SER);
						
						if (interruptsEnabled)
							nextTimedInterrupt = instrCount;
					}
					registers.write(0x02, registers.read(0x02) & 0x7F);
				}
				break;
			case 0x04: // DIV
				divReset = instrCount;
				break;
			case 0x05: // TIMA
				if (timaActive)
					nextTimaOverflow = instrCount + instrsPerTima * (0x100 - (data & 0xff));
				break;
			case 0x07: // TAC
				if ((data & 0x04) != 0)
				{
					if (!timaActive)
					{
						timaActive = true;
						nextTimaOverflow = instrCount + instrsPerTima * (0x100 - (registers.read(0x05) & 0xff));
					}
					instrsPerTima = 4 << (2 * ((data-1)&3));
					// 0-3 -> {256, 4, 16, 64}
				}
				else
				{
					if (timaActive)
					{
						timaActive = false;
						registers.write(0x05, int((instrCount + instrsPerTima * 0x100 - nextTimaOverflow) / instrsPerTima));
					}
				}
				registers.write(num, data);
				break;
			case 0x0f:
				registers.write(num, data);
				interruptsArmed = (registers[0xff] & registers[0x0f]) != 0;
				
				if (interruptsArmed && interruptsEnabled)
					nextTimedInterrupt = instrCount;
				break;
			// sound registers: 10 11 12 13 14 16 17 18 19 1a 1b 1c 1d 1e 20 21 22 23 24 25 26 30-3f
			
			// 0x10: Sound 1 freq sweep
			// 0x11: Sound 1 length
			case 0x12: // Sound 1 volume + volume sweep
				registers.write(num, data);
				if ((data & 0xf0) == 0)
					stopSound(0);
				break;
			// 0x13: Sound 1 freq 0-7
			case 0x14: // Sound 1 frequency 8-10 + control
				registers.write(num, data);
				if ((data & 0x80) != 0)
				{
					soundLength[0] = (64 - (registers.read(0x11) & 63));
					playSound(0, (registers.read(0x12) >> 4) & 0x0F);
				}
				else
				{
					updateSoundFrequency();
				}
				break;
			// 0x15: Unused
			// 0x16: Sound 2 length
			case 0x17: // Sound 2 volume + volume sweep
				registers.write(num, data);
				if ((data & 0xf0) == 0)
					stopSound(1);
				break;
			// 0x18: Sound 2 freq 0-7
			case 0x19: // Sound 2 frequency 8-10 + control
				registers.write(num, data);
				if ((data & 0x80) != 0)
				{
					soundLength[1] = (64 - (registers.read(0x16) & 63));
					playSound(1, (registers.read(0x17) >> 4) & 0x0F);
				}
				break;
			case 0x1a:
				// sound mode 3, on/off
				registers.write(num, data);
				if ((data & 0x80) == 0)
				{
					stopSound(2);
					registers[0x26] &= 0xfb; // clear bit 2 of sound status register
				}
				break;
			// 0x1b: Sound 3 length
			case 0x1c: // Sound 3 volume
				registers.write(num, data);
				if ((registers[num] & 0x60) == 0)
					stopSound(2);
				break;
			// 0x1d: Sound 3 freq 0-7
			case 0x1e: // Sound 3 frequency 8-10 + control
				registers.write(num, data);
				if ((data & 0x80) != 0)
				{
					soundLength[2] = (256 - (registers.read(0x1b) & 0xff));
					playSound(2, (((0x08 >> ((registers.read(0x1c) >> 5) & 3)) & 0x07))); // ugh
				}
				break;
			// 0x20-0x23: Sound 4
			
			// 0x24: Channel control
				
			// 0x25: Selection of sound terminal
				
			// 0x26: Sound on/off
				
			// 0x30-0x3f: Sound 3 wave pattern
			
			case 0x40: // LCDC
				ppu.UpdateLCDCFlags(data);
				registers.write(num, data);
				break;
			case 0x41: // LCDC
				registers.write(num, data & 0xf8);
				break;
			case 0x46: // DMA
				oam.position = 0;
				oam.writeBytes(memory[data >> 5], (data << 8) & 0x1f00, 0xa0);
				break;
			case 0x47: // FF47 - BKG and WIN palette
				ppu.decodePalette(0, data);
				if (registers.read(num) != data)
				{
					registers.write(num, data);
					ppu.invalidateAll(0);
				}
				break;
			case 0x48: // FF48 - OBJ1 palette
				ppu.decodePalette(4, data);
				if (registers.read(num) != data)
				{
					registers.write(num, data);
					ppu.invalidateAll(1);
				}
				break;
			case 0x49: // FF49 - OBJ2 palette
				ppu.decodePalette(8, data);
				if (registers.read(num) != data)
				{
					registers.write(num, data);
					ppu.invalidateAll(2);
				}
				break;
			
			case 0x4A: // FF4A - Window Position Y
				if ((data & 0xff) >= 144)
					ppu.stopWindowFromLine();
				registers.write(num, data);
				break;
				
			case 0x4B: // FF4B - Window Position X
				if ((data & 0xff) >= 167)
					ppu.stopWindowFromLine();
				registers.write(num, data);
				break;
				
			case 0x4D: // FF4D - KEY1 - CGB Mode Only - Prepare Speed Switch
				if (gbcFeatures)
				{
					// high bit is read only
					registers.write(num, (data & 0x7f) + (registers[num] & 0x80));
				}
				else
				{
					registers.write(num, data);
				}
				break;
			case 0x4F: // FF4F - VRAM Bank - GBC only
				if (gbcFeatures)
					ppu.setVRamBank(data & 0x01);
				registers.write(num, data);
				break;
			case 0x55: // FF55 - HDMA5 - GBC only
				if (gbcFeatures)
				{
					if (!hdmaRunning && (data & 0x80) == 0)
					{
						var dmaSrc:int = ((registers.read(0x51) & 0xff) << 8) + (registers.read(0x52) & 0xF0);
						var dmaDst:int = ((registers.read(0x53) & 0x1F) << 8) + (registers.read(0x54) & 0xF0);
						var dmaLen:int = ((data & 0x7F) * 16) + 16;
			
						for (var r:int = 0; r < dmaLen ; r++)
						{
							ppu.addressWrite(dmaDst + r, addressRead(dmaSrc + r));
						}
						// fixme, move instrCount?
						registers.write(0x55, 0xff);
					}
					else if ((data & 0x80) != 0)
					{
						// start hdma
						hdmaRunning = true;
						registers.write(0x55, data & 0x7F);
					}
					else
					{
						// stop hdma
						hdmaRunning = false;
						registers.write(0x55, registers.read(0x55) | 0x80);
					}
				}
				else
				{
					registers.write(num, data);
				}
				break;
			case 0x68: // FF68 - Background Palette Index - GBC only
				if (gbcFeatures)
					registers.write(0x69, ppu.getGBCPalette(data & 0x3f));
				registers.write(num, data);
				break;
			
			case 0x69: // FF69 - Background Palette Data - GBC only
				if (gbcFeatures)
				{
					ppu.setGBCPalette(registers.read(0x68) & 0x3f, data & 0xff);
			
					if (registers.read(0x68) < 0)
					{ // high bit = autoincrement
						next = ((registers.read(0x68) + 1) & 0x3f);
						registers.write(0x68, next + 0x80);
						registers.write(0x69, ppu.getGBCPalette(next));
					}
					else
					{
						registers.write(num, data);
					}
				}
				else
				{
					registers.write(num, data);
				}
				break;
			case 0x6A: // FF6A - Sprite Palette Index - GBC only
				if (gbcFeatures)
					registers.write(0x6B, ppu.getGBCPalette((data & 0x3f) + 0x40));
				registers.write(0x6A, data);
				break;
			case 0x6B: // FF6B - Sprite Palette Data - GBC only
				if (gbcFeatures)
				{
					ppu.setGBCPalette((registers.read(0x6A) & 0x3f) + 0x40, data & 0xff);
			
					if (registers.read(0x6A) < 0)
					{ // high bit = autoincrement
						next = ((registers.read(0x6A) + 1) & 0x3f);
						registers.write(0x6A, next + 0x80);
						registers.write(0x6B, ppu.getGBCPalette(next + 0x40));
					}
					else
					{
						registers.write(num, data);
					}
				}
				else
				{
					registers.write(num, data);
				}
				break;
			case 0x70: // FF70 - GBC Work RAM bank
				if (gbcFeatures)
				{
					if ((data & 0x07) < 2)
						gbcRamBank = 1;
					else
						gbcRamBank = data & 0x07;
					
					if (globalPC >= 0xC000)
						setPC(globalPC + localPC);
				}
				registers.write(num, data);
				break;
			case 0xff:
				registers.write(num, data);
				interruptsArmed = (registers.read(0xff) & registers.read(0x0f)) != 0;
				if (interruptsArmed && interruptsEnabled)
					nextTimedInterrupt = instrCount;
				break;
			default:
				registers.write(num, data);
				break;
			}
		}
		
		private	function initCartridge(cart:Cartridge):void
		{
			var i:int;
			
			var cartRom:ByteArray = Globals.cartridge.rom;
			var firstBank:ByteArrayAdvanced = new ByteArrayAdvanced(0x2000);
			firstBank.position = 0;
			firstBank.writeBytes(cartRom, 0, 0x2000);
			
			cartType = firstBank.read(0x0147) & 0xff;
			var numRomBanks:int = lookUpCartSize(firstBank.read(0x0148)); // Determine the number of 16kb rom banks
			gbcFeatures = ((firstBank.read(0x143) & 0x80) == 0x80) && (!Globals.disableColor);
			
			if (gbcFeatures)
				mainRam = new ByteArrayAdvanced(0x8000);	//32kB
			else
				mainRam = new ByteArrayAdvanced(0x2000);	//8kB
			gbcRamBank = 1;
			
			if (numRomBanks <= Globals.lazyLoadingThreshold)
			{
				rom = new Vector.<ByteArrayAdvanced>(numRomBanks * 2);
				rom[0] = firstBank;
				
				// Read ROM into memory
				for (i = 1 ; i < rom.length ; i++)
				{
					rom[i] = new ByteArrayAdvanced(0x2000);
					rom[i].position = 0;
					rom[i].writeBytes(cartRom, i*0x2000, 0x2000);
				}
			}
			else
			{
				rom = new Vector.<ByteArrayAdvanced>(numRomBanks * 2);
				rom[0] = firstBank;
				rom[1] = new ByteArrayAdvanced(0x2000);
				rom[1].position = 0;
				rom[1].writeBytes(cartRom, 0x2000, 0x2000);

				loadedRomBanks = 1;
			}
			
			memory[0] = rom[0];
			memory[1] = rom[1];
			romTouch = new Vector.<int>(rom.length/2);
			mapRom(1);
			
			var numRamBanks:int = getNumRAMBanks();
			
			if (numRamBanks == 0)
				numRamBanks = 1; // mbc2 has built-in ram, and anyway we want the memory mapped
			cartRam = new Vector.<ByteArrayAdvanced>(numRamBanks);
			for (i = 0 ; i < numRamBanks ; i++)
			{
				 cartRam[i] = new ByteArrayAdvanced(0x2000);
			}
			memory[5] = cartRam[0];
			
			lastRtcUpdate = SystemTimer.getCurrentTimeMillis();
		}
		
		private	function mapRom(bankNo:int):void
		{
			var i:int;

			bankNo = bankNo & ((rom.length >> 1) -1);
			currentRomBank = bankNo;
			
			romTouch[bankNo] = instrCount;
			if (rom[bankNo * 2] == null)
			{
				var newmem:Vector.<ByteArrayAdvanced> = new Vector.<ByteArrayAdvanced>(2);
				if (loadedRomBanks >= Globals.lazyLoadingThreshold)
				{
					// overwrite previous bank
					
					var candidate:int = 0; // candidate to be overwritten
					var candidateAge:int = 0x80000000;
					
					var bankCount:int = rom.length >> 1;
					
					// look for the oldest bank
					for (i = 1; i < bankCount; i++)
					{
						if (rom[i * 2] != null)
						{
							var age:int = instrCount - romTouch[i];
							if (age > candidateAge)
							{
								candidateAge = age;
								candidate = i;
							}
						}
					}
					
					newmem[0] = rom[candidate*2];
					newmem[1] = rom[candidate*2+1];
					rom[candidate*2] = null;
					rom[candidate*2+1] = null;
				}
				else
				{
					newmem[0] = new ByteArrayAdvanced(0x2000);
					newmem[1] = new ByteArrayAdvanced(0x2000);
					
					loadedRomBanks++;
				}
				
				var file:int = bankNo >> 3;
				var offset:int = (bankNo & 7) * 0x4000;
				var istream:ByteArray = Globals.cartridge.rom;
				
				var k:int = 0;
				for (i = bankNo*2 ; i < bankNo*2+2 ; i++)
				{
					rom[i] = newmem[i & 1];
					rom[i].position = 0;
					rom[i].writeBytes(istream, (file * 0x20000 + offset) + k*0x2000, 0x2000);
					k++;
				}
			}
			
			memory[2] = rom[bankNo*2];
			memory[3] = rom[bankNo*2+1];
			if ((globalPC & 0xC000) == 0x4000) {
				setPC(localPC + globalPC);
			}
		}
		
		private	function mapRam(bankNo:int):void
		{
			currentRamBank = bankNo;
			if (currentRamBank < cartRam.length)
				memory[5] = cartRam[currentRamBank];
		}
		
		private	function cartridgeWrite(addr:int, data:int):void
		{
			var halfbank:int = addr >> 13;
			var subaddr:int = addr & 0x1fff;
			var bankNo:int;
			
			switch (cartType)
			{
			case 0:
				// ROM Only
				break;
			
			case 1:
			case 2:
			case 3:
				// MBC1
				if (halfbank == 0)
				{
					cartRamEnabled = ((data & 0x0F) == 0x0A);
				}
				else if (halfbank == 1)
				{
					bankNo = data & 0x1F;
					if (bankNo == 0)
						bankNo = 1;
					mapRom((currentRomBank & 0x60) | bankNo);
				}
				else if (halfbank == 2)
				{
					if (mbc1LargeRamMode) 
						mapRam(data & 0x03);
					else
						mapRom((currentRomBank & 0x1F) | ((data & 0x03) << 5));
				}
				else if (halfbank == 3)
				{
					mbc1LargeRamMode = ((data & 1) == 1);
				}
				else if (halfbank == 5 && memory[halfbank] != null)
				{
					memory[halfbank].write(subaddr, data);
				}
				break;
			case 5:
			case 6:
				// MBC2
				if ((halfbank == 1))
				{
					if ((addr & 0x0100) != 0)
					{
						bankNo = data & 0x0F;
						if (bankNo == 0)
							bankNo = 1;
						mapRom(bankNo);
					}
					else
					{
						cartRamEnabled = ((data & 0x0F) == 0x0A);
					}
				}
				else if (halfbank == 5 && memory[halfbank] != null)
				{
					memory[halfbank].write(subaddr, data);
				}
				break;
			case 0x0F:
			case 0x10:
			case 0x11:
			case 0x12:
			case 0x13:
				// MBC3
				if (halfbank == 0)
				{
					cartRamEnabled = ((data & 0x0F) == 0x0A);
				}
				else if (halfbank == 1)
				{
					// Select ROM bank
					bankNo = data & 0x7F;
					if (bankNo == 0)
						bankNo = 1;
					mapRom(bankNo);
				}
				else if (halfbank == 2)
				{
					// Select RAM bank
					if (cartRam.length > 0)
						mapRam(data & 0x0f); // only 0-3 for ram banks, 8+ for RTC
				}
				else if (halfbank == 3)
				{
					// fixme, rtc latch
				}
				else if (halfbank == 5)
				{
					// memory write
					if (currentRamBank >= 8)
					{
						// rtc register
						rtcSync();
						rtcReg.write(currentRamBank - 8, data);
					}
					else if (memory[halfbank] != null)
					{
						memory[halfbank].write(subaddr, data);
					}
				}
				break;
			case 0x19:
			case 0x1A:
			case 0x1B:
			case 0x1C:
			case 0x1D:
			case 0x1E:
				// MBC5
				if (addr >> 12 == 1)
				{
					cartRamEnabled = ((data & 0x0F) == 0x0A);
				}
				else if (addr >> 12 == 2)
				{
					bankNo = (currentRomBank & 0xFF00) | data;
					// note: bank 0 can be mapped to 0x4000
					mapRom(bankNo);
				}
				else if (addr >> 12 == 3)
				{
					bankNo = (currentRomBank & 0x00FF) | ((data & 0x01) << 8);
					// note: bank 0 can be mapped to 0x4000
					mapRom(bankNo);
				}
				else if (halfbank == 2)
				{
					if (cartRam.length > 0)
						mapRam(data & 0x0f);
				}
				else if (halfbank == 5)
				{
					if (memory[halfbank] != null)
					{
						memory[halfbank].write(subaddr, data);
					}
				}
				break;
			}
		}
		
		protected	function rtcSync():void
		{
			if ((rtcReg.read(4) & 0x40) == 0)
			{
				// active
				var now:int = SystemTimer.getCurrentTimeMillis();
				while (now - lastRtcUpdate > 1000)
				{
					lastRtcUpdate += 1000;
					rtcReg.write(0, rtcReg.read(0) + 1);
					if (rtcReg.read(0) == 60)
					{
						rtcReg.write(0, 0);
						rtcReg.write(1, rtcReg.read(1) + 1);
						if (rtcReg.read(1) == 60)
						{
							rtcReg.write(1, 0);
							rtcReg.write(2, rtcReg.read(2) + 1);
							if (rtcReg.read(2) == 24)
							{
								rtcReg.write(2, 0);
								rtcReg.write(3, rtcReg.read(3) + 1);
								if (rtcReg.read(3) == 0)
								{
									rtcReg.write(4, (rtcReg.read(4) | (rtcReg.read(4) << 7)) ^ 1);
								}
							}
						}
					}
				}
			}
		}
		
		public	function rtcSkip(s:int):void
		{
			// seconds
			var sum:int = s + rtcReg.read(0);
			rtcReg.write(0, int(sum % 60));
			sum = sum / 60;
			if (sum == 0)
				return;
			
			// minutes
			sum = sum + rtcReg.read(1);
			rtcReg.write(1, int(sum % 60));
			sum = sum / 60;
			if (sum == 0)
				return;
			
			// hours
			sum = sum + rtcReg.read(2);
			rtcReg.write(2, int(sum % 24));
			sum = sum / 24;
			if (sum == 0)
				return;
			
			// days, bit 0-7
			sum = sum + (rtcReg.read(3) & 0xff) + ((rtcReg.read(4) & 1) << 8);
			rtcReg.write(3, sum);
			
			// overflow & day bit 8
			if (sum > 511)
				rtcReg.write(4, rtcReg.read(4) | 0x80);
			rtcReg.write(4, (rtcReg.read(4) & 0xfe) + ((sum >> 8) & 1));
		}
		
		private	function getNumRAMBanks():int
		{
			switch (rom[0].read(0x149))
			{
			case 1:
			case 2:
				return 1;
			case 3:
				return 4;
			case 4:
			case 5:
			case 6:
				return 16;
			}
			return 0;
		}
		
		private	function lookUpCartSize(sizeByte:int):int
		{
			if (sizeByte < 8)
				return 2 << sizeByte;
			else if (sizeByte == 0x52)
				return 72;
			else if (sizeByte == 0x53)
				return 80;
			else if (sizeByte == 0x54)
				return 96;
			return -1;
		}
		
		public	function hasBattery():Boolean
		{
			return (cartType == 3) || (cartType == 9) || (cartType == 0x1B) || (cartType == 0x1E) ||
					(cartType == 6) || (cartType == 0x10) || (cartType == 0x13);
		}
		
		public	function buttonDown(buttonIndex:int):void
		{
			buttonState |= 1 << buttonIndex;
			p10Requested = true;
		}
		
		public	function buttonUp(buttonIndex:int):void
		{
			buttonState &= 0xff - (1 << buttonIndex);
			p10Requested = true;
		}
		
		public	function setScale(screenWidth:int, screenHeight:int):void
		{
			ppu.setScale(screenWidth, screenHeight);
		}
		
		public	function getLastSkipCount():int
		{
			return ppu.lastSkipCount;
		}
		
		public	function isTerminated():Boolean
		{
			return terminated;
		}
		
		public	function terminate():void
		{
			terminated = true;
			stopSound(0);
			stopSound(1);
			stopSound(2);
		}
		
		public	function getRtcReg():ByteArrayAdvanced
		{
			return rtcReg;
		}
		
		public	function getCartRam():Vector.<ByteArrayAdvanced>
		{
			return cartRam;
		}
		
		public	function releaseReferences():void
		{
			incflags = null;
			decflags = null;
			rtcReg = null;
			cartRam = null;
			rom = null;
			romTouch = null;
			cartName = null;
			ppu = null;
			mainRam = null;
			gb = null;
			memory = null;
			decoderMemory = null;
			System.gc();
		}
	}
}