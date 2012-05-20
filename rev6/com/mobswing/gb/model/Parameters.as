package com.mobswing.gb.model
{
	import flash.system.System;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	public class Parameters
	{
		public	static var ROMIMAGE:String = 'game.gb';
		public	static var ROMFILE:ByteArray;
		public	static var SRAMFILE:ByteArray;
		public	static var SAVERAMURL:String;
		public	static var SOUND:Boolean = false;
		
		public	static var viewSpeedThrottle:Boolean;
		
		private static var bootTime:Number;
		
		public function Parameters()
		{
			bootTime = new Date().time;
		}

		public	static function get getCurrentTime():Number
		{
			return bootTime + getTimer(); 
		}
	}
}