package com.mobswing.gb
{
	import flash.utils.getTimer;

	public class SystemTimer
	{
		private	static var startTime:Number = new Date().time;
		
		public	static function getCurrentTimeMillis():Number
		{
			return startTime + getTimer();
		}

		public function SystemTimer()
		{
		}

	}
}