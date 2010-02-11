package com.mobswing.gb.view
{
	import __AS3__.vec.Vector;
	
	import com.mobswing.gb.control.CPU;
	import com.mobswing.gb.control.Cartridge;
	import com.mobswing.gb.model.Parameters;
	import com.mobswing.gb.model.Thread;
	import com.mobswing.gb.graphic.PPU;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	
	/** This is the main controlling class which contains the main() method
	 *  to run JavaBoy as an application, and also the necessary applet methods.
	 *  It also implements a full command based debugger using the console.
	 */
	public class Gameboy extends Sprite
	{
		 private static var WIDTH		:int = 160;
		 private static var HEIGHT		:int = 144;
		 private static var WEBSITE_URL	:String = "http://www.millstone.demon.co.uk/download/javaboy";
		 private static var hexChars	:String = "0123456789ABCDEF";

		 /** The version string is displayed on the title bar of the application */
		 private static var versionString	:String = "0.92";
		 public static var runningAsApplet	:Boolean;

		 private var appletRunning			:Boolean = true;
		 private var backBuffer				:BitmapData;	//Image
		 private var gameRunning			:Boolean;
		 private var fullFrame				:Boolean = true;
		
		 private var saveToWebEnable		:Boolean = false;
		
		 public static var schemeNames:Vector.<String> = Vector.<String>(["Standard colours", "LCD shades", "Midnight garden", "Psychadelic"]);
		
		 /** This array contains the actual data for the colour schemes.
		  *  These are only using in DMG mode.
		  *  The first four values control the BG palette, the second four
		  *  are the OBJ0 palette, and the third set of four are OBJ1.
		  */
 		 public static var schemeColours:Vector.<Vector.<int>> = Vector.<Vector.<int>>([
		    Vector.<int>([
			 0xFFFFFFFF, 0xFFAAAAAA, 0xFF555555, 0xFF000000,
			 0xFFFFFFFF, 0xFFAAAAAA, 0xFF555555, 0xFF000000,
			 0xFFFFFFFF, 0xFFAAAAAA, 0xFF555555, 0xFF000000
			]),

			Vector.<int>([
		     0xFFFFFFC0, 0xFFC2C41E, 0xFF949600, 0xFF656600,
		     0xFFFFFFC0, 0xFFC2C41E, 0xFF949600, 0xFF656600,
		     0xFFFFFFC0, 0xFFC2C41E, 0xFF949600, 0xFF656600
			]),
		    
		    Vector.<int>([
		     0xFFC0C0FF, 0xFF4040FF, 0xFF0000FF, 0xFF000080,
		     0xFFC0FFC0, 0xFF00C000, 0xFF008000, 0xFF004000,
		     0xFFC0FFC0, 0xFF00C000, 0xFF008000, 0xFF004000
			]),

			Vector.<int>([
		     0xFFFFC0FF, 0xFF8080FF, 0xFFC000C0, 0xFF800080,
		     0xFFFFFF40, 0xFFC0C000, 0xFFFF4040, 0xFF800000,
		     0xFF80FFFF, 0xFF00C0C0, 0xFF008080, 0xFF004000
			])
		]); 
		
		 /** When emulation running, references the currently loaded cartridge */
		 private var cartridge:Cartridge;
		
		 /** When emulation running, references the current CPU object */
		 private var cpu:CPU;
		 private var thread:Thread;
		
		 /** When emulation running, references the current graphics chip implementation */
		 private var ppu:PPU;
		
		 /** Stores the byte which was overwritten at the breakpoint address by the breakpoint instruction */
		 private var breakpointInstr:int;	//short
		
		 /** When set, stores the RAM address of a breakpoint. */
		 private var breakpointAddr:int = -1;	//short
		
		 private var breakpointBank:int;	//short
		
		 /** Stores commands queued to be executed by the debugger */
		 private var debuggerQueue:String = null;
		
		 /** True when the commands in debuggerQueue have yet to be executed */
		 private var debuggerPending:Boolean = false;
		
		 /** True when the debugger console interface is active */
		 private var debuggerActive:Boolean = false;
		
		 private var doubleBuffer:BitmapData;	//Image
		 private var frameBuffer:BitmapData;
		 private var frameTextField:TextField;
		
		// up down left right A B start select
		 private static var keyCodes:Vector.<int> = Vector.<int>([Keyboard.UP, Keyboard.DOWN, Keyboard.LEFT, Keyboard.RIGHT, Keyboard.CONTROL, Keyboard.SHIFT, Keyboard.ENTER, Keyboard.BACKSPACE]);
		
		 private var keyListener:Boolean = false;
		
		 /** True if the image size changed last frame, and we need to repaint the background */
		 private var imageSizeChanged:Boolean = false;
		
		 private var stripTimer:int = 0;
		
		 private var lastClickTime:Number = 0;	//long

		 /** Outputs a line of debugging information */
		 static public function debugLog(s:String):void {
		  trace("Debug: " + s);
		 }
		
		 /** Returns the unsigned value (0 - 255) of a signed byte */
		 static public function unsign(b:int):int {	//@return:short, @param b:byte
		  if (b < 0) {
		   return 256 + b;
		  } else {
		   return b;
		  }
		 }
		
		 /** Returns a string representation of an 8-bit number in hexadecimal */
		 static public function hexByte(b:int):String {
		  var s:String = String.fromCharCode(b >> 4);
		  
		     s = s + String.fromCharCode(b & 0x0F);
		
		  return s;
		 }
		
		 /** Returns a string representation of an 16-bit number in hexadecimal */
		 static public function hexWord(w:int):String {
		  return hexByte((w & 0x0000FF00) >>  8) + hexByte(w & 0x000000FF);
		 }

		 /** When running as an applet, updates the screen when necessary */
		 public function paint():void {
		  if (cpu != null) {
			cpu.ppu.draw(this.frameBuffer, x, y, this);
		  } else {
		  	this.frameBuffer.lock();
		  	this.frameBuffer.fillRect(new Rectangle(0,0,160, 144), 0xFFFFFF);
		  	drawString(this.frameBuffer, "JavaBoy (tm)", 0xFF000000, 10, 10);
		  	drawString(this.frameBuffer, "Version " + versionString, 0xFF0000, 10, 20);
		  	drawString(this.frameBuffer, "Charging flux capacitor...", 0xFF000000, 10, 40);
		  	drawString(this.frameBuffer, "Loading game ROM...", 0XFF000000, 10, 50);
		  	this.frameBuffer.unlock();
		  }
		 }
		 
		 private function drawString(bmp:BitmapData, text:String, color:uint, x:int, y:int):void
		 {
		 	this.frameTextField.text = text;
		 	this.frameTextField.setTextFormat(new TextFormat(null, 10, color));
		 	bmp.draw(this.frameTextField, new Matrix(1,0,0,1,x,y));
		 }
		 
		 public	function frameSkip(num:int):void
		 {
		 	cpu.ppu.frameSkip = num;
		 }
		 
		 public	function save():void
		 {
		 	//SAVE
		 }
		 
		 public	function load():void
		 {
		 	//LOAD
		 }
		 
		 public	function reset():void
		 {
		 	cpu.reset();
		 }
		 
		 public function setSoundEnable(on:Boolean):void {
		  if (cpu.apu != null) {
		   cpu.apu.channel1Enable = on;
		   cpu.apu.channel2Enable = on;
		   cpu.apu.channel3Enable = on;
		   cpu.apu.channel4Enable = on;
		  }
		 }
		
		 /** Activate the console debugger interface */
		 public function activateDebugger():void {
		  debuggerActive = true;
		 }
		
		 /** Deactivate the console debugger interface */
		 public function deactivateDebugger():void {
		  debuggerActive = false;
		 }
		
		 public function update():void {
		  paint();
		  fullFrame = true;
		  //trace("fullframe true");
		 }
		 
		 public function drawNextFrame():void {
		  //trace("fullframe false");
		  fullFrame = false;
		  paint();
		 }

		 public function keyPressed(e:KeyboardEvent):void {
		  var key:int = e.keyCode;
		
		  if (key == keyCodes[0]) {
		   if (!cpu.ioHandler.padUp) {
		    cpu.ioHandler.padUp = true;
		    cpu.triggerInterruptIfEnabled(cpu.INT_P10);
		   }
		  } else if (key == keyCodes[1]) {
		   if (!cpu.ioHandler.padDown) {
		    cpu.ioHandler.padDown = true;
		    cpu.triggerInterruptIfEnabled(cpu.INT_P10);
		   }
		  } else if (key == keyCodes[2]) {
		   if (!cpu.ioHandler.padLeft) {
		    cpu.ioHandler.padLeft = true;
		    cpu.triggerInterruptIfEnabled(cpu.INT_P10);
		   }
		  } else if (key == keyCodes[3]) {
		   if (!cpu.ioHandler.padRight) {
		    cpu.ioHandler.padRight = true;
		    cpu.triggerInterruptIfEnabled(cpu.INT_P10);
		   }
		  } else if (key == keyCodes[4]) {
		   if (!cpu.ioHandler.padA) {
		    cpu.ioHandler.padA = true;
		    cpu.triggerInterruptIfEnabled(cpu.INT_P10);
		   }
		  } else if (key == keyCodes[5]) {
		   if (!cpu.ioHandler.padB) {
		    cpu.ioHandler.padB = true;
		    cpu.triggerInterruptIfEnabled(cpu.INT_P10);
		   }
		  } else if (key == keyCodes[6]) {
		   if (!cpu.ioHandler.padStart) {
		    cpu.ioHandler.padStart = true;
		    cpu.triggerInterruptIfEnabled(cpu.INT_P10);
		   }
		  } else if (key == keyCodes[7]) {
		   if (!cpu.ioHandler.padSelect) {
		    cpu.ioHandler.padSelect = true;
		    cpu.triggerInterruptIfEnabled(cpu.INT_P10);
		   }
		  }
		
		  switch (key) {
		   case Keyboard.F1:
		     if (cpu.ppu.frameSkip != 1)
		     	cpu.ppu.frameSkip--;
			 if (runningAsApplet)
				trace("Frameskip now " + cpu.ppu.frameSkip);
			 break;
		   case Keyboard.F2:
		   	 if (cpu.ppu.frameSkip != 10)
			 	 cpu.ppu.frameSkip++;
			 if (runningAsApplet)
				 trace("Frameskip now " + cpu.ppu.frameSkip);
			 break;
		   case Keyboard.F5:
		   	 cpu.terminateProcess();
			 activateDebugger();
			 trace("- Break into debugger");
			 break;
		  }
		 }
		
		 public function keyReleased(e:KeyboardEvent):void {
		  var key:int = e.keyCode;
		
		  if (key == keyCodes[0]) {
		   cpu.ioHandler.padUp = false;
		   cpu.triggerInterruptIfEnabled(cpu.INT_P10);
		  } else if (key == keyCodes[1]) {
		   cpu.ioHandler.padDown = false;
		   cpu.triggerInterruptIfEnabled(cpu.INT_P10);
		  } else if (key == keyCodes[2]) {
		   cpu.ioHandler.padLeft = false;
		   cpu.triggerInterruptIfEnabled(cpu.INT_P10);
		  } else if (key == keyCodes[3]) {
		   cpu.ioHandler.padRight = false;
		   cpu.triggerInterruptIfEnabled(cpu.INT_P10);
		  } else if (key == keyCodes[4]) {
		   cpu.ioHandler.padA = false;
		   cpu.triggerInterruptIfEnabled(cpu.INT_P10);
		  } else if (key == keyCodes[5]) {
		   cpu.ioHandler.padB = false;
		   cpu.triggerInterruptIfEnabled(cpu.INT_P10);
		  } else if (key == keyCodes[6]) {
		   cpu.ioHandler.padStart = false;
		   cpu.triggerInterruptIfEnabled(cpu.INT_P10);
		  } else if (key == keyCodes[7]) {
		   cpu.ioHandler.padSelect = false;
		   cpu.triggerInterruptIfEnabled(cpu.INT_P10);
		  }
		 }

		 public function setupKeyboard():void {
			if (!keyListener) {
				if (!runningAsApplet) {
					trace("Starting key controls");
					this.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
					this.stage.addEventListener(KeyboardEvent.KEY_UP, keyReleased);
				} else {
					this.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
					this.stage.addEventListener(KeyboardEvent.KEY_UP, keyReleased);
				}
				keyListener = true;
			}
		 }

		public function Gameboy()
		{
			super();
			
			// init Frame Buffer
			this.frameBuffer = new BitmapData(160, 144, true, 0x00FFFFFF);
			var bmp:Bitmap = new Bitmap(this.frameBuffer);
			this.addChild(bmp);
			
			// init Text
			this.frameTextField = new TextField();
			this.frameTextField.autoSize = TextFieldAutoSize.LEFT;
			this.frameTextField.setTextFormat(new TextFormat(null, 10, 0xFFFFFF));
			
			runningAsApplet = false;
			
			init();
		}
		
		 public function start(romfile:ByteArray, romimage:String = 'game.gb'):void {
		 	if (romfile)
		 		Parameters.ROMFILE = romfile;
		 	if (romimage)
		 		Parameters.ROMIMAGE = romimage;
		
		  runningAsApplet = true;
		  trace("JavaBoy (tm) Version " + versionString + " (c) 2005 Neil Millstone (applet)");
			
		
		  cartridge = new Cartridge(Parameters.ROMFILE, Parameters.ROMIMAGE, this);
		  cpu = new CPU(cartridge, this);
		
		  saveToWebEnable = Parameters.SAVERAMURL != null;
		  setSoundEnable(Parameters.SOUND);
		
		  cartridge.outputCartInfo();
		  
		  //Thread start
		  if (this.stage != null)
		  	onAdded(null);
		  else
		  	this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		 }
		 
		public	function onAdded(event:Event):void
		{
			if (runningAsApplet)
			{
				trace("Starting...");
				setupKeyboard();
				cpu.reset();
				this.thread = new Thread(this.stage, cpu.execute, null, 'cpu');
				//cpu.execute(-1);
			}
		}
		
		 /** Free up allocated memory */
		 public function dispose():void {
		  if (cartridge != null) cartridge.dispose();
		  if (cpu != null) cpu.dispose();
		 }
		
		 public function init():void {
		  doubleBuffer = new BitmapData(width, height, true, 0x00FFFFFF);
		 }
		
		 public function stop():void {
		  trace("Applet stopped");
		  appletRunning = false;
		  if (cpu != null) cpu.terminate = true;
		 }
	}
}