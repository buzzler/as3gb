package com.mobswing.gb
{
	import __AS3__.vec.Vector;
	
	import flash.display.BitmapData;
	
	public class PPUAdvance extends PPU
	{
		protected	var frameBufferArray:Vector.<uint>;
		protected	var scaledBufferArray:Vector.<uint>;
		
		protected	var transparentImage:Vector.<uint> = new Vector.<uint>(0);
		protected	var	tileImage:Vector.<Vector.<uint>>;
		protected	var tileReadState:Vector.<Boolean>; // true if there are any images to be invalidated
		
		protected	var tempPix:Vector.<uint>;
		
		protected	var windowSourceLine:int;
		
		public function PPUAdvance(cpu:CPU)
		{
			super();

			colors = Vector.<int>([ 0x80F8F8F8, 0x80A8A8A8, 0x80505050, 0x80000000]);
			gbcMask = 0x80000000;
			transparentCutoff = cpu.gbcFeatures ? 32 : 4;
			
			tileImage = new Vector.<Vector.<uint>>(tileCount * colorCount);
			tileReadState = new Vector.<Boolean>(tileCount);
			tempPix = new Vector.<uint>(8 * 8);
			frameBufferArray = new Vector.<uint>(8 * 8 * 20 * 18);
		}

		override public	function addressWrite(addr:int, data:int):void
		{
			if (videoRam.read(addr) == data)
				return;
			
			if (addr < 0x1800)
			{ // Bkg Tile data area
				var tileIndex:int = (addr >> 4) + tileOffset;
				
				if (tileReadState[tileIndex])
				{
					var r:int = tileImage.length - tileCount + tileIndex;
					
					do
					{
						tileImage[r] = null;
						r -= tileCount;
					} while (r >= 0);
					tileReadState[tileIndex] = false;
				}
			}
			videoRam.write(addr, data);
		}
		
		override public	function invalidateAll(pal:int):void
		{
			var start:int = pal * tileCount * 4;
			var stop:int = (pal + 1) * tileCount * 4;
			
			for (var r:int = start; r < stop; r++)
			{
				tileImage[r] = null;
			}
		}
		
		protected function drawSpritesForLine(line:int):void
		{
			if (!spritesEnabled)
				return;
		
			var minSpriteY:int = doubledSprites ? line-15 : line -7;
			var priorityFlag:int = spritePriorityEnabled ? 0x80 : 0;
			
			for ( ; priorityFlag >= 0 ; priorityFlag -= 0x80)
			{
				var oamIx:int = 159;
				
				while (oamIx >= 0)
				{
					var attributes:int = 0xff & cpu.oam.read(oamIx--);
		
					if ((attributes & 0x80) == priorityFlag || !spritePriorityEnabled)
					{
						var tileNum:int = (0xff & cpu.oam.read(oamIx--));
						var spriteX:int = (0xff & cpu.oam.read(oamIx--)) - 8;
						var spriteY:int = (0xff & cpu.oam.read(oamIx--)) - 16;
						
						var offset:int = line - spriteY;
						if (spriteX >= 160 || spriteY < minSpriteY || offset < 0)
							continue;
						
						if (doubledSprites)
							tileNum &= 0xFE;
		
						var spriteAttrib:int = (attributes >> 5) & 0x03;
		
						if (cpu.gbcFeatures)
						{
							spriteAttrib += 0x20 + ((attributes & 0x07) << 2);
							tileNum += (384>>3) * (attributes & 0x08);
						}
						else
						{
							spriteAttrib += 4 + ((attributes & 0x10) >> 2);
						}
						
						if (priorityFlag == 0x80)
						{
							if (doubledSprites)
							{
								if ((spriteAttrib & TILE_FLIPY) != 0)
								{
									drawPartBgSprite((tileNum | 1) - (offset >> 3), spriteX, line, offset & 7, spriteAttrib);
								}
								else
								{
									drawPartBgSprite((tileNum & -2) + (offset >> 3), spriteX, line, offset & 7, spriteAttrib);
								}
							}
							else
							{
								drawPartBgSprite(tileNum, spriteX, line, offset, spriteAttrib);
							}
						}
						else
						{
							if (doubledSprites)
							{
								if ((spriteAttrib & TILE_FLIPY) != 0)
								{
									drawPartFgSprite((tileNum | 1) - (offset >> 3), spriteX, line, offset & 7, spriteAttrib);
								}
								else
								{
									drawPartFgSprite((tileNum & -2) + (offset >> 3), spriteX, line, offset & 7, spriteAttrib);
								}
							}
							else
							{
								drawPartFgSprite(tileNum, spriteX, line, offset, spriteAttrib);
							}
						}
					}
					else
					{
						oamIx -= 3;
					}
				}
			}
		}
		
		protected function drawBackgroundForLine(line:int, windowLeft:int, priority:int):Boolean
		{
			var skippedTile:Boolean = false;
			
			var sourceY:int = line + (cpu.registers.read(0x42) & 0xff);
			var sourceImageLine:int = sourceY & 7;
			
			var tileNum:int;
			var tileX:int = (cpu.registers.read(0x43) & 0xff) >> 3;
			var memStart:int = (hiBgTileMapAddress ? 0x1c00 : 0x1800) + ((sourceY & 0xf8) << 2);
		
			var screenX:int = -(cpu.registers.read(0x43) & 7);
			
			var tileAttrib:int;
			var mapAttrib:int;
			for ( ; screenX < windowLeft ; tileX++, screenX += 8)
			{
				if (bgWindowDataSelect)
					tileNum = videoRamBanks[0].read(memStart + (tileX & 0x1f)) & 0xff;
				else
					tileNum = 256 + videoRamBanks[0].read(memStart + (tileX & 0x1f));
		
				tileAttrib = 0;
				
				if (cpu.gbcFeatures)
				{
					mapAttrib = videoRamBanks[1].read(memStart + (tileX & 0x1f));
					
					if ((mapAttrib & 0x80) != priority)
					{
						skippedTile = true;
						continue;
					}
					
					tileAttrib += (mapAttrib & 0x07) << 2;
					tileAttrib += (mapAttrib >> 5) & 0x03;
					tileNum += 384 * ((mapAttrib >> 3) & 0x01);
				}
				drawPartCopy(tileNum, screenX, line, sourceImageLine, tileAttrib);
			}
		
			if (windowLeft < 160)
			{
				var windowStartAddress:int = hiWinTileMapAddress ? 0x1c00 : 0x1800;
		
				var tileAddress:int;
		
				var windowSourceTileY:int = windowSourceLine >> 3;
				var windowSourceTileLine:int = windowSourceLine & 7;
		
				tileAddress = windowStartAddress + (windowSourceTileY * 32);
		
				for (screenX = windowLeft; screenX < 160; tileAddress++, screenX += 8)
				{
					if (bgWindowDataSelect)
						tileNum = videoRamBanks[0].read(tileAddress) & 0xff;
					else
						tileNum = 256 + videoRamBanks[0].read(tileAddress);
		
					tileAttrib = 0;
					
					if (cpu.gbcFeatures)
					{
						mapAttrib = videoRamBanks[1].read(tileAddress);
						
						if ((mapAttrib & 0x80) != priority)
						{
							skippedTile = true;
							continue;
						}
						
						tileAttrib += (mapAttrib & 0x07) << 2;
						tileAttrib += (mapAttrib >> 5) & 0x03;
						tileNum += 384 * ((mapAttrib >> 3) & 0x01);
					}
					drawPartCopy(tileNum, screenX, line, windowSourceTileLine, tileAttrib);
				}
			}
			return skippedTile;
		}
		
		override public	function notifyScanline(line:int):void
		{
			if (skipping || line >= 144)
				return;
		
			if (line == 0)
				windowSourceLine = 0;
			
			var windowLeft:int;
			if (winEnabled && (cpu.registers.read(0x4A) & 0xff) <= line)
			{
				windowLeft = (cpu.registers.read(0x4B) & 0xff) - 7;
				if (windowLeft > 160)
					windowLeft = 160;
			}
			else
			{
				windowLeft = 160;
			}
			
			var skippedAnything:Boolean = drawBackgroundForLine(line, windowLeft, 0);
			
			drawSpritesForLine(line);
		
			if (skippedAnything)
				drawBackgroundForLine(line, windowLeft, 0x80);
			
			if (windowLeft < 160)
				windowSourceLine++;
			
			if (line == 143)
				updateFrameBufferImage();
		}
		
		protected function updateFrameBufferImage():void
		{
			if (!lcdEnabled)
			{
				var buffer:Vector.<uint> = scale ? scaledBufferArray : frameBufferArray;
				for (var i:int = 0 ; i < buffer.length ; i++)
					buffer[i] = -1;
				//frameBuffer = Image.createRGBImage(buffer, scaledWidth, scaledHeight, false);
				frameBuffer = new BitmapData(scaledWidth, scaledHeight, false, 0x000000);
				frameBuffer.setVector(frameBuffer.rect, buffer);
				return;
			}
			
			if (scale)
			{
				var y:int;
				var deltaX:int;
				var deltaY:int;
				var sy:int;
				var rx:int;
				var ry:int;
				var src:int;
				var dst:int;
				var dstStop:int;
				var bottomPart:int;
				var topPart:int;
				
				if (Globals.scalingMode == 0)
				{
					deltaX = (((160 << 10) - 1) / scaledWidth);
					deltaY = (((144 << 10) - 1) / scaledHeight);
					
					sy = 0;
					ry = deltaY >> 1;
					dst = 0;
					dstStop = scaledWidth;
					
					for (y = 0; y < scaledHeight ; y++)
					{
						rx = deltaX >> 1;
						src = sy * 160;
						
						while (dst < dstStop)
						{
							scaledBufferArray[dst++] = frameBufferArray[src];
							
							rx = (rx & 1023) + deltaX;
							src += rx >> 10;
						}
						
						ry = (ry & 1023) + deltaY;
						sy += ry >> 10;
						dstStop += scaledWidth;
					}
				}
				else if (Globals.scalingMode == 1)
				{
					// linear horizontal, nearest neighbor vertical
					
					deltaX = (((159 << 10) - 1) / scaledWidth);
					deltaY = (((144 << 10) - 1) / scaledHeight);
					
					sy = 0;
					ry = deltaY >> 1;
					dst = 0;
					dstStop = scaledWidth;
					
					for (y = 0 ; y < scaledHeight ; y++)
					{
						rx = deltaX >> 1;
						src = sy * 160;
						
						while (dst < dstStop)
						{
							var rightPart:int = rx >> 7;
							var leftPart:int = 8 - rightPart;
							
							scaledBufferArray[dst++] = (leftPart * frameBufferArray[src] + rightPart * frameBufferArray[src+1]) >> 3;
							
							rx += deltaX;
							src += rx >> 10;
							rx &= 1023;
						}
						
						ry = (ry & 1023) + deltaY;
						sy += ry >> 10;
						dstStop += scaledWidth;
					}
				}
				else if (Globals.scalingMode == 2)
				{
					deltaX = (((160 << 10) - 1) / scaledWidth);
					deltaY = (((143 << 10) - 1) / scaledHeight);
					
					sy = 0;
					ry = deltaY >> 1;
					dst = 0;
					dstStop = scaledWidth;
					
					for (y = 0 ; y < scaledHeight ; y++)
					{
						rx = deltaX >> 1;
						src = sy * 160;
						
						while (dst < dstStop)
						{
							bottomPart = ry >> 7;
							topPart = 8 - bottomPart;
							
							scaledBufferArray[dst++] = (topPart * frameBufferArray[src] + bottomPart * frameBufferArray[src+160]) >> 3;
							
							rx += deltaX;
							src += rx >> 10;
							rx &= 1023;
						}
						
						ry += deltaY;
						sy += ry >> 10;
						ry &= 1023;
						dstStop += scaledWidth;
					}
				}
				else if (Globals.scalingMode == 3)
				{
					deltaX = (((159 << 10) - 1) / scaledWidth);
					deltaY = (((143 << 10) - 1) / scaledHeight);
					
					sy = 0;
					ry = deltaY >> 1;
					dst = 0;
					dstStop = scaledWidth;
					
					for (y = 0 ; y < scaledHeight ; y++)
					{
						bottomPart = ry >> 7;
						topPart = 8 - bottomPart;
						
						rx = deltaX >> 1;
						src = sy * 160;
						
						while (dst < dstStop)
						{
							var topRightPart:int = (rx * topPart) >> 10;
							var topLeftPart:int = topPart - topRightPart;
							
							var bottomRightPart:int = (rx * bottomPart) >> 10;
							var bottomLeftPart:int = bottomPart - bottomRightPart;
							
							scaledBufferArray[dst++] = (topLeftPart * frameBufferArray[src] + topRightPart * frameBufferArray[src+1] +
									bottomLeftPart * frameBufferArray[src+160] + bottomRightPart * frameBufferArray[src+161]) >> 3;
							
							rx += deltaX;
							src += rx >> 10;
							rx &= 1023;
						}
						ry += deltaY;
						sy += ry >> 10;
						ry &= 1023;
						dstStop += scaledWidth;
					}
				}
				
				//frameBuffer = Image.createRGBImage(scaledBufferArray, scaledWidth, scaledHeight, false);
				frameBuffer.setVector(frameBuffer.rect, scaledBufferArray);
			}
			else
			{
				//frameBuffer = Image.createRGBImage(frameBufferArray, 160, 144, false);
				frameBuffer.setVector(frameBuffer.rect, frameBufferArray);
			}
		}
		
/* 		protected function updateImage(tileIndex:int, attribs:int):Vector.<uint>
		{
			var index:int = tileIndex + tileCount * attribs;
			
			var otherBank:Boolean = (tileIndex >= 384);
			
			var offset:int = otherBank ? ((tileIndex - 384) << 4) : (tileIndex << 4);
		
			var paletteStart:int = attribs & 0xfc;
			
			var vram:Vector.<int> = otherBank ? videoRamBanks[1] : videoRamBanks[0];
			var palette:Vector.<int> = cpu.gbcFeatures ? gbcPalette : gbPalette;
			var transparent:Boolean = attribs >= transparentCutoff;
			
			var pixix:int = 0;
			var pixixdx:int = 1;
			var pixixdy:int = 0;
			
			if ((attribs & TILE_FLIPY) != 0)
			{
				pixixdy = -2*8;
				pixix = 8 * (8 - 1);
			}
			if ((attribs & TILE_FLIPX) == 0)
			{
				pixixdx = -1;
				pixix += 8 - 1;
				pixixdy += 8 * 2;
			}
			
			for (var y:int = 8 ; --y >= 0 ; )
			{
				var num:int = weaveLookup[vram[offset++] & 0xff] + (weaveLookup[vram[offset++] & 0xff] << 1);
				if (num != 0)
					transparent = false;
				
				for (var x:int = 8 ; --x >= 0 ; )
				{
					tempPix[pixix] = palette[paletteStart + (num & 3)];
					pixix += pixixdx;
					
					num >>= 2;
				}
				pixix += pixixdy;
			}
			
			if (transparent)
			{
				tileImage[index] = transparentImage;
			}
			else
			{
				tileImage[index] = tempPix;
				tempPix = new Vector.<int>(8 * 8);
			}
			
			tileReadState[tileIndex] = true;
			
			return tileImage[index];
		} */

		protected function updateImage(tileIndex:int, attribs:int):Vector.<uint>
		{
			var index:int = tileIndex + tileCount * attribs;
			
			var otherBank:Boolean = (tileIndex >= 384);
			
			var offset:int = otherBank ? ((tileIndex - 384) << 4) : (tileIndex << 4);
		
			var paletteStart:int = attribs & 0xfc;
			
			var vram:ByteArrayAdvanced = otherBank ? videoRamBanks[1] : videoRamBanks[0];
			var palette:Vector.<int> = cpu.gbcFeatures ? gbcPalette : gbPalette;
			var transparent:Boolean = attribs >= transparentCutoff;
			
			var pixix:int = 0;
			var pixixdx:int = 1;
			var pixixdy:int = 0;
			
			if ((attribs & TILE_FLIPY) != 0)
			{
				pixixdy = -2*8;
				pixix = 8 * (8 - 1);
			}
			if ((attribs & TILE_FLIPX) == 0)
			{
				pixixdx = -1;
				pixix += 8 - 1;
				pixixdy += 8 * 2;
			}
			
			for (var y:int = 8 ; --y >= 0 ; )
			{
				var num:int = weaveLookup[vram.read(offset++) & 0xff] + (weaveLookup[vram.read(offset++) & 0xff] << 1);
				if (num != 0)
					transparent = false;
				
				for (var x:int = 8 ; --x >= 0 ; )
				{
					tempPix[pixix] = palette[paletteStart + (num & 3)];
					pixix += pixixdx;
					
					num >>= 2;
				}
				pixix += pixixdy;
			}
			
			if (transparent)
			{
				tileImage[index] = transparentImage;
			}
			else
			{
				tileImage[index] = tempPix;
				tempPix = new Vector.<uint>(8 * 8);
			}
			
			tileReadState[tileIndex] = true;
			
			return tileImage[index];
		}

		protected function drawPartCopy(tileIndex:int, x:int, y:int, sourceLine:int, attribs:int):void
		{
			var ix:int = tileIndex + tileCount * attribs;
			var im:Vector.<uint> = tileImage[ix];
			
			if (im == null)
				im = updateImage(tileIndex, attribs);
			
			var dst:int = x + y * 160;
			var src:int = sourceLine * 8;
			var dstEnd:int = (x + 8 > 160) ? ((y+1) * 160) : (dst + 8);  
			
			if (x < 0)
			{
				dst -= x;
				src -= x;
			}
			
			while (dst < dstEnd)
				frameBufferArray[dst++] = im[src++];
		}

		protected function drawPartFgSprite(tileIndex:int, x:int, y:int, sourceLine:int, attribs:int):void
		{
			var ix:int = tileIndex + tileCount * attribs;
			var im:Vector.<uint> = tileImage[ix];
			
			if (im == null)
				im = updateImage(tileIndex, attribs);
			
			if (im == transparentImage)
				return;

			var dst:int = x + y * 160;
			var src:int = sourceLine * 8;
			var dstEnd:int = (x + 8 > 160) ? ((y+1) * 160) : (dst + 8);  
			
			if (x < 0)
			{
				dst -= x;
				src -= x;
			}
			
			while (dst < dstEnd)
			{
				if (im[src] < 0)
					frameBufferArray[dst] = im[src];

				dst++;
				src++;
			}
		}
		
		protected function drawPartBgSprite(tileIndex:int, x:int, y:int, sourceLine:int, attribs:int):void
		{
			var ix:int = tileIndex + tileCount * attribs;
			var im:Vector.<uint> = tileImage[ix];
			
			if (im == null)
				im = updateImage(tileIndex, attribs);
			
			if (im == transparentImage)
				return;

			var dst:int = x + y * 160;
			var src:int = sourceLine * 8;
			var dstEnd:int = (x + 8 > 160) ? ((y+1) * 160) : (dst + 8);  
			
			if (x < 0)
			{
				dst -= x;
				src -= x;
			}

			while (dst < dstEnd)
			{
				if (im[src] < 0 && frameBufferArray[dst] >= 0)
					frameBufferArray[dst] = im[src];

				dst++;
				src++;
			}
		}
		
		override public	function setScale(screenWidth:int, screenHeight:int):void
		{
			if (Globals.keepProportions)
			{
				if (screenWidth * 18 > screenHeight * 20)
					screenWidth = screenHeight * 20 / 18;
				else
					screenHeight = screenWidth * 18 / 20;
			}
			
			if (screenWidth == scaledWidth && screenHeight == scaledHeight)
				return;
			
			scale = screenWidth != 160 || screenHeight != 144;
			
			scaledWidth = screenWidth;
			scaledHeight = screenHeight;
			
			if (scale)
				scaledBufferArray = new int[scaledWidth * scaledHeight];
			else
				scaledBufferArray = null;
		}
		
		override public	function setGBCPalette(index:int, data:int):void
		{
			super.setGBCPalette(index, data);
			
			if ((index & 0x6) == 0) {
				gbcPalette[index >> 1] &= 0x00ffffff;
			}
		}
	}
}