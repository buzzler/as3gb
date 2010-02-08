package com.mobswing.gb.model
{
	import __AS3__.vec.Vector;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.utils.getTimer;
	
	/** This class is the master class for implementations 
	  *  of the graphics class.  A graphics implementation will subclass from this class.
	  *  It contains methods for calculating the frame rate. */

	public class GraphicsChip
	{
		 /** Tile uses the background palette */ 
		 public static var TILE_BKG:int = 0;
		
		 /** Tile uses the first sprite palette */ 
		 public static var TILE_OBJ1:int = 4;
		
		 /** Tile uses the second sprite palette */
		 public static var TILE_OBJ2:int = 8;
		
		 /** Tile is flipped horizontally */
		 public static var TILE_FLIPX:int = 1; 
		
		 /** Tile is flipped vertically */ 
		 public static var TILE_FLIPY:int = 2;
		
		 /** The current contents of the video memory, mapped in at 0x8000 - 0x9FFF */ 
		 protected var videoRam:ByteArrayAdvanced = new ByteArrayAdvanced(0x8000);	//byte[] 
		
		 /** The background palette */ 
		 public var backgroundPalette:GameboyPalette; 
		
		 /** The first sprite palette */ 
		 public var obj1Palette:GameboyPalette; 
		
		 /** The second sprite palette */ 
		 public var obj2Palette:GameboyPalette;
		 public var gbcBackground:Vector.<GameboyPalette> = new Vector.<GameboyPalette>(8);	//GameboyPalette[8]
		 public var gbcSprite:Vector.<GameboyPalette> = new Vector.<GameboyPalette>(8);	//GameboyPalette[8]
		
		 public var spritesEnabled:Boolean = true;
		
		 public var bgEnabled:Boolean = true;
		 public var winEnabled:Boolean = true;
		
		 /** The image containing the Gameboy screen */ 
		 protected var backBuffer:BitmapData;	//Image 
		 
		 /** The current frame skip value */
		 public var frameSkip:int = 2;
		 
		 /** The number of frames that have been drawn so far in the current frame sampling period */
		 protected var framesDrawn:int = 0;
		 
		 /** Image magnification */
		 protected var mag:int = 2; 
		 private var width:int = 160 * mag; 
		 private var height:int = 144 * mag; 
		 
		 /** Amount of time to wait between frames (ms) */ 
		 public var frameWaitTime:int = 0; 
		 
		 /** The current frame has finished drawing */ 
		 public var frameDone:Boolean = false; 
		 private var averageFPS:int = 0; 
		 public	var startTime:Number = 0;	//long 
		 
		 /** Selection of one of two addresses for the BG and Window tile data areas */ 
		 public var bgWindowDataSelect:Boolean = true; 
		 
		 /** If true, 8x16 sprites are being used.  Otherwise, 8x8. */ 
		 public var doubledSprites:Boolean = false; 
		 
		 /** Selection of one of two address for the BG tile map. */
		 public var hiBgTileMapAddress:Boolean= false; 
		 public var dmgcpu:Dmgcpu; 
		 private var applet:DisplayObject;
		 public var tileStart:int = 0;
		 public var vidRamStart:int = 0;


		public function GraphicsChip(a:DisplayObject, d:Dmgcpu)
		{
		  dmgcpu = d;
		  
		  backgroundPalette = new GameboyPalette(0, 1, 2, 3);
		  obj1Palette = new GameboyPalette(0, 1, 2, 3);
		  obj2Palette = new GameboyPalette(0, 1, 2, 3);
		
		  for (var r:int = 0; r < 8; r++) {
		   gbcBackground[r] = new GameboyPalette(0, 1, 2, 3);
		   gbcSprite[r] = new GameboyPalette(0, 1, 2, 3);
		  }
		
		  backBuffer = new BitmapData(160 * mag, 144 * mag, false, 0);
		  applet = a;
		 } /** Set the magnification for the screen */ 
		 
		 public function setMagnify(m:int):void {
		  mag = m;
		  width = m * 160;
		  height = m * 144;
		  if (backBuffer != null) backBuffer.dispose();
		  backBuffer = new BitmapData(160 * mag, 144 * mag, false, 0);
		}

		 /** Clear up any allocated memory */ 
		 public function dispose():void {  
		  backBuffer.dispose();
		 } 
		 
		 /** Calculate the number of frames per second for the current sampling period */ 
		 public function calculateFPS():void {  
		  if (startTime == 0) {   
		   startTime = new Date().time;
		  }  if (framesDrawn > 30) {   
		   var delay:Number = getTimer();
		   averageFPS = (framesDrawn) / (delay / 1000);
		   startTime = startTime + delay;
		   var timePerFrame:int;
		
		   if (averageFPS != 0) {
		    timePerFrame = 1000 / averageFPS;
		   } else {
		    timePerFrame = 100;
		   }
		   frameWaitTime = 17 - timePerFrame + frameWaitTime;
		   framesDrawn = 0;
		  }
		 } 
		 
		 /** Return the number of frames per second achieved in the previous sampling period. */ 
		 public function getFPS():int {  
		  return averageFPS;
		 } 
		
		 public function getWidth():int {
		  return width;
		 }
		
		 public function getHeight():int {
		  return height;
		 }
		 
		 public function addressRead(addr:int):int {
		 	return 0;
		 }
		 public function addressWrite(addr:int, data:int):void {	//@param data:byte
		 	return;
		 } 
		 public function invalidateAllByAttribs(attribs:int):void {
		 	return;
		 }
		 public function invalidateAll():void {
		 	return;
		 } 
		 public function draw(g:BitmapData, startX:int, startY:int, a:DisplayObject):Boolean {
		 	return false; 
		 }
		 public function notifyScanline(line:int):void {
		 	return;
		 }
		 public	function isFrameReady():Boolean {
		 	return false;
		 }

	}
}