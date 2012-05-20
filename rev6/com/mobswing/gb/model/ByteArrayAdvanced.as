package com.mobswing.gb.model
{
	import flash.utils.ByteArray;

	public class ByteArrayAdvanced extends ByteArray
	{
		public function ByteArrayAdvanced(length:int)
		{
			super();
			this.length = length;
		}

		public	function write(index:int, value:int):void
		{
			this.position = index;
			this.writeByte(value);
		}
		
		public	function read(index:int):int
		{
			this.position = index;
			return this.readByte();
		}
	}
}