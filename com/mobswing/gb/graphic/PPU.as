package com.mobswing.gb.graphic
{
	import __AS3__.vec.Vector;
	
	import com.mobswing.gb.control.CPU;
	import com.mobswing.gb.model.ByteArrayAdvanced;
	import com.mobswing.gb.view.Gameboy;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	/** This class is one implementation of the GraphicsChip.
	 *  It performs the output of the graphics screen, including the background, window, and sprite layers.
	 *  It supports some raster effects, but only ones that happen on a tile row boundary.
	 */
	public class PPU
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
		 public var backgroundPalette:Palette; 
		
		 /** The first sprite palette */ 
		 public var obj1Palette:Palette; 
		
		 /** The second sprite palette */ 
		 public var obj2Palette:Palette;
		 public var gbcBackground:Vector.<Palette> = new Vector.<Palette>(8);	//GameboyPalette[8]
		 public var gbcSprite:Vector.<Palette> = new Vector.<Palette>(8);	//GameboyPalette[8]
		
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
		 private var width:int = 160; 
		 private var height:int = 144; 
		 
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
		 public var cpu:CPU; 
		 private var applet:DisplayObject;
		 public var tileStart:int = 0;
		 public var vidRamStart:int = 0;

		
		 /** Tile cache */
		 private var tiles:Vector.<Tile> = new Vector.<Tile>(384 * 2);
		
		 // Hacks to allow some raster effects to work.  Or at least not to break as badly.
		 private var savedWindowDataSelect:Boolean = false;
		 private var spritesEnabledThisFrame:Boolean = false;
		
		 private var windowEnableThisLine:Boolean = false;
		 private var windowStopLine:int = 144;
		 
		public function PPU(a:DisplayObject, d:CPU)
		{

		  cpu = d;
		  
		  backgroundPalette = new Palette(0, 1, 2, 3);
		  obj1Palette = new Palette(0, 1, 2, 3);
		  obj2Palette = new Palette(0, 1, 2, 3);
		
		  for (var r:int = 0; r < 8; r++) {
		   gbcBackground[r] = new Palette(0, 1, 2, 3);
		   gbcSprite[r] = new Palette(0, 1, 2, 3);
		  }
		
		  backBuffer = new BitmapData(160, 144, true, 0x00FFFFFF);
		  applet = a;

			for (r = 0; r < 384 * 2; r++) {
				tiles[r] = new Tile(a, cpu, this);
			}
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
		

		 /** Flush the tile cache */
		 public function dispose():void {
		  for (var r:int = 0; r < 384 * 2; r++) {
		   if (tiles[r] != null) tiles[r].dispose();
		  }
		 }
		
		 /** Reads data from the specified video RAM address */
		 public function addressRead(addr:int):int {	//@return short
		  return videoRam.read(addr + vidRamStart);
		 }
		
		 /** Writes data to the specified video RAM address */
		 public function addressWrite(addr:int, data:int):void {	//@param data:byte
		  if (addr < 0x1800) {   // Bkg Tile data area
		   tiles[(addr >> 4) + tileStart].invalidateAll();
		   videoRam.write(addr + vidRamStart, data);
		  } else {
		   videoRam.write(addr + vidRamStart, data);
		  }
		 }
		
		 /** Invalidates all tiles in the tile cache that have the given attributes.
		  *  These will be regenerated next time they are drawn.
		  */
		 public function invalidateAllByAttribs(attribs:int):void {
		  for (var r:int = 0; r < 384 * 2; r++) {
		   tiles[r].invalidate(attribs);
		  }
		 }
		
		 /** Invalidate all tiles in the tile cache */
		 public function invalidateAll():void {
		  for (var r:int = 0; r < 384 * 2; r++) {
		   tiles[r].invalidateAll();
		  }
		 }
		
		 /** Draw sprites into the back buffer which have the given priority */
		 public function drawSprites(back:BitmapData, priority:int):void {
		  
		  var tileBankStart:int = 0;
		  var vidRamAddress:int = 0;
		
		  // Draw sprites
		  for (var i:int = 0; i < 40; i++) {
		   var spriteX:int = cpu.addressRead(0xFE01 + (i * 4)) - 8;
		   var spriteY:int = cpu.addressRead(0xFE00 + (i * 4)) - 16;
		   var tileNum:int = cpu.addressRead(0xFE02 + (i * 4));
		   var attributes:int = cpu.addressRead(0xFE03 + (i * 4));
		
		   if ((attributes & 0x80) >> 7 == priority) {
		
		   var spriteAttrib:int = 0;
		
		   if (doubledSprites) {
		    tileNum &= 0xFE;
		   }
		
		   if (cpu.gbcFeatures) {
		    if ((attributes & 0x08) != 0) {
		     vidRamAddress = 0x2000 + (tileNum << 4);
		     tileNum += 384;
		     tileBankStart = 0x2000;
		    } else {
		     vidRamAddress = tileNum << 4;
		    }
		    spriteAttrib += ((attributes & 0x07) << 2) + 32;
		
		   } else {
		    vidRamAddress = tileNum << 4;
		    if ((attributes & 0x10) != 0) {
		     spriteAttrib |= TILE_OBJ2;
		    } else {
		     spriteAttrib |= TILE_OBJ1;
		    }
		   }
		
		   if ((attributes & 0x20) != 0) {
		    spriteAttrib |= TILE_FLIPX;
		   }
		   if ((attributes & 0x40) != 0) {
		    spriteAttrib |= TILE_FLIPY;
		   }
		
		   if (tiles[tileNum].invalid(spriteAttrib)) {
		    tiles[tileNum].validate(videoRam, vidRamAddress, spriteAttrib);
		   }
		
		   if ((spriteAttrib & TILE_FLIPY) != 0) {
		    if (doubledSprites) {
		     tiles[tileNum].draw(back, spriteX, spriteY + 8, spriteAttrib);
			} else {
		     tiles[tileNum].draw(back, spriteX, spriteY, spriteAttrib);
			}
		   } else {
		    tiles[tileNum].draw(back, spriteX, spriteY, spriteAttrib);
		   }
		
		//   back.drawString("" + tileNum, spriteX * 2, spriteY * 2);
		//   trace("Sprite " + i + ": " + spriteX + ", " + spriteY);
		
		   if (doubledSprites) {
		    if (tiles[tileNum + 1].invalid(spriteAttrib)) {
		     tiles[tileNum + 1].validate(videoRam, vidRamAddress + 16, spriteAttrib);
		    }
			
		
		    if ((spriteAttrib & TILE_FLIPY) != 0) {
		     tiles[tileNum + 1].draw(back, spriteX, spriteY, spriteAttrib);
		    } else {
		     tiles[tileNum + 1].draw(back, spriteX, spriteY + 8, spriteAttrib);
		    }
		   }
		   }
		  }
		
		 }
		
		 /** This must be called by the CPU for each scanline drawn by the display hardware.  It
		  *  handles drawing of the background layer
		  */
		 public function notifyScanline(line:int):void {
		
		  if ((framesDrawn % frameSkip) != 0) {
		   return;
		  }
		
		  if (line == 0) {
		   clearFrameBuffer();
		   /*if (spritesEnabledThisFrame)*/ drawSprites(backBuffer, 1);
		   spritesEnabledThisFrame = spritesEnabled;
		   windowStopLine = 144;
		   windowEnableThisLine = winEnabled;
		  }
		
		  // SpritesEnabledThisFrame should be true if sprites were ever on this frame
		  if (spritesEnabled) spritesEnabledThisFrame = true;
		
		  if (windowEnableThisLine) {
		   if (!winEnabled) {
		    windowStopLine = line;
			windowEnableThisLine = false;
		//	trace("Stop line: " + windowStopLine);
		   }
		  }
		
		  // Fix to screwed up status bars.  Record which data area is selected on the
		  // first line the window is to be displayed.  Will work unless this is changed
		  // after window is started
		  // NOTE: Still no real support for hblank effects on window/sprites
		  if (line == Gameboy.unsign(cpu.ioHandler.registers.read(0x4A)) + 1) {		// Compare against WY reg
		   savedWindowDataSelect = bgWindowDataSelect;
		  }
		
		 // Can't disable background on GBC (?!).  Apperently not, according to BGB
		  if ((!bgEnabled) && (!cpu.gbcFeatures)) return;
		
		  var xPixelOfs:int = Gameboy.unsign(cpu.ioHandler.registers.read(0x43)) % 8;
		  var yPixelOfs:int = Gameboy.unsign(cpu.ioHandler.registers.read(0x42)) % 8;
		
		//  if ((yPixelOfs + 4) % 8 == line % 8) {
		
		  if ( ((yPixelOfs + line) % 8 == 4) || (line == 0)) {
		
		   if ((line >= 144) && (line < 152)) notifyScanline(line + 8);
		
		   var xTileOfs:int = Gameboy.unsign(cpu.ioHandler.registers.read(0x43)) / 8;
		   var yTileOfs:int = Gameboy.unsign(cpu.ioHandler.registers.read(0x42)) / 8;
		   var bgStartAddress:int, tileNum:int;
		
		   var y:int = ((line + yPixelOfs) / 8);
		
		//   trace(y + "," + line);
		//    trace((8 * y) - yPixelOfs);
		
		   if (hiBgTileMapAddress) {
		    bgStartAddress = 0x1C00;  /* 1C00 */
		   } else {
		    bgStartAddress = 0x1800;
		   }
		
		   var tileNumAddress:int, attributeData:int, vidMemAddr:int;
		
		   for (var x:int = 0; x < 21; x++) {
		    if (bgWindowDataSelect) {
		     tileNumAddress = bgStartAddress +
		       (((y + yTileOfs) % 32) * 32) + ((x + xTileOfs) % 32);
		
		     tileNum = Gameboy.unsign(videoRam.read(tileNumAddress));
		     attributeData = Gameboy.unsign(videoRam.read(tileNumAddress + 0x2000));
		    } else {
		     tileNumAddress = bgStartAddress +
		        (((y + yTileOfs) % 32) * 32) + ((x + xTileOfs) % 32);
		
		     tileNum = 256 + videoRam.read(tileNumAddress);
		     attributeData = Gameboy.unsign(videoRam.read(tileNumAddress + 0x2000));
		    }
		
		    var attribs:int = 0;
		
		    if (cpu.gbcFeatures) {
		
		     if ((attributeData & 0x08) != 0) {
		      vidMemAddr = 0x2000 + (tileNum << 4);
		      tileNum += 384;
		     } else {
		      vidMemAddr = (tileNum << 4);
		     }
		     if ((attributeData & 0x20) != 0) {
		      attribs |= TILE_FLIPX;
		     }
		     if ((attributeData & 0x40) != 0) {
		      attribs |= TILE_FLIPY;
		     }
		     attribs += ((attributeData & 0x07) * 4);
		
		    } else {
		     vidMemAddr = (tileNum << 4);
		     attribs = TILE_BKG;
		    }
		
		
		    if (tiles[tileNum].invalid(attribs)) {
		     tiles[tileNum].validate(videoRam, vidMemAddr, attribs);
		    }
		    tiles[tileNum].draw(backBuffer, (8 * x) - xPixelOfs, (8 * y) - yPixelOfs, attribs);
		   }
		//   trace((8 * y) - yPixelOfs + " ");
		
		  }
		 }
		
		 /** Clears the frame buffer to the background colour */
		 public function clearFrameBuffer():void {
		  backBuffer.fillRect(new Rectangle(0, 0, 160, 144), backgroundPalette.getRgbEntry(0));
		 }
		
		 public function isFrameReady():Boolean {
		  return (framesDrawn % frameSkip) == 0;
		 }
		
		 /** Draw the current graphics frame into the given graphics context */
		 public function draw(g:BitmapData, startX:int, startY:int, a:DisplayObject):Boolean {
		  var tileNum:int;
		
		  calculateFPS();
		  if ((framesDrawn % frameSkip) != 0) {
		   frameDone = true;
		   framesDrawn++;
		   return false;
		  } else {
		   framesDrawn++;
		  }
		
		/*  g.setColor(new Color(255,0,0));
		  g.drawRect(5,5, 10, 10);*/
		//  trace("- Drawing");
		//  for (int r = 0; r < 384; r++) {
		//   if (!spriteTiles[r].valid) trace("Generating image for tile " + r);
		//   tiles[r].validate(videoRam, r << 4, backgroundPalette, TILE_BKG);
		//  }
		
		/*  for (int r = 0; r < 20; r++) {
		   bgTiles[r].draw(g, 8 * r, 0);
		  }*/
		
		
		
		//  drawSprites(back, 1);
		
		
		  // Draw bg layer
		/*
		  int xTileOfs = Javaboy.unsign(cpu.ioHandler.registers[0x43]) / 8;
		  int yTileOfs = Javaboy.unsign(cpu.ioHandler.registers[0x42]) / 8;
		  int xPixelOfs = Javaboy.unsign(cpu.ioHandler.registers[0x43]) % 8;
		  int yPixelOfs = Javaboy.unsign(cpu.ioHandler.registers[0x42]) % 8;
		
		  int bgStartAddress;
		  if (hiBgTileMapAddress) {
		   bgStartAddress = 0x1C00;  /* 1C00 
		  } else {
		   bgStartAddress = 0x1800;
		  }
		
		  int tileAddress = 0;
		  int attribs = 0;
		
		  
		  for (int y = 0; y < 19; y++) {
		   for (int x = 0; x < 21; x++) {
		    int attributeData = 0;
		
		
		    tileAddress = bgStartAddress +
		       (((y + yTileOfs) % 32) * 32) + ((x + xTileOfs) % 32);
		    attributeData = Javaboy.unsign(videoRam[tileAddress + 0x2000]);
		
		    if (bgWindowDataSelect) {
		     tileNum = Javaboy.unsign(videoRam[tileAddress]);
		    } else {
		     tileNum = 256 + videoRam[tileAddress];
		    }
		
		    if (cpu.gbcFeatures) {
		     attribs = (attributeData & 0x07) << 2;
		
		     if ((attributeData & 0x20) != 0) {
		      attribs |= TILE_FLIPX;
		     }
		     if ((attributeData & 0x40) != 0) {
		      attribs |= TILE_FLIPY;
		     }
		
		    } else {
		     attribs = TILE_BKG;
		    }
		
		    if (tiles[tileNum + tileStart].invalid(attribs)) {
		     tiles[tileNum + tileStart].validate(videoRam, tileNum << 4 + vidMemStart, attribs);
		    }
		    tiles[tileNum + tileStart].
		       draw(back, (8 * x) - xPixelOfs, (8 * y) - yPixelOfs, attribs);
		   }
		  }
		*/
		
		
		  /* Draw window */
		  if (winEnabled) {
		   var wx:int, wy:int;
		   var windowStartAddress:int;
		
		   if ((cpu.ioHandler.registers.read(0x40) & 0x40) != 0) {
		    windowStartAddress = 0x1C00;
		   } else {
		    windowStartAddress = 0x1800;
		   }
		   wx = Gameboy.unsign(cpu.ioHandler.registers.read(0x4B)) - 7;
		   wy = Gameboy.unsign(cpu.ioHandler.registers.read(0x4A));
		
		   backBuffer.fillRect(new Rectangle(wx, wy, 160, 144), backgroundPalette.getRgbEntry(0));
		
		   var tileAddress:int;
		   var attribData:int, attribs:int, tileDataAddress:int;
		
		   for (var y:int = 0; y < 19 - (wy / 8); y++) {
		    for (var x:int = 0; x < 21 - (wx / 8); x++) {
		     tileAddress = windowStartAddress + (y * 32) + x;
		
		//     if (!bgWindowDataSelect) {
		     if (!savedWindowDataSelect) {
		      tileNum = 256 + videoRam.read(tileAddress);
		      } else {
		      tileNum = Gameboy.unsign(videoRam.read(tileAddress));
		     }
		     tileDataAddress = tileNum << 4;
		
		     if (cpu.gbcFeatures) {
		      attribData = Gameboy.unsign(videoRam.read(tileAddress + 0x2000));
		
		      attribs = (attribData & 0x07) << 2;
		
		      if ((attribData & 0x08) != 0) {
		       tileNum += 384;
		       tileDataAddress += 0x2000;
		      }
		
		      if ((attribData & 0x20) != 0) {
		       attribs |= TILE_FLIPX;
		      }
		      if ((attribData & 0x40) != 0) {
		       attribs |= TILE_FLIPY;
		      }
		
		     } else {
		      attribs = TILE_BKG;
		     }
		
			 if (wy + y * 8 < windowStopLine) {
		      if (tiles[tileNum].invalid(attribs)) {
		       tiles[tileNum].validate(videoRam, tileDataAddress, attribs);
		      }
		      tiles[tileNum].draw(backBuffer, wx + x * 8, wy + y * 8, attribs);
		     }
			}
		   }
		  }
		
		  // Draw sprites if the flag was on at any time during this frame
		 /* if (spritesEnabledThisFrame) */drawSprites(backBuffer, 0);
		
		  if ((spritesEnabled) && (cpu.gbcFeatures)) {
		   drawSprites(backBuffer, 1);
		  }
		
		/*  back.setColor(new Color(255, 255, 255));
		  back.fillRect(0, 0, 160, 144);
		  for (int r = 0; r < 384; r++) {
		   tiles[r].validate(videoRam, r << 4, TILE_BKG);
		   tiles[r].draw(back, 8 * (r % 20), 8 * (r / 20), TILE_BKG);
		  }*/
		
		
		  g.draw(backBuffer, new Matrix(1,0,0,1,startX, startY));
		
		/*  if (mag == 1) {
		   g.drawImage(backBuffer, startX, startY, null);
		  } else {
		   g.drawImage(backBuffer, startX, startY, width, height, null);
		  }*/
		
		  frameDone = true;
		  return true;
		 }

	}
}