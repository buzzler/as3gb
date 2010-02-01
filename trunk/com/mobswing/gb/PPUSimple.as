package com.mobswing.gb
{
	import __AS3__.vec.Vector;
	
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class PPUSimple extends PPU
	{
		private var winEnabledThisFrame		:Boolean = true;
		private	var spritesEnabledThisFrame	:Boolean = true;
		private	var screenFilled			:Boolean;
		private	var windowStopped			:Boolean;
		private	var winEnabledThisLine		:Boolean = false;
		private	var windowStopLine			:int = 144;
		private	var windowStopX				:int;
		private	var windowStopY				:int;
		private	var savedWindowDataSelect	:Boolean = false;
		private	var transparentImage		:BitmapData;
		private	var tileImage				:Vector.<BitmapData>;
		private	var tileReadState			:Vector.<Boolean>;
		private	var imageBounds				:Vector.<Vector.<int>>;
		private	var tempPix					:Vector.<uint>;
		private	var tileWidth				:int = 8;
		private	var tileHeight				:int = 8;
		private	var imageHeight				:int = 8;
		
		public function PPUSimple()
		{
			super();
			
			colors = Vector.<int>([0xffffffff, 0xffaaaaaa, 0xff555555, 0xff000000]);
			gbcMask = 0xff000000;
			transparentCutoff = cpu.gbcFeatures ? 32 : 0;
			
			tileImage = new Vector.<BitmapData>(tileCount * colorCount);
			imageBounds = new Vector.<Vector.<int>>(tileCount);
			tileReadState = new Vector.<Boolean>(tileCount);
			
			cpu.memory[4] = videoRam;
			
			tempPix = new Vector.<uint>(tileWidth * tileHeight * 2);
			transparentImage = new BitmapData(tileWidth, tileHeight, true, 0x00000000);
			frameBuffer = new BitmapData(scaledWidth, scaledHeight, true, 0xFF000000);
		}

		override public	function UpdateLCDCFlags(data:int):void
		{
			if (doubledSprites != ((data & 0x04) != 0))
			{
				invalidateAll(1);
				invalidateAll(2);
			}
			super.UpdateLCDCFlags(data);
			spritesEnabledThisFrame = spritesEnabledThisFrame || spritesEnabled;
		}
		
		override public	function addressWrite(addr:int, data:int):void
		{
			if (videoRam.read(addr) == data)
				return;
			
			if (addr < 0x1800)
			{
				var tileIndex:int = (addr >> 4) + tileOffset;
				
				if (tileReadState[tileIndex])
				{
					var r:int = tileImage.length - tileCount + tileIndex;
					
					do
					{
						tileImage[r] = null;
						r -= tileCount;
					} while (r >= 0);
					imageBounds[tileIndex] = null;
					tileReadState[tileIndex] = false;
				}
			}
			videoRam.write(addr, data);
		}
		
		override public	function invalidateAll(pal:int):void
		{
			var start:int = pal * tileCount * 4;
			var stop:int = (pal + 1) * tileCount * 4;
			
			for (var r:int = start ; r < stop ; r++)
			{
				tileImage[r] = null;
			}
		}
		
		private	function drawSprites(priorityFlag:int):void
		{
trace('drawSprites');
			if (!spritesEnabledThisFrame)
				return;
			
			var tileNumMask:int = 0xff;
			if (doubledSprites)
			{
				tileNumMask = 0xfe; // last bit treated as 0
				imageHeight = tileHeight * 2;
			}
			
			for (var i:int = 156 ; i >= 0 ; i -= 4)
			{
				var attributes:int = 0xff & cpu.oam.read(i + 3);
				
				if ((attributes & 0x80) == priorityFlag)
				{
					var spriteX:int = (0xff & cpu.oam.read(i + 1)) - 8;
					var spriteY:int = (0xff & cpu.oam.read(i)) - 16;
					
					if (spriteX >= 160 || spriteY >= 144 || spriteY == -16)
						continue;
					
					var tileNum:int = (tileNumMask & cpu.oam.read(i + 2));
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
					
					draw(tileNum, spriteX, spriteY, spriteAttrib);
				}
			}
			imageHeight = tileHeight;
		}
		
		override public	function notifyScanline(line:int):void
		{
trace('notifyScanline');
			if (skipping)
				return;

			if (line == 0)
			{
				if (!cpu.gbcFeatures)
				{
					frameBuffer.fillRect(new Rectangle(0, 0, scaledWidth, scaledHeight), gbPalette[0]); 
					drawSprites(0x80);
				}
				
				windowStopLine = 144;
				winEnabledThisFrame = winEnabled;
				winEnabledThisLine = winEnabled;
				screenFilled = false;
				windowStopped = false;
			}
			
			if (winEnabledThisLine && !winEnabled)
			{
				windowStopLine = line & 0xff;
				winEnabledThisLine = false;
			}
			
			if (line == (cpu.registers.read(0x4A) & 0xff) + 1)
				savedWindowDataSelect = bgWindowDataSelect;
			
			if (!bgEnabled)
				return;

			var yPixelOfs:int;
			var screenY:int;
			if (winEnabledThisLine && 
					(!windowStopped) && 
					(((cpu.registers.read(0x4B) & 0xff) - 7) == 0) &&
					((cpu.registers.read(0x4A) & 0xff) <= (line - 7)))
			{
				yPixelOfs = cpu.registers.read(0x42) & 7;
				screenY = (line & 0xf8) - yPixelOfs;
				if (screenY >= 136)
					screenFilled = true;
			}
			else if ((((cpu.registers.read(0x42) + line) & 7) == 7) || (line == 144))
			{
				var xPixelOfs:int = cpu.registers.read(0x43) & 7;
				yPixelOfs = cpu.registers[0x42] & 7;
				var xTileOfs:int = (cpu.registers.read(0x43) & 0xff) >> 3;
				var yTileOfs:int = (cpu.registers.read(0x42) & 0xff) >> 3;
				
				var bgStartAddress:int = hiBgTileMapAddress ? 0x1c00 : 0x1800; 
				var tileNum:int;
				
				screenY = (line & 0xf8) - yPixelOfs;
				var screenX:int = -xPixelOfs;
				var screenRight:int = 160;
				
				var tileY:int = (line >> 3) + yTileOfs;
				var tileX:int = xTileOfs;

				var memStart:int = bgStartAddress + ((tileY & 0x1f) << 5);
				while (screenX < screenRight)
				{
					if (bgWindowDataSelect)
					{
						tileNum = videoRamBanks[0].read(memStart + (tileX & 0x1f)) & 0xff;
					}
					else
					{
						tileNum = 256 + videoRamBanks[0].read(memStart + (tileX & 0x1f));
					}

					var tileAttrib:int = 0;
					if (cpu.gbcFeatures)
					{
						var mapAttrib:int = videoRamBanks[1].read(memStart + (tileX & 0x1f));
						tileAttrib += (mapAttrib & 0x07) << 2;
						tileAttrib += (mapAttrib >> 5) & 0x03;
						tileNum += 384 * ((mapAttrib >> 3) & 0x01);
					}
					tileX++;
					draw(tileNum, screenX, screenY, tileAttrib);
					screenX += 8;
				}
		
				if (screenY >= 136)
					screenFilled = true;
			}
			if (line == 143)
			{
				if (!screenFilled)
					notifyScanline(144);
				updateFrameBufferImage();
			}
		}
		
		private	function updateFrameBufferImage():void
		{
trace('updateFrameBufferImage');
			if (lcdEnabled)
			{
				if (winEnabledThisFrame)
				{
					var wx:int, wy:int;
					
					var windowStartAddress:int = hiWinTileMapAddress ? 0x1c00 : 0x1800;
		
					if (windowStopped)
					{
						wx = windowStopX;
						wy = windowStopY;
					}
					else
					{
						wx = (cpu.registers.read(0x4B) & 0xff) - 7;
						wy = (cpu.registers.read(0x4A) & 0xff);
					}

					if (!cpu.gbcFeatures)
					{
						var h:int = windowStopLine - wy;
						var w:int = 160 - wx;
						var rect:Rectangle = new Rectangle(((wx * tileWidth) >> 3), ((wy * tileHeight) >> 3), (w * tileWidth) >> 3, (h * tileHeight) >> 3);
						frameBuffer.fillRect(rect, gbPalette[0]);
					}
					
					var tileNum:int, tileAddress:int;
					var screenY:int = wy;
					
					var maxy:int = 19 - (wy >> 3);
					for (var y:int = 0 ; y < maxy ; y++)
					{
						if (wy + y * 8 >= windowStopLine)
							break;
						
						tileAddress = windowStartAddress + (y * 32);
						
						for (var screenX:int = wx ; screenX < 160 ; tileAddress++)
						{
							if (savedWindowDataSelect)
								tileNum = videoRamBanks[0].read(tileAddress) & 0xff;
							else
								tileNum = 256 + videoRamBanks[0].read(tileAddress);
							
							var tileAttrib:int = 0;
							if (cpu.gbcFeatures)
							{
								var mapAttrib:int = videoRamBanks[1].read(tileAddress);
								tileAttrib += (mapAttrib & 0x07) << 2;
								tileAttrib += (mapAttrib >> 5) & 0x03;
								tileNum += 384 * ((mapAttrib >> 3) & 0x01);
							}
							draw(tileNum, screenX, screenY, tileAttrib);
							screenX += 8;
						}
						screenY += 8;
					}
				}
				
				if (cpu.gbcFeatures)
					drawSprites(0x80);
				drawSprites(0);
			}
			else
			{
				frameBuffer.fillRect(new Rectangle(0,0, scaledWidth, scaledHeight), (cpu.gbcFeatures ? 0xFFFFFFFF : gbPalette[0]));
			}
			
			spritesEnabledThisFrame = spritesEnabled;
		}
		
		private	function updateImage(tileIndex:int, attribs:int):BitmapData
		{
trace('updateImage');
			var index:int = tileIndex + tileCount * attribs;
		
			var otherBank:Boolean = (tileIndex >= 384);
		
			var offset:int = otherBank ? ((tileIndex - 384) << 4) : (tileIndex << 4);
			
			var paletteStart:int = attribs & 0xfc;
			
			var vram:ByteArrayAdvanced = otherBank ? videoRamBanks[1] : videoRamBanks[0];
			var palette:Vector.<int> = cpu.gbcFeatures ? gbcPalette : gbPalette;
			var transparentPossible:Boolean = attribs >= transparentCutoff;
			
			var x2c:int, y2c:int, x2cstart:int;
			var croppedWidth:int, croppedHeight:int;
			var preshift:int = 0;
			var x:int, y:int, num:int;
			var bounds:Vector.<int>;
			if (!transparentPossible)
			{
				croppedWidth = tileWidth;
				croppedHeight = imageHeight;
				x2cstart = 4 - tileWidth;
				y2c = 4 - tileHeight;
			}
			else if (imageBounds[tileIndex] != null)
			{
				bounds = imageBounds[tileIndex];
				
				croppedWidth = bounds[4];
				croppedHeight = bounds[5];
				y2c = bounds[6];
				x2cstart = bounds[7];
				offset += bounds[8];
				preshift = bounds[9];
			}
			else
			{
				bounds = new Vector.<int>(10);
		
				bounds[0] = tileWidth;
				bounds[1] = imageHeight;
		
				var preoffset:int = offset;
				var mask:int = 0;
				y2c = 4 - tileHeight;
				for (y = 0; y < imageHeight; y++)
				{
					num = vram.read(preoffset) | vram.read(preoffset + 1);
					if (num != 0)
					{
						bounds[1] = Math.min(bounds[1], y);
						bounds[3] = y + 1;
					}
		
					mask |= num;
					
					y2c += 8;
					while (y2c > 0)
					{
						y2c -= tileHeight;
						preoffset += 2;
					}
				}
				x2c = 4 - tileWidth;
				for (x = tileWidth ; --x >= 0 ; )
				{
					if ((mask & 1) != 0)
					{
						bounds[0] = x;
						bounds[2] = Math.max(bounds[2], x + 1);
					}
		
					x2c += 8;
					while (x2c > 0)
					{
						x2c -= tileWidth;
						mask >>= 1;
					}
				}
				
				if (bounds[0] == tileWidth)
				{
					tileImage[index] = transparentImage;
					tileReadState[tileIndex] = true;
					return tileImage[index];
				}
		
				imageBounds[tileIndex] = bounds;
				
				bounds[2] = tileWidth - bounds[2];
				bounds[3] = imageHeight - bounds[3];
				bounds[4] = croppedWidth = tileWidth - bounds[2] - bounds[0];
				bounds[5] = croppedHeight = imageHeight - bounds[3] - bounds[1];
				
				x2cstart = 4 - tileWidth + (bounds[2] << 3);
				y2c = 4 - tileHeight + (bounds[1] << 3);
				while (y2c > 0)
				{
					y2c -= tileHeight;
					bounds[8] += 2;
				}
				while (x2cstart > 0)
				{
					x2cstart -= tileWidth;
					preshift += 2;
				}
				
				bounds[6] = y2c;
				bounds[7] = x2cstart;
				offset += bounds[8];
				bounds[9] = preshift;
			}
			
			var pixix:int = 0;
			var pixixdx:int = 1;
			var pixixdy:int = 0;
			
			if ((attribs & TILE_FLIPY) != 0)
			{
				pixixdy = -croppedWidth << 1;
				pixix = croppedWidth * (croppedHeight - 1);
			}
			
			if ((attribs & TILE_FLIPX) == 0)
			{
				pixixdx = -1;
				pixix += croppedWidth - 1;
				pixixdy += croppedWidth << 1;
			}
			
			var holemask:int = 0;
			for (y = croppedHeight ; --y >= 0 ; )
			{
				num = (weaveLookup[vram.read(offset) & 0xff] + (weaveLookup[vram.read(offset + 1) & 0xff] << 1)) >> preshift;
				
				x2c = x2cstart;
				for (x = croppedWidth ; --x >= 0 ; )
				{
					tempPix[pixix] = palette[paletteStart + (num & 3)];
					
					pixix += pixixdx;
					
					x2c += 8;
					while (x2c > 0)
					{
						x2c -= tileWidth;
						num >>= 2;
					}
				}
				pixix += pixixdy;
				
				y2c += 8;
				while (y2c > 0)
				{
					y2c -= tileHeight;
					holemask |= ~(vram.read(offset) | vram.read(offset + 1));
					offset += 2;
				}
			}
			
			if (holemask >> (preshift >> 1) == 0)
			{
				transparentPossible = false;
			}
			
			var bmp:BitmapData = new BitmapData(croppedWidth, croppedHeight, transparentPossible);
			bmp.setVector(bmp.rect, tempPix);
			tileImage[index] = bmp;
			
			tileReadState[tileIndex] = true;
			
			return tileImage[index];
		}
		
		private	function draw(tileIndex:int, x:int, y:int, attribs:int):void
		{
trace('draw');
			var ix:int = tileIndex + tileCount * attribs;
			
			var im:BitmapData = tileImage[ix];
			
			if (im == null)
				im = updateImage(tileIndex, attribs);
			
			if (im == transparentImage)
				return;
			
			if (scale)
			{
				y = (y * tileHeight) >> 3;
				x = (x * tileWidth) >> 3;
			}
			
			if (attribs >= transparentCutoff)
			{
				var bounds:Vector.<int> = imageBounds[tileIndex];
				frameBuffer.copyPixels(im, im.rect, new Point(x + bounds[(attribs & 1) << 1], y + bounds[1 + (attribs & 2)]));
			}
			else
			{
				frameBuffer.copyPixels(im, im.rect, new Point(x, y));
			}
		}
		
		override public	function stopWindowFromLine():void
		{
			windowStopped = true;
			windowStopLine = (cpu.registers.read(0x44) & 0xff);
			windowStopX = (cpu.registers.read(0x4B) & 0xff) - 7;
			windowStopY = (cpu.registers.read(0x4A) & 0xff);
		}
		
		override public	function setScale(screenWidth:int, screenHeight:int):void
		{
			var oldTW:int = tileWidth;
			var oldTH:int = tileHeight;
			
			tileWidth = screenWidth / 20;
			tileHeight = screenHeight / 18;
			
			if (Globals.keepProportions)
			{
				if (tileWidth < tileHeight)
					tileHeight = tileWidth;
				else
					tileWidth = tileHeight;
			}
			
			scale = tileWidth != 8 || tileHeight != 8;
			
			scaledWidth = tileWidth * 20;
			scaledHeight = tileHeight * 18;
			
			var r:int;
			if (tileWidth != oldTW || tileHeight != oldTH)
			{
				for (r = 0 ; r < tileImage.length ; r++)
					tileImage[r] = null;
				
				for (r = 0 ; r < tileReadState.length ; r++)
				{
					tileReadState[r] = false;
					imageBounds[r] = null;
				}
			}
			
			imageHeight = tileHeight;
			tempPix = new Vector.<int>(tileWidth * tileHeight * 2);
			frameBuffer = new BitmapData(scaledWidth, scaledHeight);
		}
	}
}