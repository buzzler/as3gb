package com.mobswing.gb.control
{
	import __AS3__.vec.Vector;
	
	import com.mobswing.gb.graphic.PPU;
	import com.mobswing.gb.model.ByteArrayAdvanced;
	import com.mobswing.gb.model.Parameters;
	import com.mobswing.gb.model.Thread;
	import com.mobswing.gb.sound.APU;
	import com.mobswing.gb.view.Gameboy;
	
	import flash.display.DisplayObject;
	
	/** This is the main controlling class for the emulation
	 *  It contains the code to emulate the Z80-like processor
	 *  found in the Gameboy, and code to provide the locations
	 *  in CPU address space that points to the correct area of
	 *  ROM/RAM/IO.
	 */
	public class CPU
	{
		 /** Registers: 8-bit */
		 private var a:int, b:int, c:int, d:int, e:int, f:int;
		 /** Registers: 16-bit */
		 public var sp:int, pc:int, hl:int;
		
		 /** The number of instructions that have been executed since the
		  *  last reset
		  */
		 public var instrCount:int = 0;
		
		 private var interruptsEnabled:Boolean = false;
		
		 /** Used to implement the IE delay slot */
		 private var ieDelay:int = -1;
		
		 public var timaEnabled:Boolean = false;
		 public var instrsPerTima:int = 6000;
		
		 /** TRUE when the CPU is currently processing an interrupt */
		 private var inInterrupt:Boolean = false;
		
		 /** Enable the breakpoint flag.  As breakpoint instruction is used in some games, this is used to skip over it unless the breakpoint is actually in use */
		 private var breakpointEnable:Boolean = false;
		
		 // Constants for flags register
		
		 /** Zero flag */
		 private const F_ZERO:int =      0x80;	//short
		 /** Subtract/negative flag */
		 private const F_SUBTRACT:int =  0x40;	//short
		 /** Half carry flag */
		 private const F_HALFCARRY:int = 0x20;	//short
		 /** Carry flag */
		 private const F_CARRY:int =     0x10;	//short
		
		 public const INSTRS_PER_VBLANK:int = 9000; /* 10000  */	//short
		
		 /** Used to set the speed of the emulator.  This controls how
		  *  many instructions are executed for each horizontal line scanned
		  *  on the screen.  Multiply by 154 to find out how many instructions
		  *  per frame.
		  */
		 public const BASE_INSTRS_PER_HBLANK:int = 60;    /* 60    */	//short
		 public var INSTRS_PER_HBLANK:int = BASE_INSTRS_PER_HBLANK;	//short
		
		 /** Used to set the speed of DIV increments */
		 private const BASE_INSTRS_PER_DIV:int    = 33;    /* 33    */	//short
		 private var INSTRS_PER_DIV:int = BASE_INSTRS_PER_DIV;	//short
		
		 // Constants for interrupts
		
		 /** Vertical blank interrupt */
		 public const INT_VBLANK:int =  0x01;	//short
		
		 /** LCD Coincidence interrupt */
		 public const INT_LCDC:int =    0x02;	//short
		         
		 /** TIMA (programmable timer) interrupt */
		 public const INT_TIMA:int =    0x04;	//short
		
		 /** Serial interrupt */
		 public const INT_SER:int =     0x08;	//short
		
		 /** P10 - P13 (Joypad) interrupt */
		 public const INT_P10:int =     0x10;	//short
		
		 private var registerNames:Vector.<String> = Vector.<String>(["B", "C", "D", "E", "H", "L", "(HL)", "A"]);	//String[]
		 private var aluOperations:Vector.<String> = Vector.<String>(["ADD", "ADC", "SUB", "SBC", "AND", "XOR", "OR", "CP"]);	//String[]
		 private var shiftOperations:Vector.<String> = Vector.<String>(["RLC", "RRC", "RL", "RR", "SLA", "SRA", "SWAP", "SRL"]);	//String[]
		
		 // 8Kb main system RAM appears at 0xC000 in address space
		 // 32Kb for GBC
		 private var mainRam:ByteArrayAdvanced = new ByteArrayAdvanced(0x8000);	//byte[]

		 // 256 bytes at top of RAM are used mainly for registers
		 private var oam:ByteArrayAdvanced = new ByteArrayAdvanced(0x100);	//byte[]
		
		 private var cartridge:Cartridge;
		 public	 var ppu:PPU;
		 public  var apu:APU;
		 public  var ioHandler:IOHandler;;
		 private var applet:DisplayObject;
		 public var terminate:Boolean;
		 public var running:Boolean = false;
		
		 public var gbcFeatures:Boolean = true;
		 private var allowGbcFeatures:Boolean = true;
		 public var gbcRamBank:int = 1;
		 
		 private var newf:int;	//short
		 private var dat:int;
		 private var b1:int, b2:int, b3:int, offset:int;

		 /** Create a CPU emulator with the supplied cartridge and game link objects.  Both can be set up
		  *  or changed later if needed
		  */
		public function CPU(c:Cartridge, a:DisplayObject)
		{
		  cartridge = c;

		  ppu = new PPU(a, this);
		  checkEnableGbc();
		  apu = new APU();
		  ioHandler = new IOHandler(this);
		  applet = a;
		//  reset();
		}


		 /** Clear up memory */
		 public function dispose():void {
		  ppu.dispose();
		 }
		
		 /** Force the execution thread to stop and return to it's caller */
		 public function terminateProcess():void {
		  terminate = true;
		/*  do {
		   try {
		    java.lang.Thread.sleep(100);
		    trace("Wating for CPU...");
		   } catch (InterruptedException e) {
		    // Nothing
		   }
		  } while (running);*/
		 }
		
		 /** Perform a CPU address space read.  This maps all the relevant objects into the correct parts of
		  *  the memory
		  */
		 public function addressRead(addr:int):int {	//@return:short
		
		/*  if ((addr >= 0xDFD8) && (addr <= 0xDFF0) && (running)) {
		   trace(JavaBoy.hexWord(addr) + " read at " + JavaBoy.hexWord(pc) + " bank " + cartridge.currentBank);
		  }*/
		
		/*  if ((addr < 0) || (addr > 65535)) {
		    trace("Tried to read address " + addr + ".  pc = " + JavaBoy.hexWord(pc));
		    return 0xFF;
		  }*/
		
		  addr = addr & 0xFFFF;
		
		  switch ((addr & 0xF000)) {
		   case 0x0000 :
		   case 0x1000 :
		   case 0x2000 :
		   case 0x3000 :
		   case 0x4000 :
		   case 0x5000 :
		   case 0x6000 :
		   case 0x7000 :
		    return cartridge.addressRead(addr);
		
		   case 0x8000 :
		   case 0x9000 :
		    return ppu.addressRead(addr - 0x8000);
		
		   case 0xA000 :
		   case 0xB000 :
		    return cartridge.addressRead(addr);
		
		   case 0xC000 :
		    return (mainRam.read(addr - 0xC000));
		
		   case 0xD000 :
		    return (mainRam.read(addr - 0xD000 + (gbcRamBank * 0x1000)));
		
		   case 0xE000 :
		    return mainRam.read(addr - 0xE000);
		     /* (short) (mainRam[addr - 0xE000] & 0x00FF); */
		    
		   case 0xF000 :
		    if (addr < 0xFE00) {
		     return mainRam.read(addr - 0xE000);
		    } else if (addr < 0xFF00) {
		     return oam.read(addr - 0xFE00) & 0x00FF;
		    } else {
		     return ioHandler.ioRead(addr - 0xFF00);
		    }
		
		   default:
		    trace("Tried to read address " + addr + ".  pc = " + Gameboy.hexWord(pc));
		    return 0xFF;
		  }
		
		 }
		
		 /** Performs a CPU address space write.  Maps all of the relevant object into the right parts of
		  *  memory.
		  */
		 public function addressWrite(addr:int, data:int):void {
		
		/*  if ((addr >= 0xCFF8) && (addr <= 0xCFF8) && (running)) {
		   trace(JavaBoy.hexWord(data) + " written to " + JavaBoy.hexWord(addr) + " at " + JavaBoy.hexWord(pc) + " bank " + cartridge.currentBank);
		  }
		  if ((addr >= 0xEFF8) && (addr <= 0xEFF8) && (running)) {
		   trace(JavaBoy.hexWord(data) + " written to " + JavaBoy.hexWord(addr) + " at " + JavaBoy.hexWord(pc) + " bank " + cartridge.currentBank);
		  }*/
		
		/*  if ((addr < 0) || (addr > 65535)) {
		   trace(JavaBoy.hexWord(data) + " written to " + JavaBoy.hexWord(addr) + " at " + JavaBoy.hexWord(pc) + " bank " + cartridge.currentBank);
		  }*/
		
		  switch (addr & 0xF000) {
		   case 0x0000 :
		   case 0x1000 :
		   case 0x2000 :
		   case 0x3000 :
		   case 0x4000 :
		   case 0x5000 :
		   case 0x6000 :
		   case 0x7000 :
		     cartridge.addressWrite(addr, data);
		 //    trace("Tried to write to ROM! PC = " + JavaBoy.hexWord(pc) + ", Data = " + JavaBoy.hexByte(JavaBoy.unsign((byte) data)));
		    break;
		
		   case 0x8000 :
		   case 0x9000 :
		    ppu.addressWrite(addr - 0x8000, data);
		    break;
		
		   case 0xA000 :
		   case 0xB000 :
		    cartridge.addressWrite(addr, data);
		    break;
		
		   case 0xC000 :
		    mainRam.write(addr - 0xC000, data);
		    break;
		
		   case 0xD000 :
		    mainRam.write(addr - 0xD000 + (gbcRamBank * 0x1000), data);
		    break;
		
		   case 0xE000 :
		    mainRam.write(addr - 0xE000, data);
		    break;
		
		   case 0xF000 :
		    if (addr < 0xFE00) {
		     try {
		      mainRam.write(addr - 0xE000, data);
		     } catch (e:Error) {
		      trace("Address error: " + addr + " pc = " + Gameboy.hexWord(pc));
		     }
		    } else if (addr < 0xFF00) {
		     oam.write(addr - 0xFE00, data);
		    } else {
		     ioHandler.ioWrite(addr - 0xFF00, data);
		    }
		    break;
		  }
		 }
		
		
		 public function addressWriteOld(addr:int, data:int):void {
		
		/*  if ((addr >= 0xFFA4) && (addr <= 0xFFA5) && (running)) {
		   trace(JavaBoy.hexWord(addr) + " written at " + JavaBoy.hexWord(pc) + " bank " + cartridge.currentBank);
		  }*/
		
		
		//  System.out.print(JavaBoy.hexByte(JavaBoy.unsign((short) data)) + " --> " + JavaBoy.hexWord(addr) + ", ");
		  if ((addr < 0x8000)) {
		    cartridge.addressWrite(addr, data);
		//    trace("Tried to write to ROM! PC = " + JavaBoy.hexWord(pc) + ", Data = " + JavaBoy.hexByte(JavaBoy.unsign((byte) data)));
		  } else if (addr < 0xA000) {
		   try {
		    ppu.addressWrite(addr - 0x8000, data);
		   } catch (e:Error) {
		    trace("Error address " + addr);
		   }
		  } else if (addr < 0xC000) {
		   // RAM Bank write
		//   trace("RAM bank write! + " + JavaBoy.hexWord(addr) + " = " + JavaBoy.hexByte(data) + " at " + JavaBoy.hexWord(pc));
		   cartridge.addressWrite(addr, data);
		  } else if (addr < 0xE000) {
		   mainRam.write(addr - 0xC000, data);
		  } else if (addr < 0xFE00) {
		   mainRam.write(addr - 0xE000, data);
		  } else if (addr < 0xFF00) {
		   oam.write(addr - 0xFE00, data);
		  } else if (addr <= 0xFFFF) {
		   if (addr == 0xFF80) {
		//    trace("Register write: " + JavaBoy.hexWord(addr) + " = " + JavaBoy.hexWord(data));
		   }
		   ioHandler.ioWrite(addr - 0xFF00, data);
		//   registers[addr - 0xFF00] = (byte) data;
		  } else {
		   trace("Attempt to write to address "+ Gameboy.hexWord(addr));
		  }
		 }
		
		 /** Sets the value of a register by it's name */
		 public function setRegister(reg:String, value:int):Boolean {
		  if ((reg == "a") || (reg =="acc")) {
		   a = value;
		  } else if (reg == "b") {
		   b = value;
		  } else if (reg == "c") {
		   c = value;
		  } else if (reg == "d") {
		   d = value;
		  } else if (reg == "e") {
		   e = value;
		  } else if (reg == "f") {
		   f = value;
		  } else if (reg == "h") {
		   hl = (hl & 0x00FF) | (value << 8);
		  } else if (reg == "l") {
		   hl = (hl & 0xFF00) | value;
		  } else if (reg == "sp") {
		   sp = value;
		  } else if ((reg == "pc") || (reg == "ip")) {
		   pc = value;                             
		  } else if (reg == "bc") {
		   b = (value >> 8);
		   c = (value & 0x00FF);
		  } else if (reg == "de") {
		   d = (value >> 8);
		   e = (value & 0x00FF);
		  } else if (reg == "hl") {
		   hl = value;
		  } else {
		   return false;
		  }
		  return true;
		 }
		
		 public function setBC(value:int):void {
		  b = ((value & 0xFF00) >> 8);
		  c = (value & 0x00FF);
		 }
		
		 public function setDE(value:int):void {
		  d = ((value & 0xFF00) >> 8);
		  e = (value & 0x00FF);
		 }
		
		 public function setHL(value:int):void {
		  hl = value;
		 }
		
		 /** Performs a read of a register by internal register number */
		 public function registerRead(regNum:int):int {
		  switch (regNum) {
		   case 0  : return b;
		   case 1  : return c;
		   case 2  : return d;
		   case 3  : return e;
		   case 4  : return ((hl & 0xFF00) >> 8);
		   case 5  : return (hl & 0x00FF);
		   case 6  : return Gameboy.unsign(addressRead(hl));
		   case 7  : return a;
		   default : return -1;
		  }
		 }
		
		 /** Performs a write of a register by internal register number */
		 public function registerWrite(regNum:int, data:int):void {
		  switch (regNum) {
		   case 0  : b = data;
		             return;
		   case 1  : c = data;
		             return;
		   case 2  : d = data;
		             return;
		   case 3  : e = data;
		             return;
		   case 4  : hl = (hl & 0x00FF) | (data << 8);
		             return;
		   case 5  : hl = (hl & 0xFF00) | data;
		             return;
		   case 6  : addressWrite(hl, data);
		             return;
		   case 7  : a = data;
		             return;
		   default : return;
		  }
		 }
		
		 public function checkEnableGbc():void {
		  if ( ((cartridge.rom.read(0x143) & 0x80) == 0x80) && (allowGbcFeatures)) { // GBC Cartridge ID
		   gbcFeatures = true;
		  } else {
		   gbcFeatures = false;
		  }
		 }
		
		
		 /** Resets the CPU to it's power on state.  Memory contents are not cleared. */
		 public function reset():void {
		
		  checkEnableGbc();
		  setDoubleSpeedCpu(false);
		  ppu.dispose();
		  cartridge.reset();
		  interruptsEnabled = false;
		  ieDelay = -1;
		  pc = 0x0100;
		  sp = 0xFFFE;
		  f = 0xB0;
		  gbcRamBank = 1;
		  instrCount = 0;
		
		  if (gbcFeatures) {
		   a = 0x11;
		  } else {
		   a = 0x01;
		  }
		
		  for (var r:int = 0; r < 0x8000; r++) {
		   mainRam.write(r, 0);
		  }
		
		  setBC(0x0013);
		  setDE(0x00D8);
		  setHL(0x014D);
		  Gameboy.debugLog("CPU reset");
		
		  ioHandler.reset();
		//  pc = 0x0100;
		 }
		
		 public function setDoubleSpeedCpu(enabled:Boolean):void {
		
		  if (enabled) {
		   INSTRS_PER_HBLANK = BASE_INSTRS_PER_HBLANK * 2;
		   INSTRS_PER_DIV = BASE_INSTRS_PER_DIV * 2;
		  } else {
		   INSTRS_PER_HBLANK = BASE_INSTRS_PER_HBLANK;
		   INSTRS_PER_DIV = BASE_INSTRS_PER_DIV;
		  }
		
		 }
		
		 /** If an interrupt is enabled an the interrupt register shows that it has occured, jump to
		  *  the relevant interrupt vector address
		  */
		 public function checkInterrupts():void {
		  var intFlags:int = ioHandler.registers.read(0x0F);
		  var ieReg:int = ioHandler.registers.read(0xFF);
		  if ((intFlags & ieReg) != 0) {
		   sp -= 2;
		   addressWrite(sp + 1, pc >> 8);  // Push current program counter onto stack
		   addressWrite(sp, pc & 0x00FF);
		   interruptsEnabled = false;
		
		   if ((intFlags & ieReg & INT_VBLANK) != 0) {
		    pc = 0x40;                      // Jump to Vblank interrupt address
		    intFlags -= INT_VBLANK;
		//    trace("VBLANK Interrupt called");
		   } else if ((intFlags & ieReg & INT_LCDC) != 0) {
		    pc = 0x48;
		    intFlags -= INT_LCDC;
		//    trace("LCDC Interrupt called");
		   } else if ((intFlags & ieReg & INT_TIMA) != 0) {
		    pc = 0x50;
		    intFlags -= INT_TIMA;
		//    trace("TIMA Interrupt called");
		   } else if ((intFlags & ieReg & INT_SER) != 0) {
		    pc = 0x58;
		    intFlags -= INT_SER;
		//    trace("TIMA Interrupt called");
		   } else if ((intFlags & ieReg & INT_P10) != 0) {	// Joypad interrupt
		    pc = 0x60;
		    intFlags -= INT_P10;
		//	trace("Joypad int.");
		   } /* Other interrupts go here, not done yet */
		
		   ioHandler.registers.write(0x0F, intFlags);
		   inInterrupt = true;
		  }
		 }
		
		 /** Initiate an interrupt of the specified type */
		 public function triggerInterrupt(intr:int):void {
		  ioHandler.registers.write(0x0F, ioHandler.registers.read(0x0F) | intr);
		//  trace("Triggered:" + intr);
		 }
		
		 public function triggerInterruptIfEnabled(intr:int):void {
		  if ((ioHandler.registers.read(0xFF) & intr) != 0) ioHandler.registers.write(0x0F, ioHandler.registers.read(0x0F) | intr);
		//  trace("Triggered:" + intr);
		 }
		
		 /** Check for interrupts that need to be initiated */
		 public function initiateInterrupts():void {
		   if (timaEnabled && ((instrCount % instrsPerTima) == 0)) {
		    if (Gameboy.unsign(ioHandler.registers.read(05)) == 0) {
		     ioHandler.registers.write(05, ioHandler.registers.read(06)); // Set TIMA modulo
		     if ((ioHandler.registers.read(0xFF) & INT_TIMA) != 0)
		      triggerInterrupt(INT_TIMA);
		    }
		    ioHandler.registers.write(05, ioHandler.registers.read(05) + 1);
		   }
		
		   if ((instrCount % INSTRS_PER_DIV) == 0) {
		    ioHandler.registers.write(04, ioHandler.registers.read(04) + 1);
		   }
		
		   if ((instrCount % INSTRS_PER_HBLANK) == 0) {
		
		
		    // LCY Coincidence
			// The +1 is due to the LCY register being just about to be incremented
			var cline:int = Gameboy.unsign(ioHandler.registers.read(0x44)) + 1;
			if (cline == 152) cline = 0;
		
		    if (((ioHandler.registers.read(0xFF) & INT_LCDC) != 0) &&
			     ((ioHandler.registers.read(0x41) & 64) != 0) &&
		       (Gameboy.unsign(ioHandler.registers.read(0x45)) == cline) && ((ioHandler.registers.read(0x40) & 0x80) != 0) && (cline < 0x90)) {
		//    trace("Hblank " + cline);
		//	 trace("** LCDC Int **");
		     triggerInterrupt(INT_LCDC);
		    }
		
			// Trigger on every line
		    if (((ioHandler.registers.read(0xFF) & INT_LCDC) != 0) &&
			     ((ioHandler.registers.read(0x41) & 0x8) != 0) && ((ioHandler.registers.read(0x40) & 0x80) != 0) && (cline < 0x90) ) {
		//	 trace("** LCDC Int **");
		     triggerInterrupt(INT_LCDC);
		    }
			
			
		
		    if ((gbcFeatures) && (ioHandler.hdmaRunning)) {
		     ioHandler.performHdma();
		    }
		
		    if (Gameboy.unsign(ioHandler.registers.read(0x44)) == 143) {
		//     trace("VBLANK!");
		     for (var r:int = 144; r < 170; r++) {
		      ppu.notifyScanline(r);
		     } 
		     if ( ((ioHandler.registers.read(0x40) & 0x80) != 0) && ((ioHandler.registers.read(0xFF) & INT_VBLANK) != 0) ) {
		      triggerInterrupt(INT_VBLANK);
			  if ( ((ioHandler.registers.read(0x41) & 16) != 0) && ((ioHandler.registers.read(0xFF) & INT_LCDC) != 0) ) {
		       triggerInterrupt(INT_LCDC);
		//	   trace("VBlank LCDC!");
			  }
		     }
		
		     if ((Parameters.viewSpeedThrottle) && (ppu.frameWaitTime >= 0)) {
		//      trace("Waiting for " + ppu.frameWaitTime + "ms.");
		      try {
		       Thread.sleep(ppu.frameWaitTime);
		      } catch (e:Error) {
		       // Nothing.
		      }
		     }
		    }

			ppu.notifyScanline(Gameboy.unsign(ioHandler.registers.read(0x44)));
		    ioHandler.registers.write(0x44, (Gameboy.unsign(ioHandler.registers.read(0x44)) + 1));
		//	trace("Reg 44 = " + JavaBoy.unsign(ioHandler.registers[0x44]));
		
		    if (Gameboy.unsign(ioHandler.registers.read(0x44)) >= 153) {
		//     trace("VBlank");
		
		     ioHandler.registers.write(0x44, 0);
		     if (apu != null) apu.outputSound();
		     ppu.frameDone = false;
			 if (Gameboy.runningAsApplet) {
		      (applet as Gameboy).drawNextFrame();
			 }
		     try {
		      while (!ppu.frameDone) {
		       Thread.sleep(1);
		      }
		     } catch (e:Error) {
		      // Nothing.
		     }
		      
		
		//     trace("LCDC reset");
		    }
		   }
		 }
		
		public	function beforeExe():void
		{
			terminate = false;
			running = true;
			ppu.startTime = Parameters.getCurrentTime;
		}
		
		public	function afterExe():void
		{
			running = false;
			terminate = false;
		}
		
		 /** Execute the specified number of Gameboy instructions.  Use '-1' to execute forever */
		 public function execute(numInstr:Object):Boolean {
		
		  if (!terminate) {
		
		/*   GameBoyScreen j = (GameBoyScreen) applet;
		   if (j.viewFrameCounter.getState()) {
		    System.out.print(" " + JavaBoy.hexWord(pc) + ":" + JavaBoy.hexByte(cartridge.currentBank));
		   }*/
		//   System.out.print(" " + JavaBoy.hexWord(pc) + ":" + JavaBoy.hexByte(cartridge.currentBank));
		   instrCount++;
		
		   b1 = Gameboy.unsign(addressRead(pc));
		   offset = addressRead(pc + 1);
		   b3 = Gameboy.unsign(addressRead(pc + 2));
		   b2 = Gameboy.unsign(offset);
		
		   switch (b1) {
		    case 0x00 :               // NOP
		        pc++;
		        break;
		    case 0x01 :               // LD BC, nn
		        pc+=3;
		        b = b3;
		        c = b2;
		        break;
		    case 0x02 :               // LD (BC), A
		        pc++;
		        addressWrite((b << 8) | c, a);
		        break;
		    case 0x03 :               // INC BC
		        pc++;
		        c++;
		        if (c == 0x0100) {
		         b++;
		         c = 0;
		         if (b == 0x0100) {
		          b = 0;
		         }
		        }
		        break;
		    case 0x04 :               // INC B
		        pc++;
		        f &= F_CARRY;
		        switch (b) {
		         case 0xFF: f |= F_HALFCARRY + F_ZERO;
		                    b = 0x00;
		                    break;
		         case 0x0F: f |= F_HALFCARRY;
		                    b = 0x10;
		                    break;
		         default:   b++;
		                    break;
		        }
		        break;
		    case 0x05 :               // DEC B
		        pc++;
		        f &= F_CARRY;
		        f |= F_SUBTRACT;
		        switch (b) {
		         case 0x00: f |= F_HALFCARRY;
		                    b = 0xFF;
		                    break;
		         case 0x10: f |= F_HALFCARRY;
		                    b = 0x0F;
		                    break;
		         case 0x01: f |= F_ZERO;
		                    b = 0x00;
		                    break;
		         default:   b--;
		                    break;
		        }
		        break;
		    case 0x06 :               // LD B, nn
		        pc += 2;
		        b = b2;
		        break;
		    case 0x07 :               // RLC A
		        pc++;
		        f = 0;
		
		        a <<= 1;
		
		        if ((a & 0x0100) != 0) {
		         f |= F_CARRY;
		         a |= 1;
		         a &= 0xFF;
		        }
		        if (a == 0) {
		         f |= F_ZERO;
		        }
		        break;
		    case 0x08 :               // LD (nnnn), SP   /* **** May be wrong! **** */
		        pc+=3;
		        addressWrite((b3 << 8) + b2 + 1, (sp & 0xFF00) >> 8);
		        addressWrite((b3 << 8) + b2, (sp & 0x00FF));
		        break;
		    case 0x09 :               // ADD HL, BC
		        pc++;
		        hl = (hl + ((b << 8) + c));
		        if ((hl & 0xFFFF0000) != 0) {
		         f = (f & (F_SUBTRACT + F_ZERO + F_HALFCARRY)) | (F_CARRY);
		         hl &= 0xFFFF;
		        } else {
		         f = f & (F_SUBTRACT + F_ZERO + F_HALFCARRY);
		        }
		        break;
		    case 0x0A :               // LD A, (BC)
		        pc++;
		        a = Gameboy.unsign(addressRead((b << 8) + c));
		        break;
		    case 0x0B :               // DEC BC
		        pc++;
		        c--;
		        if ((c & 0xFF00) != 0) {
		         c = 0xFF;
		         b--;
		         if ((b & 0xFF00) != 0) {
		          b = 0xFF;
		         }
		        }
		        break;
		    case 0x0C :               // INC C
		        pc++;
		        f &= F_CARRY;
		        switch (c) {
		         case 0xFF: f |= F_HALFCARRY + F_ZERO;
		                    c = 0x00;
		                    break;
		         case 0x0F: f |= F_HALFCARRY;
		                    c = 0x10;
		                    break;
		         default:   c++;
		                    break;
		        }
		        break;
		    case 0x0D :               // DEC C
		        pc++;
		        f &= F_CARRY;
		        f |= F_SUBTRACT;
		        switch (c) {
		         case 0x00: f |= F_HALFCARRY;
		                    c = 0xFF;
		                    break;
		         case 0x10: f |= F_HALFCARRY;
		                    c = 0x0F;
		                    break;
		         case 0x01: f |= F_ZERO;
		                    c = 0x00;
		                    break;
		         default:   c--;
		                    break;
		        }
		        break;
		    case 0x0E :               // LD C, nn
		        pc+=2;
		        c = b2;
		        break;        
		    case 0x0F :               // RRC A
		        pc++;
		        if ((a & 0x01) == 0x01) {
		         f = F_CARRY;
		        } else {
		         f = 0;
		        }
		        a >>= 1;
		        if ((f & F_CARRY) == F_CARRY) {
		         a |= 0x80;
		        }
		        if (a == 0) {
		         f |= F_ZERO;
		        }
		        break;
		    case 0x10 :               // STOP
		        pc+=2;
		
		        if (gbcFeatures) {
		         if ((ioHandler.registers.read(0x4D) & 0x01) == 1) {
		          var newKey1Reg:int = ioHandler.registers.read(0x4D) & 0xFE;
		          if ((newKey1Reg & 0x80) == 0x80) {
		           setDoubleSpeedCpu(false);
		           newKey1Reg &= 0x7F;
		          } else {
		           setDoubleSpeedCpu(true);
		           newKey1Reg |= 0x80;
		//           trace("CAUTION: Game uses double speed CPU, humoungus PC required!");
		          }
		          ioHandler.registers.write(0x4D, newKey1Reg);
		         }
		        }
		
		//        terminate = true;
		//        trace("- Breakpoint reached");
		        break;
		    case 0x11 :               // LD DE, nnnn
		        pc+=3;
		        d = b3;
		        e = b2;
		        break;
		    case 0x12 :               // LD (DE), A
		        pc++;
		        addressWrite((d << 8) + e, a);
		        break;
		    case 0x13 :               // INC DE
		        pc++;
		        e++;
		        if (e == 0x0100) {
		         d++;
		         e = 0;
		         if (d == 0x0100) {
		          d = 0;
		         }
		        }
		        break;
		    case 0x14 :               // INC D
		        pc++;
		        f &= F_CARRY;
		        switch (d) {
		         case 0xFF: f |= F_HALFCARRY + F_ZERO;
		                    d = 0x00;
		                    break;
		         case 0x0F: f |= F_HALFCARRY;
		                    d = 0x10;
		                    break;
		         default:   d++;
		                    break;
		        }
		        break;
		    case 0x15 :               // DEC D
		        pc++;
		        f &= F_CARRY;
		        f |= F_SUBTRACT;
		        switch (d) {
		         case 0x00: f |= F_HALFCARRY;
		                    d = 0xFF;
		                    break;
		         case 0x10: f |= F_HALFCARRY;
		                    d = 0x0F;
		                    break;
		         case 0x01: f |= F_ZERO;
		                    d = 0x00;
		                    break;
		         default:   d--;
		                    break;
		        }
		        break;
		    case 0x16 :               // LD D, nn
		        pc += 2;
		        d = b2;
		        break;
		    case 0x17 :               // RL A
		        pc++;
		        if ((a & 0x80) == 0x80) {
		         newf = F_CARRY;
		        } else {
		         newf = 0;
		        }
		        a <<= 1;
		          
		        if ((f & F_CARRY) == F_CARRY) {
		         a |= 1;
		        }
		
		        a &= 0xFF;
		        if (a == 0) {
		         newf |= F_ZERO;
		        }
		        f = newf;
		        break;
		    case 0x18 :               // JR nn
		        pc += 2 + offset;
		        break;
		    case 0x19 :               // ADD HL, DE
		        pc++;
		        hl = (hl + ((d << 8) + e));
		        if ((hl & 0xFFFF0000) != 0) {
		         f = f & (F_SUBTRACT + F_ZERO + F_HALFCARRY) | (F_CARRY);
		         hl &= 0xFFFF;
		        } else {
		         f = f & (F_SUBTRACT + F_ZERO + F_HALFCARRY);
		        }
		        break;
		    case 0x1A :               // LD A, (DE)
		        pc++;
		        a = Gameboy.unsign(addressRead((d << 8) + e));
		        break;
		    case 0x1B :               // DEC DE
		        pc++;
		        e--;
		        if ((e & 0xFF00) != 0) {
		         e = 0xFF;
		         d--;
		         if ((d & 0xFF00) != 0) {
		          d = 0xFF;
		         }
		        }
		        break;
		    case 0x1C :               // INC E
		        pc++;
		        f &= F_CARRY;
		        switch (e) {
		         case 0xFF: f |= F_HALFCARRY + F_ZERO;
		                    e = 0x00;
		                    break;
		         case 0x0F: f |= F_HALFCARRY;
		                    e = 0x10;
		                    break;
		         default:   e++;
		                    break;
		        }
		        break;
		    case 0x1D :               // DEC E
		        pc++;
		        f &= F_CARRY;
		        f |= F_SUBTRACT;
		        switch (e) {
		         case 0x00: f |= F_HALFCARRY;
		                    e = 0xFF;
		                    break;
		         case 0x10: f |= F_HALFCARRY;
		                    e = 0x0F;
		                    break;
		         case 0x01: f |= F_ZERO;
		                    e = 0x00;
		                    break;
		         default:   e--;
		                    break;
		        }
		        break;
		    case 0x1E :               // LD E, nn
		        pc+=2;
		        e = b2;
		        break;
		    case 0x1F :               // RR A
		        pc++;
		        if ((a & 0x01) == 0x01) {
		         newf = F_CARRY;
		        } else {
		         newf = 0;
		        }
		        a >>= 1;
		  
		        if ((f & F_CARRY) == F_CARRY) {
		         a |= 0x80;
		        }
		      
		        if (a == 0) {
		         newf |= F_ZERO;
		        }
		        f = newf;
		        break;
		    case 0x20 :               // JR NZ, nn
		        if ((f & 0x80) == 0x00) {
		         pc += 2 + offset;
		        } else {
		         pc += 2;
		        }
		        break;
		    case 0x21 :               // LD HL, nnnn
		        pc += 3;
		        hl = (b3 << 8) + b2;
		        break;
		    case 0x22 :               // LD (HL+), A
		        pc++;
		        addressWrite(hl, a);
		        hl = (hl + 1) & 0xFFFF;
		        break;
		    case 0x23 :               // INC HL
		        pc++;
		        hl = (hl + 1) & 0xFFFF;
		        break;
		    case 0x24 :               // INC H         ** May be wrong **
		        pc++;
		        f &= F_CARRY;
		        switch ((hl & 0xFF00) >> 8) {
		         case 0xFF: f |= F_HALFCARRY + F_ZERO;
		                    hl = (hl & 0x00FF);
		                    break;
		         case 0x0F: f |= F_HALFCARRY;
		                    hl = (hl & 0x00FF) | 0x10;
		                    break;
		         default:   hl = (hl + 0x0100);
		                    break;
		        }
		        break;
		    case 0x25 :               // DEC H           ** May be wrong **
		        pc++;
		        f &= F_CARRY;
		        f |= F_SUBTRACT;
		        switch ((hl & 0xFF00) >> 8) {
		         case 0x00: f |= F_HALFCARRY;
		                    hl = (hl & 0x00FF) | (0xFF00);
		                    break;
		         case 0x10: f |= F_HALFCARRY;
		                    hl = (hl & 0x00FF) | (0x0F00);
		                    break;
		         case 0x01: f |= F_ZERO;
		                    hl = (hl & 0x00FF);
		                    break;
		         default:   hl = (hl & 0x00FF) | ((hl & 0xFF00) - 0x0100);
		                    break;
		        }
		        break;
		    case 0x26 :               // LD H, nn
		        pc+=2;
		        hl = (hl & 0x00FF) | (b2 << 8);
		        break;
		    case 0x27 :               // DAA         ** This could be wrong! **
		        pc++;
		
		        var upperNibble:int = (a & 0xF0) >> 4;
		        var lowerNibble:int = a & 0x0F;
		
		//        trace("Daa at " + JavaBoy.hexWord(pc));
		
		        newf = f & F_SUBTRACT;
		
		        if ((f & F_SUBTRACT) == 0) {
		
		         if ((f & F_CARRY) == 0) {
		          if ((upperNibble <= 8) && (lowerNibble >= 0xA) &&
		             ((f & F_HALFCARRY) == 0)) {
		           a += 0x06;
		          }
		
		          if ((upperNibble <= 9) && (lowerNibble <= 0x3) &&
		             ((f & F_HALFCARRY) == F_HALFCARRY)) {
		           a += 0x06;
		          }
		
		          if ((upperNibble >= 0xA) && (lowerNibble <= 0x9) &&
		             ((f & F_HALFCARRY) == 0)) {
		           a += 0x60;
		           newf |= F_CARRY;
		          }
		
		          if ((upperNibble >= 0x9) && (lowerNibble >= 0xA) &&
		             ((f & F_HALFCARRY) == 0)) {
		           a += 0x66;
		           newf |= F_CARRY;
		          }
		
		          if ((upperNibble >= 0xA) && (lowerNibble <= 0x3) &&
		             ((f & F_HALFCARRY) == F_HALFCARRY)) {
		           a += 0x66;
		           newf |= F_CARRY;
		          }
		
		         } else {  // If carry set
		
		          if ((upperNibble <= 0x2) && (lowerNibble <= 0x9) &&
		             ((f & F_HALFCARRY) == 0)) {
		           a += 0x60;
		           newf |= F_CARRY;
		          }
		
		          if ((upperNibble <= 0x2) && (lowerNibble >= 0xA) &&
		             ((f & F_HALFCARRY) == 0)) {
		           a += 0x66;
		           newf |= F_CARRY;
		          }
		
		          if ((upperNibble <= 0x3) && (lowerNibble <= 0x3) &&
		             ((f & F_HALFCARRY) == F_HALFCARRY)) {
		           a += 0x66;
		           newf |= F_CARRY;
		          }
		
		         }
		
		        } else { // Subtract is set
		
		         if ((f & F_CARRY) == 0) {
		
		          if ((upperNibble <= 0x8) && (lowerNibble >= 0x6) &&
		             ((f & F_HALFCARRY) == F_HALFCARRY)) {
		           a += 0xFA;
		          }
		
		         } else { // Carry is set
		
		          if ((upperNibble >= 0x7) && (lowerNibble <= 0x9) &&
		             ((f & F_HALFCARRY) == 0)) {
		           a += 0xA0;
		           newf |= F_CARRY;
		          }
		
		          if ((upperNibble >= 0x6) && (lowerNibble >= 0x6) &&
		             ((f & F_HALFCARRY) == F_HALFCARRY)) {
		           a += 0x9A;
		           newf |= F_CARRY;
		          }
		
		         }
		
		        }
		
		        a &= 0x00FF;
		        if (a == 0) newf |= F_ZERO;
		
		        f = newf;
		
		        break;
		    case 0x28 :               // JR Z, nn
		        if ((f & F_ZERO) == F_ZERO) {
		         pc += 2 + offset;
		        } else {
		         pc += 2;
		        }
		        break;
		    case 0x29 :               // ADD HL, HL
		        pc++;
		        hl = (hl + hl);
		        if ((hl & 0xFFFF0000) != 0) {
		         f = (f & (F_SUBTRACT + F_ZERO + F_HALFCARRY)) | (F_CARRY);
		         hl &= 0xFFFF;
		        } else {
		         f = f & (F_SUBTRACT + F_ZERO + F_HALFCARRY);
		        }
		        break;
		    case 0x2A :               // LDI A, (HL)
		        pc++;                    
		        a = Gameboy.unsign(addressRead(hl));
		        hl++;
		        break;
		    case 0x2B :               // DEC HL
		        pc++;
		        if (hl == 0) {
		         hl = 0xFFFF;
		        } else {
		         hl--;
		        }
		        break;
		    case 0x2C :               // INC L
		        pc++;
		        f &= F_CARRY;
		        switch (hl & 0x00FF) {
		         case 0xFF: f |= F_HALFCARRY + F_ZERO;
		                    hl = hl & 0xFF00;
		                    break;
		         case 0x0F: f |= F_HALFCARRY;
		                    hl++;
		                    break;
		         default:   hl++;
		                    break;
		        }
		        break;
		    case 0x2D :               // DEC L
		        pc++;
		        f &= F_CARRY;
		        f |= F_SUBTRACT;
		        switch (hl & 0x00FF) {
		         case 0x00: f |= F_HALFCARRY;
		                    hl = (hl & 0xFF00) | 0x00FF;
		                    break;
		         case 0x10: f |= F_HALFCARRY;
		                    hl = (hl & 0xFF00) | 0x000F;
		                    break;
		         case 0x01: f |= F_ZERO;
		                    hl = (hl & 0xFF00);
		                    break;
		         default:   hl = (hl & 0xFF00) | ((hl & 0x00FF) - 1);
		                    break;
		        }
		        break;
		    case 0x2E :               // LD L, nn
		        pc+=2;
		        hl = (hl & 0xFF00) | b2;
		        break;
		    case 0x2F :               // CPL A
		        pc++;
		        var mask:int = 0x80;	//short
		/*        short result = 0;
		        for (int n = 0; n < 8; n++) {
		         if ((a & mask) == 0) {
		          result |= mask;
		         } else {
		         }
		         mask >>= 1;
		        }*/
		        a = (~a) & 0x00FF;
		        f = (f & (F_CARRY | F_ZERO)) | F_SUBTRACT | F_HALFCARRY;
		        break;
		    case 0x30 :               // JR NC, nn
		        if ((f & F_CARRY) == 0) {
		         pc += 2 + offset;
		        } else {
		         pc += 2;
		        }
		        break;
		    case 0x31 :               // LD SP, nnnn
		        pc += 3;
		        sp = (b3 << 8) + b2;
		        break;
		    case 0x32 :
		        pc++;
		        addressWrite(hl, a);  // LD (HL-), A
		        hl--;
		        break;
		    case 0x33 :               // INC SP
		        pc++;
		        sp = (sp + 1) & 0xFFFF;
		        break;
		    case 0x34 :               // INC (HL)
		        pc++;
		        f &= F_CARRY;
		        dat = Gameboy.unsign(addressRead(hl));
		        switch (dat) {
		         case 0xFF: f |= F_HALFCARRY + F_ZERO;
		                    addressWrite(hl, 0x00);
		                    break;
		         case 0x0F: f |= F_HALFCARRY;
		                    addressWrite(hl, 0x10);
		                    break;
		         default:   addressWrite(hl, dat + 1);
		                    break;
		        }
		        break;
		    case 0x35 :               // DEC (HL)
		        pc++;
		        f &= F_CARRY;
		        f |= F_SUBTRACT;
		        dat = Gameboy.unsign(addressRead(hl));
		        switch (dat) {
		         case 0x00: f |= F_HALFCARRY;
		                    addressWrite(hl, 0xFF);
		                    break;
		         case 0x10: f |= F_HALFCARRY;
		                    addressWrite(hl, 0x0F);
		                    break;
		         case 0x01: f |= F_ZERO;
		                    addressWrite(hl, 0x00);
		                    break;
		         default:   addressWrite(hl, dat - 1);
		                    break;
		        }
		        break;
		    case 0x36 :               // LD (HL), nn
		        pc += 2;
		        addressWrite(hl, b2);
		        break;
		    case 0x37 :               // SCF
		        pc++;
		        f &= F_ZERO;
		        f |= F_CARRY;
		        break;
		    case 0x38 :               // JR C, nn
		        if ((f & F_CARRY) == F_CARRY) {
		         pc += 2 + offset;
		        } else {
		         pc += 2;
		        }
		        break;
		    case 0x39 :               // ADD HL, SP      ** Could be wrong **
		        pc++;
		        hl = (hl + sp);
		        if ((hl & 0xFFFF0000) != 0) {
		         f = (f & (F_SUBTRACT + F_ZERO + F_HALFCARRY)) | (F_CARRY);
		         hl &= 0xFFFF;
		        } else {
		         f = f & (F_SUBTRACT + F_ZERO + F_HALFCARRY);
		        }
		        break;
		    case 0x3A :               // LD A, (HL-)
		        pc++;
		        a = Gameboy.unsign(addressRead(hl));
		        hl = (hl - 1) & 0xFFFF;
		        break;
		    case 0x3B :               // DEC SP
		        pc++;
		        sp = (sp - 1) & 0xFFFF;
		        break;
		    case 0x3C :               // INC A
		        pc++;
		        f &= F_CARRY;
		        switch (a) {
		         case 0xFF: f |= F_HALFCARRY + F_ZERO;
		                    a = 0x00;
		                    break;
		         case 0x0F: f |= F_HALFCARRY;
		                    a = 0x10;
		                    break;
		         default:   a++;
		                    break;
		        }
		        break;
		    case 0x3D :               // DEC A
		        pc++;
		        f &= F_CARRY;
		        f |= F_SUBTRACT;
		        switch (a) {
		         case 0x00: f |= F_HALFCARRY;
		                    a = 0xFF;
		                    break;
		         case 0x10: f |= F_HALFCARRY;
		                    a = 0x0F;
		                    break;
		         case 0x01: f |= F_ZERO;
		                    a = 0x00;
		                    break;
		         default:   a--;
		                    break;
		        }
		        break;
		    case 0x3E :               // LD A, nn
		        pc += 2;
		        a = b2;
		        break;
		    case 0x3F :               // CCF
		        pc++;
		        if ((f & F_CARRY) == 0) {
		         f = (f & F_ZERO) | F_CARRY;
		        } else {
		         f = f & F_ZERO;
		        }
		        break;
		    case 0x52 :               // Debug breakpoint (LD D, D)
			    // As this insturction is used in games (why?) only break here if the breakpoint is on in the debugger
				if (breakpointEnable) {
		         terminate = true;
		         trace("- Breakpoint reached");
				} else {
				 pc++;
				}
		        break;
		
		    case 0x76 :               // HALT
		 	    interruptsEnabled = true;
		//		trace("Halted, pc = " + JavaBoy.hexWord(pc));
		        while (ioHandler.registers.read(0x0F) == 0) {
		         initiateInterrupts();
		         instrCount++;
		        }
		
		//		trace("intrcount: " + instrCount + " IE: " + JavaBoy.hexByte(ioHandler.registers[0xFF]));
		//		trace(" Finished halt");
		        pc++;
		        break;
		    case 0xAF :               // XOR A, A (== LD A, 0)
		        pc ++;
		        a = 0;
		        f = 0x80;             // Set zero flag
		        break;
		    case 0xC0 :               // RET NZ
		        if ((f & F_ZERO) == 0) {
		         pc = (Gameboy.unsign(addressRead(sp + 1)) << 8) + Gameboy.unsign(addressRead(sp));
		         sp += 2;
		        } else {
		         pc++;
		        }
		        break;
		    case 0xC1 :               // POP BC
		        pc++;
		        c = Gameboy.unsign(addressRead(sp));
		        b = Gameboy.unsign(addressRead(sp + 1));
		        sp+=2;
		        break;
		    case 0xC2 :               // JP NZ, nnnn
		        if ((f & F_ZERO) == 0) {
		         pc = (b3 << 8) + b2;
		        } else {
		         pc += 3;
		        }
		        break;
		    case 0xC3 :
		        pc = (b3 << 8) + b2;  // JP nnnn
		        break;
		    case 0xC4 :               // CALL NZ, nnnnn
		        if ((f & F_ZERO) == 0) {
		         pc += 3;
		         sp -= 2;
		         addressWrite(sp + 1, pc >> 8);
		         addressWrite(sp, pc & 0x00FF);
		         pc = (b3 << 8) + b2;
		        } else {
		         pc+=3;
		        }
		        break;
		    case 0xC5 :               // PUSH BC
		        pc++;
		        sp -= 2;
		        sp &= 0xFFFF;
		        addressWrite(sp, c);
		        addressWrite(sp + 1, b);
		        break;
		    case 0xC6 :               // ADD A, nn
		        pc+=2;
		        f = 0;
		
		        if ((((a & 0x0F) + (b2 & 0x0F)) & 0xF0) != 0x00) {
		         f |= F_HALFCARRY;
		        }
		
		        a += b2;
		
		        if ((a & 0xFF00) != 0) {     // Perform 8-bit overflow and set zero flag
		         if (a == 0x0100) {
		          f |= F_ZERO + F_CARRY + F_HALFCARRY;
		          a = 0;
		         } else {
		          f |= F_CARRY + F_HALFCARRY;
		          a &= 0x00FF;
		         }
		        }
		        break;
		    case 0xCF :               // RST 08
		        pc++;
		        sp -= 2;
		        addressWrite(sp + 1, pc >> 8);
		        addressWrite(sp, pc & 0x00FF);
		        pc = 0x08;
		        break;
		    case 0xC8 :               // RET Z
		        if ((f & F_ZERO) == F_ZERO) {
		         pc = (Gameboy.unsign(addressRead(sp + 1)) << 8) + Gameboy.unsign(addressRead(sp));
		         sp += 2;
		        } else {
		         pc++;
		        }
		        break;
		    case 0xC9 :               // RET
		        pc = (Gameboy.unsign(addressRead(sp + 1)) << 8) + Gameboy.unsign(addressRead(sp));
		        sp += 2;
		        break;
		    case 0xCA :               // JP Z, nnnn
		        if ((f & F_ZERO) == F_ZERO) {
		         pc = (b3 << 8) + b2;
		        } else {
		         pc += 3;
		        }
		        break;
		    case 0xCB :               // Shift/bit test
		        pc += 2;
		        var regNum:int = b2 & 0x07;
		        var data:int = registerRead(regNum);
		//        trace("0xCB instr! - reg " + Javaboy.hexByte((short) (b2 & 0xF4)));
		        if ((b2 & 0xC0) == 0) {
		         switch ((b2 & 0xF8)) {
		          case 0x00 :          // RLC A
		           if ((data & 0x80) == 0x80) {
		            f = F_CARRY;
		           } else {
		            f = 0;
		           }
		           data <<= 1;
		           if ((f & F_CARRY) == F_CARRY) {
		            data |= 1;
		           }
		
		           data &= 0xFF;
		           if (data == 0) {
		            f |= F_ZERO;
		           }
		           registerWrite(regNum, data);
		           break;
		          case 0x08 :          // RRC A
		           if ((data & 0x01) == 0x01) {
		            f = F_CARRY;
		           } else {
		            f = 0;
		           }
		           data >>= 1;
		           if ((f & F_CARRY) == F_CARRY) {
		            data |= 0x80;
		           }
		           if (data == 0) {
		            f |= F_ZERO;
		           }
		           registerWrite(regNum, data);
		           break;
		          case 0x10 :          // RL r
		   
		           if ((data & 0x80) == 0x80) {
		            newf = F_CARRY;
		           } else {
		            newf = 0;
		           }
		           data <<= 1;
		          
		           if ((f & F_CARRY) == F_CARRY) {
		            data |= 1;
		           }
		
		           data &= 0xFF;
		           if (data == 0) {
		            newf |= F_ZERO;
		           }
		           f = newf;
		           registerWrite(regNum, data);
		           break;
		          case 0x18 :          // RR r
		           if ((data & 0x01) == 0x01) {
		            newf = F_CARRY;
		           } else {
		            newf = 0;
		           }
		           data >>= 1;
		  
		           if ((f & F_CARRY) == F_CARRY) {
		            data |= 0x80;
		           }
		      
		           if (data == 0) {
		            newf |= F_ZERO;
		           }
		           f = newf;
		           registerWrite(regNum, data);
		           break;
		          case 0x20 :          // SLA r
		           if ((data & 0x80) == 0x80) {
		            f = F_CARRY;
		           } else {
		            f = 0;
		           }
		
		           data <<= 1;
		  
		           data &= 0xFF;
		           if (data == 0) {
		            f |= F_ZERO;
		           }
		           registerWrite(regNum, data);
		           break;
		          case 0x28 :          // SRA r
		           var topBit:int = 0;	//short
		
		           topBit = data & 0x80;
		           if ((data & 0x01) == 0x01) {
		            f = F_CARRY;
		           } else {
		            f = 0;
		           }
		
		           data >>= 1;
		           data |= topBit;
		
		           if (data == 0) {
		            f |= F_ZERO;
		           }
		           registerWrite(regNum, data);
		           break;
		          case 0x30 :          // SWAP r
		  
		           data = ((data & 0x0F) << 4) | ((data & 0xF0) >> 4);
		           if (data == 0) {
		            f = F_ZERO;
		           } else {
		            f = 0;
		           }
		//           trace("SWAP - answer is " + Javaboy.hexByte(data));
		           registerWrite(regNum, data);
		           break;
		          case 0x38 :          // SRL r
		           if ((data & 0x01) == 0x01) {
		            f = F_CARRY;
		           } else {
		            f = 0;
		           }
		
		           data >>= 1;
		
		           if (data == 0) {
		            f |= F_ZERO;
		           }
		           registerWrite(regNum, data);
		           break;
		          }
		        } else {
		
		         var bitNumber:int = (b2 & 0x38) >> 3;
		
		         if ((b2 & 0xC0) == 0x40)  {  // BIT n, r
		          mask = 0x01 << bitNumber;
		          if ((data & mask) != 0) {
		           f = (f & F_CARRY) | F_HALFCARRY;
		          } else {
		           f = (f & F_CARRY) | (F_HALFCARRY + F_ZERO);
		          }
		         }
		         if ((b2 & 0xC0) == 0x80) {  // RES n, r
		          mask = 0xFF - (0x01 << bitNumber);
		          data = data & mask;
		          registerWrite(regNum, data);
		         }
		         if ((b2 & 0xC0) == 0xC0) {  // SET n, r
		          mask = 0x01 << bitNumber;
		          data = data | mask;
		          registerWrite(regNum, data);
		         }
		
		        }
		
		        break;
		    case 0xCC :               // CALL Z, nnnnn
		        if ((f & F_ZERO) == F_ZERO) {
		         pc += 3;
		         sp -= 2;
		         addressWrite(sp + 1, pc >> 8);
		         addressWrite(sp, pc & 0x00FF);
		         pc = (b3 << 8) + b2;
		        } else {
		         pc+=3;
		        }
		        break;
		    case 0xCD :               // CALL nnnn
		        pc += 3;
		        sp -= 2;
		        addressWrite(sp + 1, pc >> 8);
		        addressWrite(sp, pc & 0x00FF);
		        pc = (b3 << 8) + b2;
		        break;
		    case 0xCE :               // ADC A, nn
		        pc+=2;
		
		        if ((f & F_CARRY) != 0) {
		         b2++;
		        }
		        f = 0;
		
		        if ((((a & 0x0F) + (b2 & 0x0F)) & 0xF0) != 0x00) {
		         f |= F_HALFCARRY;
		        }
		
		        a += b2;
		
		        if ((a & 0xFF00) != 0) {     // Perform 8-bit overflow and set zero flag
		         if (a == 0x0100) {
		          f |= F_ZERO + F_CARRY + F_HALFCARRY;
		          a = 0;
		         } else {
		          f |= F_CARRY + F_HALFCARRY;
		          a &= 0x00FF;
		         }
		        }
		        break;
		    case 0xC7 :               // RST 00
		        pc++;
		        sp -= 2;
		        addressWrite(sp + 1, pc >> 8);
		        addressWrite(sp, pc & 0x00FF);
		//        terminate = true;
		        pc = 0x00;
		        break;
		    case 0xD0 :               // RET NC
		        if ((f & F_CARRY) == 0) {
		         pc = (Gameboy.unsign(addressRead(sp + 1)) << 8) + Gameboy.unsign(addressRead(sp));
		         sp += 2;
		        } else {
		         pc++;
		        }
		        break;
		    case 0xD1 :               // POP DE
		        pc++;
		        e = Gameboy.unsign(addressRead(sp));
		        d = Gameboy.unsign(addressRead(sp + 1));
		        sp+=2;
		        break;
		    case 0xD2 :               // JP NC, nnnn
		        if ((f & F_CARRY) == 0) {
		         pc = (b3 << 8) + b2;
		        } else {
		         pc += 3;
		        }
		        break;
		    case 0xD4 :               // CALL NC, nnnn
		        if ((f & F_CARRY) == 0) {
		         pc += 3;
		         sp -= 2;
		         addressWrite(sp + 1, pc >> 8);
		         addressWrite(sp, pc & 0x00FF);
		         pc = (b3 << 8) + b2;
		        } else {
		         pc+=3;
		        }
		        break;
		    case 0xD5 :               // PUSH DE
		        pc++;
		        sp -= 2;
		        sp &= 0xFFFF;
		        addressWrite(sp, e);
		        addressWrite(sp + 1, d);
		        break;
		    case 0xD6 :               // SUB A, nn
		        pc+=2;
		
		        f = F_SUBTRACT;
		
		        if ((((a & 0x0F) - (b2 & 0x0F)) & 0xFFF0) != 0x00) {
		         f |= F_HALFCARRY;
		        }
		
		        a -= b2;
		
		        if ((a & 0xFF00) != 0) {
		         a &= 0x00FF;
		         f |= F_CARRY;
		         }
		         if (a == 0) {
		          f |= F_ZERO;
		         }
		         break;
		    case 0xD7 :               // RST 10
		        pc++;
		        sp -= 2;
		        addressWrite(sp + 1, pc >> 8);
		        addressWrite(sp, pc & 0x00FF);
		        pc = 0x10;
		        break;
		    case 0xD8 :               // RET C
		        if ((f & F_CARRY) == F_CARRY) {
		         pc = (Gameboy.unsign(addressRead(sp + 1)) << 8) + Gameboy.unsign(addressRead(sp));
		         sp += 2;
		        } else {
		         pc++;
		        }
		        break;
		    case 0xD9 :               // RETI
		        interruptsEnabled = true;
		        inInterrupt = false;
		        pc = (Gameboy.unsign(addressRead(sp + 1)) << 8) + Gameboy.unsign(addressRead(sp));
		        sp += 2;
		        break;
		    case 0xDA :               // JP C, nnnn
		        if ((f & F_CARRY) == F_CARRY) {
		         pc = (b3 << 8) + b2;
		        } else {
		         pc += 3;
		        }
		        break;
		    case 0xDC :               // CALL C, nnnn
		        if ((f & F_CARRY) == F_CARRY) {
		         pc += 3;
		         sp -= 2;
		         addressWrite(sp + 1, pc >> 8);
		         addressWrite(sp, pc & 0x00FF);
		         pc = (b3 << 8) + b2;
		        } else {
		         pc+=3;
		        }
		        break;
		    case 0xDE :               // SBC A, nn
		        pc+=2;
		        if ((f & F_CARRY) != 0) {
		         b2++;
		        }
		
		        f = F_SUBTRACT;
		        if ((((a & 0x0F) - (b2 & 0x0F)) & 0xFFF0) != 0x00) {
		         f |= F_HALFCARRY;
		        }
		
		        a -= b2;
		
		        if ((a & 0xFF00) != 0) {
		         a &= 0x00FF;
		         f |= F_CARRY;
		        }
		
		        if (a == 0) {
		         f |= F_ZERO;
		        }
		        break;
		    case 0xDF :               // RST 18
		        pc++;
		        sp -= 2;
		        addressWrite(sp + 1, pc >> 8);
		        addressWrite(sp, pc & 0x00FF);
		        pc = 0x18;
		        break;
		    case 0xE0 :               // LDH (FFnn), A
		        pc += 2;
		        addressWrite(0xFF00 + b2, a);
		        break;
		    case 0xE1 :               // POP HL
		        pc++;
		        hl = (Gameboy.unsign(addressRead(sp + 1)) << 8) + Gameboy.unsign(addressRead(sp));
		        sp += 2;
		        break;
		    case 0xE2 :               // LDH (FF00 + C), A
		        pc++;
		        addressWrite(0xFF00 + c, a);
		        break;
		    case 0xE5 :               // PUSH HL
		        pc++;
		        sp -= 2;
		        sp &= 0xFFFF;
		        addressWrite(sp + 1, hl >> 8);
		        addressWrite(sp, hl & 0x00FF);
		        break;
		    case 0xE6 :               // AND nn
		        pc+=2;
		        a &= b2;
		        if (a == 0) {
		         f = F_ZERO;
		        } else {
		         f = 0;
		        }
		        break;
		    case 0xE7 :               // RST 20
		        pc++;
		        sp -= 2;
		        addressWrite(sp + 1, pc >> 8);
		        addressWrite(sp, pc & 0x00FF);
		        pc = 0x20;
		        break;
		    case 0xE8 :               // ADD SP, nn
		        pc+=2;
		        sp = (sp + offset);
		        if ((sp & 0xFFFF0000) != 0) {
		         f = (f & (F_SUBTRACT + F_ZERO + F_HALFCARRY)) | (F_CARRY);
		         sp &= 0xFFFF;
		        } else {
		         f = (f & (F_SUBTRACT + F_ZERO + F_HALFCARRY));
		        }
		        break;
		    case 0xE9 :               // JP (HL)
		        pc++;
		        pc = hl;
		        break;
		    case 0xEA :               // LD (nnnn), A
		        pc += 3;              
		        addressWrite((b3 << 8) + b2, a);
		        break;
		    case 0xEE :               // XOR A, nn
		        pc+=2;
		        a ^= b2;
		        if (a == 0) {
		         f = F_ZERO;
		        } else {
		         f = 0;
		        }
		        break;
		    case 0xEF :               // RST 28
		        pc++;
		        sp -= 2;
		        addressWrite(sp + 1, pc >> 8);
		        addressWrite(sp, pc & 0x00FF);
		        pc = 0x28;
		        break;
		    case 0xF0 :               // LDH A, (FFnn)
		        pc += 2;
		        a = Gameboy.unsign(addressRead(0xFF00 + b2));
		        break;
		    case 0xF1 :               // POP AF
		        pc++;
		        f = Gameboy.unsign(addressRead(sp));
		        a = Gameboy.unsign(addressRead(sp + 1));
		        sp+=2;
		        break;
		    case 0xF2 :               // LD A, (FF00 + C)
		        pc++;
		        a = Gameboy.unsign(addressRead(0xFF00 + c));
		        break;
		    case 0xF3 :               // DI
		        pc++;
		        interruptsEnabled = false;
		    //    addressWrite(0xFFFF, 0);
		        break;
		    case 0xF5 :               // PUSH AF
		        pc++;
		        sp -= 2;
		        sp &= 0xFFFF;
		        addressWrite(sp, f);
		        addressWrite(sp + 1, a);
		        break;
		    case 0xF6 :               // OR A, nn
		        pc+=2;
		        a |= b2;
		        if (a == 0) {
		         f = F_ZERO;
		        } else {
		         f = 0;
		        }
		        break;
		    case 0xF7 :               // RST 30
		        pc++;
		        sp -= 2;
		        addressWrite(sp + 1, pc >> 8);
		        addressWrite(sp, pc & 0x00FF);
		        pc = 0x30;
		        break;
		    case 0xF8 :               // LD HL, SP + nn  ** HALFCARRY FLAG NOT SET ***
		        pc += 2;
		        hl = (sp + offset);
		        if ((hl & 0x10000) != 0) {
		         f = F_CARRY;
		         hl &= 0xFFFF;
		        } else {
		         f = 0;
		        }
		        break;
		    case 0xF9 :               // LD SP, HL
		        pc++;
		        sp = hl;
		        break;
		    case 0xFA :               // LD A, (nnnn)
		        pc+=3;
		        a = Gameboy.unsign(addressRead((b3 << 8) + b2));
		        break;
		    case 0xFB :               // EI
		        pc++;
		        ieDelay = 1;
		      //  interruptsEnabled = true;
		      //  addressWrite(0xFFFF, 0xFF);
		        break;
		    case 0xFE :               // CP nn     ** FLAGS ARE WRONG! **
		        pc += 2;
		        f = 0;
		        if (b2 == a) {
		         f |= F_ZERO;
		        } else {
		         if (a < b2) {
		          f |= F_CARRY;
		         }
		        }
		        break;
		    case 0xFF :               // RST 38
		        pc++;
		        sp -= 2;
		        addressWrite(sp + 1, pc >> 8);
		        addressWrite(sp, pc & 0x00FF);
		        pc = 0x38;
		        break;
		
		    default :
		
		        if ((b1 & 0xC0) == 0x80) {       // Byte 0x10?????? indicates ALU op
		         pc++;
		         var operand:int = registerRead(b1 & 0x07);
		         switch ((b1 & 0x38) >> 3) {
		          case 1 : // ADC A, r
		              if ((f & F_CARRY) != 0) {
		               operand++;
		              }
		              // Note!  No break!
		          case 0 : // ADD A, r
		
		              f = 0;
		
		              if ((((a & 0x0F) + (operand & 0x0F)) & 0xF0) != 0x00) {
		               f |= F_HALFCARRY;
		              }
		
		              a += operand;
		
		              if (a == 0) {
		               f |= F_ZERO;
		              }
		
		              if ((a & 0xFF00) != 0) {     // Perform 8-bit overflow and set zero flag
		               if (a == 0x0100) {
		                f |= F_ZERO + F_CARRY + F_HALFCARRY;
		                a = 0;
		               } else {
		                f |= F_CARRY + F_HALFCARRY;
		                a &= 0x00FF;
		               }
		              }
		              break;
		          case 3 : // SBC A, r
		              if ((f & F_CARRY) != 0) {
		               operand++;
		              }
		              // Note! No break!
		          case 2 : // SUB A, r
		
		              f = F_SUBTRACT;
		
		              if ((((a & 0x0F) - (operand & 0x0F)) & 0xFFF0) != 0x00) {
		               f |= F_HALFCARRY;
		              }
		
		              a -= operand;
		
		              if ((a & 0xFF00) != 0) {
		               a &= 0x00FF;
		               f |= F_CARRY;
		              }
		              if (a == 0) {
		               f |= F_ZERO;
		              }
		
		              break;
		          case 4 : // AND A, r
		              a &= operand;
		              if (a == 0) {
		               f = F_ZERO;
		              } else {
		               f = 0;
		              }
		              break;
		          case 5 : // XOR A, r
		              a ^= operand;
		              if (a == 0) {
		               f = F_ZERO;
		              } else {
		               f = 0;
		              }
		              break;
		          case 6 : // OR A, r
		              a |= operand;
		              if (a == 0) {
		               f = F_ZERO;
		              } else {
		               f = 0;
		              }
		              break;
		          case 7 : // CP A, r (compare)
		              f = F_SUBTRACT;
		              if (a == operand) {
		               f |= F_ZERO;
		              }
		              if (a < operand) {
		               f |= F_CARRY;
		              }
		              if ((a & 0x0F) < (operand & 0x0F)) {
		               f |= F_HALFCARRY;
		              }
		              break;
		         }
		        } else if ((b1 & 0xC0) == 0x40) {   // Byte 0x01xxxxxxx indicates 8-bit ld
		
		         pc++;
		         registerWrite((b1 & 0x38) >> 3, registerRead(b1 & 0x07));
		
		        } else {
		         trace("Unrecognized opcode (" + Gameboy.hexByte(b1) + ")");
		         terminate = true;
		         pc++;
		         break;
		        }
		   }
		
		    
		   if (ieDelay != -1) {
		
		    if (ieDelay > 0) {
		     ieDelay--;
		    } else {
		     interruptsEnabled = true;
		     ieDelay = -1;
		    }
		
		   }
		
		
		   if (interruptsEnabled) {
		    checkInterrupts();
		   }
		
		   cartridge.update();
		
		
		   initiateInterrupts();
		
		
		/*   if ((hl & 0xFFFF0000) != 0) {
		    terminate = true;
		    trace("Overflow in HL!");
		   }*/
		
		  }
		  else
		  {
		  	return false;
		  }
		  return true;
		 }
		
		 public function setBreakpoint(on:Boolean):void {
		  breakpointEnable = on;
		 }
		
		 /** Output a disassembly of the specified number of instructions starting at the speicifed address.
		  */
		 public function disassemble(address:int, numInstr:int):String {
		
		  trace("Addr  Data      Instruction");
		
		  for (var r:int = 0; r < numInstr; r++) {
		   var b1:int = Gameboy.unsign(addressRead(address));	//short
		   var offset:int = addressRead(address + 1);	//short
		   var b3:int = Gameboy.unsign(addressRead(address + 2));	//short
		   var b2:int = Gameboy.unsign(offset);	//short
		
		   var instr:String = "Unknown Opcode! (" + Gameboy.unsign(b1).toString(16) + ")";
		   var instrLength:int = 1;	//byte
		
		   switch (b1) {
		    case 0x00 :
		           instr = "NOP";
		           break;
		    case 0x01 :
		           instr = "LD BC, " + Gameboy.hexWord((b3 << 8) + b2);
		           instrLength = 3;
		           break;
		    case 0x02 :
		           instr = "LD (BC), A";
		           break;
		    case 0x03 :
		           instr = "INC BC";
		           break;
		    case 0x04 :
		           instr = "INC B";
		           break;
		    case 0x05 :
		           instr = "DEC B";
		           break;
		    case 0x06 :
		           instr = "LD B, " + Gameboy.hexByte(b2);
		           instrLength = 2;
		           break;
		    case 0x07 :
		           instr = "RLC A";
		           break;
		    case 0x08 :
		           instr = "LD (" + Gameboy.hexWord((b3 << 8) + b2) + "), SP";
		           instrLength = 3;        // Non Z80
		           break;
		    case 0x09 :
		           instr = "ADD HL, BC";
		           break;
		    case 0x0A :
		           instr = "LD A, (BC)";
		           break;
		    case 0x0B :
		           instr = "DEC BC";
		           break;
		    case 0x0C :
		           instr = "INC C";
		           break;
		    case 0x0D :
		           instr = "DEC C";
		           break;
		    case 0x0E :
		           instr = "LD C, " + Gameboy.hexByte(b2);
		           instrLength = 2;
		           break;
		    case 0x0F :
		           instr = "RRC A";
		           break;
		    case 0x10 :
		           instr = "STOP";
		           instrLength = 2;  // STOP instruction must be followed by a NOP
		           break;
		    case 0x11 :
		           instr = "LD DE, " + Gameboy.hexWord((b3 << 8) + b2);
		           instrLength = 3;
		           break;
		    case 0x12 :
		           instr = "LD (DE), A";
		           break;
		    case 0x13 :
		           instr = "INC DE";
		           break;
		    case 0x14 :
		           instr = "INC D";
		           break;
		    case 0x15 :
		           instr = "DEC D";
		           break;
		    case 0x16 :
		           instr = "LD D, " + Gameboy.hexByte(b2);
		           instrLength = 2;
		           break;
		    case 0x17 :
		           instr = "RL A";
		           break;
		    case 0x18 :
		           instr = "JR " + Gameboy.hexWord(address + 2 + offset);
		           instrLength = 2;
		           break;
		    case 0x19 :
		           instr = "ADD HL, DE";
		           break;
		    case 0x1A :
		           instr = "LD A, (DE)";
		           break;
		    case 0x1B :
		           instr = "DEC DE";
		           break;
		    case 0x1C :
		           instr = "INC E";
		           break;
		    case 0x1D :
		           instr = "DEC E";
		           break;
		    case 0x1E :
		           instr = "LD E, " + Gameboy.hexByte(b2);
		           instrLength = 2;
		           break;
		    case 0x1F :
		           instr = "RR A";
		           break;
		    case 0x20 :
		           instr = "JR NZ, " + Gameboy.hexWord(address + 2 + offset) + ": " + offset;
		           
		           instrLength = 2;
		           break;
		    case 0x21 :
		           instr = "LD HL, " + Gameboy.hexWord((b3 << 8) + b2);
		           instrLength = 3;
		           break;
		    case 0x22 :
		           instr = "LD (HL+), A";     // Non Z80
		           break;
		    case 0x23 :
		           instr = "INC HL";
		           break;
		    case 0x24 :
		           instr = "INC H";
		           break;
		    case 0x25 :
		           instr = "DEC H";
		           break;
		    case 0x26 :
		           instr = "LD H, " + Gameboy.hexByte(b2);
		           instrLength = 2;
		           break;
		    case 0x27 :
		           instr = "DAA";
		           break;
		    case 0x28 :
		           instr = "JR Z, " + Gameboy.hexWord(address + 2 + offset);
		           instrLength = 2;
		           break;
		    case 0x29 :
		           instr = "ADD HL, HL";
		           break;
		    case 0x2A :
		           instr = "LDI A, (HL)";
		           break;
		    case 0x2B :
		           instr = "DEC HL";
		           break;
		    case 0x2C :
		           instr = "INC L";
		           break;
		    case 0x2D :
		           instr = "DEC L";
		           break;
		    case 0x2E :
		           instr = "LD L, " + Gameboy.hexByte(b2);
		           instrLength = 2;
		           break;
		    case 0x2F :
		           instr = "CPL";
		           break;
		    case 0x30 :
		           instr = "JR NC, " + Gameboy.hexWord(address + 2 + offset);
		           instrLength = 2;
		           break;
		    case 0x31 :
		           instr = "LD SP, " + Gameboy.hexWord((b3 << 8) + b2);
		           instrLength = 3;
		           break;
		    case 0x32 :
		           instr = "LD (HL-), A";
		           break;
		    case 0x33 :
		           instr = "INC SP";
		           break;
		    case 0x34 :
		           instr = "INC (HL)";
		           break;
		    case 0x35 :
		           instr = "DEC (HL)";
		           break;
		    case 0x36 :
		           instr = "LD (HL), " + Gameboy.hexByte(b2);
		           instrLength = 2;
		           break;
		    case 0x37 :
		           instr = "SCF";     // Set carry flag? 
		           break;
		    case 0x38 :
		           instr = "JR C, " + Gameboy.hexWord(address + 2 + offset);
		           instrLength = 2;
		           break;
		    case 0x39 :
		           instr = "ADD HL, SP";
		           break;
		    case 0x3A :
		           instr = "LD A, (HL-)";
		           break;
		    case 0x3B :
		           instr = "DEC SP";
		           break;
		    case 0x3C :
		           instr = "INC A";
		           break;
		    case 0x3D :
		           instr = "DEC A";
		           break;
		    case 0x3E :
		           instr = "LD A, " + Gameboy.hexByte(Gameboy.unsign(b2));
		           instrLength = 2;
		           break;
		    case 0x3F :
		           instr = "CCF";   // Clear carry flag? 
		           break;
		
		    case 0x76 :
		           instr = "HALT";
		           break;
		
		    // 0x40 - 0x7F = LD Reg, Reg - see below
		    // 0x80 - 0xBF = ALU ops - see below
		
		    case 0xC0 :
		           instr = "RET NZ";
		           break;
		    case 0xC1 :
		           instr = "POP BC";
		           break;
		    case 0xC2 :
		           instr = "JP NZ, " + Gameboy.hexWord((b3 << 8) + b2);
		           instrLength = 3;
		           break;
		    case 0xC3 :
		           instr = "JP " + Gameboy.hexWord((b3 << 8) + b2);
		           instrLength = 3;
		           break;
		    case 0xC4 :
		           instr = "CALL NZ, " + Gameboy.hexWord((b3 << 8) + b2);
		           instrLength = 3;
		           break;
		    case 0xC5 :
		           instr = "PUSH BC";
		           break;
		    case 0xC6 :
		           instr = "ADD A, " + Gameboy.hexByte(b2);
		           instrLength = 2;
		           break;
		    case 0xC7 :
		           instr = "RST 00";      // Is this an interrupt call?
		           break;
		    case 0xC8 :
		           instr = "RET Z";
		           break;
		    case 0xC9 :
		           instr = "RET";
		           break;
		    case 0xCA :
		           instr = "JP Z, " + Gameboy.hexWord((b3 << 8) + b2);
		           instrLength = 3;
		           break;
		
		    // 0xCB = Shifts (see below)
		
		    case 0xCC :
		           instr = "CALL Z, " + Gameboy.hexWord((b3 << 8) + b2);
		           instrLength = 3;
		           break;
		    case 0xCD :
		           instr = "CALL " + Gameboy.hexWord((b3 << 8) + b2);
		           instrLength = 3;
		           break;
		    case 0xCE :
		           instr = "ADC A, " + Gameboy.hexByte(b2);  // Signed or unsigned?
		           instrLength = 2;
		           break;
		    case 0xCF :
		           instr = "RST 08";      // Is this an interrupt call?
		           break;
		    case 0xD0 :
		           instr = "RET NC";
		           break;
		    case 0xD1 :
		           instr = "POP DE";
		           break;
		    case 0xD2 :
		           instr = "JP NC, " + Gameboy.hexWord((b3 << 8) + b2);
		           instrLength = 3;
		           break;
		
		    // 0xD3: Unknown
		
		    case 0xD4 :
		           instr = "CALL NC, " + Gameboy.hexWord((b3 << 8) + b2);
		           instrLength = 3;
		           break;
		    case 0xD5 :
		           instr = "PUSH DE";
		           break;
		    case 0xD6 :
		           instr = "SUB A, " + Gameboy.hexByte(b2);
		           instrLength = 2;
		           break;
		    case 0xD7 :
		           instr = "RST 10";
		           break;
		    case 0xD8 :
		           instr = "RET C";
		           break;
		    case 0xD9 :
		           instr = "RETI";
		           break;
		    case 0xDA :
		           instr = "JP C, " + Gameboy.hexWord((b3 << 8) + b2);
		           instrLength = 3;
		           break;
		
		    // 0xDB: Unknown
		
		    case 0xDC :
		           instr = "CALL C, " + Gameboy.hexWord((b3 << 8) + b2);
		           instrLength = 3;
		           break;
		
		    // 0xDD: Unknown
		
		    case 0xDE :
		           instr = "SBC A, " + Gameboy.hexByte(b2);
		           instrLength = 2;
		           break;
		    case 0xDF :
		           instr = "RST 18";
		           break;
		    case 0xE0 :
		           instr = "LDH (FF" + Gameboy.hexByte(b2 & 0xFF) + "), A";
		           instrLength = 2;
		           break;
		    case 0xE1 :
		           instr = "POP HL";
		           break;
		    case 0xE2 :
		           instr = "LDH (FF00 + C), A";
		           break;
		
		    // 0xE3 - 0xE4: Unknown
		
		    case 0xE5 :
		           instr = "PUSH HL";
		           break;
		    case 0xE6 :
		           instr = "AND " + Gameboy.hexByte(b2);
		           instrLength = 2;
		           break;
		    case 0xE7 :
		           instr = "RST 20";
		           break;
		    case 0xE8 :
		           instr = "ADD SP, " + Gameboy.hexByte(offset);
		           instrLength = 2;
		           break;
		    case 0xE9 :
		           instr = "JP (HL)";
		           break;
		    case 0xEA :
		           instr = "LD (" + Gameboy.hexWord((b3 << 8) + b2) + "), A";
		           instrLength = 3;
		           break;
		
		    // 0xEB - 0xED: Unknown
		
		    case 0xEE :
		           instr = "XOR " + Gameboy.hexByte(b2);
		           instrLength = 2;
		           break;
		    case 0xEF :
		           instr = "RST 28";
		           break;
		    case 0xF0 :
		           instr = "LDH A, (FF" + Gameboy.hexByte(b2) + ")";
		           instrLength = 2;
		           break;
		    case 0xF1 :
		           instr = "POP AF";
		           break;
		    case 0xF2 :
		           instr = "LD A, (FF00 + C)";              // What's this for?
		           break;
		    case 0xF3 :
		           instr = "DI";
		           break;
		
		    // 0xF4: Unknown
		
		    case 0xF5 :
		           instr = "PUSH AF";
		           break;
		    case 0xF6 :
		           instr = "OR " + Gameboy.hexByte(b2);
		           instrLength = 2;
		           break;
		    case 0xF7 :
		           instr = "RST 30";
		           break;
		    case 0xF8 :
		           instr = "LD HL, SP + " + Gameboy.hexByte(offset);  // Check this one, docs disagree
		           instrLength = 2;
		           break;
		    case 0xF9 :
		           instr = "LD SP, HL";
		           break;
		    case 0xFA :
		           instr = "LD A, (" + Gameboy.hexWord((b3 << 8) + b2) + ")";
		           instrLength = 3;
		           break;
		    case 0xFB :
		           instr = "EI";
		           break;
		
		    // 0xFC - 0xFD: Unknown
		
		    case 0xFE :
		           instr = "CP " + Gameboy.hexByte(b2);
		           instrLength = 2;
		           break;
		    case 0xFF :
		           instr = "RST 38";
		           break;
		   }
		
		 // The following section handles LD Reg, Reg instructions
		 // Bit 7 6 5 4 3 2 1 0    D = Dest register
		 //     0 1 D D D S S S    S = Source register
		 // The exception to this rule is 0x76, which is HALT, and takes
		 // the place of LD (HL), (HL)
		var sourceRegister:int;
		var destRegister:int;
		var operation:int;
		   if ((Gameboy.unsign(b1) >= 0x40) && (Gameboy.unsign(b1) <= 0x7F) && (
		       (Gameboy.unsign(b1) != 0x76))) {
		    /* 0x76 is HALT, and takes the place of LD (HL), (HL) */
		    sourceRegister = b1 & 0x07;         /* Lower 3 bits */
		    destRegister = (b1 & 0x38) >> 3;    /* Bits 5 - 3 */
		
		//    trace("LD Op src" + sourceRegister + " dest " + destRegister);
		
		    instr = "LD " + registerNames[destRegister] + ", " +
		                    registerNames[sourceRegister];
		   }
		   
		 // The following section handles arithmetic instructions
		 // Bit 7 6 5 4 3 2 1 0    Operation       Opcode
		 //     1 0 0 0 0 R R R    Add             ADD
		 //     1 0 0 0 1 R R R    Add with carry  ADC
		 //     1 0 0 1 0 R R R    Subtract        SUB
		 //     1 0 0 1 1 R R R    Sub with carry  SBC
		 //     1 0 1 0 0 R R R    Logical and     AND
		 //     1 0 1 0 1 R R R    Logical xor     XOR
		 //     1 0 1 1 0 R R R    Logical or      OR
		 //     1 0 1 1 1 R R R    Compare?        CP
		
		   if ((Gameboy.unsign(b1) >= 0x80) && (Gameboy.unsign(b1) <= 0xBF)) {
		    sourceRegister = Gameboy.unsign(b1) & 0x07;
		    operation = (Gameboy.unsign(b1) & 0x38) >> 3;
		
		 //   trace("ALU Op " + operation + " reg " + sourceRegister);
		
		    instr = aluOperations[operation] + " A, " + registerNames[sourceRegister];
		   }
		
		 // The following section handles shift instructions
		 // These are formed by the byte 0xCB followed by the this:
		 // Bit 7 6 5 4 3 2 1 0    Operation             Opcode
		 //     0 0 0 0 0 R R R    Rotate Left Carry     RLC
		 //     0 0 0 0 1 R R R    Rotate Right Carry    RRC
		 //     0 0 0 1 0 R R R    Rotate Left           RL
		 //     0 0 0 1 1 R R R    Rotate Right          RR
		 //     0 0 1 0 0 R R R    Arith. Shift Left     SLA
		 //     0 0 1 0 1 R R R    Arith. Shift Right    SRA
		 //     0 0 1 1 0 R R R    Hi/Lo Nibble Swap     SWAP
		 //     0 0 1 1 1 R R R    Shift Right Logical   SRL
		 //     0 1 N N N R R R    Bit Test n            BIT
		 //     1 0 N N N R R R    Reset Bit n           RES
		 //     1 1 N N N R R R    Set Bit n             SET
		
		   if (Gameboy.unsign(b1) == 0xCB) {
		    var bitNumber:int;
		
		    instrLength = 2;
		
		    switch ((Gameboy.unsign(b2) & 0xC0) >> 6) {
		     case 0 :
		      operation = (Gameboy.unsign(b2) & 0x38) >> 3;
		      sourceRegister = Gameboy.unsign(b2) & 0x07;
		      instr = shiftOperations[operation] + " " + registerNames[sourceRegister];
		      break;
		     case 1 :
		      bitNumber = (Gameboy.unsign(b2) & 0x38) >> 3;
		      sourceRegister = Gameboy.unsign(b2) & 0x07;
		      instr = "BIT " + bitNumber + ", " + registerNames[sourceRegister];
		      break;
		     case 2 :
		      bitNumber = (Gameboy.unsign(b2) & 0x38) >> 3;
		      sourceRegister = Gameboy.unsign(b2) & 0x07;
		      instr = "RES " + bitNumber + ", " + registerNames[sourceRegister];
		      break;
		     case 3 :
		      bitNumber = (Gameboy.unsign(b2) & 0x38) >> 3;
		      sourceRegister = Gameboy.unsign(b2) & 0x07;
		      instr = "SET " + bitNumber + ", " + registerNames[sourceRegister];
		      break;
		    }
		   }
		
		
		   trace(Gameboy.hexWord(address) + ": " + Gameboy.hexByte(Gameboy.unsign(b1)));
		
		   if (instrLength >= 2) {
		    trace(" " + Gameboy.hexByte(Gameboy.unsign(b2)));
		   } else {
		    trace("   ");
		   }
		
		   if (instrLength == 3) {
		    trace(" " + Gameboy.hexByte(Gameboy.unsign(b3))+ "  ");
		   } else {
		    trace("     ");
		   }


   trace(instr);
   address += instrLength;
  }


  return null;
 }




	}
}