package com.mobswing.gb
{
	import __AS3__.vec.Vector;
	
	import flash.utils.ByteArray;
	
	public class Globals
	{
		public	static const RES_WIDTH	:int = 160;
		public	static const RES_HEIGHT	:int = 144;
		
		public	static var gb		:As3gb		= null;
		public	static var cpu		:CPU		= null;
		public	static var ppu		:PPU		= null;
		public	static var cartridge:Cartridge	= null;
		
		public	static var advancedGraphics		:Boolean= false;
		public	static var enableSound			:Boolean= false;
		public	static var disableColor			:Boolean= false;
		public	static var lazyLoadingThreshold	:int	= 512;
		public	static var maxFrameSkip			:int	= 9;
		public	static var keepProportions		:Boolean= true;
		public	static var scalingMode			:int	= 0;
		
		public function Globals()
		{
		}

		public	static function arraycopyInt(src:Vector.<int>, srcos:int, dst:Vector.<int>, dstos:int, len:int):void
		{
			for (var i:int = 0 ; i < len ; i++)
			{
				dst[dstos + i] = src[srcos + i];
			}
		}
		
		public	static function arraycopyByteArray(src:ByteArray, srcos:int, dst:Vector.<int>, dstos:int, len:int):void
		{
			var tmp:int = src.position;
			src.position = srcos;
			for (var i:int = 0 ; i < len ; i++)
			{
				dst[dstos + i] = src.readByte();
			}
			src.position = tmp;
		}
		
		public	static function convert2Vector(src:ByteArray):Vector.<int>
		{
			var result:Vector.<int> = new Vector.<int>(src.length);
			arraycopyByteArray(src,0,result,0,src.length);
			
			return result;
		}
		
		public	static function convert2ByteArray(src:Vector.<int>):ByteArray
		{
			var result:ByteArray = new ByteArray();
			for (var i:int = 0 ; i < src.length ; i++)
			{
				result.writeByte(src[i]);
			}
			result.position = 0;
			
			return result;
		} 
		
		public	static function arraycopyBoolean(src:Vector.<Boolean>, srcos:int, dst:Vector.<Boolean>, dstos:int, len:int):void
		{
			for (var i:int = 0 ; i < len ; i++)
			{
				dst[dstos + i] = src[srcos + i];
			}
		}
	}
}