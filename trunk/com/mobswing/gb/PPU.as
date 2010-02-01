package com.mobswing.gb
{
	import __AS3__.vec.Vector;
	
	import flash.display.BitmapData;
	
	public class PPU
	{
		protected var MS_PER_FRAME		:int = 17;
		protected var TILE_FLIPX		:int = 1;
		protected var TILE_FLIPY		:int = 2;
		protected var videoRam			:ByteArrayAdvanced;			//byte array
		protected var videoRamBanks		:Vector.<ByteArrayAdvanced>;	//2d byte array
		protected var colors			:Vector.<int>;
		protected var gbPalette			:Vector.<int> = new Vector.<int>(12);
		protected var gbcRawPalette		:Vector.<int> = new Vector.<int>(128);
		protected var gbcPalette		:Vector.<int> = new Vector.<int>(64);
		protected var gbcMask			:int;
		protected var transparentCutoff	:int;
		protected var skipping			:Boolean = true;
		protected var frameCount		:int;
		protected var skipCount			:int;
		protected var tileOffset		:int;
		protected var tileCount			:int;
		protected var colorCount		:int;
		protected var scale				:Boolean;
		protected var cpu				:CPU;
		protected var spritesEnabled	:Boolean = true;
		protected var doubledSprites	:Boolean = false;
		protected var winEnabled		:Boolean = true;
		protected var bgWindowDataSelect:Boolean = true;
		protected var bgEnabled			:Boolean = true;
		protected var hiBgTileMapAddress:Boolean = false;
		protected var lcdEnabled		:Boolean = true;
		protected var hiWinTileMapAddress:Boolean = false;
		
		public	var spritePriorityEnabled	:Boolean = true;
		private	var frameDone				:Boolean = true;		
		public	var lastSkipCount			:int;
		public	var timer					:int;
		public	var scaledWidth				:int = 160;
		public	var scaledHeight			:int = 144;
		public	var frameBuffer				:BitmapData;
		
		protected static var weaveLookup:Vector.<int> = new Vector.<int>(256);

		public	function PPU()
		{
			var i:int;

			if (weaveLookup == null)
			{
				for (i = 1; i < 256; i++)
				{
					weaveLookup[i] = 0;
					for (var d:int = 0; d < 8; d++)
						weaveLookup[i] += ((i >> d) & 1) << (d * 2);
				}
			}
			
			this.cpu = Globals.cpu;
			if (cpu.gbcFeatures)
			{
				videoRamBanks = new Vector.<ByteArrayAdvanced>(2);
				for (i = 0 ; i < videoRamBanks.length ; i++)
				{
					videoRamBanks[i] = new ByteArrayAdvanced(0x2000);
				}
				tileCount = 384*2;
				colorCount = 64;
			}
			else
			{
				videoRamBanks = new Vector.<ByteArrayAdvanced>(1);
				for (i = 0 ; i < videoRamBanks.length ; i++)
				{
					videoRamBanks[i] = new ByteArrayAdvanced(0x2000);
				}
				tileCount = 384;
				colorCount = 12;
			}
			
			videoRam = videoRamBanks[0];
			cpu.memory[4] = videoRam;
			
			scale = false;
			
			for (i = 0; i < gbcRawPalette.length; i++)
				gbcRawPalette[i] = -1000;
			for (i = 0; i < (gbcPalette.length >> 1); i++)
				gbcPalette[i] = -1;
			for (i = (gbcPalette.length >> 1); i < gbcPalette.length; i++)
				gbcPalette[i] = 0;
		}

		public	function UpdateLCDCFlags(data:int):void
		{
			bgEnabled = true;
					
			lcdEnabled = ((data & 0x80) != 0);
					
			hiWinTileMapAddress = ((data & 0x40) != 0);
		
			winEnabled = ((data & 0x20) != 0);
		
			bgWindowDataSelect = ((data & 0x10) != 0);
		
			hiBgTileMapAddress = ((data & 0x08) != 0);
		
			doubledSprites = ((data & 0x04) != 0);
		
			spritesEnabled = ((data & 0x02) != 0);
		
			if (cpu.gbcFeatures)
			{
				spritePriorityEnabled = ((data & 0x01) != 0);
			}
			else
			{
				if ((data & 0x01) == 0)
				{
					bgEnabled = false;
					winEnabled = false;
				}
			}
		}
		
		public	function vBlank():void
		{
			timer += MS_PER_FRAME;
			
			frameCount++;
			
			if (skipping)
			{
				skipCount++;
				if (skipCount >= Globals.maxFrameSkip)
				{
					skipping = false;
					var lag:int = SystemTimer.getCurrentTimeMillis() - timer;
					
					if (lag > MS_PER_FRAME)
						timer += lag - MS_PER_FRAME;
				}
				else
				{
					skipping = (timer - (SystemTimer.getCurrentTimeMillis()) < 0);
				}
				return;
			}
			
			lastSkipCount = skipCount;
			frameDone = false;
			Globals.gb.paint();
			
			var now:int = SystemTimer.getCurrentTimeMillis();
			
			if (Globals.maxFrameSkip == 0)
				skipping = false;
			else
				skipping = timer - now < 0;
			
			while (timer > now + MS_PER_FRAME)
			{
				//Thread.sleep(1);
				now = SystemTimer.getCurrentTimeMillis();
			}
			
			while (!frameDone && !cpu.isTerminated())
			{
				//Thread.yield();
			}
			skipCount = 0;
		}
		
		public	function decodePalette(startIndex:int, data:int):void
		{
			for (var i:int = 0; i < 4; i++)
				gbPalette[startIndex + i] = colors[((data >> (2 * i)) & 0x03)];
			gbPalette[startIndex] &= 0x00ffffff;
		}
		
		public	function setGBCPalette(index:int, data:int):void
		{
			if (gbcRawPalette[index] == data)
				return;
			
			gbcRawPalette[index] = data;
			if (index >= 0x40 && (index & 0x6) == 0)
				return;
			
			var value:int = (gbcRawPalette[index | 1] << 8) + gbcRawPalette[index & -2];
			
			gbcPalette[index >> 1] = gbcMask + ((value & 0x001F) << 19) + ((value & 0x03E0) << 6) + ((value & 0x7C00) >> 7);
		
			invalidateAll(index >> 3);
		}
		
		public	function getGBCPalette(index:int):int
		{
			return gbcRawPalette[index];
		}
		
		public	function setVRamBank(value:int):void
		{
			tileOffset = value * 384;
			videoRam = videoRamBanks[value];
			cpu.memory[4] = videoRam;
		}
		
		public	function notifyRepainted():void
		{
			frameDone = true;
		}
		
		public	function stopWindowFromLine():void
		{
		}
		
		public	function setScale(screenWidth:int, screenHeight:int):void
		{
		}
		
		public	function addressWrite(addr:int, data:int):void
		{
		}
		
		public	function invalidateAll(pal:int):void
		{
		}
		
		public	function notifyScanline(line:int):void
		{
		}
	}
}