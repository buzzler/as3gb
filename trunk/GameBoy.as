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
		
		public	function openRTC(filename:String):Vector.<uint>
		{
/*
			try {
				if (findValue("RTC_" + filename) != null) {
					trace("Found a previous RTC state (Will attempt to load).", 0);
					return findValue("RTC_" + filename);
				}
				else {
					trace("Could not find any previous RTC copy for the current ROM.", 0);
				}
			}
			catch (error:Error) {
				trace("Could not open the RTC data of the saved emulation state.", 2);
			}
*/
			return new Vector.<uint>();
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
		
		public	function import_save(blobData:String):void
		{
/*
			blobData = decodeBlob(blobData);
			if (blobData && blobData.blobs) {
				if (blobData.blobs.length > 0) {
					for (var index = 0; index < blobData.blobs.length; ++index) {
						trace("Importing blob \"" + blobData.blobs[index].blobID + "\"", 0);
						if (blobData.blobs[index].blobContent) {
							if (blobData.blobs[index].blobID.substring(0, 5) == "SRAM_") {
								setValue("B64_" + blobData.blobs[index].blobID, base64(blobData.blobs[index].blobContent));
							}
							else {
								setValue(blobData.blobs[index].blobID, JSON.parse(blobData.blobs[index].blobContent));
							}
						}
						else if (blobData.blobs[index].blobID) {
							trace("Save file imported had blob \"" + blobData.blobs[index].blobID + "\" with no blob data interpretable.", 2);
						}
						else {
							trace("Blob chunk information missing completely.", 2);
						}
					}
				}
				else {
					trace("Could not decode the imported file.", 2);
				}
			}
			else {
				trace("Could not decode the imported file.", 2);
			}
*/
		}
		
		public	function generateBlob(keyName:String, encodedData:String):String
		{
			var saveString:String = "EMULATOR_DATA";
			var consoleID:String = "GameBoy";
			var totalLength:uint = (saveString.length + 4 + (1 + consoleID.length)) + ((1 + keyName.length) + (4 + encodedData.length));
/*			saveString += to_little_endian_dword(totalLength);
			saveString += to_byte(consoleID.length);
			saveString += consoleID;
			saveString += to_byte(keyName.length);
			saveString += keyName;
			saveString += to_little_endian_dword(encodedData.length);
			saveString += encodedData;*/
			return saveString;
		}
		
		public	function generateMultiBlob(blobPairs:Vector.<Vector.<String>>):String
		{
/*			var consoleID:String = "GameBoy";
			var totalLength:uint = 13 + 4 + 1 + consoleID.length;
			var saveString:String = to_byte(consoleID.length);
			saveString += consoleID;
			var keyName:String = "";
			var encodedData:String = "";
			for (var index:uint = 0; index < blobPairs.length; ++index) {
				keyName = blobPairs[index][0];
				encodedData = blobPairs[index][1];
				saveString += to_byte(keyName.length);
				saveString += keyName;
				saveString += to_little_endian_dword(encodedData.length);
				saveString += encodedData;
				totalLength += 1 + keyName.length + 4 + encodedData.length;
			}
			saveString = "EMULATOR_DATA" + to_little_endian_dword(totalLength) + saveString;
			return saveString;*/
			return "";
		}
		
		public	function decodeBlob(blobData:String):Object
		{
			var blength:uint = blobData.length;
			var blobProperties:Object = {};
			blobProperties.consoleID = null;
			var blobsCount:int = -1;
			blobProperties.blobs = [];
			if (blength > 17) {
				if (blobData.substring(0, 13) == "EMULATOR_DATA") {
					var length:uint = Math.min(((blobData.charCodeAt(16) & 0xFF) << 24) | ((blobData.charCodeAt(15) & 0xFF) << 16) | ((blobData.charCodeAt(14) & 0xFF) << 8) | (blobData.charCodeAt(13) & 0xFF), length);
					var consoleIDLength:uint = blobData.charCodeAt(17) & 0xFF;
					if (length > 17 + consoleIDLength) {
						blobProperties.consoleID = blobData.substring(18, 18 + consoleIDLength);
						var blobIDLength:uint = 0;
						var blobLength:uint = 0;
						for (var index:uint = 18 + consoleIDLength; index < length;) {
							blobIDLength = blobData.charCodeAt(index++) & 0xFF;
							if (index + blobIDLength < length) {
								blobProperties.blobs[++blobsCount] = {};
								blobProperties.blobs[blobsCount].blobID = blobData.substring(index, index + blobIDLength);
								index += blobIDLength;
								if (index + 4 < length) {
									blobLength = ((blobData.charCodeAt(index + 3) & 0xFF) << 24) | ((blobData.charCodeAt(index + 2) & 0xFF) << 16) | ((blobData.charCodeAt(index + 1) & 0xFF) << 8) | (blobData.charCodeAt(index) & 0xFF);
									index += 4;
									if (index + blobLength <= length) {
										blobProperties.blobs[blobsCount].blobContent =  blobData.substring(index, index + blobLength);
										index += blobLength;
									}
									else {
										trace("Blob length check failed, blob determined to be incomplete.", 2);
										break;
									}
								}
								else {
									trace("Blob was incomplete, bailing out.", 2);
									break;
								}
							}
							else {
								trace("Blob was incomplete, bailing out.", 2);
								break;
							}
						}
					}
				}
			}
			return blobProperties;
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