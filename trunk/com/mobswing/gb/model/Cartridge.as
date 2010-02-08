package com.mobswing.gb.model
{
	import __AS3__.vec.Vector;
	
	import com.mobswing.gb.view.Javaboy;
	
	import flash.display.DisplayObject;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	

	/** This class represents the game cartridge and contains methods to load the ROM and battery RAM
	 *  (if necessary) from disk or over the web, and handles emulation of ROM mappers and RAM banking.
	 *  It is missing emulation of MBC3 (this is very rare).
	 */
	public class Cartridge
	{

		 /** Translation between ROM size byte contained in the ROM header, and the number
		  *  of 16Kb ROM banks the cartridge will contain
		  */
		 private var romSizeTable:Vector.<Array> = Vector.<Array>([[0, 2], [1, 4], [2, 8], [3, 16], [4, 32],
		             [5, 64], [6, 128], [7, 256], [0x52, 72], [0x53, 80], [0x54, 96]]);		//int[][]
		
		 /** Contains strings of the standard names of the cartridge mapper chips, indexed by
		  *  cartridge type
		  */
		 private var cartTypeTable:Vector.<String> = Vector.<String>([
		     "ROM Only",             /* 00 */
		     "ROM+MBC1",             /* 01 */
		     "ROM+MBC1+RAM",         /* 02 */
		     "ROM+MBC1+RAM+BATTERY", /* 03 */
		     "Unknown",              /* 04 */
		     "ROM+MBC2",             /* 05 */
		     "ROM+MBC2+BATTERY",     /* 06 */
		     "Unknown",              /* 07 */
		     "ROM+RAM",              /* 08 */
		     "ROM+RAM+BATTERY",      /* 09 */
		     "Unknown",              /* 0A */
			 "Unsupported ROM+MMM01",/* 0B */
		     "Unsupported ROM+MMM01+SRAM",             /* 0C */
		     "Unsupported ROM+MMM01+SRAM+BATTERY",     /* 0D */
			 "Unknown",				 /* 0E */
		     "ROM+MBC3+TIMER+BATTERY",     /* 0F */
		     "ROM+MBC3+TIMER+RAM+BATTERY", /* 10 */
		     "ROM+MBC3",             /* 11 */
		     "ROM+MBC3+RAM",         /* 12 */
		     "ROM+MBC3+RAM+BATTERY", /* 13 */
		     "Unknown",              /* 14 */
		     "Unknown",              /* 15 */
		     "Unknown",              /* 16 */
		     "Unknown",              /* 17 */
		     "Unknown",              /* 18 */
		     "ROM+MBC5",             /* 19 */
		     "ROM+MBC5+RAM",         /* 1A */
		     "ROM+MBC5+RAM+BATTERY", /* 1B */
		     "ROM+MBC5+RUMBLE",      /* 1C */
		     "ROM+MBC5+RUMBLE+RAM",  /* 1D */
		     "ROM+MBC5+RUMBLE+RAM+BATTERY"  /* 1E */  ]);
		
		  /** Compressed file types */
		  private const bNotCompressed:int = 0;	//byte
		  private const bZip:int = 1;	//byte
		  private const bJar:int = 2;	//byte
		  private const bGZip:int = 3;	//byte
		
		  /** RTC Reg names */
		  private const SECONDS:int = 0;	//byte
		  private const MINUTES:int = 1;	//byte
		  private const HOURS:int = 2;		//byte
		  private const DAYS_LO:int = 3;	//byte
		  private const DAYS_HI:int = 4;	//byte
		
		 /** Contains the complete ROM image of the cartridge */
		 public var rom:ByteArrayAdvanced;	//byte[]
		
		 /** Contains the RAM on the cartridge */
		 public var ram:ByteArrayAdvanced = new ByteArrayAdvanced(0x10000);
		
		 /** Number of 16Kb ROM banks */
		 private var numBanks:int;
		
		 /** Cartridge type - index into cartTypeTable[][] */
		 private var cartType:int;
		
		 /** Starting address of the ROM bank at 0x4000 in CPU address space */
		 private var pageStart:int = 0x4000;
		
		 /** The bank number which is currently mapped at 0x4000 in CPU address space */
		 private var currentBank:int = 1;
		
		 /** The bank which has been saved when the debugger changes the ROM mapping.  The mapping is
		  *  restored from this register when execution resumes */
		 private var savedBank:int = -1;
		
		 /** The RAM bank number which is currently mapped at 0xA000 in CPU address space */
		 private var ramBank:int;
		 private var ramPageStart:int;
		
		 private var mbc1LargeRamMode:Boolean = false;
		 private var ramEnabled:Boolean, disposed:Boolean = false;
		 private var applet:DisplayObject;	//Component
		
		 /** The filename of the currently loaded ROM */
		 private var romFileName:String;
		
		 private var cartName:String;
		
		 private var cartridgeReady:Boolean = false;
		
		 private var needsReset:Boolean = false;
		 
		 /** Real time clock registers.  Only used on MBC3 */
		 private var RTCReg:Vector.<int> = new Vector.<int>(5);	//int[5]
		 private var offsetTime:Number;
		 private var realTimeStart:Number;	//long
		 private var lastSecondIncrement:Number;	//long
		 private var romIntFileName:String;
		
		public function Cartridge(romFile:ByteArray, romFileName:String, a:DisplayObject):void
		{
		  applet = a; /* 5823 */
		  this.romFileName = romFileName;
		/*   if (JavaBoy.runningAsApplet) {
		    Applet myApplet = (Applet) a;
		    is = new URL(myApplet.getDocumentBase(), romFileName).openStream();
		   } else {
		    is = new FileInputStream(new File(romFileName));
		   }*/
		   var firstBank:ByteArrayAdvanced = new ByteArrayAdvanced(0x04000);	//byte[0x04000]
		   firstBank.writeBytes(romFile, 0, 0x04000);
		
		
		   cartType = firstBank.read(0x0147);
		
		   numBanks = lookUpCartSize(firstBank.read(0x0148));   // Determine the number of 16kb rom banks
		
		//   is.close();
		//   is = new FileInputStream(new File(romFileName));
		   rom = new ByteArrayAdvanced(0x04000 * numBanks);		// Recreate the ROM array with the correct size
		   rom.writeBytes(romFile, 0, 0x04000 * numBanks);
		   
		   if (!verifyChecksum()) {
		    trace("Warning", "This cartridge has an invalid checksum.", "It may not execute correctly.");
		   }
		
		   if (!Javaboy.runningAsApplet) {
		    loadBatteryRam();
		   }
		
		   // Set up the real time clock
		    var rightNow:Date = new Date();	//Calendar
		    var firstDay:Date = new Date(rightNow.fullYear, 0);
		    var lastDay:Date = new Date(rightNow.fullYear, rightNow.month, rightNow.date);
		
			var days:int = (firstDay.time - lastDay.time) % 86400000 + 1;
			var hour:int = rightNow.hours;
			var minute:int = rightNow.minutes;
			var second:int = rightNow.seconds;
		
			RTCReg[SECONDS] = second;
			RTCReg[MINUTES] = minute;
			RTCReg[HOURS] = hour;
			RTCReg[DAYS_LO] = days & 0x00FF;
			RTCReg[DAYS_HI] = (days & 0x01FF) >> 8;
		
			realTimeStart = rightNow.time;
			offsetTime = rightNow.time;
			lastSecondIncrement = realTimeStart;
		
		
		   cartridgeReady = true;
		}

		 public function needsResetEnable():Boolean {
		//  System.out.println("Reset !");
		  if (needsReset) {
		   needsReset = false;
		   trace("Reset requested");
		   return true;
		  } else {
		   return false;
		  }
		 }
		
		 public function resetSystem():void {
		  needsReset = true;
		 }
		
		 public function update():void {
		  // Update the realtime clock from the system time
		  var millisSinceLastUpdate:Number = offsetTime + getTimer() - lastSecondIncrement;
		
		  while (millisSinceLastUpdate > 1000) {
		   millisSinceLastUpdate -= 1000;
		   RTCReg[SECONDS]++;
		   if (RTCReg[SECONDS] == 60) {
		    RTCReg[MINUTES]++;
			RTCReg[SECONDS] = 0;
			if (RTCReg[MINUTES] == 60) {
		     RTCReg[HOURS]++;
			 RTCReg[MINUTES] = 0;
			 if (RTCReg[HOURS] == 24) {
			  if (RTCReg[DAYS_LO] == 255) {
		       RTCReg[DAYS_LO] = 0;
			   RTCReg[DAYS_HI] = 1;
			  } else {
		       RTCReg[DAYS_LO]++;
			  }
			  RTCReg[HOURS] = 0;
			 }
			}
		   }
		   lastSecondIncrement = offsetTime + getTimer();
		  }
		 }

		 /** Returns the byte currently mapped to a CPU address.  Addr must be in the range 0x0000 - 0x4000 or
		  *  0xA000 - 0xB000 (for RAM access)
		  */
		 public function addressRead(addr:int):int {	//@return:byte
		//  if (disposed) System.out.println("oh.  dodgy cartridge");
		
		//  if (cartType == 0) {
		//   return (byte) (rom[addr] & 0x00FF);
		//  } else {
		   if ((addr >= 0xA000) && (addr <= 0xBFFF)) {
		    switch (cartType) {
			 case 0x0F :
		     case 0x10 :
		     case 0x11 :
		     case 0x12 :
		     case 0x13 : {	/* MBC3 */
			  if (ramBank >= 0x04) {
		//	   System.out.println("Reading RTC reg " + ramBank + " is " + RTCReg[ramBank - 0x08]);
			   return RTCReg[ramBank - 0x08];
			  } else {
		       return ram.read(addr - 0xA000 + ramPageStart);
			  }
			 }
		
			 default : {
		      return ram.read(addr - 0xA000 + ramPageStart);
			 }
			}
		   } if (addr < 0x4000) {
		    return (rom.read(addr));
		   } else {
		    return (rom.read(pageStart + addr - 0x4000));
		   }
		//  }
		 }
		
		
		 /** Returns a string summary of the current mapper status */
		 public function getMapInfo():String {
		  var out:String;
		  switch (cartType) {
		   case 0 /* No mapper */ :
		   case 8 :
		   case 9 :
		     return "This ROM has no mapper.";
		   case 1 /* MBC1      */ :
		     return "MBC1: ROM bank " + Javaboy.hexByte(currentBank) + " mapped to " +
		            " 4000 - 7FFFF";
		   case 2 /* MBC1+RAM  */ :
		   case 3 /* MBC1+RAM+BATTERY */ :
		     out = "MBC1: ROM bank " + Javaboy.hexByte(currentBank) + " mapped to " +
		           " 4000 - 7FFFF.  ";
		     if (mbc1LargeRamMode) {
		      out = out + "Cartridge is in 16MBit ROM/8KByte RAM Mode.";
		     } else {
		      out = out + "Cartridge is in 4MBit ROM/32KByte RAM Mode.";
		     }
		     return out;
		   case 5 :
		   case 6 : 
		    return "MBC2: ROM bank " + Javaboy.hexByte(currentBank) + " mapped to 4000 - 7FFF";
		
		   case 0x19 :
		   case 0x1C :
		    return "MBC5: ROM bank " + Javaboy.hexByte(currentBank) + " mapped to 4000 - 7FFF";
		
		   case 0x1A :
		   case 0x1B :
		   case 0x1D :
		   case 0x1E :
		    return "MBC5: ROM bank " + Javaboy.hexByte(currentBank) + " mapped to 4000 - 7FFF";
		
		  }
		  return "Unknown mapper.";
		 }
		
		 /** Maps a ROM bank into the CPU address space at 0x4000 */
		 public function mapRom(bankNo:int):void {
		//  addressWrite(0x2000, bank);
		//  if (bankNo == 0) bankNo = 1;
		  currentBank = bankNo;
		  pageStart = 0x4000 * bankNo;
		 }
		
		 public function reset():void {
		  mapRom(1);
		 }
		
		 /** Save the current mapper state */
		 public function saveMapping():void {
		  if ((cartType != 0) && (savedBank == -1)) savedBank = currentBank;
		 }
		
		 /** Restore the saved mapper state */
		 public function restoreMapping():void {
		  if (savedBank != -1) {
		   trace("- ROM Mapping restored to bank " + Javaboy.hexByte(savedBank));
		   addressWrite(0x2000, savedBank);
		   savedBank = -1;
		  }
		 }
		 
		 /** Writes to an address in CPU address space.  Writes to ROM may cause a mapping change.
		  */
		 public function addressWrite(addr:int, data:int):void {
		  var ramAddress:int = 0;
		  var bankNo:int;
		
		
		  switch (cartType) {
		
		   case 0 : /* ROM Only */
		    break;
		
		   case 1 : /* MBC1 */
		   case 2 :
		   case 3 :
		    if ((addr >= 0xA000) && (addr <= 0xBFFF)) {
		     if (ramEnabled) {
		      ramAddress = addr - 0xA000 + ramPageStart;
		      ram.write(ramAddress, data);
		     }
		    } if ((addr >= 0x2000) && (addr <= 0x3FFF)) {
		     bankNo = data & 0x1F;
		     if (bankNo == 0) bankNo = 1;
		     mapRom((currentBank & 0x60) | bankNo);
		    } else if ((addr >= 0x6000) && (addr <= 0x7FFF)) {
		     if ((data & 1) == 1) {
		      mbc1LargeRamMode = true;
		//      ram = new byte[0x8000];
		     } else {
		      mbc1LargeRamMode = false;
		//      ram = new byte[0x2000];
		     }
		    } else if (addr <= 0x1FFF) {
		     if ((data & 0x0F) == 0x0A) {
		      ramEnabled = true;
		     } else {
		      ramEnabled = false;
		     }
		    } else if ((addr <= 0x5FFF) && (addr >= 0x4000)) {
		     if (mbc1LargeRamMode) {
		      ramBank = (data & 0x03);
		      ramPageStart = ramBank * 0x2000;
		//      System.out.println("RAM bank " + ramBank + " selected!");
		     } else {
		      mapRom((currentBank & 0x1F) | ((data & 0x03) << 5));
		     }
		    }
		    break;
		
		   case 5 :
		   case 6 :
		    if ((addr >= 0x2000) && (addr <= 0x3FFF) && ((addr & 0x0100) != 0) ) {
		     bankNo = data & 0x1F;
		     if (bankNo == 0) bankNo = 1;
		     mapRom(bankNo);
		    }
		    if ((addr >= 0xA000) && (addr <= 0xBFFF)) {
		     if (ramEnabled) ram.write(addr - 0xA000 + ramPageStart, data);
		    }
		
		    break;
		
		   case 0x0F :
		   case 0x10 :
		   case 0x11 :
		   case 0x12 :
		   case 0x13 :	/* MBC3 */
		
		    // Select ROM bank
		    if ((addr >= 0x2000) && (addr <= 0x3FFF)) {
		     bankNo = data & 0x7F;
		     if (bankNo == 0) bankNo = 1;
		     mapRom(bankNo);
		    } else if ((addr <= 0x5FFF) && (addr >= 0x4000)) {
			// Select RAM bank
		     ramBank = data;
		
			 if (ramBank < 0x04) {
		      ramPageStart = ramBank * 0x2000;
			 }
		//     System.out.println("RAM bank " + ramBank + " selected!");
			} 
		    if ((addr >= 0xA000) && (addr <= 0xBFFF)) {
		     // Let the game write to RAM
		 	 if (ramBank <= 0x03) {
		      ram.write(addr - 0xA000 + ramPageStart, data);
		     } else {
		 	// Write to realtime clock registers
			 RTCReg[ramBank - 0x08] = data;
		//     System.out.println("RTC Reg " + ramBank + " = " + data);
			}
		
		   }
		/*	if ((addr >= 0x6000) && (addr <= 0x7FFF)) {
		     if ((data & 1) == 1) {
		      mbc1LargeRamMode = true;
		      System.out.println("Small Ram");
		//      ram = new byte[0x8000];
		     } else {
		      mbc1LargeRamMode = false;
		      System.out.println("Large Ram");
		//      ram = new byte[0x2000];
		     }
			}*/
		
		    break;
		
		
		   case 0x19 :
		   case 0x1A :
		   case 0x1B :
		   case 0x1C :
		   case 0x1D :
		   case 0x1E :
		
		    if ((addr >= 0x2000) && (addr <= 0x2FFF)) {
		     bankNo = (currentBank & 0xFF00) | data;
		     mapRom(bankNo);
		    }
		    if ((addr >= 0x3000) && (addr <= 0x3FFF)) {
		     bankNo = (currentBank & 0x00FF) | ((data & 0x01) << 8);
		     mapRom(bankNo);
		    }
		
		    if ((addr >= 0x4000) && (addr <= 0x5FFF)) {
		     ramBank = (data & 0x07);
		     ramPageStart = ramBank * 0x2000;
		//     System.out.println("RAM bank " + ramBank + " selected!");
		    }
		    if ((addr >= 0xA000) && (addr <= 0xBFFF)) {
		     ram.write(addr - 0xA000 + ramPageStart, data);
		    }
		    break;
		
		
		  }
		
		 }
		
		 public function getNumRAMBanks():int {
		  switch (rom.read(0x149)) {
		   case 0: {
			return 0;
		   }
		   case 1: 
		   case 2: {
			return 1;
		   }
		   case 3: {
			return 4;
		   }
		   case 4: {
		    return 16;
		   }
		  }
		  return 0;
		 }
		
		 /** Read an image of battery RAM into memory if the current cartridge mapper supports it.
		  *  The filename is the same as the ROM filename, but with a .SAV extention.
		# *  Files are compatible with VGB-DOS.
		  */
		 public function loadBatteryRam():void {
		  var saveRamFileName:String = romFileName;
		  var numRamBanks:int;
		
		  try {
		   var dotPosition:int = romFileName.lastIndexOf('.');
		
		   if (dotPosition != -1) {
		    saveRamFileName = romFileName.substring(0, dotPosition) + ".sav";
		   } else {
		    saveRamFileName = romFileName + ".sav";
		   }
		
		/*   if (rom[0x149] == 0x03) {
		    numRamBanks = 4;
		   } else {
		    numRamBanks = 1;
		   }*/
		   numRamBanks = getNumRAMBanks();
		
		   if ((cartType == 3) || (cartType == 9) || (cartType == 0x1B) || (cartType == 0x1E) || (cartType == 0x10) || (cartType == 0x13) ) {
		    Parameters.SRAMFILE.position = 0;
		    Parameters.SRAMFILE.readBytes(ram, 0, numRamBanks * 8192);
		    trace("Read SRAM from '" + saveRamFileName + "'");
		   }
		   if (cartType == 6) {
		    Parameters.SRAMFILE.position = 0;
		    Parameters.SRAMFILE.readBytes(ram, 0, 512);
		    trace("Read SRAM from '" + saveRamFileName + "'");
		   }
		
		
		  } catch (e:Error) {
		   trace("Error loading battery RAM from '" + saveRamFileName + "'");
		  }
		 }
		
		 public function getBatteryRamSize():int {
		  var numRamBanks:int;
		  if (rom.read(0x149) == 0x06) {
		   return 512;
		  } else {
		   return getNumRAMBanks() * 8192;
		  }
		 }
		
		 public function getBatteryRam():ByteArrayAdvanced {
		  return ram;
		 }
		
		 public function canSave():Boolean {
		  return (cartType == 3) || (cartType == 9) || (cartType == 0x1B) || (cartType == 0x1E) || (cartType == 6) || (cartType == 0x10) || (cartType == 0x13);
		 }
		
		 /** Writes an image of battery RAM to disk, if the current cartridge mapper supports it. */
		 public function saveBatteryRam():void {
		  var saveRamFileName:String = romFileName;
		  var numRamBanks:int;
		
		/*  if (rom[0x149] == 0x03) {
		   numRamBanks = 4;
		  } else {
		   numRamBanks = 1;
		  }*/
		  numRamBanks = getNumRAMBanks();
		
		  try {
		   var dotPosition:int = romFileName.lastIndexOf('.');
		
		   if (dotPosition != -1) {
		    saveRamFileName = romFileName.substring(0, dotPosition) + ".sav";
		   } else {
		    saveRamFileName = romFileName + ".sav";
		   }
		
		   if ((cartType == 3) || (cartType == 9) || (cartType == 0x1B) || (cartType == 0x1E) || (cartType == 0x10) || (cartType == 0x13)) {
		    Parameters.SRAMFILE.position = 0;
		    Parameters.SRAMFILE.writeBytes(ram, 0, numRamBanks * 8192);
		    trace("Written SRAM to '" + saveRamFileName + "'");
		   }
		   if (cartType == 6) {
		    Parameters.SRAMFILE.position = 0;
		    Parameters.SRAMFILE.writeBytes(ram, 0, 512);
		    trace("Written SRAM to '" + saveRamFileName + "'");
		   }
		
		  } catch (e:Error) {
		   trace("Error saving battery RAM to '" + saveRamFileName + "'");
		  }
		 }
		
		 /** Peforms saving of the battery RAM before the object is discarded */
		 public function dispose():void {
		  if (!Javaboy.runningAsApplet) {
		   saveBatteryRam();
		  }
		  disposed = true;
		 }
		
		 public function verifyChecksum():Boolean {
		  var checkSum:int = (Javaboy.unsign(rom.read(0x14E)) << 8) + Javaboy.unsign(rom.read(0x14F));
		
		  var total:int = 0;                   // Calculate ROM checksum
		  for (var r:int=0; r < rom.length; r++) {
		   if ((r != 0x14E) && (r != 0x14F)) {
		    total = (total + Javaboy.unsign(rom.read(r))) & 0x0000FFFF;
		   }
		  }
		
		  return checkSum == total;
		 }
		
		 /** Gets the cartridge name */
		 public	function getCartName():String {
			return cartName;
		 }
		
		 public function getRomFilename():String {
		    return romIntFileName;
		 }
		
		 /** Outputs information about the loaded cartridge to stdout. */
		 public function outputCartInfo():void {
		  var checksumOk:Boolean;
		
		  rom.position = 0x0134;
		  cartName = rom.readUTFBytes(16);
		                        // Extract the game name from the cartridge header
		  
		//  JavaBoy.debugLog(rom[0x14F]+ " "+ rom[0x14E]);
		
		
		  checksumOk = verifyChecksum();
		
		
		  // Remove NULLs from the end of the cart name
		  var s:String = "";
		  for (var r:int = 0; r < cartName.length; r++) {
			if ((cartName.charCodeAt(r) != 0) && (cartName.charCodeAt(r) >= 32) && (cartName.charCodeAt(r) <= 127)) {
			 s += cartName.charCodeAt(r);
			}
		  }
		  cartName = s;
		
		  var infoString:String = "ROM Info: Name = " + cartName +
		                      ", Size = " + (numBanks * 128) + "Kbit, ";
		
		  if (checksumOk) {
		   infoString = infoString + "Checksum Ok.";
		  } else {
		   infoString = infoString + "Checksum invalid!";
		  }
		
		  Javaboy.debugLog(infoString);
		 }
		
		
		 /** Returns the number of 16Kb banks in a cartridge from the header size byte. */
		 public function lookUpCartSize(sizeByte:int):int {
		  var i:int = 0;
		  while ((i < romSizeTable.length) && (romSizeTable[i][0] != sizeByte)) {
		   i++;
		  }
		
		  if (romSizeTable[i][0] == sizeByte) {
		   return romSizeTable[i][1];
		  } else {
		   return -1;
		  }
		 }
	}
}