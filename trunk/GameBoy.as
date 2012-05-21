package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.net.FileReference;
	import flash.sensors.Accelerometer;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;

	public class GameBoy extends Bitmap
	{
		public	const WIDTH	:uint = 160;
		public	const HEIGHT:uint = 144;
		
		public	var gameboy			:GameBoyCore;
		public	var gbRunInterval	:uint;
		public	var settings		:Setting;
		
		public function GameBoy(setting:Setting = null)
		{
			super(new BitmapData(WIDTH,HEIGHT,false,0x0));
			this.settings = (setting!=null) ? setting:new Setting();

			this.addEventListener(Event.ADDED_TO_STAGE,		onAdded);
			this.addEventListener(Event.REMOVED_FROM_STAGE,	onRemoved);
		}
		
		private	function onAdded(event:Event):void
		{
			this.stage.addEventListener(KeyboardEvent.KEY_DOWN, this.GameBoyKeyDown);
			this.stage.addEventListener(KeyboardEvent.KEY_UP, this.GameBoyKeyUp);
		}
		
		private	function onRemoved(event:Event):void
		{
			this.stage.removeEventListener(KeyboardEvent.KEY_DOWN, this.GameBoyKeyDown);
			this.stage.removeEventListener(KeyboardEvent.KEY_UP, this.GameBoyKeyUp);
		}
		
		public	function start(ROM:ByteArray, SRAM:ByteArray = null):void
		{
			clearLastEmulation();
			gameboy = new GameBoyCore(this, ROM, SRAM);
			gameboy.start();
			run();
		}
		
		public	function run():void
		{
			if (GameBoyEmulatorInitialized()) {
				if (!GameBoyEmulatorPlaying()) {
					gameboy.stopEmulator &= 1;
					trace("Starting the iterator.", 0);
					gameboy.firstIteration = new Date().time;
					gameboy.iterations = 0;
					gbRunInterval = flash.utils.setInterval(function ():void {
						gameboy.run();
					}, settings.emulatorInterval);
				}
				else {
					trace("The GameBoy core is already running.", 1);
				}
			}
			else {
				trace("GameBoy core cannot run while it has not been initialized.", 1);
			}
		}
		
		public	function pause():void
		{
			if (GameBoyEmulatorInitialized()) {
				if (GameBoyEmulatorPlaying()) {
					clearLastEmulation();
				}
				else {
					trace("GameBoy core has already been paused.", 1);
				}
			}
			else {
				trace("GameBoy core cannot be paused while it has not been initialized.", 1);
			}
		}
		
		public	function clearLastEmulation():void
		{
			if (GameBoyEmulatorInitialized() && GameBoyEmulatorPlaying()) {
				flash.utils.clearInterval(gbRunInterval);
				gameboy.stopEmulator |= 2;
				trace("The previous emulation has been cleared.", 0);
			}
			else {
				trace("No previous emulation was found to be cleared.", 0);
			}
		}
		
		public	function saveState():ByteArray
		{
			if (GameBoyEmulatorInitialized()) {
				try {
					return gameboy.saveState();
				}
				catch (error:Error) {
					trace("Could not save the current emulation state(\"" + error.message + "\").", 2);
				}
			}
			else {
				trace("GameBoy core cannot be saved while it has not been initialized.", 1);
			}
			return new ByteArray();
		}
		
		public	function saveSRAM():ByteArray
		{
			if (GameBoyEmulatorInitialized()) {
				if (gameboy.cBATT) {
					try {
						return gameboy.saveSRAMState();
					}
					catch (error:Error) {
						trace("Could not save the current emulation state(\"" + error.message + "\").", 2);
					}
				}
				else {
					trace("Cannot save a game that does not have battery backed SRAM specified.", 1);
				}
			}
			else {
				trace("GameBoy core cannot be saved while it has not been initialized.", 1);
			}
			return new ByteArray();
		}
		
		public	function saveRTC():ByteArray
		{
			if (GameBoyEmulatorInitialized()) {
				if (gameboy.cTIMER) {
					try {
						return gameboy.saveRTCState();
					}
					catch (error:Error) {
						trace("Could not save the RTC of the current emulation state(\"" + error.message + "\").", 2);
					}
				}
			}
			else {
				trace("GameBoy core cannot be saved while it has not been initialized.", 1);
			}
			return new ByteArray();
		}
		
		public	function openSRAM(sram:ByteArray):void
		{
			try {
				var rom:ByteArray = gameboy.ROMImage;
				clearLastEmulation();
				gameboy = new GameBoyCore(this, rom, sram);
				run();
			}
			catch (error:Error) {
				trace("Could not open the  SRAM of the saved emulation state.", 2);
			}
		}
		
		public	function openRTC(rtc:ByteArray):void
		{
			try {
				gameboy.returnFromRTCState(rtc);
			}
			catch (error:Error) {
				trace("Could not open the RTC data of the saved emulation state.", 2);
			}

		}
		
		public	function openState(state:ByteArray, filename:String):void
		{
			try {
				var rom:ByteArray = gameboy.ROMImage;
				var sram:ByteArray = gameboy.SRAMImage;
				
				clearLastEmulation();
				trace("Attempting to run a saved emulation state.", 0);
				gameboy = new GameBoyCore(this, rom, sram);
				gameboy.savedStateFileName = filename;
				gameboy.returnFromState(state);
				run();
			}
			catch (error:Error) {
				trace("Could not open the saved emulation state.", 2);
			}
		}
		
		public	function GameBoyEmulatorInitialized():Boolean
		{
			return (gameboy != null);
		}
		
		public	function GameBoyEmulatorPlaying():Boolean
		{
			return ((gameboy.stopEmulator & 2) == 0);
		}
		
		public	function GameBoyKeyDown(e:KeyboardEvent):void
		{
			if (GameBoyEmulatorInitialized() && GameBoyEmulatorPlaying()) {
				var keycode:uint = settings.matchKey(e.keyCode);
				if (keycode >= 0 && keycode < 8) {
					gameboy.JoyPadEvent(keycode, true);
					try {
						e.preventDefault();
					}
					catch (error:Error) { }
				}
			}
		}
		
		public	function GameBoyKeyUp(e:KeyboardEvent):void
		{
			if (GameBoyEmulatorInitialized() && GameBoyEmulatorPlaying()) {
				var keycode:uint = settings.matchKey(e.keyCode);
				if (keycode >= 0 && keycode < 8) {
					gameboy.JoyPadEvent(keycode, false);
					try {
						e.preventDefault();
					}
					catch (error:Error) { }
				}
			}
		}
	}
}