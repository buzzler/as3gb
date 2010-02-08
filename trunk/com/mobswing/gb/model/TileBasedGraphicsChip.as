package com.mobswing.gb.model
{
	import __AS3__.vec.Vector;
	
	import com.mobswing.gb.view.Javaboy;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	/** This class is one implementation of the GraphicsChip.
	 *  It performs the output of the graphics screen, including the background, window, and sprite layers.
	 *  It supports some raster effects, but only ones that happen on a tile row boundary.
	 */
	public class TileBasedGraphicsChip extends GraphicsChip
	{
		 /** Tile cache */
		 private var tiles:Vector.<GameboyTile> = new Vector.<GameboyTile>(384 * 2);
		
		 // Hacks to allow some raster effects to work.  Or at least not to break as badly.
		 private var savedWindowDataSelect:Boolean = false;
		 private var spritesEnabledThisFrame:Boolean = false;
		
		 private var windowEnableThisLine:Boolean = false;
		 private var windowStopLine:int = 144;
		 
		public function TileBasedGraphicsChip(a:DisplayObject, d:Dmgcpu)
		{
			super(a, d);
			for (var r:int = 0; r < 384 * 2; r++) {
				tiles[r] = new GameboyTile(a, dmgcpu, this);
			}
		}

		 /** Flush the tile cache */
		 override public function dispose():void {
		  for (var r:int = 0; r < 384 * 2; r++) {
		   if (tiles[r] != null) tiles[r].dispose();
		  }
		 }
		
		 /** Reads data from the specified video RAM address */
		 override public function addressRead(addr:int):int {	//@return short
		  return videoRam.read(addr + vidRamStart);
		 }
		
		 /** Writes data to the specified video RAM address */
		 override public function addressWrite(addr:int, data:int):void {	//@param data:byte
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
		 override public function invalidateAllByAttribs(attribs:int):void {
		  for (var r:int = 0; r < 384 * 2; r++) {
		   tiles[r].invalidate(attribs);
		  }
		 }
		
		 /** Invalidate all tiles in the tile cache */
		 override public function invalidateAll():void {
		  for (var r:int = 0; r < 384 * 2; r++) {
		   tiles[r].invalidateAll();
		  }
		 }
		
		 /** Set the size of the Gameboy window. */
		 override public function setMagnify(m:int):void {
		  super.setMagnify(m);
		  for (var r:int = 0; r < 384 * 2; r++) {
		   tiles[r].setMagnify(m);
		  }
		 }
		
		 /** Draw sprites into the back buffer which have the given priority */
		 public function drawSprites(back:BitmapData, priority:int):void {
		  
		  var tileBankStart:int = 0;
		  var vidRamAddress:int = 0;
		
		  // Draw sprites
		  for (var i:int = 0; i < 40; i++) {
		   var spriteX:int = dmgcpu.addressRead(0xFE01 + (i * 4)) - 8;
		   var spriteY:int = dmgcpu.addressRead(0xFE00 + (i * 4)) - 16;
		   var tileNum:int = dmgcpu.addressRead(0xFE02 + (i * 4));
		   var attributes:int = dmgcpu.addressRead(0xFE03 + (i * 4));
		
		   if ((attributes & 0x80) >> 7 == priority) {
		
		   var spriteAttrib:int = 0;
		
		   if (doubledSprites) {
		    tileNum &= 0xFE;
		   }
		
		   if (dmgcpu.gbcFeatures) {
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
		 override public function notifyScanline(line:int):void {
		
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
		  if (line == Javaboy.unsign(dmgcpu.ioHandler.registers.read(0x4A)) + 1) {		// Compare against WY reg
		   savedWindowDataSelect = bgWindowDataSelect;
		  }
		
		 // Can't disable background on GBC (?!).  Apperently not, according to BGB
		  if ((!bgEnabled) && (!dmgcpu.gbcFeatures)) return;
		
		  var xPixelOfs:int = Javaboy.unsign(dmgcpu.ioHandler.registers.read(0x43)) % 8;
		  var yPixelOfs:int = Javaboy.unsign(dmgcpu.ioHandler.registers.read(0x42)) % 8;
		
		//  if ((yPixelOfs + 4) % 8 == line % 8) {
		
		  if ( ((yPixelOfs + line) % 8 == 4) || (line == 0)) {
		
		   if ((line >= 144) && (line < 152)) notifyScanline(line + 8);
		
		   var xTileOfs:int = Javaboy.unsign(dmgcpu.ioHandler.registers.read(0x43)) / 8;
		   var yTileOfs:int = Javaboy.unsign(dmgcpu.ioHandler.registers.read(0x42)) / 8;
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
		
		     tileNum = Javaboy.unsign(videoRam.read(tileNumAddress));
		     attributeData = Javaboy.unsign(videoRam.read(tileNumAddress + 0x2000));
		    } else {
		     tileNumAddress = bgStartAddress +
		        (((y + yTileOfs) % 32) * 32) + ((x + xTileOfs) % 32);
		
		     tileNum = 256 + videoRam.read(tileNumAddress);
		     attributeData = Javaboy.unsign(videoRam.read(tileNumAddress + 0x2000));
		    }
		
		    var attribs:int = 0;
		
		    if (dmgcpu.gbcFeatures) {
		
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
		  backBuffer.fillRect(new Rectangle(0, 0, 160*mag, 144*mag), backgroundPalette.getRgbEntry(0));
		 }
		
		 override public function isFrameReady():Boolean {
		  return (framesDrawn % frameSkip) == 0;
		 }
		
		 /** Draw the current graphics frame into the given graphics context */
		 override public function draw(g:BitmapData, startX:int, startY:int, a:DisplayObject):Boolean {
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
		  int xTileOfs = Javaboy.unsign(dmgcpu.ioHandler.registers[0x43]) / 8;
		  int yTileOfs = Javaboy.unsign(dmgcpu.ioHandler.registers[0x42]) / 8;
		  int xPixelOfs = Javaboy.unsign(dmgcpu.ioHandler.registers[0x43]) % 8;
		  int yPixelOfs = Javaboy.unsign(dmgcpu.ioHandler.registers[0x42]) % 8;
		
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
		
		    if (dmgcpu.gbcFeatures) {
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
		
		   if ((dmgcpu.ioHandler.registers.read(0x40) & 0x40) != 0) {
		    windowStartAddress = 0x1C00;
		   } else {
		    windowStartAddress = 0x1800;
		   }
		   wx = Javaboy.unsign(dmgcpu.ioHandler.registers.read(0x4B)) - 7;
		   wy = Javaboy.unsign(dmgcpu.ioHandler.registers.read(0x4A));
		
		   backBuffer.fillRect(new Rectangle(wx * mag, wy * mag, 160 * mag, 144 * mag), backgroundPalette.getRgbEntry(0));
		
		   var tileAddress:int;
		   var attribData:int, attribs:int, tileDataAddress:int;
		
		   for (var y:int = 0; y < 19 - (wy / 8); y++) {
		    for (var x:int = 0; x < 21 - (wx / 8); x++) {
		     tileAddress = windowStartAddress + (y * 32) + x;
		
		//     if (!bgWindowDataSelect) {
		     if (!savedWindowDataSelect) {
		      tileNum = 256 + videoRam.read(tileAddress);
		      } else {
		      tileNum = Javaboy.unsign(videoRam.read(tileAddress));
		     }
		     tileDataAddress = tileNum << 4;
		
		     if (dmgcpu.gbcFeatures) {
		      attribData = Javaboy.unsign(videoRam.read(tileAddress + 0x2000));
		
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
		
		  if ((spritesEnabled) && (dmgcpu.gbcFeatures)) {
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