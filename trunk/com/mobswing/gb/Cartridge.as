package com.mobswing.gb
{
	import flash.utils.ByteArray;
	
	public class Cartridge
	{
		public	var rom:ByteArray;
		public	var ram:ByteArray;
		
		public function Cartridge(rom:ByteArray, ram:ByteArray = null)
		{
			this.rom = rom;
			this.ram = ram;
		}

	}
}