package com.mobswing.gb.view
{
	import __AS3__.vec.Vector;
	
	import com.mobswing.gb.model.Cartridge;
	import com.mobswing.gb.model.Dmgcpu;
	import com.mobswing.gb.model.GameLink;
	import com.mobswing.gb.model.GraphicsChip;
	import com.mobswing.gb.model.Parameters;
	import com.mobswing.gb.model.Thread;
	
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
	public class Javaboy extends Sprite
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
		 private var dmgcpu:Dmgcpu;
		 private var thread:Thread;
		
		 /** When emulation running, references the current graphics chip implementation */
		 private var graphicsChip:GraphicsChip;
		
		 /** When connected to another computer or to a Game Boy printer, references the current Game link object */
		 private var gameLink:GameLink;
		
		 /** Stores the byte which was overwritten at the breakpoint address by the breakpoint instruction */
		 private var breakpointInstr:int;	//short
		
		 /** When set, stores the RAM address of a breakpoint. */
		 private var breakpointAddr:int = -1;	//short
		
		 private var breakpointBank:int;	//short
		
		 /** When running as an application, contains a reference to the interface frame object */
		 private var mainWindow:GameBoyScreen;
		
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
		  if (dmgcpu != null) {
		   var stripLength:int = 300;
		
		   // Centre the GB image
		   var x:int = width / 2 - dmgcpu.graphicsChip.getWidth() / 2;
		   var y:int = height / 2 - dmgcpu.graphicsChip.getHeight() / 2;
		
		   if ((stripTimer > stripLength) && (!fullFrame) && (!imageSizeChanged)) {
		   /* if ((imageSizeChanged) || (fullFrame)) {
			 if (dmgcpu.graphicsChip.isFrameReady()) {
			  g.setColor(new Color((int) (Math.random() * 255), (int) (Math.random() * 255), (int) (Math.random() * 255)));
		 	  g.fillRect(0, 0, getSize().width, getSize().height);
		 	  imageSizeChanged = false;
		   	  if (fullFrame) {
			   System.out.println("fullframe is " + fullFrame + " at "+ System.currentTimeMillis());
			  }
		
			 }
			}*/
			
		    dmgcpu.graphicsChip.draw(this.frameBuffer, x, y, this);
			
		   } else {
		    if (dmgcpu.graphicsChip.isFrameReady()) {
	
			 this.doubleBuffer.lock();
			 this.doubleBuffer.fillRect(new Rectangle(0,0, width, height),0xFFFFFF);
			 this.doubleBuffer.unlock();
		     dmgcpu.graphicsChip.draw(this.doubleBuffer, x, y, this);
		
		
			 var stripPos:int = height - 40;
			 if (stripTimer < 10) {
		      stripPos = height - (stripTimer * 4);
			 }
			 if (stripTimer >= stripLength - 10) {
		      stripPos = height - 40 + ((stripTimer - (stripLength - 10)) * 4);
			 }
		
		     this.doubleBuffer.fillRect(new Rectangle(0, stripPos, width, 44), 0x0000FF);
		     this.doubleBuffer.fillRect(new Rectangle(0, stripPos, width, 2), 0x8080FF);
		 
		     if (stripTimer < stripLength) {
				if (stripTimer < stripLength / 2) {
					 /* bufferGraphics.setColor(new Color(255, 255, 255));
					 bufferGraphics.drawString("JavaBoy - Neil Millstone", 2, stripPos + 12);
					 bufferGraphics.setColor(new Color(255, 255, 255));
					 bufferGraphics.drawString("www.millstone.demon.co.uk", 2, stripPos + 24);
					 bufferGraphics.drawString("/download/javaboy", 2, stripPos + 36); */
				 } else {
					 /* bufferGraphics.setColor(new Color(255, 255, 255));
					 bufferGraphics.drawString("ROM: " + cartridge.getCartName(), 2, stripPos + 12);
					 bufferGraphics.drawString("Double click for options", 2, stripPos + 24);
					 bufferGraphics.drawString("Emulator version: " + versionString, 2, stripPos + 36); */
				 }
			}
		
		     stripTimer++;
		     this.frameBuffer.lock();
		 	 this.frameBuffer.draw(this.doubleBuffer);
		 	 this.frameBuffer.unlock();
			} else {
		     dmgcpu.graphicsChip.draw(this.doubleBuffer, x, y, this);
		    }
		
		   } 
		  } else {
		  	this.frameBuffer.lock();
		  	this.frameBuffer.fillRect(new Rectangle(0,0,160, 144), 0xFFFFFF);
		  	drawString(this.frameBuffer, "JavaBoy (tm)", 0, 10, 10);
		  	drawString(this.frameBuffer, "Version " + versionString, 0, 10, 20);
		  	drawString(this.frameBuffer, "Charging flux capacitor...", 0, 10, 40);
		  	drawString(this.frameBuffer, "Loading game ROM...", 0, 10, 50);
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
		 	dmgcpu.graphicsChip.frameSkip = num;
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
		 	dmgcpu.reset();
		 }
		 
		 public function setSoundEnable(on:Boolean):void {
		  if (dmgcpu.soundChip != null) {
		   dmgcpu.soundChip.channel1Enable = on;
		   dmgcpu.soundChip.channel2Enable = on;
		   dmgcpu.soundChip.channel3Enable = on;
		   dmgcpu.soundChip.channel4Enable = on;
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
		  //System.out.println("fullframe true");
		 }
		 
		 public function drawNextFrame():void {
		  //System.out.println("fullframe false");
		  fullFrame = false;
		  paint();
		 }

		 public function keyPressed(e:KeyboardEvent):void {
		  var key:int = e.keyCode;
		
		  if (key == keyCodes[0]) {
		   if (!dmgcpu.ioHandler.padUp) {
		    dmgcpu.ioHandler.padUp = true;
		    dmgcpu.triggerInterruptIfEnabled(dmgcpu.INT_P10);
		   }
		  } else if (key == keyCodes[1]) {
		   if (!dmgcpu.ioHandler.padDown) {
		    dmgcpu.ioHandler.padDown = true;
		    dmgcpu.triggerInterruptIfEnabled(dmgcpu.INT_P10);
		   }
		  } else if (key == keyCodes[2]) {
		   if (!dmgcpu.ioHandler.padLeft) {
		    dmgcpu.ioHandler.padLeft = true;
		    dmgcpu.triggerInterruptIfEnabled(dmgcpu.INT_P10);
		   }
		  } else if (key == keyCodes[3]) {
		   if (!dmgcpu.ioHandler.padRight) {
		    dmgcpu.ioHandler.padRight = true;
		    dmgcpu.triggerInterruptIfEnabled(dmgcpu.INT_P10);
		   }
		  } else if (key == keyCodes[4]) {
		   if (!dmgcpu.ioHandler.padA) {
		    dmgcpu.ioHandler.padA = true;
		    dmgcpu.triggerInterruptIfEnabled(dmgcpu.INT_P10);
		   }
		  } else if (key == keyCodes[5]) {
		   if (!dmgcpu.ioHandler.padB) {
		    dmgcpu.ioHandler.padB = true;
		    dmgcpu.triggerInterruptIfEnabled(dmgcpu.INT_P10);
		   }
		  } else if (key == keyCodes[6]) {
		   if (!dmgcpu.ioHandler.padStart) {
		    dmgcpu.ioHandler.padStart = true;
		    dmgcpu.triggerInterruptIfEnabled(dmgcpu.INT_P10);
		   }
		  } else if (key == keyCodes[7]) {
		   if (!dmgcpu.ioHandler.padSelect) {
		    dmgcpu.ioHandler.padSelect = true;
		    dmgcpu.triggerInterruptIfEnabled(dmgcpu.INT_P10);
		   }
		  }
		
		  switch (key) {
		   case Keyboard.F1:
		     if (dmgcpu.graphicsChip.frameSkip != 1)
		     	dmgcpu.graphicsChip.frameSkip--;
			 if (runningAsApplet)
				trace("Frameskip now " + dmgcpu.graphicsChip.frameSkip);
			 break;
		   case Keyboard.F2:
		   	 if (dmgcpu.graphicsChip.frameSkip != 10)
			 	 dmgcpu.graphicsChip.frameSkip++;
			 if (runningAsApplet)
				 trace("Frameskip now " + dmgcpu.graphicsChip.frameSkip);
			 break;
		   case Keyboard.F5:
		   	 dmgcpu.terminateProcess();
			 activateDebugger();
			 trace("- Break into debugger");
			 break;
		  }
		 }
		
		 public function keyReleased(e:KeyboardEvent):void {
		  var key:int = e.keyCode;
		
		  if (key == keyCodes[0]) {
		   dmgcpu.ioHandler.padUp = false;
		   dmgcpu.triggerInterruptIfEnabled(dmgcpu.INT_P10);
		  } else if (key == keyCodes[1]) {
		   dmgcpu.ioHandler.padDown = false;
		   dmgcpu.triggerInterruptIfEnabled(dmgcpu.INT_P10);
		  } else if (key == keyCodes[2]) {
		   dmgcpu.ioHandler.padLeft = false;
		   dmgcpu.triggerInterruptIfEnabled(dmgcpu.INT_P10);
		  } else if (key == keyCodes[3]) {
		   dmgcpu.ioHandler.padRight = false;
		   dmgcpu.triggerInterruptIfEnabled(dmgcpu.INT_P10);
		  } else if (key == keyCodes[4]) {
		   dmgcpu.ioHandler.padA = false;
		   dmgcpu.triggerInterruptIfEnabled(dmgcpu.INT_P10);
		  } else if (key == keyCodes[5]) {
		   dmgcpu.ioHandler.padB = false;
		   dmgcpu.triggerInterruptIfEnabled(dmgcpu.INT_P10);
		  } else if (key == keyCodes[6]) {
		   dmgcpu.ioHandler.padStart = false;
		   dmgcpu.triggerInterruptIfEnabled(dmgcpu.INT_P10);
		  } else if (key == keyCodes[7]) {
		   dmgcpu.ioHandler.padSelect = false;
		   dmgcpu.triggerInterruptIfEnabled(dmgcpu.INT_P10);
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

		public function Javaboy()
		{
			super();
			
			// init Frame Buffer
			this.frameBuffer = new BitmapData(160, 144, false, 0x000000);
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
		  dmgcpu = new Dmgcpu(cartridge, null, this);
		  dmgcpu.graphicsChip.setMagnify(width / 160);
		
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
				dmgcpu.reset();
				this.thread = new Thread(this.stage, dmgcpu.execute, null, 'dmgcpu');
				//dmgcpu.execute(-1);
			}
		}
		
		 /** Free up allocated memory */
		 public function dispose():void {
		  if (cartridge != null) cartridge.dispose();
		  if (dmgcpu != null) dmgcpu.dispose();
		 }
		
		 public function init():void {
		  doubleBuffer = new BitmapData(width, height, false, 0x000000);
		 }
		
		 public function stop():void {
		  trace("Applet stopped");
		  appletRunning = false;
		  if (dmgcpu != null) dmgcpu.terminate = true;
		 }
	}
}