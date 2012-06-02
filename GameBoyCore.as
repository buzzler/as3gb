package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.System;
	import flash.utils.ByteArray;

	public class GameBoyCore
	{
		//Params, etc...
		public	var gb				:GameBoy;
		public	var settings		:Setting;
		public	var ROMImage		:ByteArray;
		public	var SRAMImage		:ByteArray;
		//CPU Registers and Flags:
		public	var registerA		:uint;
		public	var registerB		:uint;
		public	var registerC		:uint;
		public	var registerD		:uint;
		public	var registerE		:uint;
		public	var registersHL		:uint;
		public	var FZero			:Boolean;
		public	var FSubtract		:Boolean;
		public	var FHalfCarry		:Boolean;
		public	var FCarry			:Boolean;
		public	var stackPointer	:uint;
		public	var programCounter	:uint;
		//Some CPU Emulation State Variables:
		public	var CPUCyclesPerIteration		:Number;
		public	var CPUCyclesTotal				:Number;
		public	var CPUCyclesTotalBase			:Number;
		public	var CPUCyclesTotalCurrent		:Number;
		public	var CPUCyclesTotalRoundoff		:Number;
		public	var baseCPUCyclesPerIteration	:Number;
		public	var remainingClocks				:Number;
		public	var inBootstrap					:Boolean;
		public	var usedBootROM					:Boolean;
		public	var usedGBCBootROM				:Boolean;
		public	var halt						:Boolean;
		public	var skipPCIncrement				:Boolean;
		public	var stopEmulator				:uint;
		public	var IME							:Boolean;
		public	var IRQLineMatched				:uint;
		public	var interruptsRequested			:uint;
		public	var interruptsEnabled			:uint;
		public	var hdmaRunning					:Boolean;
		public	var CPUTicks					:uint;
		public	var doubleSpeedShifter			:uint;
		public	var JoyPad						:uint;
		//Main RAM, MBC RAM, GBC Main RAM, VRAM, etc.
		public	var memoryReader				:Vector.<Function>;
		public	var memoryWriter				:Vector.<Function>;
		public	var memoryHighReader			:Vector.<Function>;
		public	var memoryHighWriter			:Vector.<Function>;
		public	var ROM							:Vector.<uint>;
		public	var memory						:Vector.<uint>;
		public	var MBCRam						:Vector.<uint>;
		public	var VRAM						:Vector.<uint>;
		public	var GBCMemory					:Vector.<uint>;
		public	var MBC1Mode					:Boolean;
		public	var MBCRAMBanksEnabled			:Boolean;
		public	var currMBCRAMBank				:uint;
		public	var currMBCRAMBankPosition		:int;
		public	var cGBC						:Boolean;
		public	var gbcRamBank					:uint;
		public	var gbcRamBankPosition			:int;
		public	var gbcRamBankPositionECHO		:int;
		public	var RAMBanks					:Vector.<uint>;
		public	var ROMBank1offs				:uint;
		public	var currentROMBank				:int;
		public	var cartridgeType				:uint;
		public	var name						:String;
		public	var gameCode					:String;
		public	var fromSaveState				:Boolean;
		public	var savedStateFileName			:String;
		public	var STATTracker					:uint;
		public	var modeSTAT					:uint;
		public	var spriteCount					:uint;
		public	var LYCMatchTriggerSTAT			:Boolean;
		public	var mode2TriggerSTAT			:Boolean;
		public	var mode1TriggerSTAT			:Boolean;
		public	var mode0TriggerSTAT			:Boolean;
		public	var LCDisOn						:Boolean;
		public	var LINECONTROL					:Vector.<Function>;
		public	var DISPLAYOFFCONTROL			:Vector.<Function>;
		public	var LCDCONTROL					:Vector.<Function>;
		//RTC (Real Time Clock for MBC3):
		public	var RTCisLatched				:Boolean;
		public	var latchedSeconds				:uint;
		public	var latchedMinutes				:uint;
		public	var latchedHours				:uint;
		public	var latchedLDays				:uint;
		public	var latchedHDays				:uint;
		public	var RTCSeconds					:uint;
		public	var RTCMinutes					:uint;
		public	var RTCHours					:uint;
		public	var RTCDays						:uint;
		public	var RTCDayOverFlow				:Boolean;
		public	var RTCHALT						:Boolean;
		//Gyro:
		public	var highX	:uint;
		public	var lowX	:uint;
		public	var highY	:uint;
		public	var lowY	:uint;
		//Sound variables:
		public	var audioHandle					:APU;
		public	var numSamplesTotal				:uint;
		public	var	sampleSize					:Number;
		public	var dutyLookup					:Vector.<Number>;
		public	var currentBuffer				:Vector.<Number>;
		public	var bufferContainAmount			:uint;
		public	var LSFR15Table					:Vector.<Number>;
		public	var LSFR7Table					:Vector.<Number>;
		public	var noiseSampleTable			:Vector.<Number>;
		public	var noiseTableLength			:uint;
		public	var soundMasterEnabled			:Boolean;
		public	var channel3PCM					:Vector.<Number>;
		//Vin Shit:
		public	var VinLeftChannelMasterVolume	:Number;
		public	var VinRightChannelMasterVolume	:Number;
		//Channel paths enabled:
		public	var leftChannel0	:Boolean;
		public	var leftChannel1	:Boolean;
		public	var leftChannel2	:Boolean;
		public	var leftChannel3	:Boolean;
		public	var rightChannel0	:Boolean;
		public	var rightChannel1	:Boolean;
		public	var rightChannel2	:Boolean;
		public	var rightChannel3	:Boolean;
		//Current Samples Being Computed:
		public	var currentSampleLeft	:Number;
		public	var currentSampleRight	:Number;
		//Pre-multipliers to cache some calculations:
		public	var samplesOut			:Number;
		public	var machineOut			:Number;
		//Audio generation counters:
		public	var audioTicks			:Number;
		public	var audioIndex			:int;
		public	var rollover			:int;
		//Timing Variables
		public	var emulatorTicks				:uint;
		public	var DIVTicks					:uint;
		public	var LCDTicks					:uint;
		public	var timerTicks					:uint;
		public	var TIMAEnabled					:Boolean;
		public	var TACClocker					:uint;
		public	var serialTimer					:uint;
		public	var serialShiftTimer			:uint;
		public	var serialShiftTimerAllocated	:uint;
		public	var IRQEnableDelay				:uint;
		public	var lastIteration				:Number;
		public	var firstIteration				:Number;
		public	var iterations					:uint;
		public	var actualScanLine				:uint;
		public	var lastUnrenderedLine			:uint;
		public	var queuedScanLines				:uint;
		public	var totalLinesPassed			:uint;
		public	var haltPostClocks				:uint;
		//ROM Cartridge Components:
		public	var cBATT		:Boolean;
		public	var cMBC1		:Boolean;
		public	var cMBC2		:Boolean;
		public	var cMBC3		:Boolean;
		public	var cMBC5		:Boolean;
		public	var cMBC7		:Boolean;
		public	var cSRAM		:Boolean;
		public	var cMMMO1		:Boolean;
		public	var cRUMBLE		:Boolean;
		public	var cCamera		:Boolean;
		public	var cTAMA5		:Boolean;
		public	var cHuC3		:Boolean;
		public	var cHuC1		:Boolean;
		public	var cTIMER		:Boolean;
		public	var ROMBanks	:Vector.<uint>;
		public	var ROMBankEdge	:uint;
		public	var numRAMBanks	:uint;
		public	var numROMBanks	:uint;
		////Graphics Variables
		public	var currVRAMBank				:uint;
		public	var backgroundX					:int;
		public	var backgroundY					:int;
		public	var gfxWindowDisplay			:Boolean;
		public	var gfxSpriteShow				:Boolean;
		public	var gfxSpriteNormalHeight		:Boolean;
		public	var bgEnabled					:Boolean;
		public	var BGPriorityEnabled			:Boolean;
		public	var gfxWindowCHRBankPosition	:uint;
		public	var gfxBackgroundCHRBankPosition:uint;
		public	var gfxBackgroundBankOffset		:uint;
		public	var windowY						:int;
		public	var windowX						:int;
		public	var drewBlank					:int;
		public	var drewFrame					:Boolean;
		public	var midScanlineOffset			:int;
		public	var pixelEnd					:int;
		public	var currentX					:int;
		//BG Tile Pointer Caches:
		public	var BGCHRBank1					:Vector.<uint>;
		public	var BGCHRBank2					:Vector.<uint>;
		public	var BGCHRCurrentBank			:Vector.<uint>;
		//Tile Data Cache:
		public	var tileCache					:Vector.<Vector.<uint>>;
		//Palettes:
		public	var colors						:Vector.<uint>;
		public	var OBJPalette					:Vector.<int>;
		public	var BGPalette					:Vector.<int>;
		public	var gbcOBJRawPalette			:Vector.<uint>;
		public	var gbcBGRawPalette				:Vector.<uint>;
		public	var gbOBJPalette				:Vector.<int>;
		public	var gbBGPalette					:Vector.<int>;
		public	var gbcOBJPalette				:Vector.<int>;
		public	var gbcBGPalette				:Vector.<int>;
		public	var gbBGColorizedPalette		:Vector.<int>;
		public	var gbOBJColorizedPalette		:Vector.<int>;
		public	var cachedBGPaletteConversion	:Vector.<int>;
		public	var cachedOBJPaletteConversion	:Vector.<int>;
		public	var updateGBBGPalette			:Function;
		public	var updateGBOBJPalette			:Function;
		public	var colorizedGBPalettes			:Boolean;
		public	var BGLayerRender				:Function;
		public	var WindowLayerRender			:Function;
		public	var SpriteLayerRender			:Function;
		public	var frameBuffer					:Vector.<int>;
		public	var swizzledFrame				:Vector.<uint>;
		public	var canvasBuffer				:BitmapData;
		public	var pixelStart					:uint;
		//Variables used for scaling in JS:
		public	var onscreenWidth				:uint;
		public	var onscreenHeight				:uint;
		public	var offscreenWidth				:uint;
		public	var offscreenHeight				:uint;
		public	var offscreenRGBCount			:uint;
		//Channels...
		public	var channel1adjustedFrequencyPrep	:Number;
		public	var channel1adjustedDuty			:Number;
		public	var channel1totalLength				:Number;
		public	var channel1envelopeVolume			:uint;
		public	var channel1currentVolume			:Number;
		public	var channel1envelopeType			:Boolean;
		public	var channel1envelopeSweeps			:uint;
		public	var channel1consecutive				:Boolean;
		public	var channel1frequency				:uint;
		public	var channel1Fault					:uint;
		public	var channel1ShadowFrequency			:uint;
		public	var channel1volumeEnvTime			:Number;
		public	var channel1volumeEnvTimeLast		:Number;
		public	var channel1timeSweep				:Number;
		public	var channel1lastTimeSweep			:Number;
		public	var channel1numSweep				:uint;
		public	var channel1frequencySweepDivider	:uint;
		public	var channel1decreaseSweep			:Boolean;
		public	var channel2adjustedFrequencyPrep	:Number;
		public	var channel2adjustedDuty			:Number;
		public	var channel2totalLength				:Number;
		public	var channel2envelopeVolume			:uint;
		public	var channel2currentVolume			:Number;
		public	var channel2envelopeType			:Boolean;
		public	var channel2envelopeSweeps			:uint;
		public	var channel2consecutive				:Boolean;
		public	var channel2frequency				:uint;
		public	var channel2volumeEnvTime			:Number;
		public	var channel2volumeEnvTimeLast		:Number;
		public	var channel3canPlay					:Boolean;
		public	var channel3totalLength				:Number;
		public	var channel3patternType				:uint;
		public	var channel3frequency				:uint;
		public	var channel3consecutive				:Boolean;
		public	var channel3adjustedFrequencyPrep	:Number;
		public	var channel4adjustedFrequencyPrep	:Number;
		public	var channel4totalLength				:Number;
		public	var channel4envelopeVolume			:uint;
		public	var channel4currentVolume			:Number;
		public	var channel4envelopeType			:Boolean;
		public	var channel4envelopeSweeps			:uint;
		public	var channel4consecutive				:Boolean;
		public	var channel4volumeEnvTime			:Number;
		public	var channel4volumeEnvTimeLast		:Number;
		public	var channel4VolumeShifter			:uint;
		public	var channel1lastSampleLookup		:Number;
		public	var channel2lastSampleLookup		:Number;
		public	var channel3Tracker					:uint;
		public	var channel4lastSampleLookup		:Number;
		public	var preChewedAudioComputationMultiplier		:Number;
		public	var preChewedWAVEAudioComputationMultiplier	:Number;
		public	var whiteNoiseFrequencyPreMultiplier		:Number;
		public	var volumeEnvelopePreMultiplier				:Number;
		public	var channel1TimeSweepPreMultiplier			:Number;
		public	var audioTotalLengthMultiplier				:Number;
		
		public	var GBBOOTROM			:Vector.<uint>;
		public	var GBCBOOTROM			:Vector.<uint>;
		public	var ffxxDump			:Vector.<uint>;
		public	var OPCODE				:Vector.<Function>;
		public	var CBOPCODE			:Vector.<Function>;
		public	var TICKTable			:Vector.<uint>;
		public	var SecondaryTICKTable	:Vector.<uint>;
		public	var canvasOnscreen		:BitmapData;
		public	var soundChannelsAllocated	:uint;
		public	var soundFrameShifter		:uint;
		public	var sortBuffer			:Vector.<uint>;
		public	var OAMAddressCache		:Vector.<int>;
		public	var rect				:Rectangle;
		public	var dest				:Point;
		
		public function GameBoyCore(gb:GameBoy, ROM:ByteArray, SRAM:ByteArray = null)
		{
			this.gb				= gb;
			this.settings		= gb.settings;
			this.ROMImage		= ROM;
			this.SRAMImage		= (SRAM != null) ? SRAM:new ByteArray();
			this.rect			= new Rectangle(0,0,gb.WIDTH,gb.HEIGHT);
			this.dest			= new Point();
			this.registerA		= 0x01;
			this.registerB		= 0x00;
			this.registerC		= 0x13;
			this.registerD		= 0x00;
			this.registerE		= 0xD8;
			this.registersHL	= 0x014D;
			this.FZero			= true;
			this.FSubtract		= false;
			this.FHalfCarry		= true;
			this.FCarry			= true;
			this.stackPointer	= 0xFFFE;
			this.programCounter	= 0x0100;
			this.CPUCyclesPerIteration		= 0;
			this.CPUCyclesTotal				= 0;
			this.CPUCyclesTotalBase			= 0;
			this.CPUCyclesTotalCurrent		= 0;
			this.CPUCyclesTotalRoundoff		= 0;
			this.baseCPUCyclesPerIteration	= 0;
			this.remainingClocks			= 0;
			this.inBootstrap	= true;
			this.usedBootROM	= false;
			this.usedGBCBootROM	= false;
			this.halt			= false;
			this.skipPCIncrement= false;
			this.stopEmulator	= 3;
			this.IME			= true;
			this.IRQLineMatched		= 0;
			this.interruptsRequested= 0;
			this.interruptsEnabled	= 0;
			this.hdmaRunning		= false;
			this.CPUTicks			= 0;
			this.doubleSpeedShifter	= 0;
			this.JoyPad				= 0xFF;
			this.memoryReader		= new Vector.<Function>();
			this.memoryWriter		= new Vector.<Function>();
			this.memoryHighReader	= new Vector.<Function>();
			this.memoryHighWriter	= new Vector.<Function>();
			this.ROM				= new Vector.<uint>();
			this.memory				= new Vector.<uint>();
			this.MBCRam				= new Vector.<uint>();
			this.VRAM				= new Vector.<uint>();
			this.GBCMemory			= new Vector.<uint>();
			this.MBC1Mode				= false;
			this.MBCRAMBanksEnabled		= false;
			this.currMBCRAMBank			= 0;
			this.currMBCRAMBankPosition	= -0xA000;
			this.cGBC					= false;
			this.gbcRamBank				= 1;
			this.gbcRamBankPosition		= -0xD000;
			this.gbcRamBankPositionECHO	= -0xF000;
			this.RAMBanks				= toVector([0, 1, 2, 4, 16], "uint");
			this.ROMBank1offs			= 0;
			this.currentROMBank			= 0;
			this.cartridgeType			= 0;
			this.name					= "";
			this.gameCode				= "";
			this.fromSaveState			= false;
			this.savedStateFileName		= "";
			this.STATTracker			= 0;
			this.modeSTAT 				= 0;
			this.spriteCount			= 252;
			this.LYCMatchTriggerSTAT	= false;
			this.mode2TriggerSTAT		= false;
			this.mode1TriggerSTAT		= false;
			this.mode0TriggerSTAT		= false;
			this.LCDisOn				= false;
			this.LINECONTROL			= new Vector.<Function>();
			this.DISPLAYOFFCONTROL		= toVector([function ():void {}], "function");
			this.LCDCONTROL				= null;
			this.initializeLCDController();
			this.RTCisLatched	= false;
			this.latchedSeconds	= 0;
			this.latchedMinutes	= 0;
			this.latchedHours	= 0;
			this.latchedLDays	= 0;
			this.latchedHDays	= 0;
			this.RTCSeconds		= 0;
			this.RTCMinutes		= 0;
			this.RTCHours		= 0;
			this.RTCDays		= 0;
			this.RTCDayOverFlow	= false;
			this.RTCHALT		= false;
			this.highX			= 127;
			this.lowX			= 127;
			this.highY			= 127;
			this.lowY			= 127;
			this.audioHandle			= null;
			this.numSamplesTotal		= 0;
			this.sampleSize				= 0;
			this.dutyLookup				= toVector([0.125, 0.25, 0.5, 0.75], "number");
			this.currentBuffer			= new Vector.<Number>()
			this.bufferContainAmount	= 0;
			this.LSFR15Table			= null;
			this.LSFR7Table				= null;
			this.noiseSampleTable		= null;
			this.initializeAudioStartState();
			this.soundMasterEnabled		= false;
			this.channel3PCM			= null;
			this.VinLeftChannelMasterVolume	= 1;
			this.VinRightChannelMasterVolume= 1;
			this.leftChannel0			= false;
			this.leftChannel1			= false;
			this.leftChannel2			= false;
			this.leftChannel3			= false;
			this.rightChannel0			= false;
			this.rightChannel1			= false;
			this.rightChannel2			= false;
			this.rightChannel3			= false;
			this.currentSampleLeft		= 0;
			this.currentSampleRight		= 0;
			this.initializeTiming();
			this.samplesOut				= 0;
			this.machineOut				= 0;
			this.audioTicks				= 0;
			this.audioIndex				= 0;
			this.rollover				= 0;
			this.emulatorTicks				= 0;
			this.DIVTicks					= 56;
			this.LCDTicks					= 60;
			this.timerTicks					= 0;
			this.TIMAEnabled				= false;
			this.TACClocker					= 1024;
			this.serialTimer				= 0;
			this.serialShiftTimer			= 0;
			this.serialShiftTimerAllocated	= 0;
			this.IRQEnableDelay				= 0;
			this.lastIteration				= new Date().time;
			this.firstIteration				= new Date().time;
			this.iterations					= 0;
			this.actualScanLine				= 0;
			this.lastUnrenderedLine			= 0;
			this.queuedScanLines			= 0;
			this.totalLinesPassed			= 0;
			this.haltPostClocks				= 0;
			this.cBATT			= false;
			this.cMBC1			= false;
			this.cMBC2			= false;
			this.cMBC3			= false;
			this.cMBC5			= false;
			this.cMBC7			= false;
			this.cSRAM			= false;
			this.cMMMO1			= false;
			this.cRUMBLE		= false;
			this.cCamera		= false;
			this.cTAMA5			= false;
			this.cHuC3			= false;
			this.cHuC1			= false;
			this.cTIMER			= false;
			this.ROMBanks		= new Vector.<uint>(0x55);
			this.ROMBanks[0x00]	= 2;
			this.ROMBanks[0x01]	= 4;
			this.ROMBanks[0x02]	= 8;
			this.ROMBanks[0x03]	= 16;
			this.ROMBanks[0x04]	= 32;
			this.ROMBanks[0x05]	= 64;
			this.ROMBanks[0x06]	= 128;
			this.ROMBanks[0x07]	= 256;
			this.ROMBanks[0x08]	= 512;
			this.ROMBanks[0x52]	= 72;
			this.ROMBanks[0x53]	= 80;
			this.ROMBanks[0x54]	= 96;
			this.numRAMBanks	= 0;
			this.currVRAMBank					= 0;
			this.backgroundX					= 0;
			this.backgroundY					= 0;
			this.gfxWindowDisplay				= false;
			this.gfxSpriteShow					= false;
			this.gfxSpriteNormalHeight			= true;
			this.bgEnabled						= true;
			this.BGPriorityEnabled				= true;
			this.gfxWindowCHRBankPosition		= 0;
			this.gfxBackgroundCHRBankPosition	= 0;
			this.gfxBackgroundBankOffset		= 0x80;
			this.windowY						= 0;
			this.windowX						= 0;
			this.drewBlank						= 0;
			this.drewFrame						= false;
			this.midScanlineOffset				= -1;
			this.pixelEnd						= 0;
			this.currentX						= 0;
			this.BGCHRBank1						= null;
			this.BGCHRBank2						= null;
			this.BGCHRCurrentBank				= null;
			this.tileCache						= null;
			this.colors							= toVector([0xEFFFDE, 0xADD794, 0x529273, 0x183442], "uint");
			this.OBJPalette						= null;
			this.BGPalette						= null;
			this.gbcOBJRawPalette				= null;
			this.gbcBGRawPalette				= null;
			this.gbOBJPalette					= null;
			this.gbBGPalette					= null;
			this.gbcOBJPalette					= null;
			this.gbcBGPalette					= null;
			this.gbBGColorizedPalette			= null;
			this.gbOBJColorizedPalette			= null;
			this.cachedBGPaletteConversion		= null;
			this.cachedOBJPaletteConversion		= null;
			this.updateGBBGPalette				= this.updateGBRegularBGPalette;
			this.updateGBOBJPalette				= this.updateGBRegularOBJPalette;
			this.colorizedGBPalettes			= false;
			this.BGLayerRender					= null;
			this.WindowLayerRender				= null;
			this.SpriteLayerRender				= null;
			this.frameBuffer					= new Vector.<int>();
			this.swizzledFrame					= null;
			this.canvasBuffer					= null;
			this.pixelStart						= 0;
			this.onscreenWidth					= gb.WIDTH;
			this.offscreenWidth					= gb.WIDTH;
			this.onscreenHeight					= gb.HEIGHT;
			this.offscreenHeight				= gb.HEIGHT;
			this.offscreenRGBCount				= this.onscreenWidth * this.onscreenHeight * 4;
			this.intializeWhiteNoise();
			
			this.GBBOOTROM = toVector([
				0x31, 0xFE, 0xFF, 0xAF, 0x21, 0xFF, 0x9F, 0x32,		0xCB, 0x7C, 0x20, 0xFB, 0x21, 0x26, 0xFF, 0x0E,
				0x11, 0x3E, 0x80, 0x32, 0xE2, 0x0C, 0x3E, 0xF3,		0xE2, 0x32, 0x3E, 0x77, 0x77, 0x3E, 0xFC, 0xE0,
				0x47, 0x11, 0x04, 0x01, 0x21, 0x10, 0x80, 0x1A,		0xCD, 0x95, 0x00, 0xCD, 0x96, 0x00, 0x13, 0x7B,
				0xFE, 0x34, 0x20, 0xF3, 0x11, 0xD8, 0x00, 0x06,		0x08, 0x1A, 0x13, 0x22, 0x23, 0x05, 0x20, 0xF9,
				0x3E, 0x19, 0xEA, 0x10, 0x99, 0x21, 0x2F, 0x99,		0x0E, 0x0C, 0x3D, 0x28, 0x08, 0x32, 0x0D, 0x20,
				0xF9, 0x2E, 0x0F, 0x18, 0xF3, 0x67, 0x3E, 0x64,		0x57, 0xE0, 0x42, 0x3E, 0x91, 0xE0, 0x40, 0x04,
				0x1E, 0x02, 0x0E, 0x0C, 0xF0, 0x44, 0xFE, 0x90,		0x20, 0xFA, 0x0D, 0x20, 0xF7, 0x1D, 0x20, 0xF2,
				0x0E, 0x13, 0x24, 0x7C, 0x1E, 0x83, 0xFE, 0x62,		0x28, 0x06, 0x1E, 0xC1, 0xFE, 0x64, 0x20, 0x06,
				0x7B, 0xE2, 0x0C, 0x3E, 0x87, 0xE2, 0xF0, 0x42,		0x90, 0xE0, 0x42, 0x15, 0x20, 0xD2, 0x05, 0x20,
				0x4F, 0x16, 0x20, 0x18, 0xCB, 0x4F, 0x06, 0x04,		0xC5, 0xCB, 0x11, 0x17, 0xC1, 0xCB, 0x11, 0x17,
				0x05, 0x20, 0xF5, 0x22, 0x23, 0x22, 0x23, 0xC9,		0xCE, 0xED, 0x66, 0x66, 0xCC, 0x0D, 0x00, 0x0B,
				0x03, 0x73, 0x00, 0x83, 0x00, 0x0C, 0x00, 0x0D,		0x00, 0x08, 0x11, 0x1F, 0x88, 0x89, 0x00, 0x0E,
				0xDC, 0xCC, 0x6E, 0xE6, 0xDD, 0xDD, 0xD9, 0x99,		0xBB, 0xBB, 0x67, 0x63, 0x6E, 0x0E, 0xEC, 0xCC,
				0xDD, 0xDC, 0x99, 0x9F, 0xBB, 0xB9, 0x33, 0x3E,		0x3C, 0x42, 0xB9, 0xA5, 0xB9, 0xA5, 0x42, 0x3C,
				0x21, 0x04, 0x01, 0x11, 0xA8, 0x00, 0x1A, 0x13,		0xBE, 0x20, 0xFE, 0x23, 0x7D, 0xFE, 0x34, 0x20,
				0xF5, 0x06, 0x19, 0x78, 0x86, 0x23, 0x05, 0x20,		0xFB, 0x86, 0x20, 0xFE, 0x3E, 0x01, 0xE0, 0x50
			],"uint");
			this.GBCBOOTROM = toVector([
				0x31, 0xfe, 0xff, 0x3e, 0x02, 0xc3, 0x7c, 0x00, 	0xd3, 0x00, 0x98, 0xa0, 0x12, 0xd3, 0x00, 0x80, 
				0x00, 0x40, 0x1e, 0x53, 0xd0, 0x00, 0x1f, 0x42, 	0x1c, 0x00, 0x14, 0x2a, 0x4d, 0x19, 0x8c, 0x7e, 
				0x00, 0x7c, 0x31, 0x6e, 0x4a, 0x45, 0x52, 0x4a, 	0x00, 0x00, 0xff, 0x53, 0x1f, 0x7c, 0xff, 0x03, 
				0x1f, 0x00, 0xff, 0x1f, 0xa7, 0x00, 0xef, 0x1b, 	0x1f, 0x00, 0xef, 0x1b, 0x00, 0x7c, 0x00, 0x00, 
				0xff, 0x03, 0xce, 0xed, 0x66, 0x66, 0xcc, 0x0d, 	0x00, 0x0b, 0x03, 0x73, 0x00, 0x83, 0x00, 0x0c, 
				0x00, 0x0d, 0x00, 0x08, 0x11, 0x1f, 0x88, 0x89, 	0x00, 0x0e, 0xdc, 0xcc, 0x6e, 0xe6, 0xdd, 0xdd, 
				0xd9, 0x99, 0xbb, 0xbb, 0x67, 0x63, 0x6e, 0x0e, 	0xec, 0xcc, 0xdd, 0xdc, 0x99, 0x9f, 0xbb, 0xb9, 
				0x33, 0x3e, 0x3c, 0x42, 0xb9, 0xa5, 0xb9, 0xa5, 	0x42, 0x3c, 0x58, 0x43, 0xe0, 0x70, 0x3e, 0xfc, 
				0xe0, 0x47, 0xcd, 0x75, 0x02, 0xcd, 0x00, 0x02, 	0x26, 0xd0, 0xcd, 0x03, 0x02, 0x21, 0x00, 0xfe, 
				0x0e, 0xa0, 0xaf, 0x22, 0x0d, 0x20, 0xfc, 0x11, 	0x04, 0x01, 0x21, 0x10, 0x80, 0x4c, 0x1a, 0xe2, 
				0x0c, 0xcd, 0xc6, 0x03, 0xcd, 0xc7, 0x03, 0x13, 	0x7b, 0xfe, 0x34, 0x20, 0xf1, 0x11, 0x72, 0x00, 
				0x06, 0x08, 0x1a, 0x13, 0x22, 0x23, 0x05, 0x20, 	0xf9, 0xcd, 0xf0, 0x03, 0x3e, 0x01, 0xe0, 0x4f, 
				0x3e, 0x91, 0xe0, 0x40, 0x21, 0xb2, 0x98, 0x06, 	0x4e, 0x0e, 0x44, 0xcd, 0x91, 0x02, 0xaf, 0xe0, 
				0x4f, 0x0e, 0x80, 0x21, 0x42, 0x00, 0x06, 0x18, 	0xf2, 0x0c, 0xbe, 0x20, 0xfe, 0x23, 0x05, 0x20, 
				0xf7, 0x21, 0x34, 0x01, 0x06, 0x19, 0x78, 0x86, 	0x2c, 0x05, 0x20, 0xfb, 0x86, 0x20, 0xfe, 0xcd, 
				0x1c, 0x03, 0x18, 0x02, 0x00, 0x00, 0xcd, 0xd0, 	0x05, 0xaf, 0xe0, 0x70, 0x3e, 0x11, 0xe0, 0x50, 
				0x21, 0x00, 0x80, 0xaf, 0x22, 0xcb, 0x6c, 0x28, 	0xfb, 0xc9, 0x2a, 0x12, 0x13, 0x0d, 0x20, 0xfa, 
				0xc9, 0xe5, 0x21, 0x0f, 0xff, 0xcb, 0x86, 0xcb, 	0x46, 0x28, 0xfc, 0xe1, 0xc9, 0x11, 0x00, 0xff, 
				0x21, 0x03, 0xd0, 0x0e, 0x0f, 0x3e, 0x30, 0x12, 	0x3e, 0x20, 0x12, 0x1a, 0x2f, 0xa1, 0xcb, 0x37, 
				0x47, 0x3e, 0x10, 0x12, 0x1a, 0x2f, 0xa1, 0xb0, 	0x4f, 0x7e, 0xa9, 0xe6, 0xf0, 0x47, 0x2a, 0xa9, 
				0xa1, 0xb0, 0x32, 0x47, 0x79, 0x77, 0x3e, 0x30, 	0x12, 0xc9, 0x3e, 0x80, 0xe0, 0x68, 0xe0, 0x6a, 
				0x0e, 0x6b, 0x2a, 0xe2, 0x05, 0x20, 0xfb, 0x4a, 	0x09, 0x43, 0x0e, 0x69, 0x2a, 0xe2, 0x05, 0x20, 
				0xfb, 0xc9, 0xc5, 0xd5, 0xe5, 0x21, 0x00, 0xd8, 	0x06, 0x01, 0x16, 0x3f, 0x1e, 0x40, 0xcd, 0x4a, 
				0x02, 0xe1, 0xd1, 0xc1, 0xc9, 0x3e, 0x80, 0xe0, 	0x26, 0xe0, 0x11, 0x3e, 0xf3, 0xe0, 0x12, 0xe0, 
				0x25, 0x3e, 0x77, 0xe0, 0x24, 0x21, 0x30, 0xff, 	0xaf, 0x0e, 0x10, 0x22, 0x2f, 0x0d, 0x20, 0xfb, 
				0xc9, 0xcd, 0x11, 0x02, 0xcd, 0x62, 0x02, 0x79, 	0xfe, 0x38, 0x20, 0x14, 0xe5, 0xaf, 0xe0, 0x4f, 
				0x21, 0xa7, 0x99, 0x3e, 0x38, 0x22, 0x3c, 0xfe, 	0x3f, 0x20, 0xfa, 0x3e, 0x01, 0xe0, 0x4f, 0xe1, 
				0xc5, 0xe5, 0x21, 0x43, 0x01, 0xcb, 0x7e, 0xcc, 	0x89, 0x05, 0xe1, 0xc1, 0xcd, 0x11, 0x02, 0x79, 
				0xd6, 0x30, 0xd2, 0x06, 0x03, 0x79, 0xfe, 0x01, 	0xca, 0x06, 0x03, 0x7d, 0xfe, 0xd1, 0x28, 0x21, 
				0xc5, 0x06, 0x03, 0x0e, 0x01, 0x16, 0x03, 0x7e, 	0xe6, 0xf8, 0xb1, 0x22, 0x15, 0x20, 0xf8, 0x0c, 
				0x79, 0xfe, 0x06, 0x20, 0xf0, 0x11, 0x11, 0x00, 	0x19, 0x05, 0x20, 0xe7, 0x11, 0xa1, 0xff, 0x19, 
				0xc1, 0x04, 0x78, 0x1e, 0x83, 0xfe, 0x62, 0x28, 	0x06, 0x1e, 0xc1, 0xfe, 0x64, 0x20, 0x07, 0x7b, 
				0xe0, 0x13, 0x3e, 0x87, 0xe0, 0x14, 0xfa, 0x02, 	0xd0, 0xfe, 0x00, 0x28, 0x0a, 0x3d, 0xea, 0x02, 
				0xd0, 0x79, 0xfe, 0x01, 0xca, 0x91, 0x02, 0x0d, 	0xc2, 0x91, 0x02, 0xc9, 0x0e, 0x26, 0xcd, 0x4a, 
				0x03, 0xcd, 0x11, 0x02, 0xcd, 0x62, 0x02, 0x0d, 	0x20, 0xf4, 0xcd, 0x11, 0x02, 0x3e, 0x01, 0xe0, 
				0x4f, 0xcd, 0x3e, 0x03, 0xcd, 0x41, 0x03, 0xaf, 	0xe0, 0x4f, 0xcd, 0x3e, 0x03, 0xc9, 0x21, 0x08, 
				0x00, 0x11, 0x51, 0xff, 0x0e, 0x05, 0xcd, 0x0a, 	0x02, 0xc9, 0xc5, 0xd5, 0xe5, 0x21, 0x40, 0xd8, 
				0x0e, 0x20, 0x7e, 0xe6, 0x1f, 0xfe, 0x1f, 0x28, 	0x01, 0x3c, 0x57, 0x2a, 0x07, 0x07, 0x07, 0xe6, 
				0x07, 0x47, 0x3a, 0x07, 0x07, 0x07, 0xe6, 0x18, 	0xb0, 0xfe, 0x1f, 0x28, 0x01, 0x3c, 0x0f, 0x0f, 
				0x0f, 0x47, 0xe6, 0xe0, 0xb2, 0x22, 0x78, 0xe6, 	0x03, 0x5f, 0x7e, 0x0f, 0x0f, 0xe6, 0x1f, 0xfe, 
				0x1f, 0x28, 0x01, 0x3c, 0x07, 0x07, 0xb3, 0x22, 	0x0d, 0x20, 0xc7, 0xe1, 0xd1, 0xc1, 0xc9, 0x0e, 
				0x00, 0x1a, 0xe6, 0xf0, 0xcb, 0x49, 0x28, 0x02, 	0xcb, 0x37, 0x47, 0x23, 0x7e, 0xb0, 0x22, 0x1a, 
				0xe6, 0x0f, 0xcb, 0x49, 0x20, 0x02, 0xcb, 0x37, 	0x47, 0x23, 0x7e, 0xb0, 0x22, 0x13, 0xcb, 0x41, 
				0x28, 0x0d, 0xd5, 0x11, 0xf8, 0xff, 0xcb, 0x49, 	0x28, 0x03, 0x11, 0x08, 0x00, 0x19, 0xd1, 0x0c, 
				0x79, 0xfe, 0x18, 0x20, 0xcc, 0xc9, 0x47, 0xd5, 	0x16, 0x04, 0x58, 0xcb, 0x10, 0x17, 0xcb, 0x13, 
				0x17, 0x15, 0x20, 0xf6, 0xd1, 0x22, 0x23, 0x22, 	0x23, 0xc9, 0x3e, 0x19, 0xea, 0x10, 0x99, 0x21, 
				0x2f, 0x99, 0x0e, 0x0c, 0x3d, 0x28, 0x08, 0x32, 	0x0d, 0x20, 0xf9, 0x2e, 0x0f, 0x18, 0xf3, 0xc9, 
				0x3e, 0x01, 0xe0, 0x4f, 0xcd, 0x00, 0x02, 0x11, 	0x07, 0x06, 0x21, 0x80, 0x80, 0x0e, 0xc0, 0x1a, 
				0x22, 0x23, 0x22, 0x23, 0x13, 0x0d, 0x20, 0xf7, 	0x11, 0x04, 0x01, 0xcd, 0x8f, 0x03, 0x01, 0xa8, 
				0xff, 0x09, 0xcd, 0x8f, 0x03, 0x01, 0xf8, 0xff, 	0x09, 0x11, 0x72, 0x00, 0x0e, 0x08, 0x23, 0x1a, 
				0x22, 0x13, 0x0d, 0x20, 0xf9, 0x21, 0xc2, 0x98, 	0x06, 0x08, 0x3e, 0x08, 0x0e, 0x10, 0x22, 0x0d, 
				0x20, 0xfc, 0x11, 0x10, 0x00, 0x19, 0x05, 0x20, 	0xf3, 0xaf, 0xe0, 0x4f, 0x21, 0xc2, 0x98, 0x3e, 
				0x08, 0x22, 0x3c, 0xfe, 0x18, 0x20, 0x02, 0x2e, 	0xe2, 0xfe, 0x28, 0x20, 0x03, 0x21, 0x02, 0x99, 
				0xfe, 0x38, 0x20, 0xed, 0x21, 0xd8, 0x08, 0x11, 	0x40, 0xd8, 0x06, 0x08, 0x3e, 0xff, 0x12, 0x13, 
				0x12, 0x13, 0x0e, 0x02, 0xcd, 0x0a, 0x02, 0x3e, 	0x00, 0x12, 0x13, 0x12, 0x13, 0x13, 0x13, 0x05, 
				0x20, 0xea, 0xcd, 0x62, 0x02, 0x21, 0x4b, 0x01, 	0x7e, 0xfe, 0x33, 0x20, 0x0b, 0x2e, 0x44, 0x1e, 
				0x30, 0x2a, 0xbb, 0x20, 0x49, 0x1c, 0x18, 0x04, 	0x2e, 0x4b, 0x1e, 0x01, 0x2a, 0xbb, 0x20, 0x3e, 
				0x2e, 0x34, 0x01, 0x10, 0x00, 0x2a, 0x80, 0x47, 	0x0d, 0x20, 0xfa, 0xea, 0x00, 0xd0, 0x21, 0xc7, 
				0x06, 0x0e, 0x00, 0x2a, 0xb8, 0x28, 0x08, 0x0c, 	0x79, 0xfe, 0x4f, 0x20, 0xf6, 0x18, 0x1f, 0x79, 
				0xd6, 0x41, 0x38, 0x1c, 0x21, 0x16, 0x07, 0x16, 	0x00, 0x5f, 0x19, 0xfa, 0x37, 0x01, 0x57, 0x7e, 
				0xba, 0x28, 0x0d, 0x11, 0x0e, 0x00, 0x19, 0x79, 	0x83, 0x4f, 0xd6, 0x5e, 0x38, 0xed, 0x0e, 0x00, 
				0x21, 0x33, 0x07, 0x06, 0x00, 0x09, 0x7e, 0xe6, 	0x1f, 0xea, 0x08, 0xd0, 0x7e, 0xe6, 0xe0, 0x07, 
				0x07, 0x07, 0xea, 0x0b, 0xd0, 0xcd, 0xe9, 0x04, 	0xc9, 0x11, 0x91, 0x07, 0x21, 0x00, 0xd9, 0xfa, 
				0x0b, 0xd0, 0x47, 0x0e, 0x1e, 0xcb, 0x40, 0x20, 	0x02, 0x13, 0x13, 0x1a, 0x22, 0x20, 0x02, 0x1b, 
				0x1b, 0xcb, 0x48, 0x20, 0x02, 0x13, 0x13, 0x1a, 	0x22, 0x13, 0x13, 0x20, 0x02, 0x1b, 0x1b, 0xcb, 
				0x50, 0x28, 0x05, 0x1b, 0x2b, 0x1a, 0x22, 0x13, 	0x1a, 0x22, 0x13, 0x0d, 0x20, 0xd7, 0x21, 0x00, 
				0xd9, 0x11, 0x00, 0xda, 0xcd, 0x64, 0x05, 0xc9, 	0x21, 0x12, 0x00, 0xfa, 0x05, 0xd0, 0x07, 0x07, 
				0x06, 0x00, 0x4f, 0x09, 0x11, 0x40, 0xd8, 0x06, 	0x08, 0xe5, 0x0e, 0x02, 0xcd, 0x0a, 0x02, 0x13, 
				0x13, 0x13, 0x13, 0x13, 0x13, 0xe1, 0x05, 0x20, 	0xf0, 0x11, 0x42, 0xd8, 0x0e, 0x02, 0xcd, 0x0a, 
				0x02, 0x11, 0x4a, 0xd8, 0x0e, 0x02, 0xcd, 0x0a, 	0x02, 0x2b, 0x2b, 0x11, 0x44, 0xd8, 0x0e, 0x02, 
				0xcd, 0x0a, 0x02, 0xc9, 0x0e, 0x60, 0x2a, 0xe5, 	0xc5, 0x21, 0xe8, 0x07, 0x06, 0x00, 0x4f, 0x09, 
				0x0e, 0x08, 0xcd, 0x0a, 0x02, 0xc1, 0xe1, 0x0d, 	0x20, 0xec, 0xc9, 0xfa, 0x08, 0xd0, 0x11, 0x18, 
				0x00, 0x3c, 0x3d, 0x28, 0x03, 0x19, 0x20, 0xfa, 	0xc9, 0xcd, 0x1d, 0x02, 0x78, 0xe6, 0xff, 0x28, 
				0x0f, 0x21, 0xe4, 0x08, 0x06, 0x00, 0x2a, 0xb9, 	0x28, 0x08, 0x04, 0x78, 0xfe, 0x0c, 0x20, 0xf6, 
				0x18, 0x2d, 0x78, 0xea, 0x05, 0xd0, 0x3e, 0x1e, 	0xea, 0x02, 0xd0, 0x11, 0x0b, 0x00, 0x19, 0x56, 
				0x7a, 0xe6, 0x1f, 0x5f, 0x21, 0x08, 0xd0, 0x3a, 	0x22, 0x7b, 0x77, 0x7a, 0xe6, 0xe0, 0x07, 0x07, 
				0x07, 0x5f, 0x21, 0x0b, 0xd0, 0x3a, 0x22, 0x7b, 	0x77, 0xcd, 0xe9, 0x04, 0xcd, 0x28, 0x05, 0xc9, 
				0xcd, 0x11, 0x02, 0xfa, 0x43, 0x01, 0xcb, 0x7f, 	0x28, 0x04, 0xe0, 0x4c, 0x18, 0x28, 0x3e, 0x04, 
				0xe0, 0x4c, 0x3e, 0x01, 0xe0, 0x6c, 0x21, 0x00, 	0xda, 0xcd, 0x7b, 0x05, 0x06, 0x10, 0x16, 0x00, 
				0x1e, 0x08, 0xcd, 0x4a, 0x02, 0x21, 0x7a, 0x00, 	0xfa, 0x00, 0xd0, 0x47, 0x0e, 0x02, 0x2a, 0xb8, 
				0xcc, 0xda, 0x03, 0x0d, 0x20, 0xf8, 0xc9, 0x01, 	0x0f, 0x3f, 0x7e, 0xff, 0xff, 0xc0, 0x00, 0xc0, 
				0xf0, 0xf1, 0x03, 0x7c, 0xfc, 0xfe, 0xfe, 0x03, 	0x07, 0x07, 0x0f, 0xe0, 0xe0, 0xf0, 0xf0, 0x1e, 
				0x3e, 0x7e, 0xfe, 0x0f, 0x0f, 0x1f, 0x1f, 0xff, 	0xff, 0x00, 0x00, 0x01, 0x01, 0x01, 0x03, 0xff, 
				0xff, 0xe1, 0xe0, 0xc0, 0xf0, 0xf9, 0xfb, 0x1f, 	0x7f, 0xf8, 0xe0, 0xf3, 0xfd, 0x3e, 0x1e, 0xe0, 
				0xf0, 0xf9, 0x7f, 0x3e, 0x7c, 0xf8, 0xe0, 0xf8, 	0xf0, 0xf0, 0xf8, 0x00, 0x00, 0x7f, 0x7f, 0x07, 
				0x0f, 0x9f, 0xbf, 0x9e, 0x1f, 0xff, 0xff, 0x0f, 	0x1e, 0x3e, 0x3c, 0xf1, 0xfb, 0x7f, 0x7f, 0xfe, 
				0xde, 0xdf, 0x9f, 0x1f, 0x3f, 0x3e, 0x3c, 0xf8, 	0xf8, 0x00, 0x00, 0x03, 0x03, 0x07, 0x07, 0xff, 
				0xff, 0xc1, 0xc0, 0xf3, 0xe7, 0xf7, 0xf3, 0xc0, 	0xc0, 0xc0, 0xc0, 0x1f, 0x1f, 0x1e, 0x3e, 0x3f, 
				0x1f, 0x3e, 0x3e, 0x80, 0x00, 0x00, 0x00, 0x7c, 	0x1f, 0x07, 0x00, 0x0f, 0xff, 0xfe, 0x00, 0x7c, 
				0xf8, 0xf0, 0x00, 0x1f, 0x0f, 0x0f, 0x00, 0x7c, 	0xf8, 0xf8, 0x00, 0x3f, 0x3e, 0x1c, 0x00, 0x0f, 
				0x0f, 0x0f, 0x00, 0x7c, 0xff, 0xff, 0x00, 0x00, 	0xf8, 0xf8, 0x00, 0x07, 0x0f, 0x0f, 0x00, 0x81, 
				0xff, 0xff, 0x00, 0xf3, 0xe1, 0x80, 0x00, 0xe0, 	0xff, 0x7f, 0x00, 0xfc, 0xf0, 0xc0, 0x00, 0x3e, 
				0x7c, 0x7c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 	0x88, 0x16, 0x36, 0xd1, 0xdb, 0xf2, 0x3c, 0x8c, 
				0x92, 0x3d, 0x5c, 0x58, 0xc9, 0x3e, 0x70, 0x1d, 	0x59, 0x69, 0x19, 0x35, 0xa8, 0x14, 0xaa, 0x75, 
				0x95, 0x99, 0x34, 0x6f, 0x15, 0xff, 0x97, 0x4b, 	0x90, 0x17, 0x10, 0x39, 0xf7, 0xf6, 0xa2, 0x49, 
				0x4e, 0x43, 0x68, 0xe0, 0x8b, 0xf0, 0xce, 0x0c, 	0x29, 0xe8, 0xb7, 0x86, 0x9a, 0x52, 0x01, 0x9d, 
				0x71, 0x9c, 0xbd, 0x5d, 0x6d, 0x67, 0x3f, 0x6b, 	0xb3, 0x46, 0x28, 0xa5, 0xc6, 0xd3, 0x27, 0x61, 
				0x18, 0x66, 0x6a, 0xbf, 0x0d, 0xf4, 0x42, 0x45, 	0x46, 0x41, 0x41, 0x52, 0x42, 0x45, 0x4b, 0x45, 
				0x4b, 0x20, 0x52, 0x2d, 0x55, 0x52, 0x41, 0x52, 	0x20, 0x49, 0x4e, 0x41, 0x49, 0x4c, 0x49, 0x43, 
				0x45, 0x20, 0x52, 0x7c, 0x08, 0x12, 0xa3, 0xa2, 	0x07, 0x87, 0x4b, 0x20, 0x12, 0x65, 0xa8, 0x16, 
				0xa9, 0x86, 0xb1, 0x68, 0xa0, 0x87, 0x66, 0x12, 	0xa1, 0x30, 0x3c, 0x12, 0x85, 0x12, 0x64, 0x1b, 
				0x07, 0x06, 0x6f, 0x6e, 0x6e, 0xae, 0xaf, 0x6f, 	0xb2, 0xaf, 0xb2, 0xa8, 0xab, 0x6f, 0xaf, 0x86, 
				0xae, 0xa2, 0xa2, 0x12, 0xaf, 0x13, 0x12, 0xa1, 	0x6e, 0xaf, 0xaf, 0xad, 0x06, 0x4c, 0x6e, 0xaf, 
				0xaf, 0x12, 0x7c, 0xac, 0xa8, 0x6a, 0x6e, 0x13, 	0xa0, 0x2d, 0xa8, 0x2b, 0xac, 0x64, 0xac, 0x6d, 
				0x87, 0xbc, 0x60, 0xb4, 0x13, 0x72, 0x7c, 0xb5, 	0xae, 0xae, 0x7c, 0x7c, 0x65, 0xa2, 0x6c, 0x64, 
				0x85, 0x80, 0xb0, 0x40, 0x88, 0x20, 0x68, 0xde, 	0x00, 0x70, 0xde, 0x20, 0x78, 0x20, 0x20, 0x38, 
				0x20, 0xb0, 0x90, 0x20, 0xb0, 0xa0, 0xe0, 0xb0, 	0xc0, 0x98, 0xb6, 0x48, 0x80, 0xe0, 0x50, 0x1e, 
				0x1e, 0x58, 0x20, 0xb8, 0xe0, 0x88, 0xb0, 0x10, 	0x20, 0x00, 0x10, 0x20, 0xe0, 0x18, 0xe0, 0x18, 
				0x00, 0x18, 0xe0, 0x20, 0xa8, 0xe0, 0x20, 0x18, 	0xe0, 0x00, 0x20, 0x18, 0xd8, 0xc8, 0x18, 0xe0, 
				0x00, 0xe0, 0x40, 0x28, 0x28, 0x28, 0x18, 0xe0, 	0x60, 0x20, 0x18, 0xe0, 0x00, 0x00, 0x08, 0xe0, 
				0x18, 0x30, 0xd0, 0xd0, 0xd0, 0x20, 0xe0, 0xe8, 	0xff, 0x7f, 0xbf, 0x32, 0xd0, 0x00, 0x00, 0x00, 
				0x9f, 0x63, 0x79, 0x42, 0xb0, 0x15, 0xcb, 0x04, 	0xff, 0x7f, 0x31, 0x6e, 0x4a, 0x45, 0x00, 0x00, 
				0xff, 0x7f, 0xef, 0x1b, 0x00, 0x02, 0x00, 0x00, 	0xff, 0x7f, 0x1f, 0x42, 0xf2, 0x1c, 0x00, 0x00, 
				0xff, 0x7f, 0x94, 0x52, 0x4a, 0x29, 0x00, 0x00, 	0xff, 0x7f, 0xff, 0x03, 0x2f, 0x01, 0x00, 0x00, 
				0xff, 0x7f, 0xef, 0x03, 0xd6, 0x01, 0x00, 0x00, 	0xff, 0x7f, 0xb5, 0x42, 0xc8, 0x3d, 0x00, 0x00, 
				0x74, 0x7e, 0xff, 0x03, 0x80, 0x01, 0x00, 0x00, 	0xff, 0x67, 0xac, 0x77, 0x13, 0x1a, 0x6b, 0x2d, 
				0xd6, 0x7e, 0xff, 0x4b, 0x75, 0x21, 0x00, 0x00, 	0xff, 0x53, 0x5f, 0x4a, 0x52, 0x7e, 0x00, 0x00, 
				0xff, 0x4f, 0xd2, 0x7e, 0x4c, 0x3a, 0xe0, 0x1c, 	0xed, 0x03, 0xff, 0x7f, 0x5f, 0x25, 0x00, 0x00, 
				0x6a, 0x03, 0x1f, 0x02, 0xff, 0x03, 0xff, 0x7f, 	0xff, 0x7f, 0xdf, 0x01, 0x12, 0x01, 0x00, 0x00, 
				0x1f, 0x23, 0x5f, 0x03, 0xf2, 0x00, 0x09, 0x00, 	0xff, 0x7f, 0xea, 0x03, 0x1f, 0x01, 0x00, 0x00, 
				0x9f, 0x29, 0x1a, 0x00, 0x0c, 0x00, 0x00, 0x00, 	0xff, 0x7f, 0x7f, 0x02, 0x1f, 0x00, 0x00, 0x00, 
				0xff, 0x7f, 0xe0, 0x03, 0x06, 0x02, 0x20, 0x01, 	0xff, 0x7f, 0xeb, 0x7e, 0x1f, 0x00, 0x00, 0x7c, 
				0xff, 0x7f, 0xff, 0x3f, 0x00, 0x7e, 0x1f, 0x00, 	0xff, 0x7f, 0xff, 0x03, 0x1f, 0x00, 0x00, 0x00, 
				0xff, 0x03, 0x1f, 0x00, 0x0c, 0x00, 0x00, 0x00, 	0xff, 0x7f, 0x3f, 0x03, 0x93, 0x01, 0x00, 0x00, 
				0x00, 0x00, 0x00, 0x42, 0x7f, 0x03, 0xff, 0x7f, 	0xff, 0x7f, 0x8c, 0x7e, 0x00, 0x7c, 0x00, 0x00, 
				0xff, 0x7f, 0xef, 0x1b, 0x80, 0x61, 0x00, 0x00, 	0xff, 0x7f, 0x00, 0x7c, 0xe0, 0x03, 0x1f, 0x7c, 
				0x1f, 0x00, 0xff, 0x03, 0x40, 0x41, 0x42, 0x20, 	0x21, 0x22, 0x80, 0x81, 0x82, 0x10, 0x11, 0x12, 
				0x12, 0xb0, 0x79, 0xb8, 0xad, 0x16, 0x17, 0x07, 	0xba, 0x05, 0x7c, 0x13, 0x00, 0x00, 0x00, 0x00
			],"uint");
			this.ffxxDump = toVector([
				0x0F, 0x00, 0x7C, 0xFF, 0x00, 0x00, 0x00, 0xF8, 	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01,
				0x80, 0xBF, 0xF3, 0xFF, 0xBF, 0xFF, 0x3F, 0x00, 	0xFF, 0xBF, 0x7F, 0xFF, 0x9F, 0xFF, 0xBF, 0xFF,
				0xFF, 0x00, 0x00, 0xBF, 0x77, 0xF3, 0xF1, 0xFF, 	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
				0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 	0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF,
				0x91, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFC, 	0x00, 0x00, 0x00, 0x00, 0xFF, 0x7E, 0xFF, 0xFE,
				0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x3E, 0xFF, 	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
				0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 	0xC0, 0xFF, 0xC1, 0x00, 0xFE, 0xFF, 0xFF, 0xFF,
				0xF8, 0xFF, 0x00, 0x00, 0x00, 0x8F, 0x00, 0x00, 	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
				0xCE, 0xED, 0x66, 0x66, 0xCC, 0x0D, 0x00, 0x0B, 	0x03, 0x73, 0x00, 0x83, 0x00, 0x0C, 0x00, 0x0D,
				0x00, 0x08, 0x11, 0x1F, 0x88, 0x89, 0x00, 0x0E, 	0xDC, 0xCC, 0x6E, 0xE6, 0xDD, 0xDD, 0xD9, 0x99,
				0xBB, 0xBB, 0x67, 0x63, 0x6E, 0x0E, 0xEC, 0xCC, 	0xDD, 0xDC, 0x99, 0x9F, 0xBB, 0xB9, 0x33, 0x3E,
				0x45, 0xEC, 0x52, 0xFA, 0x08, 0xB7, 0x07, 0x5D, 	0x01, 0xFD, 0xC0, 0xFF, 0x08, 0xFC, 0x00, 0xE5,
				0x0B, 0xF8, 0xC2, 0xCE, 0xF4, 0xF9, 0x0F, 0x7F, 	0x45, 0x6D, 0x3D, 0xFE, 0x46, 0x97, 0x33, 0x5E,
				0x08, 0xEF, 0xF1, 0xFF, 0x86, 0x83, 0x24, 0x74, 	0x12, 0xFC, 0x00, 0x9F, 0xB4, 0xB7, 0x06, 0xD5,
				0xD0, 0x7A, 0x00, 0x9E, 0x04, 0x5F, 0x41, 0x2F, 	0x1D, 0x77, 0x36, 0x75, 0x81, 0xAA, 0x70, 0x3A,
				0x98, 0xD1, 0x71, 0x02, 0x4D, 0x01, 0xC1, 0xFF, 	0x0D, 0x00, 0xD3, 0x05, 0xF9, 0x00, 0x0B, 0x00
			], "uint");
			this.OPCODE = toVector([
				//NOP
				//#0x00:
				function ():void {
					//Do Nothing...
				},
				//LD BC, nn
				//#0x01:
				function ():void {
					registerC = memoryReader[programCounter](programCounter);
					registerB = memoryRead((programCounter + 1) & 0xFFFF);
					programCounter = (programCounter + 2) & 0xFFFF;
				},
				//LD (BC), A
				//#0x02:
				function ():void {
					memoryWrite((registerB << 8) | registerC, registerA);
				},
				//INC BC
				//#0x03:
				function ():void {
					var temp_var:uint = ((registerB << 8) | registerC) + 1;
					registerB = (temp_var >> 8) & 0xFF;
					registerC = temp_var & 0xFF;
				},
				//INC B
				//#0x04:
				function ():void {
					registerB = (registerB + 1) & 0xFF;
					FZero = (registerB == 0);
					FHalfCarry = ((registerB & 0xF) == 0);
					FSubtract = false;
				},
				//DEC B
				//#0x05:
				function ():void {
					registerB = (registerB - 1) & 0xFF;
					FZero = (registerB == 0);
					FHalfCarry = ((registerB & 0xF) == 0xF);
					FSubtract = true;
				},
				//LD B, n
				//#0x06:
				function ():void {
					registerB = memoryReader[programCounter](programCounter);
					programCounter = (programCounter + 1) & 0xFFFF;
				},
				//RLCA
				//#0x07:
				function ():void {
					FCarry = (registerA > 0x7F);
					registerA = ((registerA << 1) & 0xFF) | (registerA >> 7);
					FZero = FSubtract = FHalfCarry = false;
				},
				//LD (nn), SP
				//#0x08:
				function ():void {
					var temp_var:uint = (memoryRead((programCounter + 1) & 0xFFFF) << 8) | memoryReader[programCounter](programCounter);
					programCounter = (programCounter + 2) & 0xFFFF;
					memoryWrite(temp_var, stackPointer & 0xFF);
					memoryWrite((temp_var + 1) & 0xFFFF, stackPointer >> 8);
				},
				//ADD HL, BC
				//#0x09:
				function ():void {
					var dirtySum:uint = registersHL + ((registerB << 8) | registerC);
					FHalfCarry = ((registersHL & 0xFFF) > (dirtySum & 0xFFF));
					FCarry = (dirtySum > 0xFFFF);
					registersHL = dirtySum & 0xFFFF;
					FSubtract = false;
				},
				//LD A, (BC)
				//#0x0A:
				function ():void {
					registerA = memoryRead((registerB << 8) | registerC);
				},
				//DEC BC
				//#0x0B:
				function ():void {
					var temp_var:uint = (((registerB << 8) | registerC) - 1) & 0xFFFF;
					registerB = temp_var >> 8;
					registerC = temp_var & 0xFF;
				},
				//INC C
				//#0x0C:
				function ():void {
					registerC = (registerC + 1) & 0xFF;
					FZero = (registerC == 0);
					FHalfCarry = ((registerC & 0xF) == 0);
					FSubtract = false;
				},
				//DEC C
				//#0x0D:
				function ():void {
					registerC = (registerC - 1) & 0xFF;
					FZero = (registerC == 0);
					FHalfCarry = ((registerC & 0xF) == 0xF);
					FSubtract = true;
				},
				//LD C, n
				//#0x0E:
				function ():void {
					registerC = memoryReader[programCounter](programCounter);
					programCounter = (programCounter + 1) & 0xFFFF;
				},
				//RRCA
				//#0x0F:
				function ():void {
					registerA = (registerA >> 1) | ((registerA & 1) << 7);
					FCarry = (registerA > 0x7F);
					FZero = FSubtract = FHalfCarry = false;
				},
				//STOP
				//#0x10:
				function ():void {
					if (cGBC) {
						if ((memory[0xFF4D] & 0x01) == 0x01) {		//Speed change requested.
							if (memory[0xFF4D] > 0x7F) {				//Go back to single speed mode.
								trace("Going into single clock speed mode.", 0);
								doubleSpeedShifter = 0;
								memory[0xFF4D] &= 0x7F;				//Clear the double speed mode flag.
							}
							else {												//Go to double speed mode.
								trace("Going into double clock speed mode.", 0);
								doubleSpeedShifter = 1;
								memory[0xFF4D] |= 0x80;				//Set the double speed mode flag.
							}
							memory[0xFF4D] &= 0xFE;					//Reset the request bit.
						}
					}
				},
				//LD DE, nn
				//#0x11:
				function ():void {
					registerE = memoryReader[programCounter](programCounter);
					registerD = memoryRead((programCounter + 1) & 0xFFFF);
					programCounter = (programCounter + 2) & 0xFFFF;
				},
				//LD (DE), A
				//#0x12:
				function ():void {
					memoryWrite((registerD << 8) | registerE, registerA);
				},
				//INC DE
				//#0x13:
				function ():void {
					var temp_var:uint = ((registerD << 8) | registerE) + 1;
					registerD = (temp_var >> 8) & 0xFF;
					registerE = temp_var & 0xFF;
				},
				//INC D
				//#0x14:
				function ():void {
					registerD = (registerD + 1) & 0xFF;
					FZero = (registerD == 0);
					FHalfCarry = ((registerD & 0xF) == 0);
					FSubtract = false;
				},
				//DEC D
				//#0x15:
				function ():void {
					registerD = (registerD - 1) & 0xFF;
					FZero = (registerD == 0);
					FHalfCarry = ((registerD & 0xF) == 0xF);
					FSubtract = true;
				},
				//LD D, n
				//#0x16:
				function ():void {
					registerD = memoryReader[programCounter](programCounter);
					programCounter = (programCounter + 1) & 0xFFFF;
				},
				//RLA
				//#0x17:
				function ():void {
					var carry_flag:uint = (FCarry) ? 1 : 0;
					FCarry = (registerA > 0x7F);
					registerA = ((registerA << 1) & 0xFF) | carry_flag;
					FZero = FSubtract = FHalfCarry = false;
				},
				//JR n
				//#0x18:
				function ():void {
					programCounter = (programCounter + ((memoryReader[programCounter](programCounter) << 24) >> 24) + 1) & 0xFFFF;
				},
				//ADD HL, DE
				//#0x19:
				function ():void {
					var dirtySum:uint = registersHL + ((registerD << 8) | registerE);
					FHalfCarry = ((registersHL & 0xFFF) > (dirtySum & 0xFFF));
					FCarry = (dirtySum > 0xFFFF);
					registersHL = dirtySum & 0xFFFF;
					FSubtract = false;
				},
				//LD A, (DE)
				//#0x1A:
				function ():void {
					registerA = memoryRead((registerD << 8) | registerE);
				},
				//DEC DE
				//#0x1B:
				function ():void {
					var temp_var:uint = (((registerD << 8) | registerE) - 1) & 0xFFFF;
					registerD = temp_var >> 8;
					registerE = temp_var & 0xFF;
				},
				//INC E
				//#0x1C:
				function ():void {
					registerE = (registerE + 1) & 0xFF;
					FZero = (registerE == 0);
					FHalfCarry = ((registerE & 0xF) == 0);
					FSubtract = false;
				},
				//DEC E
				//#0x1D:
				function ():void {
					registerE = (registerE - 1) & 0xFF;
					FZero = (registerE == 0);
					FHalfCarry = ((registerE & 0xF) == 0xF);
					FSubtract = true;
				},
				//LD E, n
				//#0x1E:
				function ():void {
					registerE = memoryReader[programCounter](programCounter);
					programCounter = (programCounter + 1) & 0xFFFF;
				},
				//RRA
				//#0x1F:
				function ():void {
					var carry_flag:uint = (FCarry) ? 0x80 : 0;
					FCarry = ((registerA & 1) == 1);
					registerA = (registerA >> 1) | carry_flag;
					FZero = FSubtract = FHalfCarry = false;
				},
				//JR NZ, n
				//#0x20:
				function ():void {
					if (!FZero) {
						programCounter = (programCounter + ((memoryReader[programCounter](programCounter) << 24) >> 24) + 1) & 0xFFFF;
						CPUTicks += 4;
					}
					else {
						programCounter = (programCounter + 1) & 0xFFFF;
					}
				},
				//LD HL, nn
				//#0x21:
				function ():void {
					registersHL = (memoryRead((programCounter + 1) & 0xFFFF) << 8) | memoryReader[programCounter](programCounter);
					programCounter = (programCounter + 2) & 0xFFFF;
				},
				//LDI (HL), A
				//#0x22:
				function ():void {
					memoryWriter[registersHL](registersHL, registerA);
					registersHL = (registersHL + 1) & 0xFFFF;
				},
				//INC HL
				//#0x23:
				function ():void {
					registersHL = (registersHL + 1) & 0xFFFF;
				},
				//INC H
				//#0x24:
				function ():void {
					var H:uint = ((registersHL >> 8) + 1) & 0xFF;
					FZero = (H == 0);
					FHalfCarry = ((H & 0xF) == 0);
					FSubtract = false;
					registersHL = (H << 8) | (registersHL & 0xFF);
				},
				//DEC H
				//#0x25:
				function ():void {
					var H:uint = ((registersHL >> 8) - 1) & 0xFF;
					FZero = (H == 0);
					FHalfCarry = ((H & 0xF) == 0xF);
					FSubtract = true;
					registersHL = (H << 8) | (registersHL & 0xFF);
				},
				//LD H, n
				//#0x26:
				function ():void {
					registersHL = (memoryReader[programCounter](programCounter) << 8) | (registersHL & 0xFF);
					programCounter = (programCounter + 1) & 0xFFFF;
				},
				//DAA
				//#0x27:
				function ():void {
					if (!FSubtract) {
						if (FCarry || registerA > 0x99) {
							registerA = (registerA + 0x60) & 0xFF;
							FCarry = true;
						}
						if (FHalfCarry || (registerA & 0xF) > 0x9) {
							registerA = (registerA + 0x06) & 0xFF;
							FHalfCarry = false;
						}
					}
					else if (FCarry && FHalfCarry) {
						registerA = (registerA + 0x9A) & 0xFF;
						FHalfCarry = false;
					}
					else if (FCarry) {
						registerA = (registerA + 0xA0) & 0xFF;
					}
					else if (FHalfCarry) {
						registerA = (registerA + 0xFA) & 0xFF;
						FHalfCarry = false;
					}
					FZero = (registerA == 0);
				},
				//JR Z, n
				//#0x28:
				function ():void {
					if (FZero) {
						programCounter = (programCounter + ((memoryReader[programCounter](programCounter) << 24) >> 24) + 1) & 0xFFFF;
						CPUTicks += 4;
					}
					else {
						programCounter = (programCounter + 1) & 0xFFFF;
					}
				},
				//ADD HL, HL
				//#0x29:
				function ():void {
					FHalfCarry = ((registersHL & 0xFFF) > 0x7FF);
					FCarry = (registersHL > 0x7FFF);
					registersHL = (registersHL << 1) & 0xFFFF;
					FSubtract = false;
				},
				//LDI A, (HL)
				//#0x2A:
				function ():void {
					registerA = memoryReader[registersHL](registersHL);
					registersHL = (registersHL + 1) & 0xFFFF;
				},
				//DEC HL
				//#0x2B:
				function ():void {
					registersHL = (registersHL - 1) & 0xFFFF;
				},
				//INC L
				//#0x2C:
				function ():void {
					var L:uint = (registersHL + 1) & 0xFF;
					FZero = (L == 0);
					FHalfCarry = ((L & 0xF) == 0);
					FSubtract = false;
					registersHL = (registersHL & 0xFF00) | L;
				},
				//DEC L
				//#0x2D:
				function ():void {
					var L:uint = (registersHL - 1) & 0xFF;
					FZero = (L == 0);
					FHalfCarry = ((L & 0xF) == 0xF);
					FSubtract = true;
					registersHL = (registersHL & 0xFF00) | L;
				},
				//LD L, n
				//#0x2E:
				function ():void {
					registersHL = (registersHL & 0xFF00) | memoryReader[programCounter](programCounter);
					programCounter = (programCounter + 1) & 0xFFFF;
				},
				//CPL
				//#0x2F:
				function ():void {
					registerA ^= 0xFF;
					FSubtract = FHalfCarry = true;
				},
				//JR NC, n
				//#0x30:
				function ():void {
					if (!FCarry) {
						programCounter = (programCounter + ((memoryReader[programCounter](programCounter) << 24) >> 24) + 1) & 0xFFFF;
						CPUTicks += 4;
					}
					else {
						programCounter = (programCounter + 1) & 0xFFFF;
					}
				},
				//LD SP, nn
				//#0x31:
				function ():void {
					stackPointer = (memoryRead((programCounter + 1) & 0xFFFF) << 8) | memoryReader[programCounter](programCounter);
					programCounter = (programCounter + 2) & 0xFFFF;
				},
				//LDD (HL), A
				//#0x32:
				function ():void {
					memoryWriter[registersHL](registersHL, registerA);
					registersHL = (registersHL - 1) & 0xFFFF;
				},
				//INC SP
				//#0x33:
				function ():void {
					stackPointer = (stackPointer + 1) & 0xFFFF;
				},
				//INC (HL)
				//#0x34:
				function ():void {
					var temp_var:uint = (memoryReader[registersHL](registersHL) + 1) & 0xFF;
					FZero = (temp_var == 0);
					FHalfCarry = ((temp_var & 0xF) == 0);
					FSubtract = false;
					memoryWriter[registersHL](registersHL, temp_var);
				},
				//DEC (HL)
				//#0x35:
				function ():void {
					var temp_var:uint = (memoryReader[registersHL](registersHL) - 1) & 0xFF;
					FZero = (temp_var == 0);
					FHalfCarry = ((temp_var & 0xF) == 0xF);
					FSubtract = true;
					memoryWriter[registersHL](registersHL, temp_var);
				},
				//LD (HL), n
				//#0x36:
				function ():void {
					memoryWriter[registersHL](registersHL, memoryReader[programCounter](programCounter));
					programCounter = (programCounter + 1) & 0xFFFF;
				},
				//SCF
				//#0x37:
				function ():void {
					FCarry = true;
					FSubtract = FHalfCarry = false;
				},
				//JR C, n
				//#0x38:
				function ():void {
					if (FCarry) {
						programCounter = (programCounter + ((memoryReader[programCounter](programCounter) << 24) >> 24) + 1) & 0xFFFF;
						CPUTicks += 4;
					}
					else {
						programCounter = (programCounter + 1) & 0xFFFF;
					}
				},
				//ADD HL, SP
				//#0x39:
				function ():void {
					var dirtySum:uint = registersHL + stackPointer;
					FHalfCarry = ((registersHL & 0xFFF) > (dirtySum & 0xFFF));
					FCarry = (dirtySum > 0xFFFF);
					registersHL = dirtySum & 0xFFFF;
					FSubtract = false;
				},
				//LDD A, (HL)
				//#0x3A:
				function ():void {
					registerA = memoryReader[registersHL](registersHL);
					registersHL = (registersHL - 1) & 0xFFFF;
				},
				//DEC SP
				//#0x3B:
				function ():void {
					stackPointer = (stackPointer - 1) & 0xFFFF;
				},
				//INC A
				//#0x3C:
				function ():void {
					registerA = (registerA + 1) & 0xFF;
					FZero = (registerA == 0);
					FHalfCarry = ((registerA & 0xF) == 0);
					FSubtract = false;
				},
				//DEC A
				//#0x3D:
				function ():void {
					registerA = (registerA - 1) & 0xFF;
					FZero = (registerA == 0);
					FHalfCarry = ((registerA & 0xF) == 0xF);
					FSubtract = true;
				},
				//LD A, n
				//#0x3E:
				function ():void {
					registerA = memoryReader[programCounter](programCounter);
					programCounter = (programCounter + 1) & 0xFFFF;
				},
				//CCF
				//#0x3F:
				function ():void {
					FCarry = !FCarry;
					FSubtract = FHalfCarry = false;
				},
				//LD B, B
				//#0x40:
				function ():void {
					//Do nothing...
				},
				//LD B, C
				//#0x41:
				function ():void {
					registerB = registerC;
				},
				//LD B, D
				//#0x42:
				function ():void {
					registerB = registerD;
				},
				//LD B, E
				//#0x43:
				function ():void {
					registerB = registerE;
				},
				//LD B, H
				//#0x44:
				function ():void {
					registerB = registersHL >> 8;
				},
				//LD B, L
				//#0x45:
				function ():void {
					registerB = registersHL & 0xFF;
				},
				//LD B, (HL)
				//#0x46:
				function ():void {
					registerB = memoryReader[registersHL](registersHL);
				},
				//LD B, A
				//#0x47:
				function ():void {
					registerB = registerA;
				},
				//LD C, B
				//#0x48:
				function ():void {
					registerC = registerB;
				},
				//LD C, C
				//#0x49:
				function ():void {
					//Do nothing...
				},
				//LD C, D
				//#0x4A:
				function ():void {
					registerC = registerD;
				},
				//LD C, E
				//#0x4B:
				function ():void {
					registerC = registerE;
				},
				//LD C, H
				//#0x4C:
				function ():void {
					registerC = registersHL >> 8;
				},
				//LD C, L
				//#0x4D:
				function ():void {
					registerC = registersHL & 0xFF;
				},
				//LD C, (HL)
				//#0x4E:
				function ():void {
					registerC = memoryReader[registersHL](registersHL);
				},
				//LD C, A
				//#0x4F:
				function ():void {
					registerC = registerA;
				},
				//LD D, B
				//#0x50:
				function ():void {
					registerD = registerB;
				},
				//LD D, C
				//#0x51:
				function ():void {
					registerD = registerC;
				},
				//LD D, D
				//#0x52:
				function ():void {
					//Do nothing...
				},
				//LD D, E
				//#0x53:
				function ():void {
					registerD = registerE;
				},
				//LD D, H
				//#0x54:
				function ():void {
					registerD = registersHL >> 8;
				},
				//LD D, L
				//#0x55:
				function ():void {
					registerD = registersHL & 0xFF;
				},
				//LD D, (HL)
				//#0x56:
				function ():void {
					registerD = memoryReader[registersHL](registersHL);
				},
				//LD D, A
				//#0x57:
				function ():void {
					registerD = registerA;
				},
				//LD E, B
				//#0x58:
				function ():void {
					registerE = registerB;
				},
				//LD E, C
				//#0x59:
				function ():void {
					registerE = registerC;
				},
				//LD E, D
				//#0x5A:
				function ():void {
					registerE = registerD;
				},
				//LD E, E
				//#0x5B:
				function ():void {
					//Do nothing...
				},
				//LD E, H
				//#0x5C:
				function ():void {
					registerE = registersHL >> 8;
				},
				//LD E, L
				//#0x5D:
				function ():void {
					registerE = registersHL & 0xFF;
				},
				//LD E, (HL)
				//#0x5E:
				function ():void {
					registerE = memoryReader[registersHL](registersHL);
				},
				//LD E, A
				//#0x5F:
				function ():void {
					registerE = registerA;
				},
				//LD H, B
				//#0x60:
				function ():void {
					registersHL = (registerB << 8) | (registersHL & 0xFF);
				},
				//LD H, C
				//#0x61:
				function ():void {
					registersHL = (registerC << 8) | (registersHL & 0xFF);
				},
				//LD H, D
				//#0x62:
				function ():void {
					registersHL = (registerD << 8) | (registersHL & 0xFF);
				},
				//LD H, E
				//#0x63:
				function ():void {
					registersHL = (registerE << 8) | (registersHL & 0xFF);
				},
				//LD H, H
				//#0x64:
				function ():void {
					//Do nothing...
				},
				//LD H, L
				//#0x65:
				function ():void {
					registersHL = (registersHL & 0xFF) * 0x101;
				},
				//LD H, (HL)
				//#0x66:
				function ():void {
					registersHL = (memoryReader[registersHL](registersHL) << 8) | (registersHL & 0xFF);
				},
				//LD H, A
				//#0x67:
				function ():void {
					registersHL = (registerA << 8) | (registersHL & 0xFF);
				},
				//LD L, B
				//#0x68:
				function ():void {
					registersHL = (registersHL & 0xFF00) | registerB;
				},
				//LD L, C
				//#0x69:
				function ():void {
					registersHL = (registersHL & 0xFF00) | registerC;
				},
				//LD L, D
				//#0x6A:
				function ():void {
					registersHL = (registersHL & 0xFF00) | registerD;
				},
				//LD L, E
				//#0x6B:
				function ():void {
					registersHL = (registersHL & 0xFF00) | registerE;
				},
				//LD L, H
				//#0x6C:
				function ():void {
					registersHL = (registersHL & 0xFF00) | (registersHL >> 8);
				},
				//LD L, L
				//#0x6D:
				function ():void {
					//Do nothing...
				},
				//LD L, (HL)
				//#0x6E:
				function ():void {
					registersHL = (registersHL & 0xFF00) | memoryReader[registersHL](registersHL);
				},
				//LD L, A
				//#0x6F:
				function ():void {
					registersHL = (registersHL & 0xFF00) | registerA;
				},
				//LD (HL), B
				//#0x70:
				function ():void {
					memoryWriter[registersHL](registersHL, registerB);
				},
				//LD (HL), C
				//#0x71:
				function ():void {
					memoryWriter[registersHL](registersHL, registerC);
				},
				//LD (HL), D
				//#0x72:
				function ():void {
					memoryWriter[registersHL](registersHL, registerD);
				},
				//LD (HL), E
				//#0x73:
				function ():void {
					memoryWriter[registersHL](registersHL, registerE);
				},
				//LD (HL), H
				//#0x74:
				function ():void {
					memoryWriter[registersHL](registersHL, registersHL >> 8);
				},
				//LD (HL), L
				//#0x75:
				function ():void {
					memoryWriter[registersHL](registersHL, registersHL & 0xFF);
				},
				//HALT
				//#0x76:
				function ():void {
					//See if there's already an IRQ match:
					if ((interruptsEnabled & interruptsRequested & 0x1F) > 0) {
						if (!cGBC && !usedBootROM) {
							//HALT bug in the DMG CPU model (Program Counter fails to increment for one instruction after HALT):
							skipPCIncrement = true;
						}
						else {
							//CGB gets around the HALT PC bug by doubling the hidden NOP.
							CPUTicks += 4;
						}
					}
					else {
						//CPU is stalled until the next IRQ match:
						calculateHALTPeriod();
					}
				},
				//LD (HL), A
				//#0x77:
				function ():void {
					memoryWriter[registersHL](registersHL, registerA);
				},
				//LD A, B
				//#0x78:
				function ():void {
					registerA = registerB;
				},
				//LD A, C
				//#0x79:
				function ():void {
					registerA = registerC;
				},
				//LD A, D
				//#0x7A:
				function ():void {
					registerA = registerD;
				},
				//LD A, E
				//#0x7B:
				function ():void {
					registerA = registerE;
				},
				//LD A, H
				//#0x7C:
				function ():void {
					registerA = registersHL >> 8;
				},
				//LD A, L
				//#0x7D:
				function ():void {
					registerA = registersHL & 0xFF;
				},
				//LD, A, (HL)
				//#0x7E:
				function ():void {
					registerA = memoryReader[registersHL](registersHL);
				},
				//LD A, A
				//#0x7F:
				function ():void {
					//Do Nothing...
				},
				//ADD A, B
				//#0x80:
				function ():void {
					var dirtySum:uint = registerA + registerB;
					FHalfCarry = ((dirtySum & 0xF) < (registerA & 0xF));
					FCarry = (dirtySum > 0xFF);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = false;
				},
				//ADD A, C
				//#0x81:
				function ():void {
					var dirtySum:uint = registerA + registerC;
					FHalfCarry = ((dirtySum & 0xF) < (registerA & 0xF));
					FCarry = (dirtySum > 0xFF);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = false;
				},
				//ADD A, D
				//#0x82:
				function ():void {
					var dirtySum:uint = registerA + registerD;
					FHalfCarry = ((dirtySum & 0xF) < (registerA & 0xF));
					FCarry = (dirtySum > 0xFF);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = false;
				},
				//ADD A, E
				//#0x83:
				function ():void {
					var dirtySum:uint = registerA + registerE;
					FHalfCarry = ((dirtySum & 0xF) < (registerA & 0xF));
					FCarry = (dirtySum > 0xFF);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = false;
				},
				//ADD A, H
				//#0x84:
				function ():void {
					var dirtySum:uint = registerA + (registersHL >> 8);
					FHalfCarry = ((dirtySum & 0xF) < (registerA & 0xF));
					FCarry = (dirtySum > 0xFF);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = false;
				},
				//ADD A, L
				//#0x85:
				function ():void {
					var dirtySum:uint = registerA + (registersHL & 0xFF);
					FHalfCarry = ((dirtySum & 0xF) < (registerA & 0xF));
					FCarry = (dirtySum > 0xFF);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = false;
				},
				//ADD A, (HL)
				//#0x86:
				function ():void {
					var dirtySum:uint = registerA + memoryReader[registersHL](registersHL);
					FHalfCarry = ((dirtySum & 0xF) < (registerA & 0xF));
					FCarry = (dirtySum > 0xFF);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = false;
				},
				//ADD A, A
				//#0x87:
				function ():void {
					FHalfCarry = ((registerA & 0x8) == 0x8);
					FCarry = (registerA > 0x7F);
					registerA = (registerA << 1) & 0xFF;
					FZero = (registerA == 0);
					FSubtract = false;
				},
				//ADC A, B
				//#0x88:
				function ():void {
					var dirtySum:uint = registerA + registerB + ((FCarry) ? 1 : 0);
					FHalfCarry = ((registerA & 0xF) + (registerB & 0xF) + ((FCarry) ? 1 : 0) > 0xF);
					FCarry = (dirtySum > 0xFF);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = false;
				},
				//ADC A, C
				//#0x89:
				function ():void {
					var dirtySum:uint = registerA + registerC + ((FCarry) ? 1 : 0);
					FHalfCarry = ((registerA & 0xF) + (registerC & 0xF) + ((FCarry) ? 1 : 0) > 0xF);
					FCarry = (dirtySum > 0xFF);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = false;
				},
				//ADC A, D
				//#0x8A:
				function ():void {
					var dirtySum:uint = registerA + registerD + ((FCarry) ? 1 : 0);
					FHalfCarry = ((registerA & 0xF) + (registerD & 0xF) + ((FCarry) ? 1 : 0) > 0xF);
					FCarry = (dirtySum > 0xFF);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = false;
				},
				//ADC A, E
				//#0x8B:
				function ():void {
					var dirtySum:uint = registerA + registerE + ((FCarry) ? 1 : 0);
					FHalfCarry = ((registerA & 0xF) + (registerE & 0xF) + ((FCarry) ? 1 : 0) > 0xF);
					FCarry = (dirtySum > 0xFF);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = false;
				},
				//ADC A, H
				//#0x8C:
				function ():void {
					var tempValue:uint = (registersHL >> 8);
					var dirtySum:uint = registerA + tempValue + ((FCarry) ? 1 : 0);
					FHalfCarry = ((registerA & 0xF) + (tempValue & 0xF) + ((FCarry) ? 1 : 0) > 0xF);
					FCarry = (dirtySum > 0xFF);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = false;
				},
				//ADC A, L
				//#0x8D:
				function ():void {
					var tempValue:uint = (registersHL & 0xFF);
					var dirtySum:uint = registerA + tempValue + ((FCarry) ? 1 : 0);
					FHalfCarry = ((registerA & 0xF) + (tempValue & 0xF) + ((FCarry) ? 1 : 0) > 0xF);
					FCarry = (dirtySum > 0xFF);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = false;
				},
				//ADC A, (HL)
				//#0x8E:
				function ():void {
					var tempValue:uint = memoryReader[registersHL](registersHL);
					var dirtySum:uint = registerA + tempValue + ((FCarry) ? 1 : 0);
					FHalfCarry = ((registerA & 0xF) + (tempValue & 0xF) + ((FCarry) ? 1 : 0) > 0xF);
					FCarry = (dirtySum > 0xFF);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = false;
				},
				//ADC A, A
				//#0x8F:
				function ():void {
					//shift left register A one bit for some ops here as an optimization:
					var dirtySum:uint = (registerA << 1) | ((FCarry) ? 1 : 0);
					FHalfCarry = ((((registerA << 1) & 0x1E) | ((FCarry) ? 1 : 0)) > 0xF);
					FCarry = (dirtySum > 0xFF);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = false;
				},
				//SUB A, B
				//#0x90:
				function ():void {
					var dirtySum:uint = registerA - registerB;
					FHalfCarry = ((registerA & 0xF) < (dirtySum & 0xF));
					FCarry = (dirtySum < 0);
					registerA = dirtySum & 0xFF;
					FZero = (dirtySum == 0);
					FSubtract = true;
				},
				//SUB A, C
				//#0x91:
				function ():void {
					var dirtySum:uint = registerA - registerC;
					FHalfCarry = ((registerA & 0xF) < (dirtySum & 0xF));
					FCarry = (dirtySum < 0);
					registerA = dirtySum & 0xFF;
					FZero = (dirtySum == 0);
					FSubtract = true;
				},
				//SUB A, D
				//#0x92:
				function ():void {
					var dirtySum:uint = registerA - registerD;
					FHalfCarry = ((registerA & 0xF) < (dirtySum & 0xF));
					FCarry = (dirtySum < 0);
					registerA = dirtySum & 0xFF;
					FZero = (dirtySum == 0);
					FSubtract = true;
				},
				//SUB A, E
				//#0x93:
				function ():void {
					var dirtySum:uint = registerA - registerE;
					FHalfCarry = ((registerA & 0xF) < (dirtySum & 0xF));
					FCarry = (dirtySum < 0);
					registerA = dirtySum & 0xFF;
					FZero = (dirtySum == 0);
					FSubtract = true;
				},
				//SUB A, H
				//#0x94:
				function ():void {
					var dirtySum:uint = registerA - (registersHL >> 8);
					FHalfCarry = ((registerA & 0xF) < (dirtySum & 0xF));
					FCarry = (dirtySum < 0);
					registerA = dirtySum & 0xFF;
					FZero = (dirtySum == 0);
					FSubtract = true;
				},
				//SUB A, L
				//#0x95:
				function ():void {
					var dirtySum:uint = registerA - (registersHL & 0xFF);
					FHalfCarry = ((registerA & 0xF) < (dirtySum & 0xF));
					FCarry = (dirtySum < 0);
					registerA = dirtySum & 0xFF;
					FZero = (dirtySum == 0);
					FSubtract = true;
				},
				//SUB A, (HL)
				//#0x96:
				function ():void {
					var dirtySum:uint = registerA - memoryReader[registersHL](registersHL);
					FHalfCarry = ((registerA & 0xF) < (dirtySum & 0xF));
					FCarry = (dirtySum < 0);
					registerA = dirtySum & 0xFF;
					FZero = (dirtySum == 0);
					FSubtract = true;
				},
				//SUB A, A
				//#0x97:
				function ():void {
					//number - same number == 0
					registerA = 0;
					FHalfCarry = FCarry = false;
					FZero = FSubtract = true;
				},
				//SBC A, B
				//#0x98:
				function ():void {
					var dirtySum:uint = registerA - registerB - ((FCarry) ? 1 : 0);
					FHalfCarry = ((registerA & 0xF) - (registerB & 0xF) - ((FCarry) ? 1 : 0) < 0);
					FCarry = (dirtySum < 0);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = true;
				},
				//SBC A, C
				//#0x99:
				function ():void {
					var dirtySum:uint = registerA - registerC - ((FCarry) ? 1 : 0);
					FHalfCarry = ((registerA & 0xF) - (registerC & 0xF) - ((FCarry) ? 1 : 0) < 0);
					FCarry = (dirtySum < 0);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = true;
				},
				//SBC A, D
				//#0x9A:
				function ():void {
					var dirtySum:uint = registerA - registerD - ((FCarry) ? 1 : 0);
					FHalfCarry = ((registerA & 0xF) - (registerD & 0xF) - ((FCarry) ? 1 : 0) < 0);
					FCarry = (dirtySum < 0);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = true;
				},
				//SBC A, E
				//#0x9B:
				function ():void {
					var dirtySum:uint = registerA - registerE - ((FCarry) ? 1 : 0);
					FHalfCarry = ((registerA & 0xF) - (registerE & 0xF) - ((FCarry) ? 1 : 0) < 0);
					FCarry = (dirtySum < 0);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = true;
				},
				//SBC A, H
				//#0x9C:
				function ():void {
					var temp_var:uint = registersHL >> 8;
					var dirtySum:uint = registerA - temp_var - ((FCarry) ? 1 : 0);
					FHalfCarry = ((registerA & 0xF) - (temp_var & 0xF) - ((FCarry) ? 1 : 0) < 0);
					FCarry = (dirtySum < 0);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = true;
				},
				//SBC A, L
				//#0x9D:
				function ():void {
					var dirtySum:uint = registerA - (registersHL & 0xFF) - ((FCarry) ? 1 : 0);
					FHalfCarry = ((registerA & 0xF) - (registersHL & 0xF) - ((FCarry) ? 1 : 0) < 0);
					FCarry = (dirtySum < 0);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = true;
				},
				//SBC A, (HL)
				//#0x9E:
				function ():void {
					var temp_var:uint = memoryReader[registersHL](registersHL);
					var dirtySum:uint = registerA - temp_var - ((FCarry) ? 1 : 0);
					FHalfCarry = ((registerA & 0xF) - (temp_var & 0xF) - ((FCarry) ? 1 : 0) < 0);
					FCarry = (dirtySum < 0);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = true;
				},
				//SBC A, A
				//#0x9F:
				function ():void {
					//Optimized SBC A:
					if (FCarry) {
						FZero = false;
						FSubtract = FHalfCarry = FCarry = true;
						registerA = 0xFF;
					}
					else {
						FHalfCarry = FCarry = false;
						FSubtract = FZero = true;
						registerA = 0;
					}
				},
				//AND B
				//#0xA0:
				function ():void {
					registerA &= registerB;
					FZero = (registerA == 0);
					FHalfCarry = true;
					FSubtract = FCarry = false;
				},
				//AND C
				//#0xA1:
				function ():void {
					registerA &= registerC;
					FZero = (registerA == 0);
					FHalfCarry = true;
					FSubtract = FCarry = false;
				},
				//AND D
				//#0xA2:
				function ():void {
					registerA &= registerD;
					FZero = (registerA == 0);
					FHalfCarry = true;
					FSubtract = FCarry = false;
				},
				//AND E
				//#0xA3:
				function ():void {
					registerA &= registerE;
					FZero = (registerA == 0);
					FHalfCarry = true;
					FSubtract = FCarry = false;
				},
				//AND H
				//#0xA4:
				function ():void {
					registerA &= (registersHL >> 8);
					FZero = (registerA == 0);
					FHalfCarry = true;
					FSubtract = FCarry = false;
				},
				//AND L
				//#0xA5:
				function ():void {
					registerA &= registersHL;
					FZero = (registerA == 0);
					FHalfCarry = true;
					FSubtract = FCarry = false;
				},
				//AND (HL)
				//#0xA6:
				function ():void {
					registerA &= memoryReader[registersHL](registersHL);
					FZero = (registerA == 0);
					FHalfCarry = true;
					FSubtract = FCarry = false;
				},
				//AND A
				//#0xA7:
				function ():void {
					//number & same number = same number
					FZero = (registerA == 0);
					FHalfCarry = true;
					FSubtract = FCarry = false;
				},
				//XOR B
				//#0xA8:
				function ():void {
					registerA ^= registerB;
					FZero = (registerA == 0);
					FSubtract = FHalfCarry = FCarry = false;
				},
				//XOR C
				//#0xA9:
				function ():void {
					registerA ^= registerC;
					FZero = (registerA == 0);
					FSubtract = FHalfCarry = FCarry = false;
				},
				//XOR D
				//#0xAA:
				function ():void {
					registerA ^= registerD;
					FZero = (registerA == 0);
					FSubtract = FHalfCarry = FCarry = false;
				},
				//XOR E
				//#0xAB:
				function ():void {
					registerA ^= registerE;
					FZero = (registerA == 0);
					FSubtract = FHalfCarry = FCarry = false;
				},
				//XOR H
				//#0xAC:
				function ():void {
					registerA ^= (registersHL >> 8);
					FZero = (registerA == 0);
					FSubtract = FHalfCarry = FCarry = false;
				},
				//XOR L
				//#0xAD:
				function ():void {
					registerA ^= (registersHL & 0xFF);
					FZero = (registerA == 0);
					FSubtract = FHalfCarry = FCarry = false;
				},
				//XOR (HL)
				//#0xAE:
				function ():void {
					registerA ^= memoryReader[registersHL](registersHL);
					FZero = (registerA == 0);
					FSubtract = FHalfCarry = FCarry = false;
				},
				//XOR A
				//#0xAF:
				function ():void {
					//number ^ same number == 0
					registerA = 0;
					FZero = true;
					FSubtract = FHalfCarry = FCarry = false;
				},
				//OR B
				//#0xB0:
				function ():void {
					registerA |= registerB;
					FZero = (registerA == 0);
					FSubtract = FCarry = FHalfCarry = false;
				},
				//OR C
				//#0xB1:
				function ():void {
					registerA |= registerC;
					FZero = (registerA == 0);
					FSubtract = FCarry = FHalfCarry = false;
				},
				//OR D
				//#0xB2:
				function ():void {
					registerA |= registerD;
					FZero = (registerA == 0);
					FSubtract = FCarry = FHalfCarry = false;
				},
				//OR E
				//#0xB3:
				function ():void {
					registerA |= registerE;
					FZero = (registerA == 0);
					FSubtract = FCarry = FHalfCarry = false;
				},
				//OR H
				//#0xB4:
				function ():void {
					registerA |= (registersHL >> 8);
					FZero = (registerA == 0);
					FSubtract = FCarry = FHalfCarry = false;
				},
				//OR L
				//#0xB5:
				function ():void {
					registerA |= (registersHL & 0xFF);
					FZero = (registerA == 0);
					FSubtract = FCarry = FHalfCarry = false;
				},
				//OR (HL)
				//#0xB6:
				function ():void {
					registerA |= memoryReader[registersHL](registersHL);
					FZero = (registerA == 0);
					FSubtract = FCarry = FHalfCarry = false;
				},
				//OR A
				//#0xB7:
				function ():void {
					//number | same number == same number
					FZero = (registerA == 0);
					FSubtract = FCarry = FHalfCarry = false;
				},
				//CP B
				//#0xB8:
				function ():void {
					var dirtySum:uint = registerA - registerB;
					FHalfCarry = ((dirtySum & 0xF) > (registerA & 0xF));
					FCarry = (dirtySum < 0);
					FZero = (dirtySum == 0);
					FSubtract = true;
				},
				//CP C
				//#0xB9:
				function ():void {
					var dirtySum:uint = registerA - registerC;
					FHalfCarry = ((dirtySum & 0xF) > (registerA & 0xF));
					FCarry = (dirtySum < 0);
					FZero = (dirtySum == 0);
					FSubtract = true;
				},
				//CP D
				//#0xBA:
				function ():void {
					var dirtySum:uint = registerA - registerD;
					FHalfCarry = ((dirtySum & 0xF) > (registerA & 0xF));
					FCarry = (dirtySum < 0);
					FZero = (dirtySum == 0);
					FSubtract = true;
				},
				//CP E
				//#0xBB:
				function ():void {
					var dirtySum:uint = registerA - registerE;
					FHalfCarry = ((dirtySum & 0xF) > (registerA & 0xF));
					FCarry = (dirtySum < 0);
					FZero = (dirtySum == 0);
					FSubtract = true;
				},
				//CP H
				//#0xBC:
				function ():void {
					var dirtySum:uint = registerA - (registersHL >> 8);
					FHalfCarry = ((dirtySum & 0xF) > (registerA & 0xF));
					FCarry = (dirtySum < 0);
					FZero = (dirtySum == 0);
					FSubtract = true;
				},
				//CP L
				//#0xBD:
				function ():void {
					var dirtySum:uint = registerA - (registersHL & 0xFF);
					FHalfCarry = ((dirtySum & 0xF) > (registerA & 0xF));
					FCarry = (dirtySum < 0);
					FZero = (dirtySum == 0);
					FSubtract = true;
				},
				//CP (HL)
				//#0xBE:
				function ():void {
					var dirtySum:uint = registerA - memoryReader[registersHL](registersHL);
					FHalfCarry = ((dirtySum & 0xF) > (registerA & 0xF));
					FCarry = (dirtySum < 0);
					FZero = (dirtySum == 0);
					FSubtract = true;
				},
				//CP A
				//#0xBF:
				function ():void {
					FHalfCarry = FCarry = false;
					FZero = FSubtract = true;
				},
				//RET !FZ
				//#0xC0:
				function ():void {
					if (!FZero) {
						programCounter = (memoryRead((stackPointer + 1) & 0xFFFF) << 8) | memoryReader[stackPointer](stackPointer);
						stackPointer = (stackPointer + 2) & 0xFFFF;
						CPUTicks += 12;
					}
				},
				//POP BC
				//#0xC1:
				function ():void {
					registerC = memoryReader[stackPointer](stackPointer);
					registerB = memoryRead((stackPointer + 1) & 0xFFFF);
					stackPointer = (stackPointer + 2) & 0xFFFF;
				},
				//JP !FZ, nn
				//#0xC2:
				function ():void {
					if (!FZero) {
						programCounter = (memoryRead((programCounter + 1) & 0xFFFF) << 8) | memoryReader[programCounter](programCounter);
						CPUTicks += 4;
					}
					else {
						programCounter = (programCounter + 2) & 0xFFFF;
					}
				},
				//JP nn
				//#0xC3:
				function ():void {
					programCounter = (memoryRead((programCounter + 1) & 0xFFFF) << 8) | memoryReader[programCounter](programCounter);
				},
				//CALL !FZ, nn
				//#0xC4:
				function ():void {
					if (!FZero) {
						var temp_pc:uint = (memoryRead((programCounter + 1) & 0xFFFF) << 8) | memoryReader[programCounter](programCounter);
						programCounter = (programCounter + 2) & 0xFFFF;
						stackPointer = (stackPointer - 1) & 0xFFFF;
						memoryWriter[stackPointer](stackPointer, programCounter >> 8);
						stackPointer = (stackPointer - 1) & 0xFFFF;
						memoryWriter[stackPointer](stackPointer, programCounter & 0xFF);
						programCounter = temp_pc;
						CPUTicks += 12;
					}
					else {
						programCounter = (programCounter + 2) & 0xFFFF;
					}
				},
				//PUSH BC
				//#0xC5:
				function ():void {
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, registerB);
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, registerC);
				},
				//ADD, n
				//#0xC6:
				function ():void {
					var dirtySum:uint = registerA + memoryReader[programCounter](programCounter);
					programCounter = (programCounter + 1) & 0xFFFF;
					FHalfCarry = ((dirtySum & 0xF) < (registerA & 0xF));
					FCarry = (dirtySum > 0xFF);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = false;
				},
				//RST 0
				//#0xC7:
				function ():void {
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, programCounter >> 8);
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, programCounter & 0xFF);
					programCounter = 0;
				},
				//RET FZ
				//#0xC8:
				function ():void {
					if (FZero) {
						programCounter = (memoryRead((stackPointer + 1) & 0xFFFF) << 8) | memoryReader[stackPointer](stackPointer);
						stackPointer = (stackPointer + 2) & 0xFFFF;
						CPUTicks += 12;
					}
				},
				//RET
				//#0xC9:
				function ():void {
					programCounter =  (memoryRead((stackPointer + 1) & 0xFFFF) << 8) | memoryReader[stackPointer](stackPointer);
					stackPointer = (stackPointer + 2) & 0xFFFF;
				},
				//JP FZ, nn
				//#0xCA:
				function ():void {
					if (FZero) {
						programCounter = (memoryRead((programCounter + 1) & 0xFFFF) << 8) | memoryReader[programCounter](programCounter);
						CPUTicks += 4;
					}
					else {
						programCounter = (programCounter + 2) & 0xFFFF;
					}
				},
				//Secondary OP Code Set:
				//#0xCB:
				function ():void {
					var opcode:uint = memoryReader[programCounter](programCounter);
					//Increment the program counter to the next instruction:
					programCounter = (programCounter + 1) & 0xFFFF;
					//Get how many CPU cycles the current 0xCBXX op code counts for:
					CPUTicks += SecondaryTICKTable[opcode];
					//Execute secondary OP codes for the 0xCB OP code call.
					CBOPCODE[opcode]();
				},
				//CALL FZ, nn
				//#0xCC:
				function ():void {
					if (FZero) {
						var temp_pc:uint = (memoryRead((programCounter + 1) & 0xFFFF) << 8) | memoryReader[programCounter](programCounter);
						programCounter = (programCounter + 2) & 0xFFFF;
						stackPointer = (stackPointer - 1) & 0xFFFF;
						memoryWriter[stackPointer](stackPointer, programCounter >> 8);
						stackPointer = (stackPointer - 1) & 0xFFFF;
						memoryWriter[stackPointer](stackPointer, programCounter & 0xFF);
						programCounter = temp_pc;
						CPUTicks += 12;
					}
					else {
						programCounter = (programCounter + 2) & 0xFFFF;
					}
				},
				//CALL nn
				//#0xCD:
				function ():void {
					var temp_pc:uint = (memoryRead((programCounter + 1) & 0xFFFF) << 8) | memoryReader[programCounter](programCounter);
					programCounter = (programCounter + 2) & 0xFFFF;
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, programCounter >> 8);
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, programCounter & 0xFF);
					programCounter = temp_pc;
				},
				//ADC A, n
				//#0xCE:
				function ():void {
					var tempValue:uint = memoryReader[programCounter](programCounter);
					programCounter = (programCounter + 1) & 0xFFFF;
					var dirtySum:uint = registerA + tempValue + ((FCarry) ? 1 : 0);
					FHalfCarry = ((registerA & 0xF) + (tempValue & 0xF) + ((FCarry) ? 1 : 0) > 0xF);
					FCarry = (dirtySum > 0xFF);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = false;
				},
				//RST 0x8
				//#0xCF:
				function ():void {
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, programCounter >> 8);
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, programCounter & 0xFF);
					programCounter = 0x8;
				},
				//RET !FC
				//#0xD0:
				function ():void {
					if (!FCarry) {
						programCounter = (memoryRead((stackPointer + 1) & 0xFFFF) << 8) | memoryReader[stackPointer](stackPointer);
						stackPointer = (stackPointer + 2) & 0xFFFF;
						CPUTicks += 12;
					}
				},
				//POP DE
				//#0xD1:
				function ():void {
					registerE = memoryReader[stackPointer](stackPointer);
					registerD = memoryRead((stackPointer + 1) & 0xFFFF);
					stackPointer = (stackPointer + 2) & 0xFFFF;
				},
				//JP !FC, nn
				//#0xD2:
				function ():void {
					if (!FCarry) {
						programCounter = (memoryRead((programCounter + 1) & 0xFFFF) << 8) | memoryReader[programCounter](programCounter);
						CPUTicks += 4;
					}
					else {
						programCounter = (programCounter + 2) & 0xFFFF;
					}
				},
				//0xD3 - Illegal
				//#0xD3:
				function ():void {
					trace("Illegal op code 0xD3 called, pausing emulation.", 2);
					gb.pause();
				},
				//CALL !FC, nn
				//#0xD4:
				function ():void {
					if (!FCarry) {
						var temp_pc:uint = (memoryRead((programCounter + 1) & 0xFFFF) << 8) | memoryReader[programCounter](programCounter);
						programCounter = (programCounter + 2) & 0xFFFF;
						stackPointer = (stackPointer - 1) & 0xFFFF;
						memoryWriter[stackPointer](stackPointer, programCounter >> 8);
						stackPointer = (stackPointer - 1) & 0xFFFF;
						memoryWriter[stackPointer](stackPointer, programCounter & 0xFF);
						programCounter = temp_pc;
						CPUTicks += 12;
					}
					else {
						programCounter = (programCounter + 2) & 0xFFFF;
					}
				},
				//PUSH DE
				//#0xD5:
				function ():void {
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, registerD);
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, registerE);
				},
				//SUB A, n
				//#0xD6:
				function ():void {
					var dirtySum:uint = registerA - memoryReader[programCounter](programCounter);
					programCounter = (programCounter + 1) & 0xFFFF;
					FHalfCarry = ((registerA & 0xF) < (dirtySum & 0xF));
					FCarry = (dirtySum < 0);
					registerA = dirtySum & 0xFF;
					FZero = (dirtySum == 0);
					FSubtract = true;
				},
				//RST 0x10
				//#0xD7:
				function ():void {
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, programCounter >> 8);
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, programCounter & 0xFF);
					programCounter = 0x10;
				},
				//RET FC
				//#0xD8:
				function ():void {
					if (FCarry) {
						programCounter = (memoryRead((stackPointer + 1) & 0xFFFF) << 8) | memoryReader[stackPointer](stackPointer);
						stackPointer = (stackPointer + 2) & 0xFFFF;
						CPUTicks += 12;
					}
				},
				//RETI
				//#0xD9:
				function ():void {
					programCounter = (memoryRead((stackPointer + 1) & 0xFFFF) << 8) | memoryReader[stackPointer](stackPointer);
					stackPointer = (stackPointer + 2) & 0xFFFF;
					//Immediate for HALT:
					IRQEnableDelay = (IRQEnableDelay == 2 || memoryReader[programCounter](programCounter) == 0x76) ? 1 : 2;
				},
				//JP FC, nn
				//#0xDA:
				function ():void {
					if (FCarry) {
						programCounter = (memoryRead((programCounter + 1) & 0xFFFF) << 8) | memoryReader[programCounter](programCounter);
						CPUTicks += 4;
					}
					else {
						programCounter = (programCounter + 2) & 0xFFFF;
					}
				},
				//0xDB - Illegal
				//#0xDB:
				function ():void {
					trace("Illegal op code 0xDB called, pausing emulation.", 2);
					gb.pause();
				},
				//CALL FC, nn
				//#0xDC:
				function ():void {
					if (FCarry) {
						var temp_pc:uint = (memoryRead((programCounter + 1) & 0xFFFF) << 8) | memoryReader[programCounter](programCounter);
						programCounter = (programCounter + 2) & 0xFFFF;
						stackPointer = (stackPointer - 1) & 0xFFFF;
						memoryWriter[stackPointer](stackPointer, programCounter >> 8);
						stackPointer = (stackPointer - 1) & 0xFFFF;
						memoryWriter[stackPointer](stackPointer, programCounter & 0xFF);
						programCounter = temp_pc;
						CPUTicks += 12;
					}
					else {
						programCounter = (programCounter + 2) & 0xFFFF;
					}
				},
				//0xDD - Illegal
				//#0xDD:
				function ():void {
					trace("Illegal op code 0xDD called, pausing emulation.", 2);
					gb.pause();
				},
				//SBC A, n
				//#0xDE:
				function ():void {
					var temp_var:uint = memoryReader[programCounter](programCounter);
					programCounter = (programCounter + 1) & 0xFFFF;
					var dirtySum:uint = registerA - temp_var - ((FCarry) ? 1 : 0);
					FHalfCarry = ((registerA & 0xF) - (temp_var & 0xF) - ((FCarry) ? 1 : 0) < 0);
					FCarry = (dirtySum < 0);
					registerA = dirtySum & 0xFF;
					FZero = (registerA == 0);
					FSubtract = true;
				},
				//RST 0x18
				//#0xDF:
				function ():void {
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, programCounter >> 8);
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, programCounter & 0xFF);
					programCounter = 0x18;
				},
				//LDH (n), A
				//#0xE0:
				function ():void {
					memoryHighWrite(memoryReader[programCounter](programCounter), registerA);
					programCounter = (programCounter + 1) & 0xFFFF;
				},
				//POP HL
				//#0xE1:
				function ():void {
					registersHL = (memoryRead((stackPointer + 1) & 0xFFFF) << 8) | memoryReader[stackPointer](stackPointer);
					stackPointer = (stackPointer + 2) & 0xFFFF;
				},
				//LD (0xFF00 + C), A
				//#0xE2:
				function ():void {
					memoryHighWriter[registerC](registerC, registerA);
				},
				//0xE3 - Illegal
				//#0xE3:
				function ():void {
					trace("Illegal op code 0xE3 called, pausing emulation.", 2);
					gb.pause();
				},
				//0xE4 - Illegal
				//#0xE4:
				function ():void {
					trace("Illegal op code 0xE4 called, pausing emulation.", 2);
					gb.pause();
				},
				//PUSH HL
				//#0xE5:
				function ():void {
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, registersHL >> 8);
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, registersHL & 0xFF);
				},
				//AND n
				//#0xE6:
				function ():void {
					registerA &= memoryReader[programCounter](programCounter);
					programCounter = (programCounter + 1) & 0xFFFF;
					FZero = (registerA == 0);
					FHalfCarry = true;
					FSubtract = FCarry = false;
				},
				//RST 0x20
				//#0xE7:
				function ():void {
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, programCounter >> 8);
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, programCounter & 0xFF);
					programCounter = 0x20;
				},
				//ADD SP, n
				//#0xE8:
				function ():void {
					var temp_value2:uint = (memoryReader[programCounter](programCounter) << 24) >> 24;
					programCounter = (programCounter + 1) & 0xFFFF;
					var temp_value:uint = (stackPointer + temp_value2) & 0xFFFF;
					temp_value2 = stackPointer ^ temp_value2 ^ temp_value;
					stackPointer = temp_value;
					FCarry = ((temp_value2 & 0x100) == 0x100);
					FHalfCarry = ((temp_value2 & 0x10) == 0x10);
					FZero = FSubtract = false;
				},
				//JP, (HL)
				//#0xE9:
				function ():void {
					programCounter = registersHL;
				},
				//LD n, A
				//#0xEA:
				function ():void {
					memoryWrite((memoryRead((programCounter + 1) & 0xFFFF) << 8) | memoryReader[programCounter](programCounter), registerA);
					programCounter = (programCounter + 2) & 0xFFFF;
				},
				//0xEB - Illegal
				//#0xEB:
				function ():void {
					trace("Illegal op code 0xEB called, pausing emulation.", 2);
					gb.pause();
				},
				//0xEC - Illegal
				//#0xEC:
				function ():void {
					trace("Illegal op code 0xEC called, pausing emulation.", 2);
					gb.pause();
				},
				//0xED - Illegal
				//#0xED:
				function ():void {
					trace("Illegal op code 0xED called, pausing emulation.", 2);
					gb.pause();
				},
				//XOR n
				//#0xEE:
				function ():void {
					registerA ^= memoryReader[programCounter](programCounter);
					programCounter = (programCounter + 1) & 0xFFFF;
					FZero = (registerA == 0);
					FSubtract = FHalfCarry = FCarry = false;
				},
				//RST 0x28
				//#0xEF:
				function ():void {
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, programCounter >> 8);
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, programCounter & 0xFF);
					programCounter = 0x28;
				},
				//LDH A, (n)
				//#0xF0:
				function ():void {
					registerA = memoryHighRead(memoryReader[programCounter](programCounter));
					programCounter = (programCounter + 1) & 0xFFFF;
				},
				//POP AF
				//#0xF1:
				function ():void {
					var temp_var:uint = memoryReader[stackPointer](stackPointer);
					FZero = (temp_var > 0x7F);
					FSubtract = ((temp_var & 0x40) == 0x40);
					FHalfCarry = ((temp_var & 0x20) == 0x20);
					FCarry = ((temp_var & 0x10) == 0x10);
					registerA = memoryRead((stackPointer + 1) & 0xFFFF);
					stackPointer = (stackPointer + 2) & 0xFFFF;
				},
				//LD A, (0xFF00 + C)
				//#0xF2:
				function ():void {
					registerA = memoryHighReader[registerC](registerC);
				},
				//DI
				//#0xF3:
				function ():void {
					IME = false;
					IRQEnableDelay = 0;
				},
				//0xF4 - Illegal
				//#0xF4:
				function ():void {
					trace("Illegal op code 0xF4 called, pausing emulation.", 2);
					gb.pause();
				},
				//PUSH AF
				//#0xF5:
				function ():void {
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, registerA);
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, ((FZero) ? 0x80 : 0) | ((FSubtract) ? 0x40 : 0) | ((FHalfCarry) ? 0x20 : 0) | ((FCarry) ? 0x10 : 0));
				},
				//OR n
				//#0xF6:
				function ():void {
					registerA |= memoryReader[programCounter](programCounter);
					FZero = (registerA == 0);
					programCounter = (programCounter + 1) & 0xFFFF;
					FSubtract = FCarry = FHalfCarry = false;
				},
				//RST 0x30
				//#0xF7:
				function ():void {
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, programCounter >> 8);
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, programCounter & 0xFF);
					programCounter = 0x30;
				},
				//LDHL SP, n
				//#0xF8:
				function ():void {
					var temp_var:uint = (memoryReader[programCounter](programCounter) << 24) >> 24;
					programCounter = (programCounter + 1) & 0xFFFF;
					registersHL = (stackPointer + temp_var) & 0xFFFF;
					temp_var = stackPointer ^ temp_var ^ registersHL;
					FCarry = ((temp_var & 0x100) == 0x100);
					FHalfCarry = ((temp_var & 0x10) == 0x10);
					FZero = FSubtract = false;
				},
				//LD SP, HL
				//#0xF9:
				function ():void {
					stackPointer = registersHL;
				},
				//LD A, (nn)
				//#0xFA:
				function ():void {
					registerA = memoryRead((memoryRead((programCounter + 1) & 0xFFFF) << 8) | memoryReader[programCounter](programCounter));
					programCounter = (programCounter + 2) & 0xFFFF;
				},
				//EI
				//#0xFB:
				function ():void {
					//Immediate for HALT:
					IRQEnableDelay = (IRQEnableDelay == 2 || memoryReader[programCounter](programCounter) == 0x76) ? 1 : 2;
				},
				//0xFC - Illegal
				//#0xFC:
				function ():void {
					trace("Illegal op code 0xFC called, pausing emulation.", 2);
					gb.pause();
				},
				//0xFD - Illegal
				//#0xFD:
				function ():void {
					trace("Illegal op code 0xFD called, pausing emulation.", 2);
					gb.pause();
				},
				//CP n
				//#0xFE:
				function ():void {
					var dirtySum:uint = registerA - memoryReader[programCounter](programCounter);
					programCounter = (programCounter + 1) & 0xFFFF;
					FHalfCarry = ((dirtySum & 0xF) > (registerA & 0xF));
					FCarry = (dirtySum < 0);
					FZero = (dirtySum == 0);
					FSubtract = true;
				},
				//RST 0x38
				//#0xFF:
				function ():void {
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, programCounter >> 8);
					stackPointer = (stackPointer - 1) & 0xFFFF;
					memoryWriter[stackPointer](stackPointer, programCounter & 0xFF);
					programCounter = 0x38;
				}
			], "function");
			this.CBOPCODE = toVector([
				//RLC B
				//#0x00:
				function ():void {
					FCarry = (registerB > 0x7F);
					registerB = ((registerB << 1) & 0xFF) | ((FCarry) ? 1 : 0);
					FHalfCarry = FSubtract = false;
					FZero = (registerB == 0);
				}
				//RLC C
				//#0x01:
				,function ():void {
					FCarry = (registerC > 0x7F);
					registerC = ((registerC << 1) & 0xFF) | ((FCarry) ? 1 : 0);
					FHalfCarry = FSubtract = false;
					FZero = (registerC == 0);
				}
				//RLC D
				//#0x02:
				,function ():void {
					FCarry = (registerD > 0x7F);
					registerD = ((registerD << 1) & 0xFF) | ((FCarry) ? 1 : 0);
					FHalfCarry = FSubtract = false;
					FZero = (registerD == 0);
				}
				//RLC E
				//#0x03:
				,function ():void {
					FCarry = (registerE > 0x7F);
					registerE = ((registerE << 1) & 0xFF) | ((FCarry) ? 1 : 0);
					FHalfCarry = FSubtract = false;
					FZero = (registerE == 0);
				}
				//RLC H
				//#0x04:
				,function ():void {
					FCarry = (registersHL > 0x7FFF);
					registersHL = ((registersHL << 1) & 0xFE00) | ((FCarry) ? 0x100 : 0) | (registersHL & 0xFF);
					FHalfCarry = FSubtract = false;
					FZero = (registersHL < 0x100);
				}
				//RLC L
				//#0x05:
				,function ():void {
					FCarry = ((registersHL & 0x80) == 0x80);
					registersHL = (registersHL & 0xFF00) | ((registersHL << 1) & 0xFF) | ((FCarry) ? 1 : 0);
					FHalfCarry = FSubtract = false;
					FZero = ((registersHL & 0xFF) == 0);
				}
				//RLC (HL)
				//#0x06:
				,function ():void {
					var temp_var:uint = memoryReader[registersHL](registersHL);
					FCarry = (temp_var > 0x7F);
					temp_var = ((temp_var << 1) & 0xFF) | ((FCarry) ? 1 : 0);
					memoryWriter[registersHL](registersHL, temp_var);
					FHalfCarry = FSubtract = false;
					FZero = (temp_var == 0);
					}
					//RLC A
					//#0x07:
					,function ():void {
						FCarry = (registerA > 0x7F);
						registerA = ((registerA << 1) & 0xFF) | ((FCarry) ? 1 : 0);
						FHalfCarry = FSubtract = false;
						FZero = (registerA == 0);
					}
					//RRC B
					//#0x08:
					,function ():void {
						FCarry = ((registerB & 0x01) == 0x01);
						registerB = ((FCarry) ? 0x80 : 0) | (registerB >> 1);
						FHalfCarry = FSubtract = false;
						FZero = (registerB == 0);
					}
					//RRC C
					//#0x09:
					,function ():void {
						FCarry = ((registerC & 0x01) == 0x01);
						registerC = ((FCarry) ? 0x80 : 0) | (registerC >> 1);
						FHalfCarry = FSubtract = false;
						FZero = (registerC == 0);
					}
					//RRC D
					//#0x0A:
					,function ():void {
						FCarry = ((registerD & 0x01) == 0x01);
						registerD = ((FCarry) ? 0x80 : 0) | (registerD >> 1);
						FHalfCarry = FSubtract = false;
						FZero = (registerD == 0);
					}
					//RRC E
					//#0x0B:
					,function ():void {
						FCarry = ((registerE & 0x01) == 0x01);
						registerE = ((FCarry) ? 0x80 : 0) | (registerE >> 1);
						FHalfCarry = FSubtract = false;
						FZero = (registerE == 0);
					}
					//RRC H
					//#0x0C:
					,function ():void {
						FCarry = ((registersHL & 0x0100) == 0x0100);
						registersHL = ((FCarry) ? 0x8000 : 0) | ((registersHL >> 1) & 0xFF00) | (registersHL & 0xFF);
						FHalfCarry = FSubtract = false;
						FZero = (registersHL < 0x100);
					}
					//RRC L
					//#0x0D:
					,function ():void {
						FCarry = ((registersHL & 0x01) == 0x01);
						registersHL = (registersHL & 0xFF00) | ((FCarry) ? 0x80 : 0) | ((registersHL & 0xFF) >> 1);
						FHalfCarry = FSubtract = false;
						FZero = ((registersHL & 0xFF) == 0);
					}
					//RRC (HL)
					//#0x0E:
					,function ():void {
						var temp_var:uint = memoryReader[registersHL](registersHL);
						FCarry = ((temp_var & 0x01) == 0x01);
						temp_var = ((FCarry) ? 0x80 : 0) | (temp_var >> 1);
						memoryWriter[registersHL](registersHL, temp_var);
						FHalfCarry = FSubtract = false;
						FZero = (temp_var == 0);
					}
					//RRC A
					//#0x0F:
					,function ():void {
						FCarry = ((registerA & 0x01) == 0x01);
						registerA = ((FCarry) ? 0x80 : 0) | (registerA >> 1);
						FHalfCarry = FSubtract = false;
						FZero = (registerA == 0);
					}
					//RL B
					//#0x10:
					,function ():void {
						var newFCarry:uint = (registerB > 0x7F);
						registerB = ((registerB << 1) & 0xFF) | ((FCarry) ? 1 : 0);
						FCarry = newFCarry;
						FHalfCarry = FSubtract = false;
						FZero = (registerB == 0);
					}
					//RL C
					//#0x11:
					,function ():void {
						var newFCarry:uint = (registerC > 0x7F);
						registerC = ((registerC << 1) & 0xFF) | ((FCarry) ? 1 : 0);
						FCarry = newFCarry;
						FHalfCarry = FSubtract = false;
						FZero = (registerC == 0);
					}
					//RL D
					//#0x12:
					,function ():void {
						var newFCarry:uint = (registerD > 0x7F);
						registerD = ((registerD << 1) & 0xFF) | ((FCarry) ? 1 : 0);
						FCarry = newFCarry;
						FHalfCarry = FSubtract = false;
						FZero = (registerD == 0);
					}
					//RL E
					//#0x13:
					,function ():void {
						var newFCarry:uint = (registerE > 0x7F);
						registerE = ((registerE << 1) & 0xFF) | ((FCarry) ? 1 : 0);
						FCarry = newFCarry;
						FHalfCarry = FSubtract = false;
						FZero = (registerE == 0);
					}
					//RL H
					//#0x14:
					,function ():void {
						var newFCarry:uint = (registersHL > 0x7FFF);
						registersHL = ((registersHL << 1) & 0xFE00) | ((FCarry) ? 0x100 : 0) | (registersHL & 0xFF);
						FCarry = newFCarry;
						FHalfCarry = FSubtract = false;
						FZero = (registersHL < 0x100);
					}
					//RL L
					//#0x15:
					,function ():void {
						var newFCarry:uint = ((registersHL & 0x80) == 0x80);
						registersHL = (registersHL & 0xFF00) | ((registersHL << 1) & 0xFF) | ((FCarry) ? 1 : 0);
						FCarry = newFCarry;
						FHalfCarry = FSubtract = false;
						FZero = ((registersHL & 0xFF) == 0);
					}
					//RL (HL)
					//#0x16:
					,function ():void {
						var temp_var:uint = memoryReader[registersHL](registersHL);
						var newFCarry:uint = (temp_var > 0x7F);
						temp_var = ((temp_var << 1) & 0xFF) | ((FCarry) ? 1 : 0);
						FCarry = newFCarry;
						memoryWriter[registersHL](registersHL, temp_var);
						FHalfCarry = FSubtract = false;
						FZero = (temp_var == 0);
					}
					//RL A
					//#0x17:
					,function ():void {
						var newFCarry:uint = (registerA > 0x7F);
						registerA = ((registerA << 1) & 0xFF) | ((FCarry) ? 1 : 0);
						FCarry = newFCarry;
						FHalfCarry = FSubtract = false;
						FZero = (registerA == 0);
					}
					//RR B
					//#0x18:
					,function ():void {
						var newFCarry:uint = ((registerB & 0x01) == 0x01);
						registerB = ((FCarry) ? 0x80 : 0) | (registerB >> 1);
						FCarry = newFCarry;
						FHalfCarry = FSubtract = false;
						FZero = (registerB == 0);
					}
					//RR C
					//#0x19:
					,function ():void {
						var newFCarry:uint = ((registerC & 0x01) == 0x01);
						registerC = ((FCarry) ? 0x80 : 0) | (registerC >> 1);
						FCarry = newFCarry;
						FHalfCarry = FSubtract = false;
						FZero = (registerC == 0);
					}
					//RR D
					//#0x1A:
					,function ():void {
						var newFCarry:uint = ((registerD & 0x01) == 0x01);
						registerD = ((FCarry) ? 0x80 : 0) | (registerD >> 1);
						FCarry = newFCarry;
						FHalfCarry = FSubtract = false;
						FZero = (registerD == 0);
					}
					//RR E
					//#0x1B:
					,function ():void {
						var newFCarry:uint = ((registerE & 0x01) == 0x01);
						registerE = ((FCarry) ? 0x80 : 0) | (registerE >> 1);
						FCarry = newFCarry;
						FHalfCarry = FSubtract = false;
						FZero = (registerE == 0);
					}
					//RR H
					//#0x1C:
					,function ():void {
						var newFCarry:uint = ((registersHL & 0x0100) == 0x0100);
						registersHL = ((FCarry) ? 0x8000 : 0) | ((registersHL >> 1) & 0xFF00) | (registersHL & 0xFF);
						FCarry = newFCarry;
						FHalfCarry = FSubtract = false;
						FZero = (registersHL < 0x100);
					}
					//RR L
					//#0x1D:
					,function ():void {
						var newFCarry:uint = ((registersHL & 0x01) == 0x01);
						registersHL = (registersHL & 0xFF00) | ((FCarry) ? 0x80 : 0) | ((registersHL & 0xFF) >> 1);
						FCarry = newFCarry;
						FHalfCarry = FSubtract = false;
						FZero = ((registersHL & 0xFF) == 0);
					}
					//RR (HL)
					//#0x1E:
					,function ():void {
						var temp_var:uint = memoryReader[registersHL](registersHL);
						var newFCarry:uint = ((temp_var & 0x01) == 0x01);
						temp_var = ((FCarry) ? 0x80 : 0) | (temp_var >> 1);
						FCarry = newFCarry;
						memoryWriter[registersHL](registersHL, temp_var);
						FHalfCarry = FSubtract = false;
						FZero = (temp_var == 0);
					}
					//RR A
					//#0x1F:
					,function ():void {
						var newFCarry:uint = ((registerA & 0x01) == 0x01);
						registerA = ((FCarry) ? 0x80 : 0) | (registerA >> 1);
						FCarry = newFCarry;
						FHalfCarry = FSubtract = false;
						FZero = (registerA == 0);
					}
					//SLA B
					//#0x20:
					,function ():void {
						FCarry = (registerB > 0x7F);
						registerB = (registerB << 1) & 0xFF;
						FHalfCarry = FSubtract = false;
						FZero = (registerB == 0);
					}
					//SLA C
					//#0x21:
					,function ():void {
						FCarry = (registerC > 0x7F);
						registerC = (registerC << 1) & 0xFF;
						FHalfCarry = FSubtract = false;
						FZero = (registerC == 0);
					}
					//SLA D
					//#0x22:
					,function ():void {
						FCarry = (registerD > 0x7F);
						registerD = (registerD << 1) & 0xFF;
						FHalfCarry = FSubtract = false;
						FZero = (registerD == 0);
					}
					//SLA E
					//#0x23:
					,function ():void {
						FCarry = (registerE > 0x7F);
						registerE = (registerE << 1) & 0xFF;
						FHalfCarry = FSubtract = false;
						FZero = (registerE == 0);
					}
					//SLA H
					//#0x24:
					,function ():void {
						FCarry = (registersHL > 0x7FFF);
						registersHL = ((registersHL << 1) & 0xFE00) | (registersHL & 0xFF);
						FHalfCarry = FSubtract = false;
						FZero = (registersHL < 0x100);
					}
					//SLA L
					//#0x25:
					,function ():void {
						FCarry = ((registersHL & 0x0080) == 0x0080);
						registersHL = (registersHL & 0xFF00) | ((registersHL << 1) & 0xFF);
						FHalfCarry = FSubtract = false;
						FZero = ((registersHL & 0xFF) == 0);
					}
					//SLA (HL)
					//#0x26:
					,function ():void {
						var temp_var:uint = memoryReader[registersHL](registersHL);
						FCarry = (temp_var > 0x7F);
						temp_var = (temp_var << 1) & 0xFF;
						memoryWriter[registersHL](registersHL, temp_var);
						FHalfCarry = FSubtract = false;
						FZero = (temp_var == 0);
					}
					//SLA A
					//#0x27:
					,function ():void {
						FCarry = (registerA > 0x7F);
						registerA = (registerA << 1) & 0xFF;
						FHalfCarry = FSubtract = false;
						FZero = (registerA == 0);
					}
					//SRA B
					//#0x28:
					,function ():void {
						FCarry = ((registerB & 0x01) == 0x01);
						registerB = (registerB & 0x80) | (registerB >> 1);
						FHalfCarry = FSubtract = false;
						FZero = (registerB == 0);
					}
					//SRA C
					//#0x29:
					,function ():void {
						FCarry = ((registerC & 0x01) == 0x01);
						registerC = (registerC & 0x80) | (registerC >> 1);
						FHalfCarry = FSubtract = false;
						FZero = (registerC == 0);
					}
					//SRA D
					//#0x2A:
					,function ():void {
						FCarry = ((registerD & 0x01) == 0x01);
						registerD = (registerD & 0x80) | (registerD >> 1);
						FHalfCarry = FSubtract = false;
						FZero = (registerD == 0);
					}
					//SRA E
					//#0x2B:
					,function ():void {
						FCarry = ((registerE & 0x01) == 0x01);
						registerE = (registerE & 0x80) | (registerE >> 1);
						FHalfCarry = FSubtract = false;
						FZero = (registerE == 0);
					}
					//SRA H
					//#0x2C:
					,function ():void {
						FCarry = ((registersHL & 0x0100) == 0x0100);
						registersHL = ((registersHL >> 1) & 0xFF00) | (registersHL & 0x80FF);
						FHalfCarry = FSubtract = false;
						FZero = (registersHL < 0x100);
					}
					//SRA L
					//#0x2D:
					,function ():void {
						FCarry = ((registersHL & 0x0001) == 0x0001);
						registersHL = (registersHL & 0xFF80) | ((registersHL & 0xFF) >> 1);
						FHalfCarry = FSubtract = false;
						FZero = ((registersHL & 0xFF) == 0);
					}
					//SRA (HL)
					//#0x2E:
					,function ():void {
						var temp_var:uint = memoryReader[registersHL](registersHL);
						FCarry = ((temp_var & 0x01) == 0x01);
						temp_var = (temp_var & 0x80) | (temp_var >> 1);
						memoryWriter[registersHL](registersHL, temp_var);
						FHalfCarry = FSubtract = false;
						FZero = (temp_var == 0);
					}
					//SRA A
					//#0x2F:
					,function ():void {
						FCarry = ((registerA & 0x01) == 0x01);
						registerA = (registerA & 0x80) | (registerA >> 1);
						FHalfCarry = FSubtract = false;
						FZero = (registerA == 0);
					}
					//SWAP B
					//#0x30:
					,function ():void {
						registerB = ((registerB & 0xF) << 4) | (registerB >> 4);
						FZero = (registerB == 0);
						FCarry = FHalfCarry = FSubtract = false;
					}
					//SWAP C
					//#0x31:
					,function ():void {
						registerC = ((registerC & 0xF) << 4) | (registerC >> 4);
						FZero = (registerC == 0);
						FCarry = FHalfCarry = FSubtract = false;
					}
					//SWAP D
					//#0x32:
					,function ():void {
						registerD = ((registerD & 0xF) << 4) | (registerD >> 4);
						FZero = (registerD == 0);
						FCarry = FHalfCarry = FSubtract = false;
					}
					//SWAP E
					//#0x33:
					,function ():void {
						registerE = ((registerE & 0xF) << 4) | (registerE >> 4);
						FZero = (registerE == 0);
						FCarry = FHalfCarry = FSubtract = false;
					}
					//SWAP H
					//#0x34:
					,function ():void {
						registersHL = ((registersHL & 0xF00) << 4) | ((registersHL & 0xF000) >> 4) | (registersHL & 0xFF);
						FZero = (registersHL < 0x100);
						FCarry = FHalfCarry = FSubtract = false;
					}
					//SWAP L
					//#0x35:
					,function ():void {
						registersHL = (registersHL & 0xFF00) | ((registersHL & 0xF) << 4) | ((registersHL & 0xF0) >> 4);
						FZero = ((registersHL & 0xFF) == 0);
						FCarry = FHalfCarry = FSubtract = false;
					}
					//SWAP (HL)
					//#0x36:
					,function ():void {
						var temp_var:uint = memoryReader[registersHL](registersHL);
						temp_var = ((temp_var & 0xF) << 4) | (temp_var >> 4);
						memoryWriter[registersHL](registersHL, temp_var);
						FZero = (temp_var == 0);
						FCarry = FHalfCarry = FSubtract = false;
					}
					//SWAP A
					//#0x37:
					,function ():void {
						registerA = ((registerA & 0xF) << 4) | (registerA >> 4);
						FZero = (registerA == 0);
						FCarry = FHalfCarry = FSubtract = false;
					}
					//SRL B
					//#0x38:
					,function ():void {
						FCarry = ((registerB & 0x01) == 0x01);
						registerB >>= 1;
						FHalfCarry = FSubtract = false;
						FZero = (registerB == 0);
					}
					//SRL C
					//#0x39:
					,function ():void {
						FCarry = ((registerC & 0x01) == 0x01);
						registerC >>= 1;
						FHalfCarry = FSubtract = false;
						FZero = (registerC == 0);
					}
					//SRL D
					//#0x3A:
					,function ():void {
						FCarry = ((registerD & 0x01) == 0x01);
						registerD >>= 1;
						FHalfCarry = FSubtract = false;
						FZero = (registerD == 0);
					}
					//SRL E
					//#0x3B:
					,function ():void {
						FCarry = ((registerE & 0x01) == 0x01);
						registerE >>= 1;
						FHalfCarry = FSubtract = false;
						FZero = (registerE == 0);
					}
					//SRL H
					//#0x3C:
					,function ():void {
						FCarry = ((registersHL & 0x0100) == 0x0100);
						registersHL = ((registersHL >> 1) & 0xFF00) | (registersHL & 0xFF);
						FHalfCarry = FSubtract = false;
						FZero = (registersHL < 0x100);
					}
					//SRL L
					//#0x3D:
					,function ():void {
						FCarry = ((registersHL & 0x0001) == 0x0001);
						registersHL = (registersHL & 0xFF00) | ((registersHL & 0xFF) >> 1);
						FHalfCarry = FSubtract = false;
						FZero = ((registersHL & 0xFF) == 0);
					}
					//SRL (HL)
					//#0x3E:
					,function ():void {
						var temp_var:uint = memoryReader[registersHL](registersHL);
						FCarry = ((temp_var & 0x01) == 0x01);
						memoryWriter[registersHL](registersHL, temp_var >> 1);
						FHalfCarry = FSubtract = false;
						FZero = (temp_var < 2);
					}
					//SRL A
					//#0x3F:
					,function ():void {
						FCarry = ((registerA & 0x01) == 0x01);
						registerA >>= 1;
						FHalfCarry = FSubtract = false;
						FZero = (registerA == 0);
					}
					//BIT 0, B
					//#0x40:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerB & 0x01) == 0);
					}
					//BIT 0, C
					//#0x41:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerC & 0x01) == 0);
					}
					//BIT 0, D
					//#0x42:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerD & 0x01) == 0);
					}
					//BIT 0, E
					//#0x43:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerE & 0x01) == 0);
					}
					//BIT 0, H
					//#0x44:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registersHL & 0x0100) == 0);
					}
					//BIT 0, L
					//#0x45:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registersHL & 0x0001) == 0);
					}
					//BIT 0, (HL)
					//#0x46:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((memoryReader[registersHL](registersHL) & 0x01) == 0);
					}
					//BIT 0, A
					//#0x47:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerA & 0x01) == 0);
					}
					//BIT 1, B
					//#0x48:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerB & 0x02) == 0);
					}
					//BIT 1, C
					//#0x49:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerC & 0x02) == 0);
					}
					//BIT 1, D
					//#0x4A:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerD & 0x02) == 0);
					}
					//BIT 1, E
					//#0x4B:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerE & 0x02) == 0);
					}
					//BIT 1, H
					//#0x4C:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registersHL & 0x0200) == 0);
					}
					//BIT 1, L
					//#0x4D:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registersHL & 0x0002) == 0);
					}
					//BIT 1, (HL)
					//#0x4E:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((memoryReader[registersHL](registersHL) & 0x02) == 0);
					}
					//BIT 1, A
					//#0x4F:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerA & 0x02) == 0);
					}
					//BIT 2, B
					//#0x50:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerB & 0x04) == 0);
					}
					//BIT 2, C
					//#0x51:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerC & 0x04) == 0);
					}
					//BIT 2, D
					//#0x52:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerD & 0x04) == 0);
					}
					//BIT 2, E
					//#0x53:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerE & 0x04) == 0);
					}
					//BIT 2, H
					//#0x54:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registersHL & 0x0400) == 0);
					}
					//BIT 2, L
					//#0x55:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registersHL & 0x0004) == 0);
					}
					//BIT 2, (HL)
					//#0x56:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((memoryReader[registersHL](registersHL) & 0x04) == 0);
					}
					//BIT 2, A
					//#0x57:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerA & 0x04) == 0);
					}
					//BIT 3, B
					//#0x58:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerB & 0x08) == 0);
					}
					//BIT 3, C
					//#0x59:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerC & 0x08) == 0);
					}
					//BIT 3, D
					//#0x5A:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerD & 0x08) == 0);
					}
					//BIT 3, E
					//#0x5B:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerE & 0x08) == 0);
					}
					//BIT 3, H
					//#0x5C:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registersHL & 0x0800) == 0);
					}
					//BIT 3, L
					//#0x5D:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registersHL & 0x0008) == 0);
					}
					//BIT 3, (HL)
					//#0x5E:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((memoryReader[registersHL](registersHL) & 0x08) == 0);
					}
					//BIT 3, A
					//#0x5F:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerA & 0x08) == 0);
					}
					//BIT 4, B
					//#0x60:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerB & 0x10) == 0);
					}
					//BIT 4, C
					//#0x61:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerC & 0x10) == 0);
					}
					//BIT 4, D
					//#0x62:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerD & 0x10) == 0);
					}
					//BIT 4, E
					//#0x63:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerE & 0x10) == 0);
					}
					//BIT 4, H
					//#0x64:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registersHL & 0x1000) == 0);
					}
					//BIT 4, L
					//#0x65:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registersHL & 0x0010) == 0);
					}
					//BIT 4, (HL)
					//#0x66:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((memoryReader[registersHL](registersHL) & 0x10) == 0);
					}
					//BIT 4, A
					//#0x67:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerA & 0x10) == 0);
					}
					//BIT 5, B
					//#0x68:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerB & 0x20) == 0);
					}
					//BIT 5, C
					//#0x69:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerC & 0x20) == 0);
					}
					//BIT 5, D
					//#0x6A:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerD & 0x20) == 0);
					}
					//BIT 5, E
					//#0x6B:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerE & 0x20) == 0);
					}
					//BIT 5, H
					//#0x6C:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registersHL & 0x2000) == 0);
					}
					//BIT 5, L
					//#0x6D:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registersHL & 0x0020) == 0);
					}
					//BIT 5, (HL)
					//#0x6E:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((memoryReader[registersHL](registersHL) & 0x20) == 0);
					}
					//BIT 5, A
					//#0x6F:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerA & 0x20) == 0);
					}
					//BIT 6, B
					//#0x70:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerB & 0x40) == 0);
					}
					//BIT 6, C
					//#0x71:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerC & 0x40) == 0);
					}
					//BIT 6, D
					//#0x72:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerD & 0x40) == 0);
					}
					//BIT 6, E
					//#0x73:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerE & 0x40) == 0);
					}
					//BIT 6, H
					//#0x74:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registersHL & 0x4000) == 0);
					}
					//BIT 6, L
					//#0x75:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registersHL & 0x0040) == 0);
					}
					//BIT 6, (HL)
					//#0x76:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((memoryReader[registersHL](registersHL) & 0x40) == 0);
					}
					//BIT 6, A
					//#0x77:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerA & 0x40) == 0);
					}
					//BIT 7, B
					//#0x78:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerB & 0x80) == 0);
					}
					//BIT 7, C
					//#0x79:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerC & 0x80) == 0);
					}
					//BIT 7, D
					//#0x7A:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerD & 0x80) == 0);
					}
					//BIT 7, E
					//#0x7B:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerE & 0x80) == 0);
					}
					//BIT 7, H
					//#0x7C:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registersHL & 0x8000) == 0);
					}
					//BIT 7, L
					//#0x7D:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registersHL & 0x0080) == 0);
					}
					//BIT 7, (HL)
					//#0x7E:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((memoryReader[registersHL](registersHL) & 0x80) == 0);
					}
					//BIT 7, A
					//#0x7F:
					,function ():void {
						FHalfCarry = true;
						FSubtract = false;
						FZero = ((registerA & 0x80) == 0);
					}
					//RES 0, B
					//#0x80:
					,function ():void {
						registerB &= 0xFE;
					}
					//RES 0, C
					//#0x81:
					,function ():void {
						registerC &= 0xFE;
					}
					//RES 0, D
					//#0x82:
					,function ():void {
						registerD &= 0xFE;
					}
					//RES 0, E
					//#0x83:
					,function ():void {
						registerE &= 0xFE;
					}
					//RES 0, H
					//#0x84:
					,function ():void {
						registersHL &= 0xFEFF;
					}
					//RES 0, L
					//#0x85:
					,function ():void {
						registersHL &= 0xFFFE;
					}
					//RES 0, (HL)
					//#0x86:
					,function ():void {
						memoryWriter[registersHL](registersHL, memoryReader[registersHL](registersHL) & 0xFE);
					}
					//RES 0, A
					//#0x87:
					,function ():void {
						registerA &= 0xFE;
					}
					//RES 1, B
					//#0x88:
					,function ():void {
						registerB &= 0xFD;
					}
					//RES 1, C
					//#0x89:
					,function ():void {
						registerC &= 0xFD;
					}
					//RES 1, D
					//#0x8A:
					,function ():void {
						registerD &= 0xFD;
					}
					//RES 1, E
					//#0x8B:
					,function ():void {
						registerE &= 0xFD;
					}
					//RES 1, H
					//#0x8C:
					,function ():void {
						registersHL &= 0xFDFF;
					}
					//RES 1, L
					//#0x8D:
					,function ():void {
						registersHL &= 0xFFFD;
					}
					//RES 1, (HL)
					//#0x8E:
					,function ():void {
						memoryWriter[registersHL](registersHL, memoryReader[registersHL](registersHL) & 0xFD);
					}
					//RES 1, A
					//#0x8F:
					,function ():void {
						registerA &= 0xFD;
					}
					//RES 2, B
					//#0x90:
					,function ():void {
						registerB &= 0xFB;
					}
					//RES 2, C
					//#0x91:
					,function ():void {
						registerC &= 0xFB;
					}
					//RES 2, D
					//#0x92:
					,function ():void {
						registerD &= 0xFB;
					}
					//RES 2, E
					//#0x93:
					,function ():void {
						registerE &= 0xFB;
					}
					//RES 2, H
					//#0x94:
					,function ():void {
						registersHL &= 0xFBFF;
					}
					//RES 2, L
					//#0x95:
					,function ():void {
						registersHL &= 0xFFFB;
					}
					//RES 2, (HL)
					//#0x96:
					,function ():void {
						memoryWriter[registersHL](registersHL, memoryReader[registersHL](registersHL) & 0xFB);
					}
					//RES 2, A
					//#0x97:
					,function ():void {
						registerA &= 0xFB;
					}
					//RES 3, B
					//#0x98:
					,function ():void {
						registerB &= 0xF7;
					}
					//RES 3, C
					//#0x99:
					,function ():void {
						registerC &= 0xF7;
					}
					//RES 3, D
					//#0x9A:
					,function ():void {
						registerD &= 0xF7;
					}
					//RES 3, E
					//#0x9B:
					,function ():void {
						registerE &= 0xF7;
					}
					//RES 3, H
					//#0x9C:
					,function ():void {
						registersHL &= 0xF7FF;
					}
					//RES 3, L
					//#0x9D:
					,function ():void {
						registersHL &= 0xFFF7;
					}
					//RES 3, (HL)
					//#0x9E:
					,function ():void {
						memoryWriter[registersHL](registersHL, memoryReader[registersHL](registersHL) & 0xF7);
					}
					//RES 3, A
					//#0x9F:
					,function ():void {
						registerA &= 0xF7;
					}
					//RES 3, B
					//#0xA0:
					,function ():void {
						registerB &= 0xEF;
					}
					//RES 4, C
					//#0xA1:
					,function ():void {
						registerC &= 0xEF;
					}
					//RES 4, D
					//#0xA2:
					,function ():void {
						registerD &= 0xEF;
					}
					//RES 4, E
					//#0xA3:
					,function ():void {
						registerE &= 0xEF;
					}
					//RES 4, H
					//#0xA4:
					,function ():void {
						registersHL &= 0xEFFF;
					}
					//RES 4, L
					//#0xA5:
					,function ():void {
						registersHL &= 0xFFEF;
					}
					//RES 4, (HL)
					//#0xA6:
					,function ():void {
						memoryWriter[registersHL](registersHL, memoryReader[registersHL](registersHL) & 0xEF);
					}
					//RES 4, A
					//#0xA7:
					,function ():void {
						registerA &= 0xEF;
					}
					//RES 5, B
					//#0xA8:
					,function ():void {
						registerB &= 0xDF;
					}
					//RES 5, C
					//#0xA9:
					,function ():void {
						registerC &= 0xDF;
					}
					//RES 5, D
					//#0xAA:
					,function ():void {
						registerD &= 0xDF;
					}
					//RES 5, E
					//#0xAB:
					,function ():void {
						registerE &= 0xDF;
					}
					//RES 5, H
					//#0xAC:
					,function ():void {
						registersHL &= 0xDFFF;
					}
					//RES 5, L
					//#0xAD:
					,function ():void {
						registersHL &= 0xFFDF;
					}
					//RES 5, (HL)
					//#0xAE:
					,function ():void {
						memoryWriter[registersHL](registersHL, memoryReader[registersHL](registersHL) & 0xDF);
					}
					//RES 5, A
					//#0xAF:
					,function ():void {
						registerA &= 0xDF;
					}
					//RES 6, B
					//#0xB0:
					,function ():void {
						registerB &= 0xBF;
					}
					//RES 6, C
					//#0xB1:
					,function ():void {
						registerC &= 0xBF;
					}
					//RES 6, D
					//#0xB2:
					,function ():void {
						registerD &= 0xBF;
					}
					//RES 6, E
					//#0xB3:
					,function ():void {
						registerE &= 0xBF;
					}
					//RES 6, H
					//#0xB4:
					,function ():void {
						registersHL &= 0xBFFF;
					}
					//RES 6, L
					//#0xB5:
					,function ():void {
						registersHL &= 0xFFBF;
					}
					//RES 6, (HL)
					//#0xB6:
					,function ():void {
						memoryWriter[registersHL](registersHL, memoryReader[registersHL](registersHL) & 0xBF);
					}
					//RES 6, A
					//#0xB7:
					,function ():void {
						registerA &= 0xBF;
					}
					//RES 7, B
					//#0xB8:
					,function ():void {
						registerB &= 0x7F;
					}
					//RES 7, C
					//#0xB9:
					,function ():void {
						registerC &= 0x7F;
					}
					//RES 7, D
					//#0xBA:
					,function ():void {
						registerD &= 0x7F;
					}
					//RES 7, E
					//#0xBB:
					,function ():void {
						registerE &= 0x7F;
					}
					//RES 7, H
					//#0xBC:
					,function ():void {
						registersHL &= 0x7FFF;
					}
					//RES 7, L
					//#0xBD:
					,function ():void {
						registersHL &= 0xFF7F;
					}
					//RES 7, (HL)
					//#0xBE:
					,function ():void {
						memoryWriter[registersHL](registersHL, memoryReader[registersHL](registersHL) & 0x7F);
					}
					//RES 7, A
					//#0xBF:
					,function ():void {
						registerA &= 0x7F;
					}
					//SET 0, B
					//#0xC0:
					,function ():void {
						registerB |= 0x01;
					}
					//SET 0, C
					//#0xC1:
					,function ():void {
						registerC |= 0x01;
					}
					//SET 0, D
					//#0xC2:
					,function ():void {
						registerD |= 0x01;
					}
					//SET 0, E
					//#0xC3:
					,function ():void {
						registerE |= 0x01;
					}
					//SET 0, H
					//#0xC4:
					,function ():void {
						registersHL |= 0x0100;
					}
					//SET 0, L
					//#0xC5:
					,function ():void {
						registersHL |= 0x01;
					}
					//SET 0, (HL)
					//#0xC6:
					,function ():void {
						memoryWriter[registersHL](registersHL, memoryReader[registersHL](registersHL) | 0x01);
					}
					//SET 0, A
					//#0xC7:
					,function ():void {
						registerA |= 0x01;
					}
					//SET 1, B
					//#0xC8:
					,function ():void {
						registerB |= 0x02;
					}
					//SET 1, C
					//#0xC9:
					,function ():void {
						registerC |= 0x02;
					}
					//SET 1, D
					//#0xCA:
					,function ():void {
						registerD |= 0x02;
					}
					//SET 1, E
					//#0xCB:
					,function ():void {
						registerE |= 0x02;
					}
					//SET 1, H
					//#0xCC:
					,function ():void {
						registersHL |= 0x0200;
					}
					//SET 1, L
					//#0xCD:
					,function ():void {
						registersHL |= 0x02;
					}
					//SET 1, (HL)
					//#0xCE:
					,function ():void {
						memoryWriter[registersHL](registersHL, memoryReader[registersHL](registersHL) | 0x02);
					}
					//SET 1, A
					//#0xCF:
					,function ():void {
						registerA |= 0x02;
					}
					//SET 2, B
					//#0xD0:
					,function ():void {
						registerB |= 0x04;
					}
					//SET 2, C
					//#0xD1:
					,function ():void {
						registerC |= 0x04;
					}
					//SET 2, D
					//#0xD2:
					,function ():void {
						registerD |= 0x04;
					}
					//SET 2, E
					//#0xD3:
					,function ():void {
						registerE |= 0x04;
					}
					//SET 2, H
					//#0xD4:
					,function ():void {
						registersHL |= 0x0400;
					}
					//SET 2, L
					//#0xD5:
					,function ():void {
						registersHL |= 0x04;
					}
					//SET 2, (HL)
					//#0xD6:
					,function ():void {
						memoryWriter[registersHL](registersHL, memoryReader[registersHL](registersHL) | 0x04);
					}
					//SET 2, A
					//#0xD7:
					,function ():void {
						registerA |= 0x04;
					}
					//SET 3, B
					//#0xD8:
					,function ():void {
						registerB |= 0x08;
					}
					//SET 3, C
					//#0xD9:
					,function ():void {
						registerC |= 0x08;
					}
					//SET 3, D
					//#0xDA:
					,function ():void {
						registerD |= 0x08;
					}
					//SET 3, E
					//#0xDB:
					,function ():void {
						registerE |= 0x08;
					}
					//SET 3, H
					//#0xDC:
					,function ():void {
						registersHL |= 0x0800;
					}
					//SET 3, L
					//#0xDD:
					,function ():void {
						registersHL |= 0x08;
					}
					//SET 3, (HL)
					//#0xDE:
					,function ():void {
						memoryWriter[registersHL](registersHL, memoryReader[registersHL](registersHL) | 0x08);
					}
					//SET 3, A
					//#0xDF:
					,function ():void {
						registerA |= 0x08;
					}
					//SET 4, B
					//#0xE0:
					,function ():void {
						registerB |= 0x10;
					}
					//SET 4, C
					//#0xE1:
					,function ():void {
						registerC |= 0x10;
					}
					//SET 4, D
					//#0xE2:
					,function ():void {
						registerD |= 0x10;
					}
					//SET 4, E
					//#0xE3:
					,function ():void {
						registerE |= 0x10;
					}
					//SET 4, H
					//#0xE4:
					,function ():void {
						registersHL |= 0x1000;
					}
					//SET 4, L
					//#0xE5:
					,function ():void {
						registersHL |= 0x10;
					}
					//SET 4, (HL)
					//#0xE6:
					,function ():void {
						memoryWriter[registersHL](registersHL, memoryReader[registersHL](registersHL) | 0x10);
					}
					//SET 4, A
					//#0xE7:
					,function ():void {
						registerA |= 0x10;
					}
					//SET 5, B
					//#0xE8:
					,function ():void {
						registerB |= 0x20;
					}
					//SET 5, C
					//#0xE9:
					,function ():void {
						registerC |= 0x20;
					}
					//SET 5, D
					//#0xEA:
					,function ():void {
						registerD |= 0x20;
					}
					//SET 5, E
					//#0xEB:
					,function ():void {
						registerE |= 0x20;
					}
					//SET 5, H
					//#0xEC:
					,function ():void {
						registersHL |= 0x2000;
					}
					//SET 5, L
					//#0xED:
					,function ():void {
						registersHL |= 0x20;
					}
					//SET 5, (HL)
					//#0xEE:
					,function ():void {
						memoryWriter[registersHL](registersHL, memoryReader[registersHL](registersHL) | 0x20);
					}
					//SET 5, A
					//#0xEF:
					,function ():void {
						registerA |= 0x20;
					}
					//SET 6, B
					//#0xF0:
					,function ():void {
						registerB |= 0x40;
					}
					//SET 6, C
					//#0xF1:
					,function ():void {
						registerC |= 0x40;
					}
					//SET 6, D
					//#0xF2:
					,function ():void {
						registerD |= 0x40;
					}
					//SET 6, E
					//#0xF3:
					,function ():void {
						registerE |= 0x40;
					}
					//SET 6, H
					//#0xF4:
					,function ():void {
						registersHL |= 0x4000;
					}
					//SET 6, L
					//#0xF5:
					,function ():void {
						registersHL |= 0x40;
					}
					//SET 6, (HL)
					//#0xF6:
					,function ():void {
						memoryWriter[registersHL](registersHL, memoryReader[registersHL](registersHL) | 0x40);
					}
					//SET 6, A
					//#0xF7:
					,function ():void {
						registerA |= 0x40;
					}
					//SET 7, B
					//#0xF8:
					,function ():void {
						registerB |= 0x80;
					}
					//SET 7, C
					//#0xF9:
					,function ():void {
						registerC |= 0x80;
					}
					//SET 7, D
					//#0xFA:
					,function ():void {
						registerD |= 0x80;
					}
					//SET 7, E
					//#0xFB:
					,function ():void {
						registerE |= 0x80;
					}
					//SET 7, H
					//#0xFC:
					,function ():void {
						registersHL |= 0x8000;
					}
					//SET 7, L
					//#0xFD:
					,function ():void {
						registersHL |= 0x80;
					}
					//SET 7, (HL)
					//#0xFE:
					,function ():void {
						memoryWriter[registersHL](registersHL, memoryReader[registersHL](registersHL) | 0x80);
					}
					//SET 7, A
					//#0xFF:
					,function ():void {
						registerA |= 0x80;
					}
			], "function");
			this.TICKTable = toVector([
				4, 12,  8,  8,  4,  4,  8,  4,     20,  8,  8, 8,  4,  4, 8,  4,
				4, 12,  8,  8,  4,  4,  8,  4,     12,  8,  8, 8,  4,  4, 8,  4,
				8, 12,  8,  8,  4,  4,  8,  4,      8,  8,  8, 8,  4,  4, 8,  4,
				8, 12,  8,  8, 12, 12, 12,  4,      8,  8,  8, 8,  4,  4, 8,  4,
				4,  4,  4,  4,  4,  4,  8,  4,      4,  4,  4, 4,  4,  4, 8,  4,
				4,  4,  4,  4,  4,  4,  8,  4,      4,  4,  4, 4,  4,  4, 8,  4,
				4,  4,  4,  4,  4,  4,  8,  4,      4,  4,  4, 4,  4,  4, 8,  4,
				8,  8,  8,  8,  8,  8,  4,  8,      4,  4,  4, 4,  4,  4, 8,  4,
				4,  4,  4,  4,  4,  4,  8,  4,      4,  4,  4, 4,  4,  4, 8,  4,
				4,  4,  4,  4,  4,  4,  8,  4,      4,  4,  4, 4,  4,  4, 8,  4,
				4,  4,  4,  4,  4,  4,  8,  4,      4,  4,  4, 4,  4,  4, 8,  4,
				4,  4,  4,  4,  4,  4,  8,  4,      4,  4,  4, 4,  4,  4, 8,  4,
				8, 12, 12, 16, 12, 16,  8, 16,      8, 16, 12, 0, 12, 24, 8, 16,
				8, 12, 12,  4, 12, 16,  8, 16,      8, 16, 12, 4, 12,  4, 8, 16,
				12, 12,  8,  4,  4, 16,  8, 16,     16,  4, 16, 4,  4,  4, 8, 16,
				12, 12,  8,  4,  4, 16,  8, 16,     12,  8, 16, 4,  0,  4, 8, 16
			], "uint");
			this.SecondaryTICKTable = toVector([
				8, 8, 8, 8, 8, 8, 16, 8,        8, 8, 8, 8, 8, 8, 16, 8,
				8, 8, 8, 8, 8, 8, 16, 8,        8, 8, 8, 8, 8, 8, 16, 8,
				8, 8, 8, 8, 8, 8, 16, 8,        8, 8, 8, 8, 8, 8, 16, 8,
				8, 8, 8, 8, 8, 8, 16, 8,        8, 8, 8, 8, 8, 8, 16, 8,
				8, 8, 8, 8, 8, 8, 12, 8,        8, 8, 8, 8, 8, 8, 12, 8,
				8, 8, 8, 8, 8, 8, 12, 8,        8, 8, 8, 8, 8, 8, 12, 8,
				8, 8, 8, 8, 8, 8, 12, 8,        8, 8, 8, 8, 8, 8, 12, 8,
				8, 8, 8, 8, 8, 8, 12, 8,        8, 8, 8, 8, 8, 8, 12, 8,
				8, 8, 8, 8, 8, 8, 16, 8,        8, 8, 8, 8, 8, 8, 16, 8,
				8, 8, 8, 8, 8, 8, 16, 8,        8, 8, 8, 8, 8, 8, 16, 8,
				8, 8, 8, 8, 8, 8, 16, 8,        8, 8, 8, 8, 8, 8, 16, 8,
				8, 8, 8, 8, 8, 8, 16, 8,        8, 8, 8, 8, 8, 8, 16, 8,
				8, 8, 8, 8, 8, 8, 16, 8,        8, 8, 8, 8, 8, 8, 16, 8,
				8, 8, 8, 8, 8, 8, 16, 8,        8, 8, 8, 8, 8, 8, 16, 8,
				8, 8, 8, 8, 8, 8, 16, 8,        8, 8, 8, 8, 8, 8, 16, 8,
				8, 8, 8, 8, 8, 8, 16, 8,        8, 8, 8, 8, 8, 8, 16, 8
			], "uint");
		}

		public	function saveSRAMState():ByteArray
		{
			var result:ByteArray = new ByteArray();
			if (!this.cBATT || this.MBCRam.length == 0) {
				return result;
			}
			
			var index:uint = 0;
			while (index < this.MBCRam.length) {
				result.writeByte(this.MBCRam[index++] & 0xFF);
			}
			return result;
		}
		
		public	function saveRTCState():ByteArray
		{
			var result:ByteArray = new ByteArray();
			if (!this.cTIMER) {
				return result;
			}
			
			result.writeDouble(this.lastIteration);
			result.writeBoolean(this.RTCisLatched);
			result.writeUnsignedInt(this.latchedSeconds);
			result.writeUnsignedInt(this.latchedMinutes);
			result.writeUnsignedInt(this.latchedHours);
			result.writeUnsignedInt(this.latchedLDays);
			result.writeUnsignedInt(this.latchedHDays);
			result.writeUnsignedInt(this.RTCSeconds);
			result.writeUnsignedInt(this.RTCMinutes);
			result.writeUnsignedInt(this.RTCHours);
			result.writeUnsignedInt(this.RTCDays);
			result.writeBoolean(this.RTCDayOverFlow);
			result.writeBoolean(this.RTCHALT);
			return result;
		}
		
		public	function saveState():ByteArray
		{
			var index:uint = 0;
			var result:ByteArray = new ByteArray();
			
			if (this.ROM) {
				result.writeUnsignedInt(this.ROM.length);
				for (index = 0; index < this.ROM.length ; index++) {
					result.writeByte(this.ROM[index] & 0xFF);
				}
			}
			else {
				result.writeUnsignedInt(0);
			}
			result.writeBoolean(this.inBootstrap);
			result.writeUnsignedInt(this.registerA);
			result.writeBoolean(this.FZero);
			result.writeBoolean(this.FSubtract);
			result.writeBoolean(this.FHalfCarry);
			result.writeBoolean(this.FCarry);
			result.writeUnsignedInt(this.registerB);
			result.writeUnsignedInt(this.registerC);
			result.writeUnsignedInt(this.registerD);
			result.writeUnsignedInt(this.registerE);
			result.writeUnsignedInt(this.registersHL);
			result.writeUnsignedInt(this.stackPointer);
			result.writeUnsignedInt(this.programCounter);
			result.writeBoolean(this.halt);
			result.writeBoolean(this.IME);
			result.writeBoolean(this.hdmaRunning);
			result.writeUnsignedInt(this.CPUTicks);
			result.writeUnsignedInt(this.doubleSpeedShifter);
			if (this.memory) {
				result.writeUnsignedInt(this.memory.length);
				for (index = 0 ; index < this.memory.length ; index++) {
					result.writeByte(this.memory[index] & 0xFF);
				}
			}
			else {
				result.writeUnsignedInt(0);
			}
			if (this.MBCRam) {
				result.writeUnsignedInt(this.MBCRam.length);
				for (index = 0 ; index < this.MBCRam.length ; index++) {
					result.writeByte(this.MBCRam[index] & 0xFF);
				}
			}
			else {
				result.writeUnsignedInt(0);
			}
			if (this.VRAM) {
				result.writeUnsignedInt(this.VRAM.length);
				for (index = 0 ; index < this.VRAM.length ; index++) {
					result.writeByte(this.VRAM[index] & 0xFF);
				}
			}
			else {
				result.writeUnsignedInt(0);
			}
			result.writeUnsignedInt(this.currVRAMBank);
			if (this.GBCMemory) {
				result.writeUnsignedInt(this.GBCMemory.length);
				for (index = 0 ; index < this.GBCMemory.length ; index++) {
					result.writeByte(this.GBCMemory[index] & 0xFF);
				}
			}
			else {
				result.writeUnsignedInt(0);
			}
			result.writeBoolean(this.MBC1Mode);
			result.writeBoolean(this.MBCRAMBanksEnabled);
			result.writeUnsignedInt(this.currMBCRAMBank);
			result.writeInt(this.currMBCRAMBankPosition);
			result.writeBoolean(this.cGBC);
			result.writeUnsignedInt(this.gbcRamBank);
			result.writeInt(this.gbcRamBankPosition);
			result.writeUnsignedInt(this.ROMBank1offs);
			result.writeInt(this.currentROMBank);
			result.writeUnsignedInt(this.cartridgeType);
			result.writeUTF(this.name);
			result.writeUTF(this.gameCode);
			result.writeUnsignedInt(this.modeSTAT);
			result.writeBoolean(this.LYCMatchTriggerSTAT);
			result.writeBoolean(this.mode2TriggerSTAT);
			result.writeBoolean(this.mode1TriggerSTAT);
			result.writeBoolean(this.mode0TriggerSTAT);
			result.writeBoolean(this.LCDisOn);
			result.writeUnsignedInt(this.gfxWindowCHRBankPosition);
			result.writeBoolean(this.gfxWindowDisplay);
			result.writeBoolean(this.gfxSpriteShow);
			result.writeBoolean(this.gfxSpriteNormalHeight);
			result.writeUnsignedInt(this.gfxBackgroundCHRBankPosition);
			result.writeUnsignedInt(this.gfxBackgroundBankOffset);
			result.writeBoolean(this.TIMAEnabled);
			result.writeUnsignedInt(this.DIVTicks);
			result.writeUnsignedInt(this.LCDTicks);
			result.writeUnsignedInt(this.timerTicks);
			result.writeUnsignedInt(this.TACClocker);
			result.writeUnsignedInt(this.serialTimer);
			result.writeUnsignedInt(this.serialShiftTimer);
			result.writeUnsignedInt(this.serialShiftTimerAllocated);
			result.writeUnsignedInt(this.IRQEnableDelay);
			result.writeDouble(this.lastIteration);
			result.writeBoolean(this.cBATT);
			result.writeBoolean(this.cMBC1);
			result.writeBoolean(this.cMBC2);
			result.writeBoolean(this.cMBC3);
			result.writeBoolean(this.cMBC5);
			result.writeBoolean(this.cMBC7);
			result.writeBoolean(this.cMMMO1);
			result.writeBoolean(this.cRUMBLE);
			result.writeBoolean(this.cCamera);
			result.writeBoolean(this.cTAMA5);
			result.writeBoolean(this.cHuC3);
			result.writeBoolean(this.cHuC1);
			result.writeInt(this.drewBlank);
			if (this.frameBuffer) {
				result.writeUnsignedInt(this.frameBuffer.length);
				for (index = 0 ; index < this.frameBuffer.length ; index++) {
					result.writeInt(this.frameBuffer[index]);
				}
			}
			else {
				result.writeUnsignedInt(0);
			}
			result.writeBoolean(this.bgEnabled);
			result.writeBoolean(this.BGPriorityEnabled);
			result.writeDouble(this.channel1adjustedFrequencyPrep);
			result.writeDouble(this.channel1lastSampleLookup);
			result.writeDouble(this.channel1adjustedDuty);
			result.writeDouble(this.channel1totalLength);
			result.writeUnsignedInt(this.channel1envelopeVolume);
			result.writeDouble(this.channel1currentVolume);
			result.writeBoolean(this.channel1envelopeType);
			result.writeUnsignedInt(this.channel1envelopeSweeps);
			result.writeBoolean(this.channel1consecutive);
			result.writeUnsignedInt(this.channel1frequency);
			result.writeUnsignedInt(this.channel1Fault);
			result.writeUnsignedInt(this.channel1ShadowFrequency);
			result.writeDouble(this.channel1volumeEnvTime);
			result.writeDouble(this.channel1volumeEnvTimeLast);
			result.writeDouble(this.channel1timeSweep);
			result.writeDouble(this.channel1lastTimeSweep);
			result.writeUnsignedInt(this.channel1numSweep);
			result.writeUnsignedInt(this.channel1frequencySweepDivider);
			result.writeBoolean(this.channel1decreaseSweep);
			result.writeDouble(this.channel2adjustedFrequencyPrep);
			result.writeDouble(this.channel2lastSampleLookup);
			result.writeDouble(this.channel2adjustedDuty);
			result.writeDouble(this.channel2totalLength);
			result.writeUnsignedInt(this.channel2envelopeVolume);
			result.writeDouble(this.channel2currentVolume);
			result.writeBoolean(this.channel2envelopeType);
			result.writeUnsignedInt(this.channel2envelopeSweeps);
			result.writeBoolean(this.channel2consecutive);
			result.writeUnsignedInt(this.channel2frequency);
			result.writeDouble(this.channel2volumeEnvTime);
			result.writeDouble(this.channel2volumeEnvTimeLast);
			result.writeBoolean(this.channel3canPlay);
			result.writeDouble(this.channel3totalLength);
			result.writeUnsignedInt(this.channel3patternType);
			result.writeUnsignedInt(this.channel3frequency);
			result.writeBoolean(this.channel3consecutive);
			if (this.channel3PCM) {
				result.writeUnsignedInt(this.channel3PCM.length);
				for (index = 0 ; index < this.channel3PCM.length ; index++) {
					result.writeDouble(this.channel3PCM[index]);
				}
			}
			else {
				result.writeUnsignedInt(0);
			}
			result.writeDouble(this.channel3adjustedFrequencyPrep);
			result.writeDouble(this.channel4adjustedFrequencyPrep);
			result.writeDouble(this.channel4lastSampleLookup);
			result.writeDouble(this.channel4totalLength);
			result.writeUnsignedInt(this.channel4envelopeVolume);
			result.writeDouble(this.channel4currentVolume);
			result.writeBoolean(this.channel4envelopeType);
			result.writeUnsignedInt(this.channel4envelopeSweeps);
			result.writeBoolean(this.channel4consecutive);
			result.writeDouble(this.channel4volumeEnvTime);
			result.writeDouble(this.channel4volumeEnvTimeLast);
			result.writeUnsignedInt(this.noiseTableLength);
			result.writeBoolean(this.soundMasterEnabled);
			result.writeDouble(this.VinLeftChannelMasterVolume);
			result.writeDouble(this.VinRightChannelMasterVolume);
			result.writeBoolean(this.leftChannel0);
			result.writeBoolean(this.leftChannel1);
			result.writeBoolean(this.leftChannel2);
			result.writeBoolean(this.leftChannel3);
			result.writeBoolean(this.rightChannel0);
			result.writeBoolean(this.rightChannel1);
			result.writeBoolean(this.rightChannel2);
			result.writeBoolean(this.rightChannel3);
			result.writeUnsignedInt(this.actualScanLine);
			result.writeUnsignedInt(this.lastUnrenderedLine);
			result.writeUnsignedInt(this.queuedScanLines);
			result.writeBoolean(this.RTCisLatched);
			result.writeUnsignedInt(this.latchedSeconds);
			result.writeUnsignedInt(this.latchedMinutes);
			result.writeUnsignedInt(this.latchedHours);
			result.writeUnsignedInt(this.latchedLDays);
			result.writeUnsignedInt(this.latchedHDays);
			result.writeUnsignedInt(this.RTCSeconds);
			result.writeUnsignedInt(this.RTCMinutes);
			result.writeUnsignedInt(this.RTCHours);
			result.writeUnsignedInt(this.RTCDays);
			result.writeBoolean(this.RTCDayOverFlow);
			result.writeBoolean(this.RTCHALT);
			result.writeBoolean(this.usedBootROM);
			result.writeBoolean(this.skipPCIncrement);
			result.writeUnsignedInt(this.STATTracker);
			result.writeInt(this.gbcRamBankPositionECHO);
			result.writeUnsignedInt(this.numRAMBanks);
			result.writeInt(this.windowY);
			result.writeInt(this.windowX);
			if (this.gbcOBJRawPalette) {
				result.writeUnsignedInt(this.gbcOBJRawPalette.length);
				for (index = 0 ; index < this.gbcOBJRawPalette.length ; index++) {
					result.writeUnsignedInt(this.gbcOBJRawPalette[index]);
				}
			}
			else {
				result.writeUnsignedInt(0);
			}
			if (this.gbcBGRawPalette) {
				result.writeUnsignedInt(this.gbcBGRawPalette.length);
				for (index = 0 ; index < this.gbcBGRawPalette.length ; index++) {
					result.writeUnsignedInt(this.gbcBGRawPalette[index]);
				}
			}
			else {
				result.writeUnsignedInt(0);
			}
			if (this.gbOBJPalette) {
				result.writeUnsignedInt(this.gbOBJPalette.length);
				for (index = 0 ; index < this.gbOBJPalette.length ; index++) {
					result.writeInt(this.gbOBJPalette[index]);
				}
			}
			else {
				result.writeUnsignedInt(0);
			}
			if (this.gbBGPalette) {
				result.writeUnsignedInt(this.gbBGPalette.length);
				for (index = 0 ; index < this.gbBGPalette.length ; index++) {
					result.writeInt(this.gbBGPalette[index]);
				}
			}
			else {
				result.writeUnsignedInt(0);
			}
			if (this.gbcOBJPalette) {
				result.writeUnsignedInt(this.gbcOBJPalette.length);
				for (index = 0 ; index < this.gbcOBJPalette.length ; index++) {
					result.writeInt(this.gbcOBJPalette[index]);
				}
			}
			else {
				result.writeUnsignedInt(0);
			}
			if (this.gbcBGPalette) {
				result.writeUnsignedInt(this.gbcBGPalette.length);
				for (index = 0 ; index < this.gbcBGPalette.length ; index++) {
					result.writeInt(this.gbcBGPalette[index]);
				}
			}
			else {
				result.writeUnsignedInt(0);
			}
			if (this.gbBGColorizedPalette) {
				result.writeUnsignedInt(this.gbBGColorizedPalette.length);
				for (index = 0 ; index < this.gbBGColorizedPalette.length ; index++) {
					result.writeInt(this.gbBGColorizedPalette[index]);
				}
			}
			else {
				result.writeUnsignedInt(0);
			}
			if (this.gbOBJColorizedPalette) {
				result.writeUnsignedInt(this.gbOBJColorizedPalette.length);
				for (index = 0 ; index < this.gbOBJColorizedPalette.length ; index++) {
					result.writeInt(this.gbOBJColorizedPalette[index]);
				}
			}
			else {
				result.writeUnsignedInt(0);
			}
			if (this.cachedBGPaletteConversion) {
				result.writeUnsignedInt(this.cachedBGPaletteConversion.length);
				for (index = 0 ; index < this.cachedBGPaletteConversion.length ; index++) {
					result.writeInt(this.cachedBGPaletteConversion[index]);
				}
			}
			else {
				result.writeUnsignedInt(0);
			}
			if (this.cachedOBJPaletteConversion) {
				result.writeUnsignedInt(this.cachedOBJPaletteConversion.length);
				for (index = 0 ; index < this.cachedOBJPaletteConversion.length ; index++) {
					result.writeInt(this.cachedOBJPaletteConversion[index]);
				}
			}
			else {
				result.writeUnsignedInt(0);
			}
			if (this.BGCHRBank1) {
				result.writeUnsignedInt(this.BGCHRBank1.length);
				for (index = 0 ; index < this.BGCHRBank1.length ; index++) {
					result.writeUnsignedInt(this.BGCHRBank1[index]);
				}
			}
			else {
				result.writeUnsignedInt(0);
			}
			if (this.BGCHRBank2) {
				result.writeUnsignedInt(this.BGCHRBank2.length);
				for (index = 0 ; index < this.BGCHRBank2.length ; index++) {
					result.writeUnsignedInt(this.BGCHRBank2[index]);
				}
			}
			else {
				result.writeUnsignedInt(0);
			}
			result.writeUnsignedInt(this.haltPostClocks);
			result.writeUnsignedInt(this.interruptsRequested);
			result.writeUnsignedInt(this.interruptsEnabled);
			result.writeDouble(this.remainingClocks);
			result.writeBoolean(this.colorizedGBPalettes);
			result.writeInt(this.backgroundY);
			result.writeInt(this.backgroundX);
			return result;
		}
		
		public	function fromByteArray(baseArray:ByteArray, type:String, length:uint):*
		{
			var index:uint = 0;
			var result:*;
			switch (type)
			{
				case "uint8":
					result = new Vector.<uint>(length);
					for (index=0 ; index<length ; index++)
					{
						result[index] = baseArray.readByte() & 0xFF;
					}
					break;
				case "uint":
					result = new Vector.<uint>(length);
					for (index=0 ; index<length ; index++)
					{
						result[index] = baseArray.readUnsignedInt();
					}
					break;
				case "int":
					result = new Vector.<int>(length);
					for (index=0 ; index<length ; index++)
					{
						result[index] = baseArray.readInt();
					}
					break;
				case "number":
					result = new Vector.<Number>(length);
					for (index=0 ; index<length ; index++)
					{
						result[index] = baseArray.readDouble();
					}
					break;
				case "boolean":
					result = new Vector.<Boolean>(length);
					for (index=0 ; index<length ; index++)
					{
						result[index] = baseArray.readBoolean();
					}
					break;
			}
			return result;
		}
		
		public	function returnFromState(state:ByteArray):void
		{
			var index:uint;
			state.position = 0;
			this.ROM							= this.fromByteArray(state, "uint8", state.readUnsignedInt());
			this.ROMBankEdge					= Math.floor(this.ROM.length / 0x4000);
			this.inBootstrap					= state.readBoolean();
			this.registerA						= state.readUnsignedInt();
			this.FZero							= state.readBoolean();
			this.FSubtract						= state.readBoolean();
			this.FHalfCarry						= state.readBoolean();
			this.FCarry							= state.readBoolean();
			this.registerB						= state.readUnsignedInt();
			this.registerC						= state.readUnsignedInt();
			this.registerD						= state.readUnsignedInt();
			this.registerE						= state.readUnsignedInt();
			this.registersHL					= state.readUnsignedInt();
			this.stackPointer					= state.readUnsignedInt();
			this.programCounter					= state.readUnsignedInt();
			this.halt							= state.readBoolean();
			this.IME							= state.readBoolean();
			this.hdmaRunning					= state.readBoolean();
			this.CPUTicks						= state.readUnsignedInt();
			this.doubleSpeedShifter				= state.readUnsignedInt();
			this.memory							= this.fromByteArray(state, "uint8", state.readUnsignedInt());
			this.MBCRam							= this.fromByteArray(state, "uint8", state.readUnsignedInt());
			this.VRAM							= this.fromByteArray(state, "uint8", state.readUnsignedInt());
			this.currVRAMBank					= state.readUnsignedInt();
			this.GBCMemory						= this.fromByteArray(state, "uint8", state.readUnsignedInt());
			this.MBC1Mode						= state.readBoolean();
			this.MBCRAMBanksEnabled				= state.readBoolean();
			this.currMBCRAMBank					= state.readUnsignedInt();
			this.currMBCRAMBankPosition			= state.readInt();
			this.cGBC							= state.readBoolean();
			this.gbcRamBank						= state.readUnsignedInt();
			this.gbcRamBankPosition				= state.readInt();
			this.ROMBank1offs					= state.readUnsignedInt();
			this.currentROMBank					= state.readInt();
			this.cartridgeType					= state.readUnsignedInt();
			this.name							= state.readUTF();
			this.gameCode						= state.readUTF();
			this.modeSTAT						= state.readUnsignedInt();
			this.LYCMatchTriggerSTAT			= state.readBoolean();
			this.mode2TriggerSTAT				= state.readBoolean();
			this.mode1TriggerSTAT				= state.readBoolean();
			this.mode0TriggerSTAT				= state.readBoolean();
			this.LCDisOn						= state.readBoolean();
			this.gfxWindowCHRBankPosition		= state.readUnsignedInt();
			this.gfxWindowDisplay				= state.readBoolean();
			this.gfxSpriteShow					= state.readBoolean();
			this.gfxSpriteNormalHeight			= state.readBoolean();
			this.gfxBackgroundCHRBankPosition	= state.readUnsignedInt();
			this.gfxBackgroundBankOffset		= state.readUnsignedInt();
			this.TIMAEnabled					= state.readBoolean();
			this.DIVTicks						= state.readUnsignedInt();
			this.LCDTicks						= state.readUnsignedInt();
			this.timerTicks						= state.readUnsignedInt();
			this.TACClocker						= state.readUnsignedInt();
			this.serialTimer					= state.readUnsignedInt();
			this.serialShiftTimer				= state.readUnsignedInt();
			this.serialShiftTimerAllocated		= state.readUnsignedInt();
			this.IRQEnableDelay					= state.readUnsignedInt();
			this.lastIteration					= state.readDouble();
			this.cBATT							= state.readBoolean();
			this.cMBC1							= state.readBoolean();
			this.cMBC2							= state.readBoolean();
			this.cMBC3							= state.readBoolean();
			this.cMBC5							= state.readBoolean();
			this.cMBC7							= state.readBoolean();
			this.cMMMO1							= state.readBoolean();
			this.cRUMBLE						= state.readBoolean();
			this.cCamera						= state.readBoolean();
			this.cTAMA5							= state.readBoolean();
			this.cHuC3							= state.readBoolean();
			this.cHuC1							= state.readBoolean();
			this.drewBlank						= state.readInt();
			this.frameBuffer					= this.fromByteArray(state, "int", state.readUnsignedInt());
			this.bgEnabled						= state.readBoolean();
			this.BGPriorityEnabled				= state.readBoolean();
			this.channel1adjustedFrequencyPrep	= state.readDouble();
			this.channel1lastSampleLookup		= state.readDouble();
			this.channel1adjustedDuty			= state.readDouble();
			this.channel1totalLength			= state.readDouble();
			this.channel1envelopeVolume			= state.readUnsignedInt();
			this.channel1currentVolume			= state.readDouble();
			this.channel1envelopeType			= state.readBoolean();
			this.channel1envelopeSweeps			= state.readUnsignedInt();
			this.channel1consecutive			= state.readBoolean();
			this.channel1frequency				= state.readUnsignedInt();
			this.channel1Fault					= state.readUnsignedInt();
			this.channel1ShadowFrequency		= state.readUnsignedInt()
			this.channel1volumeEnvTime			= state.readDouble();
			this.channel1volumeEnvTimeLast		= state.readDouble();
			this.channel1timeSweep				= state.readDouble();
			this.channel1lastTimeSweep			= state.readDouble();
			this.channel1numSweep				= state.readUnsignedInt();
			this.channel1frequencySweepDivider	= state.readUnsignedInt();
			this.channel1decreaseSweep			= state.readBoolean();
			this.channel2adjustedFrequencyPrep	= state.readDouble();
			this.channel2lastSampleLookup		= state.readDouble();
			this.channel2adjustedDuty			= state.readDouble();
			this.channel2totalLength			= state.readDouble();
			this.channel2envelopeVolume			= state.readUnsignedInt();
			this.channel2currentVolume			= state.readDouble();
			this.channel2envelopeType			= state.readBoolean();
			this.channel2envelopeSweeps			= state.readUnsignedInt();
			this.channel2consecutive			= state.readBoolean();
			this.channel2frequency				= state.readUnsignedInt();
			this.channel2volumeEnvTime			= state.readDouble();
			this.channel2volumeEnvTimeLast		= state.readDouble();
			this.channel3canPlay				= state.readBoolean();
			this.channel3totalLength			= state.readDouble();
			this.channel3patternType			= state.readUnsignedInt();
			this.channel3frequency				= state.readUnsignedInt();
			this.channel3consecutive			= state.readBoolean();
			this.channel3PCM					= this.fromByteArray(state, "number", state.readUnsignedInt());
			this.channel3adjustedFrequencyPrep	= state.readDouble();
			this.channel4adjustedFrequencyPrep	= state.readDouble();
			this.channel4lastSampleLookup		= state.readDouble();
			this.channel4totalLength			= state.readDouble();
			this.channel4envelopeVolume			= state.readUnsignedInt()
			this.channel4currentVolume			= state.readDouble();
			this.channel4envelopeType			= state.readBoolean();
			this.channel4envelopeSweeps			= state.readUnsignedInt();
			this.channel4consecutive			= state.readBoolean();
			this.channel4volumeEnvTime			= state.readDouble();
			this.channel4volumeEnvTimeLast		= state.readDouble();
			this.noiseTableLength				= state.readUnsignedInt();
			this.soundMasterEnabled				= state.readBoolean();
			this.VinLeftChannelMasterVolume		= state.readDouble();
			this.VinRightChannelMasterVolume	= state.readDouble();
			this.leftChannel0					= state.readBoolean();
			this.leftChannel1					= state.readBoolean();
			this.leftChannel2					= state.readBoolean();
			this.leftChannel3					= state.readBoolean();
			this.rightChannel0					= state.readBoolean();
			this.rightChannel1					= state.readBoolean();
			this.rightChannel2					= state.readBoolean();
			this.rightChannel3					= state.readBoolean();
			this.actualScanLine					= state.readUnsignedInt();
			this.lastUnrenderedLine				= state.readUnsignedInt();
			this.queuedScanLines				= state.readUnsignedInt();
			this.RTCisLatched					= state.readBoolean();
			this.latchedSeconds					= state.readUnsignedInt();
			this.latchedMinutes					= state.readUnsignedInt();
			this.latchedHours					= state.readUnsignedInt();
			this.latchedLDays					= state.readUnsignedInt();
			this.latchedHDays					= state.readUnsignedInt();
			this.RTCSeconds						= state.readUnsignedInt();
			this.RTCMinutes						= state.readUnsignedInt();
			this.RTCHours						= state.readUnsignedInt();
			this.RTCDays						= state.readUnsignedInt();
			this.RTCDayOverFlow					= state.readBoolean();
			this.RTCHALT						= state.readBoolean();
			this.usedBootROM					= state.readBoolean();
			this.skipPCIncrement				= state.readBoolean();
			this.STATTracker					= state.readUnsignedInt();
			this.gbcRamBankPositionECHO			= state.readInt();
			this.numRAMBanks					= state.readUnsignedInt();
			this.windowY						= state.readInt();
			this.windowX						= state.readInt();
			this.gbcOBJRawPalette				= this.fromByteArray(state, "uint", state.readUnsignedInt());
			this.gbcBGRawPalette				= this.fromByteArray(state, "uint", state.readUnsignedInt());
			this.gbOBJPalette					= this.fromByteArray(state, "int", state.readUnsignedInt());
			this.gbBGPalette					= this.fromByteArray(state, "int", state.readUnsignedInt());
			this.gbcOBJPalette					= this.fromByteArray(state, "int", state.readUnsignedInt());
			this.gbcBGPalette					= this.fromByteArray(state, "int", state.readUnsignedInt());
			this.gbBGColorizedPalette			= this.fromByteArray(state, "int", state.readUnsignedInt());
			this.gbOBJColorizedPalette			= this.fromByteArray(state, "int", state.readUnsignedInt());
			this.cachedBGPaletteConversion		= this.fromByteArray(state, "int", state.readUnsignedInt());
			this.cachedOBJPaletteConversion		= this.fromByteArray(state, "int", state.readUnsignedInt());
			this.BGCHRBank1						= this.fromByteArray(state, "uint", state.readUnsignedInt());
			this.BGCHRBank2						= this.fromByteArray(state, "uint", state.readUnsignedInt());
			this.haltPostClocks					= state.readUnsignedInt()
			this.interruptsRequested			= state.readUnsignedInt()
			this.interruptsEnabled				= state.readUnsignedInt()
			this.checkIRQMatching();
			this.remainingClocks				= state.readDouble();
			this.colorizedGBPalettes			= state.readBoolean();
			this.backgroundY					= state.readInt();
			this.backgroundX					= state.readInt();
			this.fromSaveState					= true;
			this.initializeReferencesFromSaveState();
			this.memoryReadJumpCompile();
			this.memoryWriteJumpCompile();
			this.initLCD();
			this.initSound();
			this.noiseSampleTable				= (this.noiseTableLength == 0x8000) ? this.LSFR15Table : this.LSFR7Table;
			this.channel4VolumeShifter			= (this.noiseTableLength == 0x8000) ? 15 : 7;
		}
		
		public	function returnFromRTCState(rtcData:ByteArray = null):void
		{
			if (gb && this.cTIMER && rtcData) {
				rtcData.position = 0;
				this.lastIteration	= rtcData.readDouble();
				this.RTCisLatched	= rtcData.readBoolean();
				this.latchedSeconds	= rtcData.readUnsignedInt();
				this.latchedMinutes	= rtcData.readUnsignedInt();
				this.latchedHours	= rtcData.readUnsignedInt();
				this.latchedLDays	= rtcData.readUnsignedInt();
				this.latchedHDays	= rtcData.readUnsignedInt();
				this.RTCSeconds		= rtcData.readUnsignedInt();
				this.RTCMinutes		= rtcData.readUnsignedInt();
				this.RTCHours		= rtcData.readUnsignedInt();
				this.RTCDays		= rtcData.readUnsignedInt();
				this.RTCDayOverFlow	= rtcData.readBoolean();
				this.RTCHALT		= rtcData.readBoolean();
			}
		}
		
		public	function start():void
		{
			this.initMemory();
			this.ROMLoad();
			this.initLCD();
			this.initSound();
			this.run();
		}
		
		public	function initMemory():void
		{
			this.memory = this.getVector(0x10000, 0, "uint8");
			this.frameBuffer = this.getVector(23040, 0xF8F8F8, "int32");
			this.BGCHRBank1 = this.getVector(0x800, 0, "uint8");
			this.channel3PCM = this.getVector(0x80, 0, "float32");
		}
		
		public	function generateCacheArray(tileAmount:int):Vector.<Vector.<uint>>
		{
			var tileArray:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();
			var tileNumber:int = 0;
			while (tileNumber < tileAmount) {
				tileArray.push(this.getVector(64, 0, "uint8"));
				tileNumber++;
			}
			return tileArray;
		}
		
		public	function initSkipBootstrap():void
		{
			var index:uint = 0xFF;
			while (index >= 0) {
				if (index >= 0x30 && index < 0x40) {
					this.memoryWrite(0xFF00 | index, this.ffxxDump[index]);
				}
				else {
					switch (index) {
						case 0x00:
						case 0x01:
						case 0x02:
						case 0x05:
						case 0x07:
						case 0x0F:
						case 0xFF:
							this.memoryWrite(0xFF00 | index, this.ffxxDump[index]);
							break;
						default:
							this.memory[0xFF00 | index] = this.ffxxDump[index];
					}
				}
				--index;
			}
			if (this.cGBC) {
				this.memory[0xFF6C] = 0xFE;
				this.memory[0xFF74] = 0xFE;
			}
			else {
				this.memory[0xFF48] = 0xFF;
				this.memory[0xFF49] = 0xFF;
				this.memory[0xFF6C] = 0xFF;
				this.memory[0xFF74] = 0xFF;
			}
			trace("Starting without the GBC boot ROM.", 0);
			this.registerA = (this.cGBC) ? 0x11 : 0x1;
			this.registerB = 0;
			this.registerC = 0x13;
			this.registerD = 0;
			this.registerE = 0xD8;
			this.FZero = true;
			this.FSubtract = false;
			this.FHalfCarry = true;
			this.FCarry = true;
			this.registersHL = 0x014D;
			this.LCDCONTROL = this.LINECONTROL;
			this.IME = false;
			this.IRQLineMatched = 0;
			this.interruptsRequested = 225;
			this.interruptsEnabled = 0;
			this.hdmaRunning = false;
			this.CPUTicks = 12;
			this.STATTracker = 0;
			this.modeSTAT = 1;
			this.spriteCount = 252;
			this.LYCMatchTriggerSTAT = false;
			this.mode2TriggerSTAT = false;
			this.mode1TriggerSTAT = false;
			this.mode0TriggerSTAT = false;
			this.LCDisOn = true;
			this.channel1adjustedFrequencyPrep = 0.008126984126984127;
			this.channel1adjustedDuty = 0.5;
			this.channel1totalLength = 0;
			this.channel1envelopeVolume = 0;
			this.channel1currentVolume = 0;
			this.channel1envelopeType = false;
			this.channel1envelopeSweeps = 0;
			this.channel1consecutive = true;
			this.channel1frequency = 1985;
			this.channel1Fault = 0;
			this.channel1ShadowFrequency = 1985;
			this.channel1volumeEnvTime = 0;
			this.channel1volumeEnvTimeLast = 12000;
			this.channel1timeSweep = 0;
			this.channel1lastTimeSweep = 0;
			this.channel1numSweep = 0;
			this.channel1frequencySweepDivider = 0;
			this.channel1decreaseSweep = false;
			this.channel2adjustedFrequencyPrep = 0;
			this.channel2adjustedDuty = 0.5;
			this.channel2totalLength = 0;
			this.channel2envelopeVolume = 0;
			this.channel2currentVolume = 0;
			this.channel2envelopeType = false;
			this.channel2envelopeSweeps = 0;
			this.channel2consecutive = true;
			this.channel2frequency = 0;
			this.channel2volumeEnvTime = 0;
			this.channel2volumeEnvTimeLast = 0;
			this.channel3canPlay = false;
			this.channel3totalLength = 0;
			this.channel3patternType = 0;
			this.channel3frequency = 0;
			this.channel3consecutive = true;
			this.channel3adjustedFrequencyPrep = 0.512;
			this.channel4adjustedFrequencyPrep = 0;
			this.channel4totalLength = 0;
			this.channel4envelopeVolume = 0;
			this.channel4currentVolume = 0;
			this.channel4envelopeType = false;
			this.channel4envelopeSweeps = 0;
			this.channel4consecutive = true;
			this.channel4volumeEnvTime = 0;
			this.channel4volumeEnvTimeLast = 0;
			this.noiseTableLength = 0x8000;
			this.noiseSampleTable = this.LSFR15Table;
			this.channel4VolumeShifter = 15;
			this.channel1lastSampleLookup = 0.7169351111064097;
			this.channel2lastSampleLookup = 0;
			this.channel3Tracker = 0;
			this.channel4lastSampleLookup = 0;
			this.VinLeftChannelMasterVolume = 1;
			this.VinRightChannelMasterVolume = 1;
			this.soundMasterEnabled = true;
			this.leftChannel0 = true;
			this.leftChannel1 = true;
			this.leftChannel2 = true;
			this.leftChannel3 = true;
			this.rightChannel0 = true;
			this.rightChannel1 = true;
			this.rightChannel2 = false;
			this.rightChannel3 = false;
			this.DIVTicks = 27044;
			this.LCDTicks = gb.WIDTH;
			this.timerTicks = 0;
			this.TIMAEnabled = false;
			this.TACClocker = 1024;
			this.serialTimer = 0;
			this.serialShiftTimer = 0;
			this.serialShiftTimerAllocated = 0;
			this.IRQEnableDelay = 0;
			this.actualScanLine = gb.HEIGHT;
			this.lastUnrenderedLine = 0;
			this.gfxWindowDisplay = false;
			this.gfxSpriteShow = false;
			this.gfxSpriteNormalHeight = true;
			this.bgEnabled = true;
			this.BGPriorityEnabled = true;
			this.gfxWindowCHRBankPosition = 0;
			this.gfxBackgroundCHRBankPosition = 0;
			this.gfxBackgroundBankOffset = 0;
			this.windowY = 0;
			this.windowX = 0;
			this.drewBlank = 0;
			this.midScanlineOffset = -1;
			this.currentX = 0;
		}
		
		public	function initBootstrap():void
		{
			trace("Starting the selected boot ROM.", 0);
			this.programCounter = 0;
			this.stackPointer = 0;
			this.IME = false;
			this.LCDTicks = 0;
			this.DIVTicks = 0;
			this.registerA = 0;
			this.registerB = 0;
			this.registerC = 0;
			this.registerD = 0;
			this.registerE = 0;
			this.FZero = this.FSubtract = this.FHalfCarry = this.FCarry = false;
			this.registersHL = 0;
			this.leftChannel0 = false;
			this.leftChannel1 = false;
			this.leftChannel2 = false;
			this.leftChannel3 = false;
			this.rightChannel0 = false;
			this.rightChannel1 = false;
			this.rightChannel2 = false;
			this.rightChannel3 = false;
			this.channel2frequency = this.channel1frequency = 0;
			this.channel2volumeEnvTime = this.channel1volumeEnvTime = 0;
			this.channel4consecutive = this.channel2consecutive = this.channel1consecutive = false;
			this.VinLeftChannelMasterVolume = 1;
			this.VinRightChannelMasterVolume = 1;
			this.memory[0xFF00] = 0xF;
		}
		
		public	function ROMLoad():void
		{
			this.ROM = new Vector.<uint>();
			this.usedBootROM = settings.useGBCBios;
			var maxLength:uint = this.ROMImage.length;
			if (maxLength < 0x4000) {
				throw(new Error("ROM image size too small."));
			}
			this.ROM = this.getVector(maxLength, 0, "uint8");
			var romIndex:int = 0;
			if (this.usedBootROM) {
				if (!settings.useGBBootROM) {
					for (; romIndex < 0x100; ++romIndex) {
						this.memory[romIndex] = this.GBCBOOTROM[romIndex];
						this.ROMImage.position = romIndex;
						this.ROM[romIndex] = (this.ROMImage.readByte() & 0xFF);
					}
					for (; romIndex < 0x200; ++romIndex) {
						this.ROMImage.position = romIndex;
						this.memory[romIndex] = this.ROM[romIndex] = (this.ROMImage.readByte() & 0xFF);
					}
					for (; romIndex < 0x900; ++romIndex) {
						this.memory[romIndex] = this.GBCBOOTROM[romIndex - 0x100];
						this.ROMImage.position = romIndex;
						this.ROM[romIndex] = (this.ROMImage.readByte() & 0xFF);
					}
					this.usedGBCBootROM = true;
				}
				else {
					for (; romIndex < 0x100; ++romIndex) {
						this.memory[romIndex] = this.GBBOOTROM[romIndex];
						this.ROMImage.position = romIndex;
						this.ROM[romIndex] = (this.ROMImage.readByte() & 0xFF);
					}
				}
				for (; romIndex < 0x4000; ++romIndex) {
					this.ROMImage.position = romIndex;
					this.memory[romIndex] = this.ROM[romIndex] = (this.ROMImage.readByte() & 0xFF);
				}
			}
			else {
				for (; romIndex < 0x4000; ++romIndex) {
					this.ROMImage.position = romIndex;
					this.memory[romIndex] = this.ROM[romIndex] = (this.ROMImage.readByte() & 0xFF);
				}
			}
			for (; romIndex < maxLength; ++romIndex) {
				this.ROMImage.position = romIndex;
				this.ROM[romIndex] = (this.ROMImage.readByte() & 0xFF);
			}
			this.ROMBankEdge = Math.floor(this.ROM.length / 0x4000);
			this.interpretCartridge();
			this.checkIRQMatching();
		}
		
		public	function getROMImage():ByteArray
		{
			if (this.ROMImage.length > 0) {
				return this.ROMImage;
			}
			var length:uint = this.ROM.length;
			ROMImage.position = 0;
			for (var index:uint = 0; index < length; index++) {
				this.ROMImage.writeByte( this.ROM[index] & 0xFF );
			}
			return this.ROMImage;
		}
		
		public	function interpretCartridge():void
		{
			var index:uint;
			for (index = 0x134; index < 0x13F; index++) {
				this.ROMImage.position = index;
				var c1:uint = this.ROMImage.readByte() & 0xFF;
				if (c1 > 0) {
					this.name += String.fromCharCode(c1);
				}
			}
			for (index = 0x13F; index < 0x143; index++) {
				this.ROMImage.position = index;
				var c2:uint = this.ROMImage.readByte() & 0xFF;
				if (c2 > 0) {
					this.gameCode += String.fromCharCode(c2);
				}
			}
			this.ROMImage.position = 0x143;
			trace("Game Title: " + this.name + "[" + this.gameCode + "][" + String.fromCharCode(this.ROMImage.readByte() & 0xFF) + "]", 0);
			trace("Game Code: " + this.gameCode, 0);
			this.cartridgeType = this.ROM[0x147];
			trace("Cartridge type #" + this.cartridgeType.toString(), 0);
			var MBCType:String = "";
			switch (this.cartridgeType) {
				case 0x00:
					if (!settings.overrideMBC1) {
						MBCType = "ROM";
						break;
					}
				case 0x01:
					this.cMBC1 = true;
					MBCType = "MBC1";
					break;
				case 0x02:
					this.cMBC1 = true;
					this.cSRAM = true;
					MBCType = "MBC1 + SRAM";
					break;
				case 0x03:
					this.cMBC1 = true;
					this.cSRAM = true;
					this.cBATT = true;
					MBCType = "MBC1 + SRAM + BATT";
					break;
				case 0x05:
					this.cMBC2 = true;
					MBCType = "MBC2";
					break;
				case 0x06:
					this.cMBC2 = true;
					this.cBATT = true;
					MBCType = "MBC2 + BATT";
					break;
				case 0x08:
					this.cSRAM = true;
					MBCType = "ROM + SRAM";
					break;
				case 0x09:
					this.cSRAM = true;
					this.cBATT = true;
					MBCType = "ROM + SRAM + BATT";
					break;
				case 0x0B:
					this.cMMMO1 = true;
					MBCType = "MMMO1";
					break;
				case 0x0C:
					this.cMMMO1 = true;
					this.cSRAM = true;
					MBCType = "MMMO1 + SRAM";
					break;
				case 0x0D:
					this.cMMMO1 = true;
					this.cSRAM = true;
					this.cBATT = true;
					MBCType = "MMMO1 + SRAM + BATT";
					break;
				case 0x0F:
					this.cMBC3 = true;
					this.cTIMER = true;
					this.cBATT = true;
					MBCType = "MBC3 + TIMER + BATT";
					break;
				case 0x10:
					this.cMBC3 = true;
					this.cTIMER = true;
					this.cBATT = true;
					this.cSRAM = true;
					MBCType = "MBC3 + TIMER + BATT + SRAM";
					break;
				case 0x11:
					this.cMBC3 = true;
					MBCType = "MBC3";
					break;
				case 0x12:
					this.cMBC3 = true;
					this.cSRAM = true;
					MBCType = "MBC3 + SRAM";
					break;
				case 0x13:
					this.cMBC3 = true;
					this.cSRAM = true;
					this.cBATT = true;
					MBCType = "MBC3 + SRAM + BATT";
					break;
				case 0x19:
					this.cMBC5 = true;
					MBCType = "MBC5";
					break;
				case 0x1A:
					this.cMBC5 = true;
					this.cSRAM = true;
					MBCType = "MBC5 + SRAM";
					break;
				case 0x1B:
					this.cMBC5 = true;
					this.cSRAM = true;
					this.cBATT = true;
					MBCType = "MBC5 + SRAM + BATT";
					break;
				case 0x1C:
					this.cRUMBLE = true;
					MBCType = "RUMBLE";
					break;
				case 0x1D:
					this.cRUMBLE = true;
					this.cSRAM = true;
					MBCType = "RUMBLE + SRAM";
					break;
				case 0x1E:
					this.cRUMBLE = true;
					this.cSRAM = true;
					this.cBATT = true;
					MBCType = "RUMBLE + SRAM + BATT";
					break;
				case 0x1F:
					this.cCamera = true;
					MBCType = "GameBoy Camera";
					break;
				case 0x22:
					this.cMBC7 = true;
					this.cSRAM = true;
					this.cBATT = true;
					MBCType = "MBC7 + SRAM + BATT";
					break;
				case 0xFD:
					this.cTAMA5 = true;
					MBCType = "TAMA5";
					break;
				case 0xFE:
					this.cHuC3 = true;
					MBCType = "HuC3";
					break;
				case 0xFF:
					this.cHuC1 = true;
					MBCType = "HuC1";
					break;
				default:
					MBCType = "Unknown";
					trace("Cartridge type is unknown.", 2);
					gb.pause();
			}
			trace("Cartridge Type: " + MBCType + ".", 0);
			this.numROMBanks = this.ROMBanks[this.ROM[0x148]];
			trace(this.numROMBanks.toString() + " ROM banks.", 0);
			switch (this.RAMBanks[this.ROM[0x149]]) {
				case 0:
					trace("No RAM banking requested for allocation or MBC is of type 2.", 0);
					break;
				case 2:
					trace("1 RAM bank requested for allocation.", 0);
					break;
				case 3:
					trace("4 RAM banks requested for allocation.", 0);
					break;
				case 4:
					trace("16 RAM banks requested for allocation.", 0);
					break;
				default:
					trace("RAM bank amount requested is unknown, will use maximum allowed by specified MBC type.", 0);
			}
			if (!this.usedBootROM) {
				switch (this.ROM[0x143]) {
					case 0x00:
						this.cGBC = false;
						trace("Only GB mode detected.", 0);
						break;
					case 0x32:
						if (!settings.priorityGameBoy && this.name + this.gameCode + this.ROM[0x143].toString() == "Game and Watch 50") {
							this.cGBC = true;
							trace("Created a boot exception for Game and Watch Gallery 2 (GBC ID byte is wrong on the cartridge).", 1);
						}
						else {
							this.cGBC = false;
						}
						break;
					case 0x80:
						this.cGBC = !settings.priorityGameBoy;
						trace("GB and GBC mode detected.", 0);
						break;
					case 0xC0:
						this.cGBC = true;
						trace("Only GBC mode detected.", 0);
						break;
					default:
						this.cGBC = false;
						trace("Unknown GameBoy game type code #" + this.ROM[0x143].toString() + ", defaulting to GB mode (Old games don't have a type code).", 1);
				}
				this.inBootstrap = false;
				this.setupRAM();
				this.initSkipBootstrap();
			}
			else {
				this.cGBC = this.usedGBCBootROM;
				this.setupRAM();
				this.initBootstrap();
			}
			this.initializeModeSpecificArrays();

			var cOldLicense:uint = this.ROM[0x14B];
			var cNewLicense:uint = (this.ROM[0x144] & 0xFF00) | (this.ROM[0x145] & 0xFF);
			if (cOldLicense != 0x33) {
				trace("Old style license code: " + cOldLicense.toString(), 0);
			}
			else {
				trace("New style license code: " + cNewLicense.toString(), 0);
			}
			this.ROMImage.clear();
		}
		
		public	function disableBootROM():void
		{
			for (var index:uint = 0; index < 0x100; ++index) {
				this.memory[index] = this.ROM[index];
			}
			if (this.usedGBCBootROM) {
				for (index = 0x200; index < 0x900; ++index) {
					this.memory[index] = this.ROM[index];
				}
				if (!this.cGBC) {
					this.GBCtoGBModeAdjust();
				}
				else {
					this.recompileBootIOWriteHandling();
				}
			}
			else {
				this.recompileBootIOWriteHandling();
			}
		}
		
		public	function initializeTiming():void
		{
			this.baseCPUCyclesPerIteration = 0x80000 / 0x7D * settings.emulatorInterval;
			this.setEmulatorSpeed(1);
		}
		
		public	function setEmulatorSpeed(speed:Number):void
		{
			this.CPUCyclesPerIteration = this.baseCPUCyclesPerIteration * speed;
			this.CPUCyclesTotalRoundoff = this.CPUCyclesPerIteration % 4;
			this.CPUCyclesTotalBase = this.CPUCyclesTotal = (this.CPUCyclesPerIteration - this.CPUCyclesTotalRoundoff) | 0;
			this.CPUCyclesTotalCurrent = 0;
			this.setAudioSpeed(speed);
		}
		
		public	function setAudioSpeed(speed:Number):void
		{
			var sample:Number = settings.sampleRate;
			this.preChewedAudioComputationMultiplier = 0x20000 / sample;
			this.preChewedWAVEAudioComputationMultiplier = 0x200000 /sample;
			this.whiteNoiseFrequencyPreMultiplier = 0x80000 / sample;
			this.volumeEnvelopePreMultiplier = sample / 0x40 / speed;
			this.channel1TimeSweepPreMultiplier = sample / 0x80 / speed;
			this.audioTotalLengthMultiplier = sample / 0x100 / speed;
		}
		
		public	function setupRAM():void
		{
			if (this.cMBC2) {
				this.numRAMBanks = 1 / 16;
			}
			else if (this.cMBC1 || this.cRUMBLE || this.cMBC3 || this.cHuC3) {
				this.numRAMBanks = 4;
			}
			else if (this.cMBC5) {
				this.numRAMBanks = 16;
			}
			else if (this.cSRAM) {
				this.numRAMBanks = 1;
			}
			if (this.numRAMBanks > 0) {
				if (!this.MBCRAMUtilized()) {
					this.MBCRAMBanksEnabled = true;
				}
//				var MBCRam:Vector.<uint> = (gb.openSRAM!=null) ? gb.openSRAM(this.name) : new Vector.<uint>();
//				if (MBCRam.length > 0) {
//					this.MBCRam = this.toTypedArray(MBCRam, "uint8");
//				}
//				else {
//					this.MBCRam = this.getTypedArray(this.numRAMBanks * 0x2000, 0, "uint8");
//				}
				var length:int = this.SRAMImage.length;
				if (length > 0) {
					this.MBCRam = new Vector.<uint>(length);
					this.SRAMImage.position = 0;
					for (var index:int=0 ; index<length  ; ++index) {
						this.MBCRam[index] = this.SRAMImage.readByte() & 0xFF;
					}
//					this.MBCRam = this.toTypedArray(MBCRam, "uint8");
				}
				else {
					this.MBCRam = this.getVector(this.numRAMBanks * 0x2000, 0, "uint8");
				}
			}
			trace("Actual bytes of MBC RAM allocated: " + (this.numRAMBanks * 0x2000), 0);
			this.returnFromRTCState();
			if (this.cGBC) {
				this.VRAM = this.getVector(0x2000, 0, "uint8");
				this.GBCMemory = this.getVector(0x7000, 0, "uint8");
			}
			this.memoryReadJumpCompile();
			this.memoryWriteJumpCompile();
		}
		
		public	function MBCRAMUtilized():Boolean
		{
			return this.cMBC1 || this.cMBC2 || this.cMBC3 || this.cMBC5 || this.cMBC7 || this.cRUMBLE;
		}
		
		public	function initLCD():void
		{
			this.canvasBuffer = new BitmapData(gb.WIDTH, gb.HEIGHT, false, 0x0);
			this.canvasBuffer.fillRect(rect, 0xFFF8F8F8);
			
			this.graphicsBlit();
			this.gb.visible = true;
			if (this.swizzledFrame == null) {
				this.swizzledFrame = this.getVector(23040, 0xFF, "uint8");
			}
			this.drewFrame = true;
			this.requestDraw();
		}
		
		public	function graphicsBlit():void
		{
			this.gb.bitmapData.copyPixels(this.canvasBuffer, rect, dest);
		}
		
		public	function JoyPadEvent(key:uint, down:Boolean):void
		{
			if (down) {
				this.JoyPad &= 0xFF ^ (1 << key);
				if (!this.cGBC && (!this.usedBootROM || !this.usedGBCBootROM)) {
					this.interruptsRequested |= 0x10;
					this.remainingClocks = 0;
					this.checkIRQMatching();
				}
			}
			else {
				this.JoyPad |= (1 << key);
			}
			this.memory[0xFF00] = (this.memory[0xFF00] & 0x30) + ((((this.memory[0xFF00] & 0x20) == 0) ? (this.JoyPad >> 4) : 0xF) & (((this.memory[0xFF00] & 0x10) == 0) ? (this.JoyPad & 0xF) : 0xF));
		}

		public	function GyroEvent(x:int, y:int):void
		{
			x *= -100;
			x += 2047;
			this.highX = x >> 8;
			this.lowX = x & 0xFF;
			y *= -100;
			y += 2047;
			this.highY = y >> 8;
			this.lowY = y & 0xFF;
		}
		
		public	function initSound():void
		{
			this.sampleSize = settings.sampleRate / 1000 * settings.emulatorInterval;
			trace("...Samples per interpreter loop iteration (Per Channel): " + this.sampleSize.toString(), 0);
			this.samplesOut = this.sampleSize / this.CPUCyclesPerIteration;
			trace("...Samples per clock cycle (Per Channel): " + this.samplesOut.toString(), 0);
			this.machineOut = 1 / this.samplesOut;
			if (settings.enableSound) {
				this.soundChannelsAllocated = (!settings.forceMonoSound) ? 2 : 1;
				this.soundFrameShifter = this.soundChannelsAllocated - 1;
				try {
					this.audioHandle = new APU(this.soundChannelsAllocated, settings.sampleRate, 0, Math.max(this.sampleSize * settings.maxAudioIteration, 8192) << this.soundFrameShifter, settings.volume);
					trace("...Audio Channels: " + this.soundChannelsAllocated.toString(), 0);
					trace("...Sample Rate: " + settings.sampleRate.toString(), 0);
					this.initAudioBuffer();
				}
				catch (error:Error) {
					trace("Audio system cannot run: " + error.message, 2);
					settings.enableSound = false;
				}
			}
			else if (this.audioHandle) {
				try {
					this.audioHandle.changeVolume(0);
				}
				catch (error:Error) { }
			}
		}
		
		public	function changeVolume():void
		{
			if (settings.enableSound && this.audioHandle) {
				try {
					this.audioHandle.changeVolume(settings.volume);
				}
				catch (error:Error) { }
			}
		}
		
		public	function initAudioBuffer():void
		{
			this.audioIndex = 0;
			this.bufferContainAmount = Math.max(this.sampleSize * settings.minAudioIteration, 4096) << this.soundFrameShifter;
			this.numSamplesTotal = this.sampleSize << this.soundFrameShifter;
			this.currentBuffer = this.getVector(this.numSamplesTotal, 0, "float32");
		}
		
		public	function intializeWhiteNoise():void
		{
			var randomFactor:Number = 1;
			this.LSFR15Table = this.getVector(0x80000, 0, "float32");
			var LSFR:uint = 0x7FFF;
			var LSFRShifted:uint = 0x3FFF;
			for (var index:uint = 0; index < 0x8000; ++index) {
				randomFactor = 1 - (LSFR & 1);
				this.LSFR15Table[0x08000 | index] = randomFactor / 0x1E;
				this.LSFR15Table[0x10000 | index] = randomFactor * 0x2 / 0x1E;
				this.LSFR15Table[0x18000 | index] = randomFactor * 0x3 / 0x1E;
				this.LSFR15Table[0x20000 | index] = randomFactor * 0x4 / 0x1E;
				this.LSFR15Table[0x28000 | index] = randomFactor * 0x5 / 0x1E;
				this.LSFR15Table[0x30000 | index] = randomFactor * 0x6 / 0x1E;
				this.LSFR15Table[0x38000 | index] = randomFactor * 0x7 / 0x1E;
				this.LSFR15Table[0x40000 | index] = randomFactor * 0x8 / 0x1E;
				this.LSFR15Table[0x48000 | index] = randomFactor * 0x9 / 0x1E;
				this.LSFR15Table[0x50000 | index] = randomFactor * 0xA / 0x1E;
				this.LSFR15Table[0x58000 | index] = randomFactor * 0xB / 0x1E;
				this.LSFR15Table[0x60000 | index] = randomFactor * 0xC / 0x1E;
				this.LSFR15Table[0x68000 | index] = randomFactor * 0xD / 0x1E;
				this.LSFR15Table[0x70000 | index] = randomFactor * 0xE / 0x1E;
				this.LSFR15Table[0x78000 | index] = randomFactor / 2;
				LSFRShifted = LSFR >> 1;
				LSFR = LSFRShifted | (((LSFRShifted ^ LSFR) & 0x1) << 14);
			}
			this.LSFR7Table = this.getVector(0x800, 0, "float32");
			LSFR = 0x7F;
			for (index = 0; index < 0x80; ++index) {
				randomFactor = 1 - (LSFR & 1);
				this.LSFR7Table[0x080 | index] = randomFactor / 0x1E;
				this.LSFR7Table[0x100 | index] = randomFactor * 0x2 / 0x1E;
				this.LSFR7Table[0x180 | index] = randomFactor * 0x3 / 0x1E;
				this.LSFR7Table[0x200 | index] = randomFactor * 0x4 / 0x1E;
				this.LSFR7Table[0x280 | index] = randomFactor * 0x5 / 0x1E;
				this.LSFR7Table[0x300 | index] = randomFactor * 0x6 / 0x1E;
				this.LSFR7Table[0x380 | index] = randomFactor * 0x7 / 0x1E;
				this.LSFR7Table[0x400 | index] = randomFactor * 0x8 / 0x1E;
				this.LSFR7Table[0x480 | index] = randomFactor * 0x9 / 0x1E;
				this.LSFR7Table[0x500 | index] = randomFactor * 0xA / 0x1E;
				this.LSFR7Table[0x580 | index] = randomFactor * 0xB / 0x1E;
				this.LSFR7Table[0x600 | index] = randomFactor * 0xC / 0x1E;
				this.LSFR7Table[0x680 | index] = randomFactor * 0xD / 0x1E;
				this.LSFR7Table[0x700 | index] = randomFactor * 0xE / 0x1E;
				this.LSFR7Table[0x780 | index] = randomFactor / 2;
				LSFRShifted = LSFR >> 1;
				LSFR = LSFRShifted | (((LSFRShifted ^ LSFR) & 0x1) << 6);
			}
			if (!this.noiseSampleTable && this.memory.length == 0x10000) {
				this.noiseSampleTable = ((this.memory[0xFF22] & 0x8) == 0x8) ? this.LSFR7Table : this.LSFR15Table;
			}
		}
		
		public	function audioUnderrunAdjustment():void
		{
			if (settings.enableSound) {
				var temp:Number = this.bufferContainAmount - this.audioHandle.remainingBuffer();
				if (temp > 0) {
					var underrunAmount:uint = temp;
					this.CPUCyclesTotalCurrent += (underrunAmount >> this.soundFrameShifter) * this.machineOut;
					this.recalculateIterationClockLimit();
				}
			}
		}
		
		public	function initializeAudioStartState():void
		{
			this.channel1adjustedFrequencyPrep = 0;
			this.channel1adjustedDuty = 0.5;
			this.channel1totalLength = 0;
			this.channel1envelopeVolume = 0;
			this.channel1currentVolume = 0;
			this.channel1envelopeType = false;
			this.channel1envelopeSweeps = 0;
			this.channel1consecutive = true;
			this.channel1frequency = 0;
			this.channel1Fault = 0x2;
			this.channel1ShadowFrequency = 0;
			this.channel1volumeEnvTime = 0;
			this.channel1volumeEnvTimeLast = 0;
			this.channel1timeSweep = 0;
			this.channel1lastTimeSweep = 0;
			this.channel1numSweep = 0;
			this.channel1frequencySweepDivider = 0;
			this.channel1decreaseSweep = false;
			this.channel2adjustedFrequencyPrep = 0;
			this.channel2adjustedDuty = 0.5;
			this.channel2totalLength = 0;
			this.channel2envelopeVolume = 0;
			this.channel2currentVolume = 0;
			this.channel2envelopeType = false;
			this.channel2envelopeSweeps = 0;
			this.channel2consecutive = true;
			this.channel2frequency = 0;
			this.channel2volumeEnvTime = 0;
			this.channel2volumeEnvTimeLast = 0;
			this.channel3canPlay = false;
			this.channel3totalLength = 0;
			this.channel3patternType = 0;
			this.channel3frequency = 0;
			this.channel3consecutive = true;
			this.channel3adjustedFrequencyPrep = 0x20000 / this.settings.sampleRate;
			this.channel4adjustedFrequencyPrep = 0;
			this.channel4totalLength = 0;
			this.channel4envelopeVolume = 0;
			this.channel4currentVolume = 0;
			this.channel4envelopeType = false;
			this.channel4envelopeSweeps = 0;
			this.channel4consecutive = true;
			this.channel4volumeEnvTime = 0;
			this.channel4volumeEnvTimeLast = 0;
			this.noiseTableLength = 0x8000;
			this.noiseSampleTable = this.LSFR15Table;
			this.channel4VolumeShifter = 15;
			this.channel1lastSampleLookup = 0;
			this.channel2lastSampleLookup = 0;
			this.channel3Tracker = 0;
			this.channel4lastSampleLookup = 0;
			this.VinLeftChannelMasterVolume = 1;
			this.VinRightChannelMasterVolume = 1;
		}
		
		public	function generateAudio (numSamples:int):void
		{
			if (this.soundMasterEnabled) {
				if (!settings.forceMonoSound) {
					while (--numSamples > -1) {
						this.audioChannelsComputeStereo();
						this.currentBuffer[this.audioIndex++] = this.currentSampleLeft * this.VinLeftChannelMasterVolume - 1;
						this.currentBuffer[this.audioIndex++] = this.currentSampleRight * this.VinRightChannelMasterVolume - 1;
						if (this.audioIndex == this.numSamplesTotal) {
							this.audioIndex = 0;
							this.audioHandle.writeAudioNoCallback(this.currentBuffer);
						}
					}
				}
				else {
					while (--numSamples > -1) {
						this.audioChannelsComputeStereo();
						this.currentBuffer[this.audioIndex++] = this.currentSampleRight * this.VinRightChannelMasterVolume - 1;
						if (this.audioIndex == this.numSamplesTotal) {
							this.audioIndex = 0;
							this.audioHandle.writeAudioNoCallback(this.currentBuffer);
						}
					}
				}
			}
			else {
				if (!settings.forceMonoSound) {
					while (--numSamples > -1) {
						this.currentBuffer[this.audioIndex++] = -1;
						this.currentBuffer[this.audioIndex++] = -1;
						if (this.audioIndex == this.numSamplesTotal) {
							this.audioIndex = 0;
							this.audioHandle.writeAudioNoCallback(this.currentBuffer);
						}
					}
				}
				else {
					while (--numSamples > -1) {
						this.currentBuffer[this.audioIndex++] = -1;
						if (this.audioIndex == this.numSamplesTotal) {
							this.audioIndex = 0;
							this.audioHandle.writeAudioNoCallback(this.currentBuffer);
						}
					}
				}
			}
		}
		
		public	function generateAudioFake(numSamples:int):void
		{
			if (this.soundMasterEnabled) {
				while (--numSamples > -1) {
					this.audioChannelsComputeStereo();
				}
			}
		}
		
		public	function audioJIT():void
		{
			var amount:Number = this.audioTicks * this.samplesOut;
			var actual:Number = amount | 0;
			this.rollover += amount - actual;
			if (this.rollover >= 1) {
				--this.rollover;
				++actual;
			}
			this.audioTicks = 0;
			if (settings.enableSound) {
				this.generateAudio(actual);
			}
			else {
				this.generateAudioFake(actual);
			}
		}
		
		public	function audioChannelsComputeStereo():void
		{
			if ((this.channel1consecutive || this.channel1totalLength > 0) && this.channel1Fault == 0) {
				if (this.channel1lastSampleLookup <= this.channel1adjustedDuty) {
					this.currentSampleLeft = (this.leftChannel0) ? this.channel1currentVolume : 0;
					this.currentSampleRight = (this.rightChannel0) ? this.channel1currentVolume : 0;
				}
				else {
					this.currentSampleRight = this.currentSampleLeft = 0;
				}
				if (this.channel1numSweep > 0) {
					if (--this.channel1timeSweep == 0) {
						--this.channel1numSweep;
						if (this.channel1decreaseSweep) {
							this.channel1ShadowFrequency -= this.channel1ShadowFrequency >> this.channel1frequencySweepDivider;
							this.channel1adjustedFrequencyPrep = this.preChewedAudioComputationMultiplier / (0x800 - this.channel1ShadowFrequency);
						}
						else {
							this.channel1ShadowFrequency += this.channel1ShadowFrequency >> this.channel1frequencySweepDivider;
							if (this.channel1ShadowFrequency <= 0x7FF) {
								this.channel1adjustedFrequencyPrep = this.preChewedAudioComputationMultiplier / (0x800 - this.channel1ShadowFrequency);
							}
							else {
								this.channel1Fault |= 0x2;
								this.memory[0xFF26] &= 0xFE;
							}
						}
						this.channel1timeSweep = this.channel1lastTimeSweep;
					}
				}
				if (this.channel1envelopeSweeps > 0) {
					if (this.channel1volumeEnvTime > 0) {
						--this.channel1volumeEnvTime;
					}
					else {
						if (!this.channel1envelopeType) {
							if (this.channel1envelopeVolume > 0) {
								this.channel1currentVolume = --this.channel1envelopeVolume / 0x1E;
								this.channel1volumeEnvTime = this.channel1volumeEnvTimeLast;
							}
							else {
								this.channel1envelopeSweeps = 0;
							}
						}
						else if (this.channel1envelopeVolume < 0xF) {
							this.channel1currentVolume = ++this.channel1envelopeVolume / 0x1E;
							this.channel1volumeEnvTime = this.channel1volumeEnvTimeLast;
						}
						else {
							this.channel1envelopeSweeps = 0;
						}
					}
				}
				if (this.channel1totalLength > 0) {
					--this.channel1totalLength;
					if (this.channel1totalLength <= 0) {
						this.memory[0xFF26] &= 0xFE;
					}
				}
				this.channel1lastSampleLookup += this.channel1adjustedFrequencyPrep;
				while (this.channel1lastSampleLookup >= 1) {
					this.channel1lastSampleLookup -= 1;
				}
			}
			else {
				this.currentSampleRight = this.currentSampleLeft = 0;
			}
			if ((this.channel2consecutive || this.channel2totalLength > 0)) {
				if (this.channel2lastSampleLookup <= this.channel2adjustedDuty) {
					if (this.leftChannel1) {
						this.currentSampleLeft += this.channel2currentVolume;
					}
					if (this.rightChannel1) {
						this.currentSampleRight += this.channel2currentVolume;
					}
				}
				if (this.channel2envelopeSweeps > 0) {
					if (this.channel2volumeEnvTime > 0) {
						--this.channel2volumeEnvTime;
					}
					else {
						if (!this.channel2envelopeType) {
							if (this.channel2envelopeVolume > 0) {
								this.channel2currentVolume = --this.channel2envelopeVolume / 0x1E;
								this.channel2volumeEnvTime = this.channel2volumeEnvTimeLast;
							}
							else {
								this.channel2envelopeSweeps = 0;
							}
						}
						else if (this.channel2envelopeVolume < 0xF) {
							this.channel2currentVolume = ++this.channel2envelopeVolume / 0x1E;
							this.channel2volumeEnvTime = this.channel2volumeEnvTimeLast;
						}
						else {
							this.channel2envelopeSweeps = 0;
						}
					}
				}
				if (this.channel2totalLength > 0) {
					--this.channel2totalLength;
					if (this.channel2totalLength <= 0) {
						this.memory[0xFF26] &= 0xFD;
					}
				}
				this.channel2lastSampleLookup += this.channel2adjustedFrequencyPrep;
				while (this.channel2lastSampleLookup >= 1) {
					this.channel2lastSampleLookup -= 1;
				}
			}
			if (this.channel3canPlay && (this.channel3consecutive || this.channel3totalLength > 0)) {
				var PCMSample:Number = this.channel3PCM[this.channel3Tracker | this.channel3patternType];	
				if (this.leftChannel2) {
					this.currentSampleLeft += PCMSample;
				}
				if (this.rightChannel2) {
					this.currentSampleRight += PCMSample;
				}
				this.channel3Tracker += this.channel3adjustedFrequencyPrep;
				if (this.channel3Tracker >= 0x20) {
					this.channel3Tracker -= 0x20;
				}
				if (this.channel3totalLength > 0) {
					--this.channel3totalLength;
					if (this.channel3totalLength <= 0) {
						this.memory[0xFF26] &= 0xFB;
					}
				}
			}
			if (this.channel4consecutive || this.channel4totalLength > 0) {
				var duty:Number = this.noiseSampleTable[this.channel4currentVolume | this.channel4lastSampleLookup];
				if (this.leftChannel3) {
					this.currentSampleLeft += duty;
				}
				if (this.rightChannel3) {
					this.currentSampleRight += duty;
				}
				if (this.channel4envelopeSweeps > 0) {
					if (this.channel4volumeEnvTime > 0) {
						--this.channel4volumeEnvTime;
					}
					else {
						if (!this.channel4envelopeType) {
							if (this.channel4envelopeVolume > 0) {
								this.channel4currentVolume = --this.channel4envelopeVolume << this.channel4VolumeShifter;
								this.channel4volumeEnvTime = this.channel4volumeEnvTimeLast;
							}
							else {
								this.channel4envelopeSweeps = 0;
							}
						}
						else if (this.channel4envelopeVolume < 0xF) {
							this.channel4currentVolume = ++this.channel4envelopeVolume << this.channel4VolumeShifter;
							this.channel4volumeEnvTime = this.channel4volumeEnvTimeLast;
						}
						else {
							this.channel4envelopeSweeps = 0;
						}
					}
				}
				if (this.channel4totalLength > 0) {
					--this.channel4totalLength;
					if (this.channel4totalLength <= 0) {
						this.memory[0xFF26] &= 0xF7;
					}
				}
				this.channel4lastSampleLookup += this.channel4adjustedFrequencyPrep;
				if (this.channel4lastSampleLookup >= this.noiseTableLength) {
					this.channel4lastSampleLookup -= this.noiseTableLength;
				}
			}
		}
		
		public	function run():void
		{
			if ((this.stopEmulator & 2) == 0) {
				if ((this.stopEmulator & 1) == 1) {
					this.stopEmulator = 0;
					this.drewFrame = false;
					this.audioUnderrunAdjustment();
					this.clockUpdate();
					if (!this.halt) {
						this.executeIteration();
					}
					else {
						this.CPUTicks = 0;
						this.calculateHALTPeriod();
						if (this.halt) {
							this.updateCoreFull();
						}
						else {
							this.executeIteration();
						}
					}
					this.requestDraw();
				}
				else {
					trace("Iterator restarted a faulted core.", 2);
					gb.pause();
				}
			}
		}
		
		public	function executeIteration():void
		{
			var opcodeToExecute:int = 0;
			var timedTicks:uint = 0;
			while (this.stopEmulator == 0) {
				switch (this.IRQEnableDelay) {
					case 1:
						this.IME = true;
						this.checkIRQMatching();
					case 2:
						--this.IRQEnableDelay;
				}
				if (this.IRQLineMatched > 0) {
					this.launchIRQ();
				}
				opcodeToExecute = this.memoryReader[this.programCounter](this.programCounter);
				this.programCounter = (this.programCounter + 1) & 0xFFFF;
				if (this.skipPCIncrement) {
					this.programCounter = (this.programCounter - 1) & 0xFFFF;
					this.skipPCIncrement = false;
				}
				this.CPUTicks = this.TICKTable[opcodeToExecute];
				this.OPCODE[opcodeToExecute]();
				this.LCDTicks += this.CPUTicks >> this.doubleSpeedShifter;
				this.LCDCONTROL[this.actualScanLine]();
				timedTicks = this.CPUTicks >> this.doubleSpeedShifter;
				this.audioTicks += timedTicks;
				this.emulatorTicks += timedTicks;
				this.DIVTicks += this.CPUTicks;
				if (this.TIMAEnabled) {
					this.timerTicks += this.CPUTicks;
					while (this.timerTicks >= this.TACClocker) {
						this.timerTicks -= this.TACClocker;
						if (++this.memory[0xFF05] == 0x100) {
							this.memory[0xFF05] = this.memory[0xFF06];
							this.interruptsRequested |= 0x4;
							this.checkIRQMatching();
						}
					}
				}
				if (this.serialTimer > 0) {
					this.serialTimer -= this.CPUTicks;
					if (this.serialTimer <= 0) {
						this.interruptsRequested |= 0x8;
						this.checkIRQMatching();
					}
					this.serialShiftTimer -= this.CPUTicks;
					if (this.serialShiftTimer <= 0) {
						this.serialShiftTimer = this.serialShiftTimerAllocated;
						this.memory[0xFF01] = ((this.memory[0xFF01] << 1) & 0xFE) | 0x01;
					}
				}
				if (this.emulatorTicks >= this.CPUCyclesTotal) {
					this.iterationEndRoutine();
				}
			}
		}
		
		public	function iterationEndRoutine():void
		{
			if ((this.stopEmulator & 0x1) == 0) {
				this.audioJIT();
				this.memory[0xFF04] = (this.memory[0xFF04] + (this.DIVTicks >> 8)) & 0xFF;
				this.DIVTicks &= 0xFF;
				this.stopEmulator |= 1;
				this.emulatorTicks -= this.CPUCyclesTotal;
				this.CPUCyclesTotalCurrent += this.CPUCyclesTotalRoundoff;
				this.recalculateIterationClockLimit();
			}
		}
		
		public	function recalculateIterationClockLimit():void
		{
			var endModulus:Number = this.CPUCyclesTotalCurrent % 4;
			this.CPUCyclesTotal = this.CPUCyclesTotalBase + this.CPUCyclesTotalCurrent - endModulus;
			this.CPUCyclesTotalCurrent = endModulus;
		}
		
		public	function scanLineMode2():void
		{
			if (this.STATTracker != 1) {
				if (this.mode2TriggerSTAT) {
					this.interruptsRequested |= 0x2;
					this.checkIRQMatching();
				}
				this.STATTracker = 1;
				this.modeSTAT = 2;
			}
		}
		
		public	function scanLineMode3():void
		{
			if (this.modeSTAT != 3) {
				if (this.STATTracker == 0 && this.mode2TriggerSTAT) {
					this.interruptsRequested |= 0x2;
					this.checkIRQMatching();
				}
				this.STATTracker = 1;
				this.modeSTAT = 3;
			}
		}
		
		public	function scanLineMode0():void
		{
			if (this.modeSTAT != 0) {
				if (this.STATTracker != 2) {
					if (this.STATTracker == 0) {
						if (this.mode2TriggerSTAT) {
							this.interruptsRequested |= 0x2;
							this.checkIRQMatching();
						}
						this.modeSTAT = 3;
					}
					this.incrementScanLineQueue();
					this.updateSpriteCount(this.actualScanLine);
					this.STATTracker = 2;
				}
				if (this.LCDTicks >= this.spriteCount) {
					if (this.hdmaRunning) {
						this.executeHDMA();
					}
					if (this.mode0TriggerSTAT) {
						this.interruptsRequested |= 0x2;
						this.checkIRQMatching();
					}
					this.STATTracker = 3;
					this.modeSTAT = 0;
				}
			}
		}
		
		public	function clocksUntilLYCMatch():uint
		{
			if (this.memory[0xFF45] != 0) {
				if (this.memory[0xFF45] > this.actualScanLine) {
					return 456 * (this.memory[0xFF45] - this.actualScanLine);
				}
				return 456 * (154 - this.actualScanLine + this.memory[0xFF45]);
			}
			return (456 * ((this.actualScanLine == 153 && this.memory[0xFF44] == 0) ? 154 : (153 - this.actualScanLine))) + 8;
		}
		
		public	function clocksUntilMode0():uint
		{
			switch (this.modeSTAT) {
				case 0:
					if (this.actualScanLine == 143) {
						this.updateSpriteCount(0);
						return this.spriteCount + 5016;
					}
					this.updateSpriteCount(this.actualScanLine + 1);
					return this.spriteCount + 456;
				case 2:
				case 3:
					this.updateSpriteCount(this.actualScanLine);
					return this.spriteCount;
				case 1:
				default:
					this.updateSpriteCount(0);
					return this.spriteCount + (456 * (154 - this.actualScanLine));
			}
		}
		
		public	function updateSpriteCount(line:uint):void
		{
			this.spriteCount = 252;
			if (this.cGBC && this.gfxSpriteShow) {
				var lineAdjusted:uint = line + 0x10;
				var yoffset:int = 0;
				var yCap:uint = (this.gfxSpriteNormalHeight) ? 0x8 : 0x10;
				for (var OAMAddress:uint = 0xFE00; OAMAddress < 0xFEA0 && this.spriteCount < 312; OAMAddress += 4) {
					yoffset = lineAdjusted - this.memory[OAMAddress];
					if (yoffset > -1 && yoffset < yCap) {
						this.spriteCount += 6;
					}
				}
			}
		}
		
		public	function matchLYC():void
		{
			if (this.memory[0xFF44] == this.memory[0xFF45]) {
				this.memory[0xFF41] |= 0x04;
				if (this.LYCMatchTriggerSTAT) {
					this.interruptsRequested |= 0x2;
					this.checkIRQMatching();
				}
			} 
			else {
				this.memory[0xFF41] &= 0x7B;
			}
		}
		
		public	function updateCore():void
		{
			this.LCDTicks += this.CPUTicks >> this.doubleSpeedShifter;
			this.LCDCONTROL[this.actualScanLine](this);
			var timedTicks:uint = this.CPUTicks >> this.doubleSpeedShifter;
			this.audioTicks += timedTicks;
			this.emulatorTicks += timedTicks;
			this.DIVTicks += this.CPUTicks;
			if (this.TIMAEnabled) {
				this.timerTicks += this.CPUTicks;
				while (this.timerTicks >= this.TACClocker) {
					this.timerTicks -= this.TACClocker;
					if (++this.memory[0xFF05] == 0x100) {
						this.memory[0xFF05] = this.memory[0xFF06];
						this.interruptsRequested |= 0x4;
						this.checkIRQMatching();
					}
				}
			}
			if (this.serialTimer > 0) {
				this.serialTimer -= this.CPUTicks;
				if (this.serialTimer <= 0) {
					this.interruptsRequested |= 0x8;
					this.checkIRQMatching();
				}
				this.serialShiftTimer -= this.CPUTicks;
				if (this.serialShiftTimer <= 0) {
					this.serialShiftTimer = this.serialShiftTimerAllocated;
					this.memory[0xFF01] = ((this.memory[0xFF01] << 1) & 0xFE) | 0x01;
				}
			}
		}
		
		public	function updateCoreFull():void
		{
			this.updateCore();
			if (this.emulatorTicks >= this.CPUCyclesTotal) {
				this.iterationEndRoutine();
			}
		}
		
		public	function initializeLCDController():void
		{
			var line:uint = 0;
			while (line < 154) {
				if (line < 143) {
					this.LINECONTROL[line] = function ():void {
						if (LCDTicks < 80) {
							scanLineMode2();
						}
						else if (LCDTicks < 252) {
							scanLineMode3();
						}
						else if (LCDTicks < 456) {
							scanLineMode0();
						}
						else {
							LCDTicks -= 456;
							if (STATTracker != 3) {
								if (STATTracker != 2) {
									if (STATTracker == 0 && mode2TriggerSTAT) {
										interruptsRequested |= 0x2;
									}
									incrementScanLineQueue();
								}
								if (hdmaRunning) {
									executeHDMA();
								}
								if (mode0TriggerSTAT) {
									interruptsRequested |= 0x2;
								}
							}
							actualScanLine = ++memory[0xFF44];
							if (actualScanLine == memory[0xFF45]) {
								memory[0xFF41] |= 0x04;
								if (LYCMatchTriggerSTAT) {
									interruptsRequested |= 0x2;
								}
							} 
							else {
								memory[0xFF41] &= 0x7B;
							}
							checkIRQMatching();
							STATTracker = 0;
							modeSTAT = 2;
							LINECONTROL[actualScanLine]();
						}
					}
				}
				else if (line == 143) {
					this.LINECONTROL[143] = function ():void {
						if (LCDTicks < 80) {
							scanLineMode2();
						}
						else if (LCDTicks < 252) {
							scanLineMode3();
						}
						else if (LCDTicks < 456) {
							scanLineMode0();
						}
						else {
							LCDTicks -= 456;
							if (STATTracker != 3) {
								if (STATTracker != 2) {
									if (STATTracker == 0 && mode2TriggerSTAT) {
										interruptsRequested |= 0x2;
									}
									incrementScanLineQueue();
								}
								if (hdmaRunning) {
									executeHDMA();
								}
								if (mode0TriggerSTAT) {
									interruptsRequested |= 0x2;
								}
							}
							actualScanLine = memory[0xFF44] = gb.HEIGHT;
							if (memory[0xFF45] == gb.HEIGHT) {
								memory[0xFF41] |= 0x04;
								if (LYCMatchTriggerSTAT) {
									interruptsRequested |= 0x2;
								}
							} 
							else {
								memory[0xFF41] &= 0x7B;
							}
							STATTracker = 0;
							modeSTAT = 1;
							interruptsRequested |= (mode1TriggerSTAT) ? 0x3 : 0x1;
							checkIRQMatching();
							if (drewBlank == 0) {
								if (totalLinesPassed < gb.HEIGHT || (totalLinesPassed == gb.HEIGHT && midScanlineOffset > -1)) {
									graphicsJITVBlank();
									prepareFrame();
								}
							}
							else {
								--drewBlank;
							}
							LINECONTROL[gb.HEIGHT]();
						}
					}
				}
				else if (line < 153) {
					this.LINECONTROL[line] = function ():void {
						if (LCDTicks >= 456) {
							LCDTicks -= 456;
							actualScanLine = ++memory[0xFF44];
							if (actualScanLine == memory[0xFF45]) {
								memory[0xFF41] |= 0x04;
								if (LYCMatchTriggerSTAT) {
									interruptsRequested |= 0x2;
									checkIRQMatching();
								}
							} 
							else {
								memory[0xFF41] &= 0x7B;
							}
							LINECONTROL[actualScanLine]();
						}
					}
				}
				else {
					this.LINECONTROL[153] = function ():void {
						if (LCDTicks >= 8) {
							if (STATTracker != 4 && memory[0xFF44] == 153) {
								memory[0xFF44] = 0;
								if (memory[0xFF45] == 0) {
									memory[0xFF41] |= 0x04;
									if (LYCMatchTriggerSTAT) {
										interruptsRequested |= 0x2;
										checkIRQMatching();
									}
								} 
								else {
									memory[0xFF41] &= 0x7B;
								}
								STATTracker = 4;
							}
							if (LCDTicks >= 456) {
								LCDTicks -= 456;
								STATTracker = actualScanLine = 0;
								LINECONTROL[0]();
							}
						}
					}
				}
				++line;
			}
		}
		
		public	function DisplayShowOff():void
		{
			if (this.drewBlank == 0) {
				this.clearFrameBuffer();
				this.drewFrame = true;
			}
			this.drewBlank = 2;
		}
		
		public	function executeHDMA():void
		{
			this.DMAWrite(1);
			if (this.halt) {
				if ((this.LCDTicks - this.spriteCount) < ((4 >> this.doubleSpeedShifter) | 0x20)) {
					this.CPUTicks = 4 + ((0x20 + this.spriteCount) << this.doubleSpeedShifter);
					this.LCDTicks = this.spriteCount + ((4 >> this.doubleSpeedShifter) | 0x20);
				}
			}
			else {
				this.LCDTicks += (4 >> this.doubleSpeedShifter) | 0x20;
			}
			if (this.memory[0xFF55] == 0) {
				this.hdmaRunning = false;
				this.memory[0xFF55] = 0xFF;
			}
			else {
				--this.memory[0xFF55];
			}
		}
		
		public	function clockUpdate():void
		{
			if (this.cTIMER) {
				var newTime:Number = new Date().time;
				var timeElapsed:Number = newTime - this.lastIteration;
				this.lastIteration = newTime;
				if (this.cTIMER && !this.RTCHALT) {
					this.RTCSeconds += Math.round(timeElapsed / 1000);
					while (this.RTCSeconds >= 60) {
						this.RTCSeconds -= 60;
						++this.RTCMinutes;
						if (this.RTCMinutes >= 60) {
							this.RTCMinutes -= 60;
							++this.RTCHours;
							if (this.RTCHours >= 24) {
								this.RTCHours -= 24
								++this.RTCDays;
								if (this.RTCDays >= 512) {
									this.RTCDays -= 512;
									this.RTCDayOverFlow = true;
								}
							}
						}
					}
				}
			}
		}
		
		public	function prepareFrame():void
		{
			this.swizzleFrameBuffer();
			this.drewFrame = true;
		}
		
		public	function requestDraw():void
		{
			if (this.drewFrame) {
				var canvasRGBALength:uint = this.offscreenRGBCount;
				if (canvasRGBALength > 0) {
					this.canvasBuffer.setVector(rect, swizzledFrame);
					this.graphicsBlit();
				}
			}
		}
		
		public	function swizzleFrameBuffer():void
		{
			var index:int = 0;
			while (index<23040)
			{
				this.swizzledFrame[index] = this.frameBuffer[index] & 0xFFFFFF;
				index++;
			}
		}

		public	function clearFrameBuffer():void
		{
			var bufferIndex:uint = 0;
			var frameBuffer:Vector.<uint> = this.swizzledFrame;
			if (this.cGBC || this.colorizedGBPalettes) {
				while (bufferIndex < 23040) {
					frameBuffer[bufferIndex++] = 0xF8F8F8;
				}
			}
			else {
				while (bufferIndex < 23040) {
					frameBuffer[bufferIndex++] = 0xEFFFDE;
				}
			}
		}

		public	function renderScanLine(scanlineToRender:uint):void
		{
			this.pixelStart = scanlineToRender * gb.WIDTH;
			if (this.bgEnabled) {
				this.pixelEnd = gb.WIDTH;
				this.BGLayerRender(scanlineToRender);
				this.WindowLayerRender(scanlineToRender);
			}
			else {
				var pixelLine:Number = (scanlineToRender + 1) * gb.WIDTH;
				var defaultColor:uint = (this.cGBC || this.colorizedGBPalettes) ? 0xF8F8F8 : 0xEFFFDE;
				for (var pixelPosition:uint = (scanlineToRender * gb.WIDTH) + this.currentX; pixelPosition < pixelLine; pixelPosition++) {
					this.frameBuffer[pixelPosition] = defaultColor;
				}
			}
			this.SpriteLayerRender(scanlineToRender);
			this.currentX = 0;
			this.midScanlineOffset = -1;
		}

		public	function renderMidScanLine():void
		{
			if (this.actualScanLine < gb.HEIGHT && this.modeSTAT == 3) {
				if (this.midScanlineOffset == -1) {
					this.midScanlineOffset = this.backgroundX & 0x7;
				}
				if (this.LCDTicks >= 82) {
					this.pixelEnd = this.LCDTicks - 74;
					this.pixelEnd = Math.min(this.pixelEnd - this.midScanlineOffset - (this.pixelEnd % 0x8), gb.WIDTH);
					if (this.bgEnabled) {
						this.pixelStart = this.lastUnrenderedLine * gb.WIDTH;
						this.BGLayerRender(this.lastUnrenderedLine);
						this.WindowLayerRender(this.lastUnrenderedLine);
					}
					else {
						var pixelLine:Number = (this.lastUnrenderedLine * gb.WIDTH) + this.pixelEnd;
						var defaultColor:uint = (this.cGBC || this.colorizedGBPalettes) ? 0xF8F8F8 : 0xEFFFDE;
						for (var pixelPosition:uint = (this.lastUnrenderedLine * gb.WIDTH) + this.currentX; pixelPosition < pixelLine; pixelPosition++) {
							this.frameBuffer[pixelPosition] = defaultColor;
						}
					}
					this.currentX = this.pixelEnd;
				}
			}
		}
		
		public	function initializeModeSpecificArrays():void
		{
			this.LCDCONTROL = (this.LCDisOn) ? this.LINECONTROL : this.DISPLAYOFFCONTROL;
			if (this.cGBC) {
				this.gbcOBJRawPalette = this.getVector(0x40, 0, "uint8");
				this.gbcBGRawPalette = this.getVector(0x40, 0, "uint8");
				this.gbcOBJPalette = this.getVector(0x20, 0x1000000, "int32");
				this.gbcBGPalette = this.getVector(0x40, 0, "int32");
				this.BGCHRBank2 = this.getVector(0x800, 0, "uint8");
				this.BGCHRCurrentBank = (this.currVRAMBank > 0) ? this.BGCHRBank2 : this.BGCHRBank1;
				this.tileCache = this.generateCacheArray(0xF80);
			}
			else {
				this.gbOBJPalette = this.getVector(8, 0, "int32");
				this.gbBGPalette = this.getVector(4, 0, "int32");
				this.BGPalette = this.gbBGPalette;
				this.OBJPalette = this.gbOBJPalette;
				this.tileCache = this.generateCacheArray(0x700);
				this.sortBuffer = this.getVector(0x100, 0, "uint8");
				this.OAMAddressCache = this.getVector(10, 0, "int8");
			}
			this.renderPathBuild();
		}
		
		public	function GBCtoGBModeAdjust():void
		{
			trace("Stepping down from GBC mode.", 0);
			this.VRAM = this.GBCMemory = this.BGCHRCurrentBank = this.BGCHRBank2 = null;
			this.tileCache.length = 0x700;
			if (settings.colorizeGameBoy) {
				this.gbBGColorizedPalette = this.getVector(4, 0, "int32");
				this.gbOBJColorizedPalette = this.getVector(8, 0, "int32");
				this.cachedBGPaletteConversion = this.getVector(4, 0, "int32");
				this.cachedOBJPaletteConversion = this.getVector(8, 0, "int32");
				this.BGPalette = this.gbBGColorizedPalette;
				this.OBJPalette = this.gbOBJColorizedPalette;
				this.gbOBJPalette = this.gbBGPalette = null;
				this.getGBCColor();
			}
			else {
				this.gbOBJPalette = this.getVector(8, 0, "int32");
				this.gbBGPalette = this.getVector(4, 0, "int32");
				this.BGPalette = this.gbBGPalette;
				this.OBJPalette = this.gbOBJPalette;
			}
			this.sortBuffer = this.getVector(0x100, 0, "uint8");
			this.OAMAddressCache = this.getVector(10, 0, "int32");
			this.renderPathBuild();
			this.memoryReadJumpCompile();
			this.memoryWriteJumpCompile();
		}
		
		public	function renderPathBuild():void
		{
			if (!this.cGBC) {
				this.BGLayerRender = this.BGGBLayerRender;
				this.WindowLayerRender = this.WindowGBLayerRender;
				this.SpriteLayerRender = this.SpriteGBLayerRender;
			}
			else {
				this.priorityFlaggingPathRebuild();
				this.SpriteLayerRender = this.SpriteGBCLayerRender;
			}
		}
		
		public	function priorityFlaggingPathRebuild():void
		{
			if (this.BGPriorityEnabled) {
				this.BGLayerRender = this.BGGBCLayerRender;
				this.WindowLayerRender = this.WindowGBCLayerRender;
			}
			else {
				this.BGLayerRender = this.BGGBCLayerRenderNoPriorityFlagging;
				this.WindowLayerRender = this.WindowGBCLayerRenderNoPriorityFlagging;
			}
		}
		
		public	function initializeReferencesFromSaveState():void
		{
			this.LCDCONTROL = (this.LCDisOn) ? this.LINECONTROL : this.DISPLAYOFFCONTROL;
			var tileIndex:uint = 0;
			if (!this.cGBC) {
				if (this.colorizedGBPalettes) {
					this.BGPalette = this.gbBGColorizedPalette;
					this.OBJPalette = this.gbOBJColorizedPalette;
					this.updateGBBGPalette = this.updateGBColorizedBGPalette;
					this.updateGBOBJPalette = this.updateGBColorizedOBJPalette;
					
				}
				else {
					this.BGPalette = this.gbBGPalette;
					this.OBJPalette = this.gbOBJPalette;
				}
				this.tileCache = this.generateCacheArray(0x700);
				for (tileIndex = 0x8000; tileIndex < 0x9000; tileIndex += 2) {
					this.generateGBOAMTileLine(tileIndex);
				}
				for (tileIndex = 0x9000; tileIndex < 0x9800; tileIndex += 2) {
					this.generateGBTileLine(tileIndex);
				}
			}
			else {
				this.BGCHRCurrentBank = (this.currVRAMBank > 0) ? this.BGCHRBank2 : this.BGCHRBank1;
				this.tileCache = this.generateCacheArray(0xF80);
				for (; tileIndex < 0x1800; tileIndex += 0x10) {
					this.generateGBCTileBank1(tileIndex);
					this.generateGBCTileBank2(tileIndex);
				}
			}
			this.renderPathBuild();
		}
		
		public	function RGBTint(value:uint):uint
		{
			var r:uint = value & 0x1F;
			var g:uint = (value >> 5) & 0x1F;
			var b:uint = (value >> 10) & 0x1F;
			return ((r * 13 + g * 2 + b) >> 1) << 16 | (g * 3 + b) << 9 | (r * 3 + g * 2 + b * 11) >> 1;
		}
		
		public	function getGBCColor():void
		{
			for (var counter:uint = 0; counter < 4; counter++) {
				var adjustedIndex:uint = counter << 1;
				this.cachedBGPaletteConversion[counter] = this.RGBTint((this.gbcBGRawPalette[adjustedIndex | 1] << 8) | this.gbcBGRawPalette[adjustedIndex]);
				this.cachedOBJPaletteConversion[counter] = this.RGBTint((this.gbcOBJRawPalette[adjustedIndex | 1] << 8) | this.gbcOBJRawPalette[adjustedIndex]);
			}
			for (counter = 4; counter < 8; counter++) {
				adjustedIndex = counter << 1;
				this.cachedOBJPaletteConversion[counter] = this.RGBTint((this.gbcOBJRawPalette[adjustedIndex | 1] << 8) | this.gbcOBJRawPalette[adjustedIndex]);
			}
			this.updateGBBGPalette = this.updateGBColorizedBGPalette;
			this.updateGBOBJPalette = this.updateGBColorizedOBJPalette;
			this.updateGBBGPalette(this.memory[0xFF47]);
			this.updateGBOBJPalette(0, this.memory[0xFF48]);
			this.updateGBOBJPalette(1, this.memory[0xFF49]);
			this.colorizedGBPalettes = true;
		}
		
		public	function updateGBRegularBGPalette(data:uint):void
		{
			this.gbBGPalette[0] = this.colors[data & 0x03] | 0x2000000;
			this.gbBGPalette[1] = this.colors[(data >> 2) & 0x03];
			this.gbBGPalette[2] = this.colors[(data >> 4) & 0x03];
			this.gbBGPalette[3] = this.colors[data >> 6];
		}
		
		public	function updateGBColorizedBGPalette(data:uint):void
		{
			this.gbBGColorizedPalette[0] = this.cachedBGPaletteConversion[data & 0x03] | 0x2000000;
			this.gbBGColorizedPalette[1] = this.cachedBGPaletteConversion[(data >> 2) & 0x03];
			this.gbBGColorizedPalette[2] = this.cachedBGPaletteConversion[(data >> 4) & 0x03];
			this.gbBGColorizedPalette[3] = this.cachedBGPaletteConversion[data >> 6];
		}
		
		public	function updateGBRegularOBJPalette(index:uint, data:uint):void
		{
			this.gbOBJPalette[index | 1] = this.colors[(data >> 2) & 0x03];
			this.gbOBJPalette[index | 2] = this.colors[(data >> 4) & 0x03];
			this.gbOBJPalette[index | 3] = this.colors[data >> 6];
		}
		
		public	function updateGBColorizedOBJPalette(index:uint, data:uint):void
		{
			this.gbOBJColorizedPalette[index | 1] = this.cachedOBJPaletteConversion[index | ((data >> 2) & 0x03)];
			this.gbOBJColorizedPalette[index | 2] = this.cachedOBJPaletteConversion[index | ((data >> 4) & 0x03)];
			this.gbOBJColorizedPalette[index | 3] = this.cachedOBJPaletteConversion[index | (data >> 6)];
		}
		
		public	function updateGBCBGPalette(index:uint, data:uint):void
		{
			if (this.gbcBGRawPalette[index] != data) {
				this.midScanLineJIT();
				this.gbcBGRawPalette[index] = data;
				if ((index & 0x06) == 0) {
					data = 0x2000000 | this.RGBTint((this.gbcBGRawPalette[index | 1] << 8) | this.gbcBGRawPalette[index & 0x3E]);
					index >>= 1;
					this.gbcBGPalette[index] = data;
					this.gbcBGPalette[0x20 | index] = 0x1000000 | data;
				}
				else {
					data = this.RGBTint((this.gbcBGRawPalette[index | 1] << 8) | this.gbcBGRawPalette[index & 0x3E]);
					index >>= 1;
					this.gbcBGPalette[index] = data;
					this.gbcBGPalette[0x20 | index] = 0x1000000 | data;
				}
			}
		}
		
		public	function updateGBCOBJPalette(index:uint, data:uint):void
		{
			if (this.gbcOBJRawPalette[index] != data) {
				this.gbcOBJRawPalette[index] = data;
				if ((index & 0x06) > 0) {
					this.midScanLineJIT();
					this.gbcOBJPalette[index >> 1] = 0x1000000 | this.RGBTint((this.gbcOBJRawPalette[index | 1] << 8) | this.gbcOBJRawPalette[index & 0x3E]);
				}
			}
		}
		
		public	function BGGBLayerRender(scanlineToRender:uint):void
		{
			var scrollYAdjusted:uint = (this.backgroundY + scanlineToRender) & 0xFF;
			var tileYLine:uint = (scrollYAdjusted & 7) << 3;
			var tileYDown:uint = this.gfxBackgroundCHRBankPosition | ((scrollYAdjusted & 0xF8) << 2);
			var scrollXAdjusted:uint = (this.backgroundX + this.currentX) & 0xFF;
			var pixelPosition:uint = this.pixelStart + this.currentX;
			var pixelPositionEnd:uint = this.pixelStart + ((this.gfxWindowDisplay && (scanlineToRender - this.windowY) >= 0) ? Math.min(Math.max(this.windowX, 0) + this.currentX, this.pixelEnd) : this.pixelEnd);
			var tileNumber:uint = tileYDown + (scrollXAdjusted >> 3);
			var chrCode:uint = this.BGCHRBank1[tileNumber];
			if (chrCode < this.gfxBackgroundBankOffset) {
				chrCode |= 0x100;
			}
			var tile:Vector.<uint> = this.tileCache[chrCode];
			for (var texel:int = (scrollXAdjusted & 0x7); texel < 8 && pixelPosition < pixelPositionEnd && scrollXAdjusted < 0x100; ++scrollXAdjusted) {
				this.frameBuffer[pixelPosition++] = this.BGPalette[tile[tileYLine | texel++]];
			}
			var scrollXAdjustedAligned:uint = Math.min(pixelPositionEnd - pixelPosition, 0x100 - scrollXAdjusted) >> 3;
			scrollXAdjusted += scrollXAdjustedAligned << 3;
			scrollXAdjustedAligned += tileNumber;
			while (tileNumber < scrollXAdjustedAligned) {
				chrCode = this.BGCHRBank1[++tileNumber];
				if (chrCode < this.gfxBackgroundBankOffset) {
					chrCode |= 0x100;
				}
				tile = this.tileCache[chrCode];
				texel = tileYLine;
				this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel++]];
				this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel++]];
				this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel++]];
				this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel++]];
				this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel++]];
				this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel++]];
				this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel++]];
				this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel]];
			}
			if (pixelPosition < pixelPositionEnd) {
				if (scrollXAdjusted < 0x100) {
					chrCode = this.BGCHRBank1[++tileNumber];
					if (chrCode < this.gfxBackgroundBankOffset) {
						chrCode |= 0x100;
					}
					tile = this.tileCache[chrCode];
					for (texel = tileYLine - 1; pixelPosition < pixelPositionEnd && scrollXAdjusted < 0x100; ++scrollXAdjusted) {
						this.frameBuffer[pixelPosition++] = this.BGPalette[tile[++texel]];
					}
				}
				scrollXAdjustedAligned = ((pixelPositionEnd - pixelPosition) >> 3) + tileYDown;
				while (tileYDown < scrollXAdjustedAligned) {
					chrCode = this.BGCHRBank1[tileYDown++];
					if (chrCode < this.gfxBackgroundBankOffset) {
						chrCode |= 0x100;
					}
					tile = this.tileCache[chrCode];
					texel = tileYLine;
					this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel++]];
					this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel++]];
					this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel++]];
					this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel++]];
					this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel++]];
					this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel++]];
					this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel++]];
					this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel]];
				}
				if (pixelPosition < pixelPositionEnd) {
					chrCode = this.BGCHRBank1[tileYDown];
					if (chrCode < this.gfxBackgroundBankOffset) {
						chrCode |= 0x100;
					}
					tile = this.tileCache[chrCode];
					switch (pixelPositionEnd - pixelPosition) {
						case 7:
							this.frameBuffer[pixelPosition + 6] = this.BGPalette[tile[tileYLine | 6]];
						case 6:
							this.frameBuffer[pixelPosition + 5] = this.BGPalette[tile[tileYLine | 5]];
						case 5:
							this.frameBuffer[pixelPosition + 4] = this.BGPalette[tile[tileYLine | 4]];
						case 4:
							this.frameBuffer[pixelPosition + 3] = this.BGPalette[tile[tileYLine | 3]];
						case 3:
							this.frameBuffer[pixelPosition + 2] = this.BGPalette[tile[tileYLine | 2]];
						case 2:
							this.frameBuffer[pixelPosition + 1] = this.BGPalette[tile[tileYLine | 1]];
						case 1:
							this.frameBuffer[pixelPosition] = this.BGPalette[tile[tileYLine]];
					}
				}
			}
		}
		
		public	function BGGBCLayerRender(scanlineToRender:uint):void
		{
			var scrollYAdjusted:uint = (this.backgroundY + scanlineToRender) & 0xFF;
			var tileYLine:uint = (scrollYAdjusted & 7) << 3;
			var tileYDown:uint = this.gfxBackgroundCHRBankPosition | ((scrollYAdjusted & 0xF8) << 2);
			var scrollXAdjusted:uint = (this.backgroundX + this.currentX) & 0xFF;
			var pixelPosition:int = this.pixelStart + this.currentX;
			var pixelPositionEnd:int = this.pixelStart + ((this.gfxWindowDisplay && (scanlineToRender - this.windowY) >= 0) ? Math.min(Math.max(this.windowX, 0) + this.currentX, this.pixelEnd) : this.pixelEnd);
			var tileNumber:uint = tileYDown + (scrollXAdjusted >> 3);
			var chrCode:uint = this.BGCHRBank1[tileNumber];
			if (chrCode < this.gfxBackgroundBankOffset) {
				chrCode |= 0x100;
			}
			var attrCode:uint = this.BGCHRBank2[tileNumber];
			var tile:Vector.<uint> = this.tileCache[((attrCode & 0x08) << 8) | ((attrCode & 0x60) << 4) | chrCode];
			var palette:uint = ((attrCode & 0x7) << 2) | ((attrCode & 0x80) >> 2);
			for (var texel:int = (scrollXAdjusted & 0x7); texel < 8 && pixelPosition < pixelPositionEnd && scrollXAdjusted < 0x100; ++scrollXAdjusted) {
				this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[tileYLine | texel++]];
			}
			var scrollXAdjustedAligned:uint = Math.min(pixelPositionEnd - pixelPosition, 0x100 - scrollXAdjusted) >> 3;
			scrollXAdjusted += scrollXAdjustedAligned << 3;
			scrollXAdjustedAligned += tileNumber;
			while (tileNumber < scrollXAdjustedAligned) {
				chrCode = this.BGCHRBank1[++tileNumber];
				if (chrCode < this.gfxBackgroundBankOffset) {
					chrCode |= 0x100;
				}
				attrCode = this.BGCHRBank2[tileNumber];
				tile = this.tileCache[((attrCode & 0x08) << 8) | ((attrCode & 0x60) << 4) | chrCode];
				palette = ((attrCode & 0x7) << 2) | ((attrCode & 0x80) >> 2);
				texel = tileYLine;
				this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
				this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
				this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
				this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
				this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
				this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
				this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
				this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel]];
			}
			if (pixelPosition < pixelPositionEnd) {
				if (scrollXAdjusted < 0x100) {
					chrCode = this.BGCHRBank1[++tileNumber];
					if (chrCode < this.gfxBackgroundBankOffset) {
						chrCode |= 0x100;
					}
					attrCode = this.BGCHRBank2[tileNumber];
					tile = this.tileCache[((attrCode & 0x08) << 8) | ((attrCode & 0x60) << 4) | chrCode];
					palette = ((attrCode & 0x7) << 2) | ((attrCode & 0x80) >> 2);
					for (texel = tileYLine - 1; pixelPosition < pixelPositionEnd && scrollXAdjusted < 0x100; ++scrollXAdjusted) {
						this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[++texel]];
					}
				}
				scrollXAdjustedAligned = ((pixelPositionEnd - pixelPosition) >> 3) + tileYDown;
				while (tileYDown < scrollXAdjustedAligned) {
					chrCode = this.BGCHRBank1[tileYDown];
					if (chrCode < this.gfxBackgroundBankOffset) {
						chrCode |= 0x100;
					}
					attrCode = this.BGCHRBank2[tileYDown++];
					tile = this.tileCache[((attrCode & 0x08) << 8) | ((attrCode & 0x60) << 4) | chrCode];
					palette = ((attrCode & 0x7) << 2) | ((attrCode & 0x80) >> 2);
					texel = tileYLine;
					this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
					this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
					this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
					this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
					this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
					this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
					this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
					this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel]];
				}
				if (pixelPosition < pixelPositionEnd) {
					chrCode = this.BGCHRBank1[tileYDown];
					if (chrCode < this.gfxBackgroundBankOffset) {
						chrCode |= 0x100;
					}
					attrCode = this.BGCHRBank2[tileYDown];
					tile = this.tileCache[((attrCode & 0x08) << 8) | ((attrCode & 0x60) << 4) | chrCode];
					palette = ((attrCode & 0x7) << 2) | ((attrCode & 0x80) >> 2);
					switch (pixelPositionEnd - pixelPosition) {
						case 7:
							this.frameBuffer[pixelPosition + 6] = this.gbcBGPalette[palette | tile[tileYLine | 6]];
						case 6:
							this.frameBuffer[pixelPosition + 5] = this.gbcBGPalette[palette | tile[tileYLine | 5]];
						case 5:
							this.frameBuffer[pixelPosition + 4] = this.gbcBGPalette[palette | tile[tileYLine | 4]];
						case 4:
							this.frameBuffer[pixelPosition + 3] = this.gbcBGPalette[palette | tile[tileYLine | 3]];
						case 3:
							this.frameBuffer[pixelPosition + 2] = this.gbcBGPalette[palette | tile[tileYLine | 2]];
						case 2:
							this.frameBuffer[pixelPosition + 1] = this.gbcBGPalette[palette | tile[tileYLine | 1]];
						case 1:
							this.frameBuffer[pixelPosition] = this.gbcBGPalette[palette | tile[tileYLine]];
					}
				}
			}
		}
		
		public	function BGGBCLayerRenderNoPriorityFlagging(scanlineToRender:uint):void
		{
			var scrollYAdjusted:uint = (this.backgroundY + scanlineToRender) & 0xFF;
			var tileYLine:uint = (scrollYAdjusted & 7) << 3;
			var tileYDown:uint = this.gfxBackgroundCHRBankPosition | ((scrollYAdjusted & 0xF8) << 2);
			var scrollXAdjusted:uint = (this.backgroundX + this.currentX) & 0xFF;
			var pixelPosition:uint = this.pixelStart + this.currentX;
			var pixelPositionEnd:uint = this.pixelStart + ((this.gfxWindowDisplay && (scanlineToRender - this.windowY) >= 0) ? Math.min(Math.max(this.windowX, 0) + this.currentX, this.pixelEnd) : this.pixelEnd);
			var tileNumber:uint = tileYDown + (scrollXAdjusted >> 3);
			var chrCode:uint = this.BGCHRBank1[tileNumber];
			if (chrCode < this.gfxBackgroundBankOffset) {
				chrCode |= 0x100;
			}
			var attrCode:uint = this.BGCHRBank2[tileNumber];
			var tile:Vector.<uint> = this.tileCache[((attrCode & 0x08) << 8) | ((attrCode & 0x60) << 4) | chrCode];
			var palette:uint = (attrCode & 0x7) << 2;
			for (var texel:int = (scrollXAdjusted & 0x7); texel < 8 && pixelPosition < pixelPositionEnd && scrollXAdjusted < 0x100; ++scrollXAdjusted) {
				this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[tileYLine | texel++]];
			}
			var scrollXAdjustedAligned:uint = Math.min(pixelPositionEnd - pixelPosition, 0x100 - scrollXAdjusted) >> 3;
			scrollXAdjusted += scrollXAdjustedAligned << 3;
			scrollXAdjustedAligned += tileNumber;
			while (tileNumber < scrollXAdjustedAligned) {
				chrCode = this.BGCHRBank1[++tileNumber];
				if (chrCode < this.gfxBackgroundBankOffset) {
					chrCode |= 0x100;
				}
				attrCode = this.BGCHRBank2[tileNumber];
				tile = this.tileCache[((attrCode & 0x08) << 8) | ((attrCode & 0x60) << 4) | chrCode];
				palette = (attrCode & 0x7) << 2;
				texel = tileYLine;
				this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
				this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
				this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
				this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
				this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
				this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
				this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
				this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel]];
			}
			if (pixelPosition < pixelPositionEnd) {
				if (scrollXAdjusted < 0x100) {
					chrCode = this.BGCHRBank1[++tileNumber];
					if (chrCode < this.gfxBackgroundBankOffset) {
						chrCode |= 0x100;
					}
					attrCode = this.BGCHRBank2[tileNumber];
					tile = this.tileCache[((attrCode & 0x08) << 8) | ((attrCode & 0x60) << 4) | chrCode];
					palette = (attrCode & 0x7) << 2;
					for (texel = tileYLine - 1; pixelPosition < pixelPositionEnd && scrollXAdjusted < 0x100; ++scrollXAdjusted) {
						this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[++texel]];
					}
				}
				scrollXAdjustedAligned = ((pixelPositionEnd - pixelPosition) >> 3) + tileYDown;
				while (tileYDown < scrollXAdjustedAligned) {
					chrCode = this.BGCHRBank1[tileYDown];
					if (chrCode < this.gfxBackgroundBankOffset) {
						chrCode |= 0x100;
					}
					attrCode = this.BGCHRBank2[tileYDown++];
					tile = this.tileCache[((attrCode & 0x08) << 8) | ((attrCode & 0x60) << 4) | chrCode];
					palette = (attrCode & 0x7) << 2;
					texel = tileYLine;
					this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
					this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
					this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
					this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
					this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
					this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
					this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
					this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel]];
				}
				if (pixelPosition < pixelPositionEnd) {
					chrCode = this.BGCHRBank1[tileYDown];
					if (chrCode < this.gfxBackgroundBankOffset) {
						chrCode |= 0x100;
					}
					attrCode = this.BGCHRBank2[tileYDown];
					tile = this.tileCache[((attrCode & 0x08) << 8) | ((attrCode & 0x60) << 4) | chrCode];
					palette = (attrCode & 0x7) << 2;
					switch (pixelPositionEnd - pixelPosition) {
						case 7:
							this.frameBuffer[pixelPosition + 6] = this.gbcBGPalette[palette | tile[tileYLine | 6]];
						case 6:
							this.frameBuffer[pixelPosition + 5] = this.gbcBGPalette[palette | tile[tileYLine | 5]];
						case 5:
							this.frameBuffer[pixelPosition + 4] = this.gbcBGPalette[palette | tile[tileYLine | 4]];
						case 4:
							this.frameBuffer[pixelPosition + 3] = this.gbcBGPalette[palette | tile[tileYLine | 3]];
						case 3:
							this.frameBuffer[pixelPosition + 2] = this.gbcBGPalette[palette | tile[tileYLine | 2]];
						case 2:
							this.frameBuffer[pixelPosition + 1] = this.gbcBGPalette[palette | tile[tileYLine | 1]];
						case 1:
							this.frameBuffer[pixelPosition] = this.gbcBGPalette[palette | tile[tileYLine]];
					}
				}
			}
		}
		
		public	function WindowGBLayerRender(scanlineToRender:uint):void
		{
			if (this.gfxWindowDisplay) {
				if (scanlineToRender >= this.windowY) {
					var scrollYAdjusted:uint = scanlineToRender - this.windowY;
					var scrollXRangeAdjusted:int = (this.windowX > 0) ? (this.windowX + this.currentX) : this.currentX;
					var pixelPosition:uint = this.pixelStart + scrollXRangeAdjusted;
					var pixelPositionEnd:uint = this.pixelStart + this.pixelEnd;
					if (pixelPosition < pixelPositionEnd) {
						var tileYLine:uint = (scrollYAdjusted & 0x7) << 3;
						var tileNumber:uint = (this.gfxWindowCHRBankPosition | ((scrollYAdjusted & 0xF8) << 2)) + (this.currentX >> 3);
						var chrCode:uint = this.BGCHRBank1[tileNumber];
						if (chrCode < this.gfxBackgroundBankOffset) {
							chrCode |= 0x100;
						}
						var tile:Vector.<uint> = this.tileCache[chrCode];
						var texel:int = (scrollXRangeAdjusted - this.windowX) & 0x7;
						scrollXRangeAdjusted = Math.min(8, texel + pixelPositionEnd - pixelPosition);
						while (texel < scrollXRangeAdjusted) {
							this.frameBuffer[pixelPosition++] = this.BGPalette[tile[tileYLine | texel++]];
						}
						scrollXRangeAdjusted = tileNumber + ((pixelPositionEnd - pixelPosition) >> 3);
						while (tileNumber < scrollXRangeAdjusted) {
							chrCode = this.BGCHRBank1[++tileNumber];
							if (chrCode < this.gfxBackgroundBankOffset) {
								chrCode |= 0x100;
							}
							tile = this.tileCache[chrCode];
							texel = tileYLine;
							this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel++]];
							this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel++]];
							this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel++]];
							this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel++]];
							this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel++]];
							this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel++]];
							this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel++]];
							this.frameBuffer[pixelPosition++] = this.BGPalette[tile[texel]];
						}
						if (pixelPosition < pixelPositionEnd) {
							chrCode = this.BGCHRBank1[++tileNumber];
							if (chrCode < this.gfxBackgroundBankOffset) {
								chrCode |= 0x100;
							}
							tile = this.tileCache[chrCode];
							switch (pixelPositionEnd - pixelPosition) {
								case 7:
									this.frameBuffer[pixelPosition + 6] = this.BGPalette[tile[tileYLine | 6]];
								case 6:
									this.frameBuffer[pixelPosition + 5] = this.BGPalette[tile[tileYLine | 5]];
								case 5:
									this.frameBuffer[pixelPosition + 4] = this.BGPalette[tile[tileYLine | 4]];
								case 4:
									this.frameBuffer[pixelPosition + 3] = this.BGPalette[tile[tileYLine | 3]];
								case 3:
									this.frameBuffer[pixelPosition + 2] = this.BGPalette[tile[tileYLine | 2]];
								case 2:
									this.frameBuffer[pixelPosition + 1] = this.BGPalette[tile[tileYLine | 1]];
								case 1:
									this.frameBuffer[pixelPosition] = this.BGPalette[tile[tileYLine]];
							}
						}
					}
				}
			}
		}
		
		public	function WindowGBCLayerRender(scanlineToRender:uint):void
		{
			if (this.gfxWindowDisplay) {
				if (scanlineToRender >= this.windowY) {
					var scrollYAdjusted:uint = scanlineToRender - this.windowY;
					var scrollXRangeAdjusted:uint = (this.windowX > 0) ? (this.windowX + this.currentX) : this.currentX;
					var pixelPosition:uint = this.pixelStart + scrollXRangeAdjusted;
					var pixelPositionEnd:uint = this.pixelStart + this.pixelEnd;
					if (pixelPosition < pixelPositionEnd) {
						var tileYLine:uint = (scrollYAdjusted & 0x7) << 3;
						var tileNumber:uint = (this.gfxWindowCHRBankPosition | ((scrollYAdjusted & 0xF8) << 2)) + (this.currentX >> 3);
						var chrCode:uint = this.BGCHRBank1[tileNumber];
						if (chrCode < this.gfxBackgroundBankOffset) {
							chrCode |= 0x100;
						}
						var attrCode:uint = this.BGCHRBank2[tileNumber];
						var tile:Vector.<uint> = this.tileCache[((attrCode & 0x08) << 8) | ((attrCode & 0x60) << 4) | chrCode];
						var palette:uint = ((attrCode & 0x7) << 2) | ((attrCode & 0x80) >> 2);
						var texel:int = (scrollXRangeAdjusted - this.windowX) & 0x7;
						scrollXRangeAdjusted = Math.min(8, texel + pixelPositionEnd - pixelPosition);
						while (texel < scrollXRangeAdjusted) {
							this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[tileYLine | texel++]];
						}
						scrollXRangeAdjusted = tileNumber + ((pixelPositionEnd - pixelPosition) >> 3);
						while (tileNumber < scrollXRangeAdjusted) {
							chrCode = this.BGCHRBank1[++tileNumber];
							if (chrCode < this.gfxBackgroundBankOffset) {
								chrCode |= 0x100;
							}
							attrCode = this.BGCHRBank2[tileNumber];
							tile = this.tileCache[((attrCode & 0x08) << 8) | ((attrCode & 0x60) << 4) | chrCode];
							palette = ((attrCode & 0x7) << 2) | ((attrCode & 0x80) >> 2);
							texel = tileYLine;
							this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
							this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
							this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
							this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
							this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
							this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
							this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
							this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel]];
						}
						if (pixelPosition < pixelPositionEnd) {
							chrCode = this.BGCHRBank1[++tileNumber];
							if (chrCode < this.gfxBackgroundBankOffset) {
								chrCode |= 0x100;
							}
							attrCode = this.BGCHRBank2[tileNumber];
							tile = this.tileCache[((attrCode & 0x08) << 8) | ((attrCode & 0x60) << 4) | chrCode];
							palette = ((attrCode & 0x7) << 2) | ((attrCode & 0x80) >> 2);
							switch (pixelPositionEnd - pixelPosition) {
								case 7:
									this.frameBuffer[pixelPosition + 6] = this.gbcBGPalette[palette | tile[tileYLine | 6]];
								case 6:
									this.frameBuffer[pixelPosition + 5] = this.gbcBGPalette[palette | tile[tileYLine | 5]];
								case 5:
									this.frameBuffer[pixelPosition + 4] = this.gbcBGPalette[palette | tile[tileYLine | 4]];
								case 4:
									this.frameBuffer[pixelPosition + 3] = this.gbcBGPalette[palette | tile[tileYLine | 3]];
								case 3:
									this.frameBuffer[pixelPosition + 2] = this.gbcBGPalette[palette | tile[tileYLine | 2]];
								case 2:
									this.frameBuffer[pixelPosition + 1] = this.gbcBGPalette[palette | tile[tileYLine | 1]];
								case 1:
									this.frameBuffer[pixelPosition] = this.gbcBGPalette[palette | tile[tileYLine]];
							}
						}
					}
				}
			}
		}
		
		public	function WindowGBCLayerRenderNoPriorityFlagging(scanlineToRender:uint):void
		{
			if (this.gfxWindowDisplay) {
				if (scanlineToRender >= this.windowY) {
					var scrollYAdjusted:uint = scanlineToRender - this.windowY;
					var scrollXRangeAdjusted:uint = (this.windowX > 0) ? (this.windowX + this.currentX) : this.currentX;
					var pixelPosition:uint = this.pixelStart + scrollXRangeAdjusted;
					var pixelPositionEnd:uint = this.pixelStart + this.pixelEnd;
					if (pixelPosition < pixelPositionEnd) {
						var tileYLine:uint = (scrollYAdjusted & 0x7) << 3;
						var tileNumber:uint = (this.gfxWindowCHRBankPosition | ((scrollYAdjusted & 0xF8) << 2)) + (this.currentX >> 3);
						var chrCode:uint = this.BGCHRBank1[tileNumber];
						if (chrCode < this.gfxBackgroundBankOffset) {
							chrCode |= 0x100;
						}
						var attrCode:uint = this.BGCHRBank2[tileNumber];
						var tile:Vector.<uint> = this.tileCache[((attrCode & 0x08) << 8) | ((attrCode & 0x60) << 4) | chrCode];
						var palette:uint = (attrCode & 0x7) << 2;
						var texel:int = (scrollXRangeAdjusted - this.windowX) & 0x7;
						scrollXRangeAdjusted = Math.min(8, texel + pixelPositionEnd - pixelPosition);
						while (texel < scrollXRangeAdjusted) {
							this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[tileYLine | texel++]];
						}
						scrollXRangeAdjusted = tileNumber + ((pixelPositionEnd - pixelPosition) >> 3);
						while (tileNumber < scrollXRangeAdjusted) {
							chrCode = this.BGCHRBank1[++tileNumber];
							if (chrCode < this.gfxBackgroundBankOffset) {
								chrCode |= 0x100;
							}
							attrCode = this.BGCHRBank2[tileNumber];
							tile = this.tileCache[((attrCode & 0x08) << 8) | ((attrCode & 0x60) << 4) | chrCode];
							palette = (attrCode & 0x7) << 2;
							texel = tileYLine;
							this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
							this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
							this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
							this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
							this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
							this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
							this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel++]];
							this.frameBuffer[pixelPosition++] = this.gbcBGPalette[palette | tile[texel]];
						}
						if (pixelPosition < pixelPositionEnd) {
							chrCode = this.BGCHRBank1[++tileNumber];
							if (chrCode < this.gfxBackgroundBankOffset) {
								chrCode |= 0x100;
							}
							attrCode = this.BGCHRBank2[tileNumber];
							tile = this.tileCache[((attrCode & 0x08) << 8) | ((attrCode & 0x60) << 4) | chrCode];
							palette = (attrCode & 0x7) << 2;
							switch (pixelPositionEnd - pixelPosition) {
								case 7:
									this.frameBuffer[pixelPosition + 6] = this.gbcBGPalette[palette | tile[tileYLine | 6]];
								case 6:
									this.frameBuffer[pixelPosition + 5] = this.gbcBGPalette[palette | tile[tileYLine | 5]];
								case 5:
									this.frameBuffer[pixelPosition + 4] = this.gbcBGPalette[palette | tile[tileYLine | 4]];
								case 4:
									this.frameBuffer[pixelPosition + 3] = this.gbcBGPalette[palette | tile[tileYLine | 3]];
								case 3:
									this.frameBuffer[pixelPosition + 2] = this.gbcBGPalette[palette | tile[tileYLine | 2]];
								case 2:
									this.frameBuffer[pixelPosition + 1] = this.gbcBGPalette[palette | tile[tileYLine | 1]];
								case 1:
									this.frameBuffer[pixelPosition] = this.gbcBGPalette[palette | tile[tileYLine]];
							}
						}
					}
				}
			}
		}
		
		public	function SpriteGBLayerRender(scanlineToRender:uint):void
		{
			if (this.gfxSpriteShow) {
				var lineAdjusted:uint = scanlineToRender + 0x10;
				var OAMAddress:uint = 0xFE00;
				var yoffset:uint = 0;
				var xcoord:int = 1;
				var xCoordStart:int = 0;
				var xCoordEnd:int = 0;
				var attrCode:uint = 0;
				var palette:uint = 0;
				var tile:Vector.<uint> = null;
				var data:uint = 0;
				var spriteCount:uint = 0;
				var length:uint = 0;
				var currentPixel:uint = 0;
				var linePixel:int = 0;
				while (xcoord < 168) {
					this.sortBuffer[xcoord++] = 0xFF;
				}
				if (this.gfxSpriteNormalHeight) {
					for (length = this.findLowestSpriteDrawable(lineAdjusted, 0x7); spriteCount < length; ++spriteCount) {
						OAMAddress = this.OAMAddressCache[spriteCount];
						yoffset = (lineAdjusted - this.memory[OAMAddress]) << 3;
						attrCode = this.memory[OAMAddress | 3];
						palette = (attrCode & 0x10) >> 2;
						tile = this.tileCache[((attrCode & 0x60) << 4) | this.memory[OAMAddress | 0x2]];
						linePixel = xCoordStart = this.memory[OAMAddress | 1];
						xCoordEnd = Math.min(168 - linePixel, 8);
						xcoord = (linePixel > 7) ? 0 : (8 - linePixel);
						for (currentPixel = this.pixelStart + ((linePixel > 8) ? (linePixel - 8) : 0); xcoord < xCoordEnd; ++xcoord, ++currentPixel, ++linePixel) {	
							if (this.sortBuffer[linePixel] > xCoordStart) {
								if (this.frameBuffer[currentPixel] >= 0x2000000) {
									data = tile[yoffset | xcoord];
									if (data > 0) {
										this.frameBuffer[currentPixel] = this.OBJPalette[palette | data];
										this.sortBuffer[linePixel] = xCoordStart;
									}
								}
								else if (this.frameBuffer[currentPixel] < 0x1000000) {
									data = tile[yoffset | xcoord];
									if (data > 0 && attrCode < 0x80) {
										this.frameBuffer[currentPixel] = this.OBJPalette[palette | data];
										this.sortBuffer[linePixel] = xCoordStart;
									}
								}
							}
						}
					}
				}
				else {
					for (length = this.findLowestSpriteDrawable(lineAdjusted, 0xF); spriteCount < length; ++spriteCount) {
						OAMAddress = this.OAMAddressCache[spriteCount];
						yoffset = (lineAdjusted - this.memory[OAMAddress]) << 3;
						attrCode = this.memory[OAMAddress | 3];
						palette = (attrCode & 0x10) >> 2;
						if ((attrCode & 0x40) == (0x40 & yoffset)) {
							tile = this.tileCache[((attrCode & 0x60) << 4) | (this.memory[OAMAddress | 0x2] & 0xFE)];
						}
						else {
							tile = this.tileCache[((attrCode & 0x60) << 4) | this.memory[OAMAddress | 0x2] | 1];
						}
						yoffset &= 0x3F;
						linePixel = xCoordStart = this.memory[OAMAddress | 1];
						xCoordEnd = Math.min(168 - linePixel, 8);
						xcoord = (linePixel > 7) ? 0 : (8 - linePixel);
						for (currentPixel = this.pixelStart + ((linePixel > 8) ? (linePixel - 8) : 0); xcoord < xCoordEnd; ++xcoord, ++currentPixel, ++linePixel) {	
							if (this.sortBuffer[linePixel] > xCoordStart) {
								if (this.frameBuffer[currentPixel] >= 0x2000000) {
									data = tile[yoffset | xcoord];
									if (data > 0) {
										this.frameBuffer[currentPixel] = this.OBJPalette[palette | data];
										this.sortBuffer[linePixel] = xCoordStart;
									}
								}
								else if (this.frameBuffer[currentPixel] < 0x1000000) {
									data = tile[yoffset | xcoord];
									if (data > 0 && attrCode < 0x80) {
										this.frameBuffer[currentPixel] = this.OBJPalette[palette | data];
										this.sortBuffer[linePixel] = xCoordStart;
									}
								}
							}
						}
					}
				}
			}
		}
		
		public	function findLowestSpriteDrawable(scanlineToRender:uint, drawableRange:uint):uint
		{
			var address:uint = 0xFE00;
			var spriteCount:uint = 0;
			var diff:uint = 0;
			while (address < 0xFEA0 && spriteCount < 10) {
				diff = scanlineToRender - this.memory[address];
				if ((diff & drawableRange) == diff) {
					this.OAMAddressCache[spriteCount++] = address;
				}
				address += 4;
			}
			return spriteCount;
		}
		
		public	function SpriteGBCLayerRender(scanlineToRender:uint):void
		{
			if (this.gfxSpriteShow) {
				var OAMAddress:uint = 0xFE00;
				var lineAdjusted:uint = scanlineToRender + 0x10;
				var yoffset:uint = 0;
				var xcoord:int = 0;
				var endX:uint = 0;
				var xCounter:uint = 0;
				var attrCode:uint = 0;
				var palette:uint = 0;
				var tile:Vector.<uint> = null;
				var data:uint = 0;
				var currentPixel:uint = 0;
				var spriteCount:uint = 0;
				if (this.gfxSpriteNormalHeight) {
					for (; OAMAddress < 0xFEA0 && spriteCount < 10; OAMAddress += 4) {
						yoffset = lineAdjusted - this.memory[OAMAddress];
						if ((yoffset & 0x7) == yoffset) {
							xcoord = this.memory[OAMAddress | 1] - 8;
							endX = Math.min(gb.WIDTH, xcoord + 8);
							attrCode = this.memory[OAMAddress | 3];
							palette = (attrCode & 7) << 2;
							tile = this.tileCache[((attrCode & 0x08) << 8) | ((attrCode & 0x60) << 4) | this.memory[OAMAddress | 2]];
							xCounter = (xcoord > 0) ? xcoord : 0;
							xcoord -= yoffset << 3;
							for (currentPixel = this.pixelStart + xCounter; xCounter < endX; ++xCounter, ++currentPixel) {
								if (this.frameBuffer[currentPixel] >= 0x2000000) {
									data = tile[xCounter - xcoord];
									if (data > 0) {
										this.frameBuffer[currentPixel] = this.gbcOBJPalette[palette | data];
									}
								}
								else if (this.frameBuffer[currentPixel] < 0x1000000) {
									data = tile[xCounter - xcoord];
									if (data > 0 && attrCode < 0x80) {
										this.frameBuffer[currentPixel] = this.gbcOBJPalette[palette | data];
									}
								}
							}
							++spriteCount;
						}
					}
				}
				else {
					for (; OAMAddress < 0xFEA0 && spriteCount < 10; OAMAddress += 4) {
						yoffset = lineAdjusted - this.memory[OAMAddress];
						if ((yoffset & 0xF) == yoffset) {
							xcoord = this.memory[OAMAddress | 1] - 8;
							endX = Math.min(gb.WIDTH, xcoord + 8);
							attrCode = this.memory[OAMAddress | 3];
							palette = (attrCode & 7) << 2;
							if ((attrCode & 0x40) == (0x40 & (yoffset << 3))) {
								tile = this.tileCache[((attrCode & 0x08) << 8) | ((attrCode & 0x60) << 4) | (this.memory[OAMAddress | 0x2] & 0xFE)];
							}
							else {
								tile = this.tileCache[((attrCode & 0x08) << 8) | ((attrCode & 0x60) << 4) | this.memory[OAMAddress | 0x2] | 1];
							}
							xCounter = (xcoord > 0) ? xcoord : 0;
							xcoord -= (yoffset & 0x7) << 3;
							for (currentPixel = this.pixelStart + xCounter; xCounter < endX; ++xCounter, ++currentPixel) {
								if (this.frameBuffer[currentPixel] >= 0x2000000) {
									data = tile[xCounter - xcoord];
									if (data > 0) {
										this.frameBuffer[currentPixel] = this.gbcOBJPalette[palette | data];
									}
								}
								else if (this.frameBuffer[currentPixel] < 0x1000000) {
									data = tile[xCounter - xcoord];
									if (data > 0 && attrCode < 0x80) {
										this.frameBuffer[currentPixel] = this.gbcOBJPalette[palette | data];
									}
								}
							}
							++spriteCount;
						}
					}
				}
			}
		}
		
		public	function generateGBTileLine(address:uint):void
		{
			var lineCopy:uint = (this.memory[0x1 | address] << 8) | this.memory[0x9FFE & address];
			var tileBlock:Vector.<uint> = this.tileCache[(address & 0x1FF0) >> 4];
			address = (address & 0xE) << 2;
			tileBlock[address | 7] = ((lineCopy & 0x100) >> 7) | (lineCopy & 0x1);
			tileBlock[address | 6] = ((lineCopy & 0x200) >> 8) | ((lineCopy & 0x2) >> 1);
			tileBlock[address | 5] = ((lineCopy & 0x400) >> 9) | ((lineCopy & 0x4) >> 2);
			tileBlock[address | 4] = ((lineCopy & 0x800) >> 10) | ((lineCopy & 0x8) >> 3);
			tileBlock[address | 3] = ((lineCopy & 0x1000) >> 11) | ((lineCopy & 0x10) >> 4);
			tileBlock[address | 2] = ((lineCopy & 0x2000) >> 12) | ((lineCopy & 0x20) >> 5);
			tileBlock[address | 1] = ((lineCopy & 0x4000) >> 13) | ((lineCopy & 0x40) >> 6);
			tileBlock[address] = ((lineCopy & 0x8000) >> 14) | ((lineCopy & 0x80) >> 7);
		}
		
		public	function generateGBCTileLineBank1(address:uint):void
		{
			var lineCopy:uint = (this.memory[0x1 | address] << 8) | this.memory[0x9FFE & address];
			address &= 0x1FFE;
			var tileBlock1:Vector.<uint> = this.tileCache[address >> 4];
			var tileBlock2:Vector.<uint> = this.tileCache[0x200 | (address >> 4)];
			var tileBlock3:Vector.<uint> = this.tileCache[0x400 | (address >> 4)];
			var tileBlock4:Vector.<uint> = this.tileCache[0x600 | (address >> 4)];
			address = (address & 0xE) << 2;
			var addressFlipped:uint = 0x38 - address;
			tileBlock4[addressFlipped] = tileBlock2[address] = tileBlock3[addressFlipped | 7] = tileBlock1[address | 7] = ((lineCopy & 0x100) >> 7) | (lineCopy & 0x1);
			tileBlock4[addressFlipped | 1] = tileBlock2[address | 1] = tileBlock3[addressFlipped | 6] = tileBlock1[address | 6] = ((lineCopy & 0x200) >> 8) | ((lineCopy & 0x2) >> 1);
			tileBlock4[addressFlipped | 2] = tileBlock2[address | 2] = tileBlock3[addressFlipped | 5] = tileBlock1[address | 5] = ((lineCopy & 0x400) >> 9) | ((lineCopy & 0x4) >> 2);
			tileBlock4[addressFlipped | 3] = tileBlock2[address | 3] = tileBlock3[addressFlipped | 4] = tileBlock1[address | 4] = ((lineCopy & 0x800) >> 10) | ((lineCopy & 0x8) >> 3);
			tileBlock4[addressFlipped | 4] = tileBlock2[address | 4] = tileBlock3[addressFlipped | 3] = tileBlock1[address | 3] = ((lineCopy & 0x1000) >> 11) | ((lineCopy & 0x10) >> 4);
			tileBlock4[addressFlipped | 5] = tileBlock2[address | 5] = tileBlock3[addressFlipped | 2] = tileBlock1[address | 2] = ((lineCopy & 0x2000) >> 12) | ((lineCopy & 0x20) >> 5);
			tileBlock4[addressFlipped | 6] = tileBlock2[address | 6] = tileBlock3[addressFlipped | 1] = tileBlock1[address | 1] = ((lineCopy & 0x4000) >> 13) | ((lineCopy & 0x40) >> 6);
			tileBlock4[addressFlipped | 7] = tileBlock2[address | 7] = tileBlock3[addressFlipped] = tileBlock1[address] = ((lineCopy & 0x8000) >> 14) | ((lineCopy & 0x80) >> 7);
		}
		
		public	function generateGBCTileBank1(vramAddress:uint):void
		{
			var address:uint = vramAddress >> 4;
			var tileBlock1:Vector.<uint> = this.tileCache[address];
			var tileBlock2:Vector.<uint> = this.tileCache[0x200 | address];
			var tileBlock3:Vector.<uint> = this.tileCache[0x400 | address];
			var tileBlock4:Vector.<uint> = this.tileCache[0x600 | address];
			var lineCopy:uint = 0;
			vramAddress |= 0x8000;
			address = 0;
			var addressFlipped:int = 56;
			do {
				lineCopy = (this.memory[0x1 | vramAddress] << 8) | this.memory[vramAddress];
				tileBlock4[addressFlipped] = tileBlock2[address] = tileBlock3[addressFlipped | 7] = tileBlock1[address | 7] = ((lineCopy & 0x100) >> 7) | (lineCopy & 0x1);
				tileBlock4[addressFlipped | 1] = tileBlock2[address | 1] = tileBlock3[addressFlipped | 6] = tileBlock1[address | 6] = ((lineCopy & 0x200) >> 8) | ((lineCopy & 0x2) >> 1);
				tileBlock4[addressFlipped | 2] = tileBlock2[address | 2] = tileBlock3[addressFlipped | 5] = tileBlock1[address | 5] = ((lineCopy & 0x400) >> 9) | ((lineCopy & 0x4) >> 2);
				tileBlock4[addressFlipped | 3] = tileBlock2[address | 3] = tileBlock3[addressFlipped | 4] = tileBlock1[address | 4] = ((lineCopy & 0x800) >> 10) | ((lineCopy & 0x8) >> 3);
				tileBlock4[addressFlipped | 4] = tileBlock2[address | 4] = tileBlock3[addressFlipped | 3] = tileBlock1[address | 3] = ((lineCopy & 0x1000) >> 11) | ((lineCopy & 0x10) >> 4);
				tileBlock4[addressFlipped | 5] = tileBlock2[address | 5] = tileBlock3[addressFlipped | 2] = tileBlock1[address | 2] = ((lineCopy & 0x2000) >> 12) | ((lineCopy & 0x20) >> 5);
				tileBlock4[addressFlipped | 6] = tileBlock2[address | 6] = tileBlock3[addressFlipped | 1] = tileBlock1[address | 1] = ((lineCopy & 0x4000) >> 13) | ((lineCopy & 0x40) >> 6);
				tileBlock4[addressFlipped | 7] = tileBlock2[address | 7] = tileBlock3[addressFlipped] = tileBlock1[address] = ((lineCopy & 0x8000) >> 14) | ((lineCopy & 0x80) >> 7);
				address += 8;
				addressFlipped -= 8;
				vramAddress += 2;
			} while (addressFlipped > -1);
		}
		
		public	function generateGBCTileLineBank2(address:uint):void
		{
			var lineCopy:uint = (this.VRAM[0x1 | address] << 8) | this.VRAM[0x1FFE & address];
			var tileBlock1:Vector.<uint> = this.tileCache[0x800 | (address >> 4)];
			var tileBlock2:Vector.<uint> = this.tileCache[0xA00 | (address >> 4)];
			var tileBlock3:Vector.<uint> = this.tileCache[0xC00 | (address >> 4)];
			var tileBlock4:Vector.<uint> = this.tileCache[0xE00 | (address >> 4)];
			address = (address & 0xE) << 2;
			var addressFlipped:uint = 0x38 - address;
			tileBlock4[addressFlipped] = tileBlock2[address] = tileBlock3[addressFlipped | 7] = tileBlock1[address | 7] = ((lineCopy & 0x100) >> 7) | (lineCopy & 0x1);
			tileBlock4[addressFlipped | 1] = tileBlock2[address | 1] = tileBlock3[addressFlipped | 6] = tileBlock1[address | 6] = ((lineCopy & 0x200) >> 8) | ((lineCopy & 0x2) >> 1);
			tileBlock4[addressFlipped | 2] = tileBlock2[address | 2] = tileBlock3[addressFlipped | 5] = tileBlock1[address | 5] = ((lineCopy & 0x400) >> 9) | ((lineCopy & 0x4) >> 2);
			tileBlock4[addressFlipped | 3] = tileBlock2[address | 3] = tileBlock3[addressFlipped | 4] = tileBlock1[address | 4] = ((lineCopy & 0x800) >> 10) | ((lineCopy & 0x8) >> 3);
			tileBlock4[addressFlipped | 4] = tileBlock2[address | 4] = tileBlock3[addressFlipped | 3] = tileBlock1[address | 3] = ((lineCopy & 0x1000) >> 11) | ((lineCopy & 0x10) >> 4);
			tileBlock4[addressFlipped | 5] = tileBlock2[address | 5] = tileBlock3[addressFlipped | 2] = tileBlock1[address | 2] = ((lineCopy & 0x2000) >> 12) | ((lineCopy & 0x20) >> 5);
			tileBlock4[addressFlipped | 6] = tileBlock2[address | 6] = tileBlock3[addressFlipped | 1] = tileBlock1[address | 1] = ((lineCopy & 0x4000) >> 13) | ((lineCopy & 0x40) >> 6);
			tileBlock4[addressFlipped | 7] = tileBlock2[address | 7] = tileBlock3[addressFlipped] = tileBlock1[address] = ((lineCopy & 0x8000) >> 14) | ((lineCopy & 0x80) >> 7);
		}
		
		public	function generateGBCTileBank2(vramAddress:uint):void
		{
			var address:uint = vramAddress >> 4;	
			var tileBlock1:Vector.<uint> = this.tileCache[0x800 | address];
			var tileBlock2:Vector.<uint> = this.tileCache[0xA00 | address];
			var tileBlock3:Vector.<uint> = this.tileCache[0xC00 | address];
			var tileBlock4:Vector.<uint> = this.tileCache[0xE00 | address];
			var lineCopy:uint = 0;
			address = 0;
			var addressFlipped:int = 56;
			do {
				lineCopy = (this.VRAM[0x1 | vramAddress] << 8) | this.VRAM[vramAddress];
				tileBlock4[addressFlipped] = tileBlock2[address] = tileBlock3[addressFlipped | 7] = tileBlock1[address | 7] = ((lineCopy & 0x100) >> 7) | (lineCopy & 0x1);
				tileBlock4[addressFlipped | 1] = tileBlock2[address | 1] = tileBlock3[addressFlipped | 6] = tileBlock1[address | 6] = ((lineCopy & 0x200) >> 8) | ((lineCopy & 0x2) >> 1);
				tileBlock4[addressFlipped | 2] = tileBlock2[address | 2] = tileBlock3[addressFlipped | 5] = tileBlock1[address | 5] = ((lineCopy & 0x400) >> 9) | ((lineCopy & 0x4) >> 2);
				tileBlock4[addressFlipped | 3] = tileBlock2[address | 3] = tileBlock3[addressFlipped | 4] = tileBlock1[address | 4] = ((lineCopy & 0x800) >> 10) | ((lineCopy & 0x8) >> 3);
				tileBlock4[addressFlipped | 4] = tileBlock2[address | 4] = tileBlock3[addressFlipped | 3] = tileBlock1[address | 3] = ((lineCopy & 0x1000) >> 11) | ((lineCopy & 0x10) >> 4);
				tileBlock4[addressFlipped | 5] = tileBlock2[address | 5] = tileBlock3[addressFlipped | 2] = tileBlock1[address | 2] = ((lineCopy & 0x2000) >> 12) | ((lineCopy & 0x20) >> 5);
				tileBlock4[addressFlipped | 6] = tileBlock2[address | 6] = tileBlock3[addressFlipped | 1] = tileBlock1[address | 1] = ((lineCopy & 0x4000) >> 13) | ((lineCopy & 0x40) >> 6);
				tileBlock4[addressFlipped | 7] = tileBlock2[address | 7] = tileBlock3[addressFlipped] = tileBlock1[address] = ((lineCopy & 0x8000) >> 14) | ((lineCopy & 0x80) >> 7);
				address += 8;
				addressFlipped -= 8;
				vramAddress += 2;
			} while (addressFlipped > -1);
		}
		
		public	function generateGBOAMTileLine(address:uint):void
		{
			var lineCopy:uint = (this.memory[0x1 | address] << 8) | this.memory[0x9FFE & address];
			address &= 0x1FFE;
			var tileBlock1:Vector.<uint> = this.tileCache[address >> 4];
			var tileBlock2:Vector.<uint> = this.tileCache[0x200 | (address >> 4)];
			var tileBlock3:Vector.<uint> = this.tileCache[0x400 | (address >> 4)];
			var tileBlock4:Vector.<uint> = this.tileCache[0x600 | (address >> 4)];
			address = (address & 0xE) << 2;
			var addressFlipped:uint = 0x38 - address;
			tileBlock4[addressFlipped] = tileBlock2[address] = tileBlock3[addressFlipped | 7] = tileBlock1[address | 7] = ((lineCopy & 0x100) >> 7) | (lineCopy & 0x1);
			tileBlock4[addressFlipped | 1] = tileBlock2[address | 1] = tileBlock3[addressFlipped | 6] = tileBlock1[address | 6] = ((lineCopy & 0x200) >> 8) | ((lineCopy & 0x2) >> 1);
			tileBlock4[addressFlipped | 2] = tileBlock2[address | 2] = tileBlock3[addressFlipped | 5] = tileBlock1[address | 5] = ((lineCopy & 0x400) >> 9) | ((lineCopy & 0x4) >> 2);
			tileBlock4[addressFlipped | 3] = tileBlock2[address | 3] = tileBlock3[addressFlipped | 4] = tileBlock1[address | 4] = ((lineCopy & 0x800) >> 10) | ((lineCopy & 0x8) >> 3);
			tileBlock4[addressFlipped | 4] = tileBlock2[address | 4] = tileBlock3[addressFlipped | 3] = tileBlock1[address | 3] = ((lineCopy & 0x1000) >> 11) | ((lineCopy & 0x10) >> 4);
			tileBlock4[addressFlipped | 5] = tileBlock2[address | 5] = tileBlock3[addressFlipped | 2] = tileBlock1[address | 2] = ((lineCopy & 0x2000) >> 12) | ((lineCopy & 0x20) >> 5);
			tileBlock4[addressFlipped | 6] = tileBlock2[address | 6] = tileBlock3[addressFlipped | 1] = tileBlock1[address | 1] = ((lineCopy & 0x4000) >> 13) | ((lineCopy & 0x40) >> 6);
			tileBlock4[addressFlipped | 7] = tileBlock2[address | 7] = tileBlock3[addressFlipped] = tileBlock1[address] = ((lineCopy & 0x8000) >> 14) | ((lineCopy & 0x80) >> 7);
		}
		
		public	function graphicsJIT():void
		{
			if (this.LCDisOn) {
				this.totalLinesPassed = 0;
				this.graphicsJITScanlineGroup();
			}
		}
		
		public	function graphicsJITVBlank():void
		{
			this.totalLinesPassed += this.queuedScanLines;
			this.graphicsJITScanlineGroup();
		}
		
		public	function graphicsJITScanlineGroup():void
		{
			while (this.queuedScanLines > 0) {
				this.renderScanLine(this.lastUnrenderedLine);
				if (this.lastUnrenderedLine < 143) {
					++this.lastUnrenderedLine;
				}
				else {
					this.lastUnrenderedLine = 0;
				}
				--this.queuedScanLines;
			}
		}
		
		public	function incrementScanLineQueue():void
		{
			if (this.queuedScanLines < gb.HEIGHT) {
				++this.queuedScanLines;
			}
			else {
				this.currentX = 0;
				this.midScanlineOffset = -1;
				if (this.lastUnrenderedLine < 143) {
					++this.lastUnrenderedLine;
				}
				else {
					this.lastUnrenderedLine = 0;
				}
			}
		}
		
		public	function midScanLineJIT():void
		{
			this.graphicsJIT();
			this.renderMidScanLine();
		}
		
		public	function launchIRQ():void
		{
			var bitShift:uint = 0;
			var testbit:uint = 1;
			do {
				if ((testbit & this.IRQLineMatched) == testbit) {
					this.IME = false;
					this.interruptsRequested -= testbit;
					this.IRQLineMatched = 0;
					this.CPUTicks = 20;
					this.stackPointer = (this.stackPointer - 1) & 0xFFFF;
					this.memoryWriter[this.stackPointer](this.stackPointer, this.programCounter >> 8);
					this.stackPointer = (this.stackPointer - 1) & 0xFFFF;
					this.memoryWriter[this.stackPointer](this.stackPointer, this.programCounter & 0xFF);
					this.programCounter = 0x40 | (bitShift << 3);
					this.updateCore();
					return;
				}
				testbit = 1 << ++bitShift;
			} while (bitShift < 5);
		}
		
		public	function checkIRQMatching():void
		{
			if (this.IME) {
				this.IRQLineMatched = this.interruptsEnabled & this.interruptsRequested & 0x1F;
			}
		}
		
		public	function calculateHALTPeriod():void
		{
			var currentClocks:int;
			if (!this.halt) {
				this.halt = true;
				currentClocks = -1;
				var temp_var:int = 0;
				if (this.LCDisOn) {
					if ((this.interruptsEnabled & 0x1) == 0x1) {
						currentClocks = ((456 * (((this.modeSTAT == 1) ? 298 : gb.HEIGHT) - this.actualScanLine)) - this.LCDTicks) << this.doubleSpeedShifter;
					}
					if ((this.interruptsEnabled & 0x2) == 0x2) {
						if (this.mode0TriggerSTAT) {
							temp_var = (this.clocksUntilMode0() - this.LCDTicks) << this.doubleSpeedShifter;
							if (temp_var <= currentClocks || currentClocks == -1) {
								currentClocks = temp_var;
							}
						}
						if (this.mode1TriggerSTAT && (this.interruptsEnabled & 0x1) == 0) {
							temp_var = ((456 * (((this.modeSTAT == 1) ? 298 : gb.HEIGHT) - this.actualScanLine)) - this.LCDTicks) << this.doubleSpeedShifter;
							if (temp_var <= currentClocks || currentClocks == -1) {
								currentClocks = temp_var;
							}
						}
						if (this.mode2TriggerSTAT) {
							temp_var = (((this.actualScanLine >= 143) ? (456 * (154 - this.actualScanLine)) : 456) - this.LCDTicks) << this.doubleSpeedShifter;
							if (temp_var <= currentClocks || currentClocks == -1) {
								currentClocks = temp_var;
							}
						}
						if (this.LYCMatchTriggerSTAT && this.memory[0xFF45] <= 153) {
							temp_var = (this.clocksUntilLYCMatch() - this.LCDTicks) << this.doubleSpeedShifter;
							if (temp_var <= currentClocks || currentClocks == -1) {
								currentClocks = temp_var;
							}
						}
					}
				}
				if (this.TIMAEnabled && (this.interruptsEnabled & 0x4) == 0x4) {
					temp_var = ((0x100 - this.memory[0xFF05]) * this.TACClocker) - this.timerTicks;
					if (temp_var <= currentClocks || currentClocks == -1) {
						currentClocks = temp_var;
					}
				}
				if (this.serialTimer > 0 && (this.interruptsEnabled & 0x8) == 0x8) {
					if (this.serialTimer <= currentClocks || currentClocks == -1) {
						currentClocks = this.serialTimer;
					}
				}
			}
			else {
				currentClocks = this.remainingClocks;
			}
			var maxClocks:uint = (this.CPUCyclesTotal - this.emulatorTicks) << this.doubleSpeedShifter;
			if (currentClocks >= 0) {
				if (currentClocks <= maxClocks) {
					this.CPUTicks = Math.max(currentClocks, this.CPUTicks);
					this.updateCoreFull();
					this.halt = false;
					this.CPUTicks = 0;
				}
				else {
					this.CPUTicks = Math.max(maxClocks, this.CPUTicks);
					this.remainingClocks = currentClocks - this.CPUTicks;
				}
			}
			else {
				this.CPUTicks += maxClocks;
			}
		}
		
		public	function memoryRead(address:uint):uint
		{
			return this.memoryReader[address](address);
		}
		
		public	function memoryHighRead(address:uint):uint
		{
			return this.memoryHighReader[address](address);
		}
		
		public	function memoryReadJumpCompile():uint
		{
			for (var index:uint = 0x0000; index <= 0xFFFF; index++) {
				if (index < 0x4000) {
					this.memoryReader[index] = this.memoryReadNormal;
				}
				else if (index < 0x8000) {
					this.memoryReader[index] = this.memoryReadROM;
				}
				else if (index < 0x9800) {
					this.memoryReader[index] = (this.cGBC) ? this.VRAMDATAReadCGBCPU : this.VRAMDATAReadDMGCPU;
				}
				else if (index < 0xA000) {
					this.memoryReader[index] = (this.cGBC) ? this.VRAMCHRReadCGBCPU : this.VRAMCHRReadDMGCPU;
				}
				else if (index >= 0xA000 && index < 0xC000) {
					if ((this.numRAMBanks == 1 / 16 && index < 0xA200) || this.numRAMBanks >= 1) {
						if (this.cMBC7) {
							this.memoryReader[index] = this.memoryReadMBC7;
						}
						else if (!this.cMBC3) {
							this.memoryReader[index] = this.memoryReadMBC;
						}
						else {
							this.memoryReader[index] = this.memoryReadMBC3;
						}
					}
					else {
						this.memoryReader[index] = this.memoryReadBAD;
					}
				}
				else if (index >= 0xC000 && index < 0xE000) {
					if (!this.cGBC || index < 0xD000) {
						this.memoryReader[index] = this.memoryReadNormal;
					}
					else {
						this.memoryReader[index] = this.memoryReadGBCMemory;
					}
				}
				else if (index >= 0xE000 && index < 0xFE00) {
					if (!this.cGBC || index < 0xF000) {
						this.memoryReader[index] = this.memoryReadECHONormal;
					}
					else {
						this.memoryReader[index] = this.memoryReadECHOGBCMemory;
					}
				}
				else if (index < 0xFEA0) {
					this.memoryReader[index] = this.memoryReadOAM;
				}
				else if (this.cGBC && index >= 0xFEA0 && index < 0xFF00) {
					this.memoryReader[index] = this.memoryReadNormal;
				}
				else if (index >= 0xFF00) {
					switch (index) {
						case 0xFF00:
							this.memoryHighReader[0] = this.memoryReader[0xFF00] = function (address:uint):uint {
								return 0xC0 | memory[0xFF00];
							}
							break;
						case 0xFF01:
							this.memoryHighReader[0x01] = this.memoryReader[0xFF01] = function (address:uint):uint {
								return (memory[0xFF02] < 0x80) ? memory[0xFF01] : 0xFF;
							}
							break;
						case 0xFF02:
							if (this.cGBC) {
								this.memoryHighReader[0x02] = this.memoryReader[0xFF02] = function (address:uint):uint {
									return ((serialTimer <= 0) ? 0x7C : 0xFC) | memory[0xFF02];
								}
							}
							else {
								this.memoryHighReader[0x02] = this.memoryReader[0xFF02] = function (address:uint):uint {
									return ((serialTimer <= 0) ? 0x7E : 0xFE) | memory[0xFF02];
								}
							}
							break;
						case 0xFF04:
							this.memoryHighReader[0x04] = this.memoryReader[0xFF04] = function (address:uint):uint {
								memory[0xFF04] = (memory[0xFF04] + (DIVTicks >> 8)) & 0xFF;
								DIVTicks &= 0xFF;
								return memory[0xFF04];
								
							}
							break;
						case 0xFF07:
							this.memoryHighReader[0x07] = this.memoryReader[0xFF07] = function (address:uint):uint {
								return 0xF8 | memory[0xFF07];
							}
							break;
						case 0xFF0F:
							this.memoryHighReader[0x0F] = this.memoryReader[0xFF0F] = function (address:uint):uint {
								return 0xE0 | interruptsRequested;
							}
							break;
						case 0xFF10:
							this.memoryHighReader[0x10] = this.memoryReader[0xFF10] = function (address:uint):uint {
								return 0x80 | memory[0xFF10];
							}
							break;
						case 0xFF11:
							this.memoryHighReader[0x11] = this.memoryReader[0xFF11] = function (address:uint):uint {
								return 0x3F | memory[0xFF11];
							}
							break;
						case 0xFF13:
							this.memoryHighReader[0x13] = this.memoryReader[0xFF13] = this.memoryReadBAD;
							break;
						case 0xFF14:
							this.memoryHighReader[0x14] = this.memoryReader[0xFF14] = function (address:uint):uint {
								return 0xBF | memory[0xFF14];
							}
							break;
						case 0xFF16:
							this.memoryHighReader[0x16] = this.memoryReader[0xFF16] = function (address:uint):uint {
								return 0x3F | memory[0xFF16];
							}
							break;
						case 0xFF18:
							this.memoryHighReader[0x18] = this.memoryReader[0xFF18] = this.memoryReadBAD;
							break;
						case 0xFF19:
							this.memoryHighReader[0x19] = this.memoryReader[0xFF19] = function (address:uint):uint {
								return 0xBF | memory[0xFF19];
							}
							break;
						case 0xFF1A:
							this.memoryHighReader[0x1A] = this.memoryReader[0xFF1A] = function (address:uint):uint {
								return 0x7F | memory[0xFF1A];
							}
							break;
						case 0xFF1B:
							this.memoryHighReader[0x1B] = this.memoryReader[0xFF1B] = this.memoryReadBAD;
							break;
						case 0xFF1C:
							this.memoryHighReader[0x1C] = this.memoryReader[0xFF1C] = function (address:uint):uint {
								return 0x9F | memory[0xFF1C];
							}
							break;
						case 0xFF1D:
							this.memoryHighReader[0x1D] = this.memoryReader[0xFF1D] = function (address:uint):uint {
								return 0xFF;
							}
							break;
						case 0xFF1E:
							this.memoryHighReader[0x1E] = this.memoryReader[0xFF1E] = function (address:uint):uint {
								return 0xBF | memory[0xFF1E];
							}
							break;
						case 0xFF1F:
						case 0xFF20:
							this.memoryHighReader[index & 0xFF] = this.memoryReader[index] = this.memoryReadBAD;
							break;
						case 0xFF23:
							this.memoryHighReader[0x23] = this.memoryReader[0xFF23] = function (address:uint):uint {
								return 0xBF | memory[0xFF23];
							}
							break;
						case 0xFF26:
							this.memoryHighReader[0x26] = this.memoryReader[0xFF26] = function (address:uint):uint {
								audioJIT();
								return 0x70 | memory[0xFF26];
							}
							break;
						case 0xFF27:
						case 0xFF28:
						case 0xFF29:
						case 0xFF2A:
						case 0xFF2B:
						case 0xFF2C:
						case 0xFF2D:
						case 0xFF2E:
						case 0xFF2F:
							this.memoryHighReader[index & 0xFF] = this.memoryReader[index] = this.memoryReadBAD;
							break;
						case 0xFF30:
						case 0xFF31:
						case 0xFF32:
						case 0xFF33:
						case 0xFF34:
						case 0xFF35:
						case 0xFF36:
						case 0xFF37:
						case 0xFF38:
						case 0xFF39:
						case 0xFF3A:
						case 0xFF3B:
						case 0xFF3C:
						case 0xFF3D:
						case 0xFF3E:
						case 0xFF3F:
							this.memoryReader[index] = function (address:uint):uint {
								return (channel3canPlay) ? memory[0xFF00 | (channel3Tracker >> 1)] : memory[address];
							}
							this.memoryHighReader[index & 0xFF] = function (address:uint):uint {
								return (channel3canPlay) ? memory[0xFF00 | (channel3Tracker >> 1)] : memory[0xFF00 | address];
							}
							break;
						case 0xFF41:
							this.memoryHighReader[0x41] = this.memoryReader[0xFF41] = function (address:uint):uint {
								return 0x80 | memory[0xFF41] | modeSTAT;
							}
							break;
						case 0xFF42:
							this.memoryHighReader[0x42] = this.memoryReader[0xFF42] = function (address:uint):uint {
								return backgroundY;
							}
							break;
						case 0xFF43:
							this.memoryHighReader[0x43] = this.memoryReader[0xFF43] = function (address:uint):uint {
								return backgroundX;
							}
							break;
						case 0xFF44:
							this.memoryHighReader[0x44] = this.memoryReader[0xFF44] = function (address:uint):uint {
								return ((LCDisOn) ? memory[0xFF44] : 0);
							}
							break;
						case 0xFF4A:
							this.memoryHighReader[0x4A] = this.memoryReader[0xFF4A] = function (address:uint):uint {
								return windowY;
							}
							break;
						case 0xFF4F:
							this.memoryHighReader[0x4F] = this.memoryReader[0xFF4F] = function (address:uint):uint {
								return currVRAMBank;
							}
							break;
						case 0xFF55:
							if (this.cGBC) {
								this.memoryHighReader[0x55] = this.memoryReader[0xFF55] = function (address:uint):uint {
									if (!LCDisOn && hdmaRunning) {
										DMAWrite((memory[0xFF55] & 0x7F) + 1);
										memory[0xFF55] = 0xFF;
										hdmaRunning = false;
									}
									return memory[0xFF55];
								}
							}
							else {
								this.memoryReader[0xFF55] = this.memoryReadNormal;
								this.memoryHighReader[0x55] = this.memoryHighReadNormal;
							}
							break;
						case 0xFF56:
							if (this.cGBC) {
								this.memoryHighReader[0x56] = this.memoryReader[0xFF56] = function (address:uint):uint {
									return 0x3C | ((memory[0xFF56] >= 0xC0) ? (0x2 | (memory[0xFF56] & 0xC1)) : (memory[0xFF56] & 0xC3));
								}
							}
							else {
								this.memoryReader[0xFF56] = this.memoryReadNormal;
								this.memoryHighReader[0x56] = this.memoryHighReadNormal;
							}
							break;
						case 0xFF6C:
							if (this.cGBC) {
								this.memoryHighReader[0x6C] = this.memoryReader[0xFF6C] = function (address:uint):uint {
									return 0xFE | memory[0xFF6C];
								}
							}
							else {
								this.memoryHighReader[0x6C] = this.memoryReader[0xFF6C] = this.memoryReadBAD;
							}
							break;
						case 0xFF70:
							if (this.cGBC) {
								this.memoryHighReader[0x70] = this.memoryReader[0xFF70] = function (address:uint):uint {
									return 0x40 | memory[0xFF70];
								}
							}
							else {
								this.memoryHighReader[0x70] = this.memoryReader[0xFF70] = this.memoryReadBAD;
							}
							break;
						case 0xFF75:
							this.memoryHighReader[0x75] = this.memoryReader[0xFF75] = function (address:uint):uint {
								return 0x8F | memory[0xFF75];
							}
							break;
						case 0xFF76:
						case 0xFF77:
							this.memoryHighReader[index & 0xFF] = this.memoryReader[index] = function (address:uint):uint {
								return 0;
							}
							break;
						case 0xFFFF:
							this.memoryHighReader[0xFF] = this.memoryReader[0xFFFF] = function (address:uint):uint {
								return interruptsEnabled;
							}
							break;
						default:
							this.memoryReader[index] = this.memoryReadNormal;
							this.memoryHighReader[index & 0xFF] = this.memoryHighReadNormal;
					}
				}
				else {
					this.memoryReader[index] = this.memoryReadBAD;
				}
			}
			return 0;
		}
		
		public	function memoryReadNormal(address:uint):uint
		{
			return this.memory[address];
		}

		public	function memoryHighReadNormal(address:uint):uint
		{
			return this.memory[0xFF00 | address];
		}
		
		public	function memoryReadROM(address:uint):uint
		{
			return this.ROM[this.currentROMBank + address];
		}
		
		public	function memoryReadMBC(address:uint):uint
		{
			if (this.MBCRAMBanksEnabled || settings.overrideMBC) {
				return this.MBCRam[address + this.currMBCRAMBankPosition];
			}
			return 0xFF;
		}
		
		public	function memoryReadMBC7(address:uint):uint
		{
			if (this.MBCRAMBanksEnabled || settings.overrideMBC) {
				switch (address) {
					case 0xA000:
					case 0xA060:
					case 0xA070:
						return 0;
					case 0xA080:
						return 0;
					case 0xA050:
						return this.highY;
					case 0xA040:
						return this.lowY;
					case 0xA030:
						return this.highX;
					case 0xA020:
						return this.lowX;
					default:
						return this.MBCRam[address + this.currMBCRAMBankPosition];
				}
			}
			return 0xFF;
		}
		
		public	function memoryReadMBC3(address:uint):uint
		{
			if (this.MBCRAMBanksEnabled || settings.overrideMBC) {
				switch (this.currMBCRAMBank) {
					case 0x00:
					case 0x01:
					case 0x02:
					case 0x03:
						return this.MBCRam[address + this.currMBCRAMBankPosition];
						break;
					case 0x08:
						return this.latchedSeconds;
						break;
					case 0x09:
						return this.latchedMinutes;
						break;
					case 0x0A:
						return this.latchedHours;
						break;
					case 0x0B:
						return this.latchedLDays;
						break;
					case 0x0C:
						return (((this.RTCDayOverFlow) ? 0x80 : 0) + ((this.RTCHALT) ? 0x40 : 0)) + this.latchedHDays;
				}
			}
			return 0xFF;
		}
		
		public	function memoryReadGBCMemory(address:uint):uint
		{
			return this.GBCMemory[address + this.gbcRamBankPosition];
		}
		
		public	function memoryReadOAM(address:uint):uint
		{
			return (this.modeSTAT > 1) ?  0xFF : this.memory[address];
		}
		
		public	function memoryReadECHOGBCMemory(address:uint):uint
		{
			return this.GBCMemory[address + this.gbcRamBankPositionECHO];
		}
		
		public	function memoryReadECHONormal(address:uint):uint
		{
			return this.memory[address - 0x2000];
		}
		
		public	function memoryReadBAD(address:uint):uint
		{
			return 0xFF;
		}
		
		public	function VRAMDATAReadCGBCPU(address:uint):uint
		{
			return (this.modeSTAT > 2) ? 0xFF : ((this.currVRAMBank == 0) ? this.memory[address] : this.VRAM[address & 0x1FFF]);
		}
		
		public	function VRAMDATAReadDMGCPU(address:uint):uint
		{
			return (this.modeSTAT > 2) ? 0xFF : this.memory[address];
		}
		
		public	function VRAMCHRReadCGBCPU(address:uint):uint
		{
			return (this.modeSTAT > 2) ? 0xFF : this.BGCHRCurrentBank[address & 0x7FF];
		}
		
		public	function VRAMCHRReadDMGCPU(address:uint):uint
		{
			return (this.modeSTAT > 2) ? 0xFF : this.BGCHRBank1[address & 0x7FF];
		}
		
		public	function setCurrentMBC1ROMBank():void
		{
			switch (this.ROMBank1offs) {
				case 0x00:
				case 0x20:
				case 0x40:
				case 0x60:
					this.currentROMBank = (this.ROMBank1offs % this.ROMBankEdge) << 14;
					break;
				default:
					this.currentROMBank = ((this.ROMBank1offs % this.ROMBankEdge) - 1) << 14;
			}
		}
		
		public	function setCurrentMBC2AND3ROMBank():void
		{
			this.currentROMBank = Math.max((this.ROMBank1offs % this.ROMBankEdge) - 1, 0) << 14;
		}
		
		public	function setCurrentMBC5ROMBank():void
		{
			this.currentROMBank = ((this.ROMBank1offs % this.ROMBankEdge) - 1) << 14;
		}
		
		public	function memoryWrite(address:uint, data:uint):void
		{
			this.memoryWriter[address](address, data);
		}
		
		public	function memoryHighWrite(address:uint, data:uint):void
		{
			this.memoryHighWriter[address](address, data);
		}
		
		public	function memoryWriteJumpCompile():void
		{
			for (var index:uint = 0x0000; index <= 0xFFFF; index++) {
				if (index < 0x8000) {
					if (this.cMBC1) {
						if (index < 0x2000) {
							this.memoryWriter[index] = this.MBCWriteEnable;
						}
						else if (index < 0x4000) {
							this.memoryWriter[index] = this.MBC1WriteROMBank;
						}
						else if (index < 0x6000) {
							this.memoryWriter[index] = this.MBC1WriteRAMBank;
						}
						else {
							this.memoryWriter[index] = this.MBC1WriteType;
						}
					}
					else if (this.cMBC2) {
						if (index < 0x1000) {
							this.memoryWriter[index] = this.MBCWriteEnable;
						}
						else if (index >= 0x2100 && index < 0x2200) {
							this.memoryWriter[index] = this.MBC2WriteROMBank;
						}
						else {
							this.memoryWriter[index] = this.cartIgnoreWrite;
						}
					}
					else if (this.cMBC3) {
						if (index < 0x2000) {
							this.memoryWriter[index] = this.MBCWriteEnable;
						}
						else if (index < 0x4000) {
							this.memoryWriter[index] = this.MBC3WriteROMBank;
						}
						else if (index < 0x6000) {
							this.memoryWriter[index] = this.MBC3WriteRAMBank;
						}
						else {
							this.memoryWriter[index] = this.MBC3WriteRTCLatch;
						}
					}
					else if (this.cMBC5 || this.cRUMBLE || this.cMBC7) {
						if (index < 0x2000) {
							this.memoryWriter[index] = this.MBCWriteEnable;
						}
						else if (index < 0x3000) {
							this.memoryWriter[index] = this.MBC5WriteROMBankLow;
						}
						else if (index < 0x4000) {
							this.memoryWriter[index] = this.MBC5WriteROMBankHigh;
						}
						else if (index < 0x6000) {
							this.memoryWriter[index] = (this.cRUMBLE) ? this.RUMBLEWriteRAMBank : this.MBC5WriteRAMBank;
						}
						else {
							this.memoryWriter[index] = this.cartIgnoreWrite;
						}
					}
					else if (this.cHuC3) {
						if (index < 0x2000) {
							this.memoryWriter[index] = this.MBCWriteEnable;
						}
						else if (index < 0x4000) {
							this.memoryWriter[index] = this.MBC3WriteROMBank;
						}
						else if (index < 0x6000) {
							this.memoryWriter[index] = this.HuC3WriteRAMBank;
						}
						else {
							this.memoryWriter[index] = this.cartIgnoreWrite;
						}
					}
					else {
						this.memoryWriter[index] = this.cartIgnoreWrite;
					}
				}
				else if (index < 0x9000) {
					this.memoryWriter[index] = (this.cGBC) ? this.VRAMGBCDATAWrite : this.VRAMGBDATAWrite;
				}
				else if (index < 0x9800) {
					this.memoryWriter[index] = (this.cGBC) ? this.VRAMGBCDATAWrite : this.VRAMGBDATAUpperWrite;
				}
				else if (index < 0xA000) {
					this.memoryWriter[index] = (this.cGBC) ? this.VRAMGBCCHRMAPWrite : this.VRAMGBCHRMAPWrite;
				}
				else if (index < 0xC000) {
					if ((this.numRAMBanks == 1 / 16 && index < 0xA200) || this.numRAMBanks >= 1) {
						if (!this.cMBC3) {
							this.memoryWriter[index] = this.memoryWriteMBCRAM;
						}
						else {
							this.memoryWriter[index] = this.memoryWriteMBC3RAM;
						}
					}
					else {
						this.memoryWriter[index] = this.cartIgnoreWrite;
					}
				}
				else if (index < 0xE000) {
					if (this.cGBC && index >= 0xD000) {
						this.memoryWriter[index] = this.memoryWriteGBCRAM;
					}
					else {
						this.memoryWriter[index] = this.memoryWriteNormal;
					}
				}
				else if (index < 0xFE00) {
					if (this.cGBC && index >= 0xF000) {
						this.memoryWriter[index] = this.memoryWriteECHOGBCRAM;
					}
					else {
						this.memoryWriter[index] = this.memoryWriteECHONormal;
					}
				}
				else if (index <= 0xFEA0) {
					this.memoryWriter[index] = this.memoryWriteOAMRAM;
				}
				else if (index < 0xFF00) {
					if (this.cGBC) {
						this.memoryWriter[index] = this.memoryWriteNormal;
					}
					else {
						this.memoryWriter[index] = this.cartIgnoreWrite;
					}
				}
				else {
					this.memoryWriter[index] = this.memoryWriteNormal;
					this.memoryHighWriter[index & 0xFF] = this.memoryHighWriteNormal;
				}
			}
			this.registerWriteJumpCompile();
		}
		
		public	function MBCWriteEnable(address:uint, data:uint):void
		{
			this.MBCRAMBanksEnabled = ((data & 0x0F) == 0x0A);
		}
		
		public	function MBC1WriteROMBank(address:uint, data:uint):void
		{
			this.ROMBank1offs = (this.ROMBank1offs & 0x60) | (data & 0x1F);
			this.setCurrentMBC1ROMBank();
		}
		
		public	function MBC1WriteRAMBank(address:uint, data:uint):void
		{
			if (this.MBC1Mode) {
				this.currMBCRAMBank = data & 0x03;
				this.currMBCRAMBankPosition = (this.currMBCRAMBank << 13) - 0xA000;
			}
			else {
				this.ROMBank1offs = ((data & 0x03) << 5) | (this.ROMBank1offs & 0x1F);
				this.setCurrentMBC1ROMBank();
			}
		}
		
		public	function MBC1WriteType(address:uint, data:uint):void
		{
			this.MBC1Mode = ((data & 0x1) == 0x1);
			if (this.MBC1Mode) {
				this.ROMBank1offs &= 0x1F;
				this.setCurrentMBC1ROMBank();
			}
			else {
				this.currMBCRAMBank = 0;
				this.currMBCRAMBankPosition = -0xA000;
			}
		}
		
		public	function MBC2WriteROMBank(address:uint, data:uint):void
		{
			this.ROMBank1offs = data & 0x0F;
			this.setCurrentMBC2AND3ROMBank();
		}
		
		public	function MBC3WriteROMBank(address:uint, data:uint):void
		{
			this.ROMBank1offs = data & 0x7F;
			this.setCurrentMBC2AND3ROMBank();
		}
		
		public	function MBC3WriteRAMBank(address:uint, data:uint):void
		{
			this.currMBCRAMBank = data;
			if (data < 4) {
				this.currMBCRAMBankPosition = (this.currMBCRAMBank << 13) - 0xA000;
			}
		}
		
		public	function MBC3WriteRTCLatch(address:uint, data:uint):void
		{
			if (data == 0) {
				this.RTCisLatched = false;
			}
			else if (!this.RTCisLatched) {
				this.RTCisLatched = true;
				this.latchedSeconds = this.RTCSeconds | 0;
				this.latchedMinutes = this.RTCMinutes;
				this.latchedHours = this.RTCHours;
				this.latchedLDays = (this.RTCDays & 0xFF);
				this.latchedHDays = this.RTCDays >> 8;
			}
		}
		
		public	function MBC5WriteROMBankLow(address:uint, data:uint):void
		{
			this.ROMBank1offs = (this.ROMBank1offs & 0x100) | data;
			this.setCurrentMBC5ROMBank();
		}
		
		public	function MBC5WriteROMBankHigh(address:uint, data:uint):void
		{
			this.ROMBank1offs  = ((data & 0x01) << 8) | (this.ROMBank1offs & 0xFF);
			this.setCurrentMBC5ROMBank();
		}
		
		public	function MBC5WriteRAMBank(address:uint, data:uint):void
		{
			this.currMBCRAMBank = data & 0xF;
			this.currMBCRAMBankPosition = (this.currMBCRAMBank << 13) - 0xA000;
		}
		
		public	function RUMBLEWriteRAMBank(address:uint, data:uint):void
		{
			this.currMBCRAMBank = data & 0x03;
			this.currMBCRAMBankPosition = (this.currMBCRAMBank << 13) - 0xA000;
		}
		
		public	function HuC3WriteRAMBank(address:uint, data:uint):void
		{
			this.currMBCRAMBank = data & 0x03;
			this.currMBCRAMBankPosition = (this.currMBCRAMBank << 13) - 0xA000;
		}
		
		public	function cartIgnoreWrite(address:uint, data:uint):void
		{
			;
		}
		
		public	function memoryWriteNormal(address:uint, data:uint):void
		{
			this.memory[address] = data;
		}
		
		public	function memoryHighWriteNormal(address:uint, data:uint):void
		{
			this.memory[0xFF00 | address] = data;
		}
		
		public	function memoryWriteMBCRAM(address:uint, data:uint):void
		{
			if (this.MBCRAMBanksEnabled || settings.overrideMBC) {
				this.MBCRam[address + this.currMBCRAMBankPosition] = data;
			}
		}
		
		public	function memoryWriteMBC3RAM(address:uint, data:uint):void
		{
			if (this.MBCRAMBanksEnabled || settings.overrideMBC) {
				switch (this.currMBCRAMBank) {
					case 0x00:
					case 0x01:
					case 0x02:
					case 0x03:
						this.MBCRam[address + this.currMBCRAMBankPosition] = data;
						break;
					case 0x08:
						if (data < 60) {
							this.RTCSeconds = data;
						}
						else {
							trace("(Bank #" + this.currMBCRAMBank.toString() + ") RTC write out of range: " + data.toString(), 1);
						}
						break;
					case 0x09:
						if (data < 60) {
							this.RTCMinutes = data;
						}
						else {
							trace("(Bank #" + this.currMBCRAMBank.toString() + ") RTC write out of range: " + data.toString(), 1);
						}
						break;
					case 0x0A:
						if (data < 24) {
							this.RTCHours = data;
						}
						else {
							trace("(Bank #" + this.currMBCRAMBank.toString() + ") RTC write out of range: " + data.toString(), 1);
						}
						break;
					case 0x0B:
						this.RTCDays = (data & 0xFF) | (this.RTCDays & 0x100);
						break;
					case 0x0C:
						this.RTCDayOverFlow = (data > 0x7F);
						this.RTCHALT = (data & 0x40) == 0x40;
						this.RTCDays = ((data & 0x1) << 8) | (this.RTCDays & 0xFF);
						break;
					default:
						trace("Invalid MBC3 bank address selected: " + this.currMBCRAMBank.toString(), 0);
				}
			}
		}
		
		public	function memoryWriteGBCRAM(address:uint, data:uint):void
		{
			this.GBCMemory[address + this.gbcRamBankPosition] = data;
		}
		
		public	function memoryWriteOAMRAM(address:uint, data:uint):void
		{
			if (this.modeSTAT < 2) {
				if (this.memory[address] != data) {
					this.graphicsJIT();
					this.memory[address] = data;
				}
			}
		}
		
		public	function memoryWriteECHOGBCRAM(address:uint, data:uint):void
		{
			this.GBCMemory[address + this.gbcRamBankPositionECHO] = data;
		}
		
		public	function memoryWriteECHONormal(address:uint, data:uint):void
		{
			this.memory[address - 0x2000] = data;
		}
		
		public	function VRAMGBDATAWrite(address:uint, data:uint):void
		{
			if (this.modeSTAT < 3) {
				if (this.memory[address] != data) {
					this.graphicsJIT();
					this.memory[address] = data;
					this.generateGBOAMTileLine(address);
				}
			}
		}
		
		public	function VRAMGBDATAUpperWrite(address:uint, data:uint):void
		{
			if (this.modeSTAT < 3) {
				if (this.memory[address] != data) {
					this.graphicsJIT();
					this.memory[address] = data;
					this.generateGBTileLine(address);
				}
			}
		}
		
		public	function VRAMGBCDATAWrite(address:uint, data:uint):void
		{
			if (this.modeSTAT < 3) {
				if (this.currVRAMBank == 0) {
					if (this.memory[address] != data) {
						this.graphicsJIT();
						this.memory[address] = data;
						this.generateGBCTileLineBank1(address);
					}
				}
				else {
					address &= 0x1FFF;
					if (this.VRAM[address] != data) {
						this.graphicsJIT();
						this.VRAM[address] = data;
						this.generateGBCTileLineBank2(address);
					}
				}
			}
		}
		
		public	function VRAMGBCHRMAPWrite(address:uint, data:uint):void
		{
			if (this.modeSTAT < 3) {
				address &= 0x7FF;
				if (this.BGCHRBank1[address] != data) {
					this.graphicsJIT();
					this.BGCHRBank1[address] = data;
				}
			}
		}
		
		public	function VRAMGBCCHRMAPWrite(address:uint, data:uint):void
		{
			if (this.modeSTAT < 3) {
				address &= 0x7FF;
				if (this.BGCHRCurrentBank[address] != data) {
					this.graphicsJIT();
					this.BGCHRCurrentBank[address] = data;
				}
			}
		}
		
		public	function DMAWrite(tilesToTransfer:uint):void
		{
			if (!this.halt) {
				this.CPUTicks += 4 | ((tilesToTransfer << 5) << this.doubleSpeedShifter);
			}
			var source:uint = (this.memory[0xFF51] << 8) | this.memory[0xFF52];
			var destination:uint = (this.memory[0xFF53] << 8) | this.memory[0xFF54];
			this.graphicsJIT();
			if (this.currVRAMBank == 0) {
				do {
					if (destination < 0x1800) {
						memory[0x8000 | destination] = memoryReader[source](source++);
						memory[0x8001 | destination] = memoryReader[source](source++);
						memory[0x8002 | destination] = memoryReader[source](source++);
						memory[0x8003 | destination] = memoryReader[source](source++);
						memory[0x8004 | destination] = memoryReader[source](source++);
						memory[0x8005 | destination] = memoryReader[source](source++);
						memory[0x8006 | destination] = memoryReader[source](source++);
						memory[0x8007 | destination] = memoryReader[source](source++);
						memory[0x8008 | destination] = memoryReader[source](source++);
						memory[0x8009 | destination] = memoryReader[source](source++);
						memory[0x800A | destination] = memoryReader[source](source++);
						memory[0x800B | destination] = memoryReader[source](source++);
						memory[0x800C | destination] = memoryReader[source](source++);
						memory[0x800D | destination] = memoryReader[source](source++);
						memory[0x800E | destination] = memoryReader[source](source++);
						memory[0x800F | destination] = memoryReader[source](source++);
						this.generateGBCTileBank1(destination);
						destination += 0x10;
					}
					else {
						destination &= 0x7F0;
						this.BGCHRBank1[destination++] = memoryReader[source](source++);
						this.BGCHRBank1[destination++] = memoryReader[source](source++);
						this.BGCHRBank1[destination++] = memoryReader[source](source++);
						this.BGCHRBank1[destination++] = memoryReader[source](source++);
						this.BGCHRBank1[destination++] = memoryReader[source](source++);
						this.BGCHRBank1[destination++] = memoryReader[source](source++);
						this.BGCHRBank1[destination++] = memoryReader[source](source++);
						this.BGCHRBank1[destination++] = memoryReader[source](source++);
						this.BGCHRBank1[destination++] = memoryReader[source](source++);
						this.BGCHRBank1[destination++] = memoryReader[source](source++);
						this.BGCHRBank1[destination++] = memoryReader[source](source++);
						this.BGCHRBank1[destination++] = memoryReader[source](source++);
						this.BGCHRBank1[destination++] = memoryReader[source](source++);
						this.BGCHRBank1[destination++] = memoryReader[source](source++);
						this.BGCHRBank1[destination++] = memoryReader[source](source++);
						this.BGCHRBank1[destination++] = memoryReader[source](source++);
						destination = (destination + 0x1800) & 0x1FF0;
					}
					source &= 0xFFF0;
					--tilesToTransfer;
				} while (tilesToTransfer > 0);
			}
			else {
				do {
					if (destination < 0x1800) {
						VRAM[destination] = memoryReader[source](source++);
						VRAM[destination | 0x1] = memoryReader[source](source++);
						VRAM[destination | 0x2] = memoryReader[source](source++);
						VRAM[destination | 0x3] = memoryReader[source](source++);
						VRAM[destination | 0x4] = memoryReader[source](source++);
						VRAM[destination | 0x5] = memoryReader[source](source++);
						VRAM[destination | 0x6] = memoryReader[source](source++);
						VRAM[destination | 0x7] = memoryReader[source](source++);
						VRAM[destination | 0x8] = memoryReader[source](source++);
						VRAM[destination | 0x9] = memoryReader[source](source++);
						VRAM[destination | 0xA] = memoryReader[source](source++);
						VRAM[destination | 0xB] = memoryReader[source](source++);
						VRAM[destination | 0xC] = memoryReader[source](source++);
						VRAM[destination | 0xD] = memoryReader[source](source++);
						VRAM[destination | 0xE] = memoryReader[source](source++);
						VRAM[destination | 0xF] = memoryReader[source](source++);
						this.generateGBCTileBank2(destination);
						destination += 0x10;
					}
					else {
						destination &= 0x7F0;
						this.BGCHRBank2[destination++] = memoryReader[source](source++);
						this.BGCHRBank2[destination++] = memoryReader[source](source++);
						this.BGCHRBank2[destination++] = memoryReader[source](source++);
						this.BGCHRBank2[destination++] = memoryReader[source](source++);
						this.BGCHRBank2[destination++] = memoryReader[source](source++);
						this.BGCHRBank2[destination++] = memoryReader[source](source++);
						this.BGCHRBank2[destination++] = memoryReader[source](source++);
						this.BGCHRBank2[destination++] = memoryReader[source](source++);
						this.BGCHRBank2[destination++] = memoryReader[source](source++);
						this.BGCHRBank2[destination++] = memoryReader[source](source++);
						this.BGCHRBank2[destination++] = memoryReader[source](source++);
						this.BGCHRBank2[destination++] = memoryReader[source](source++);
						this.BGCHRBank2[destination++] = memoryReader[source](source++);
						this.BGCHRBank2[destination++] = memoryReader[source](source++);
						this.BGCHRBank2[destination++] = memoryReader[source](source++);
						this.BGCHRBank2[destination++] = memoryReader[source](source++);
						destination = (destination + 0x1800) & 0x1FF0;
					}
					source &= 0xFFF0;
					--tilesToTransfer;
				} while (tilesToTransfer > 0);
			}
			memory[0xFF51] = source >> 8;
			memory[0xFF52] = source & 0xF0;
			memory[0xFF53] = destination >> 8;
			memory[0xFF54] = destination & 0xF0;
		}
		
		public	function registerWriteJumpCompile():void
		{
			this.memoryHighWriter[0] = this.memoryWriter[0xFF00] = function (address:uint, data:uint):void {
				memory[0xFF00] = (data & 0x30) | ((((data & 0x20) == 0) ? (JoyPad >> 4) : 0xF) & (((data & 0x10) == 0) ? (JoyPad & 0xF) : 0xF));
			}
			this.memoryHighWriter[0x1] = this.memoryWriter[0xFF01] = function (address:uint, data:uint):void {
				if (memory[0xFF02] < 0x80) {
					memory[0xFF01] = data;
				}
			}
			this.memoryHighWriter[0x4] = this.memoryWriter[0xFF04] = function (address:uint, data:uint):void {
				DIVTicks &= 0xFF;
				memory[0xFF04] = 0;
			}
			this.memoryHighWriter[0x5] = this.memoryWriter[0xFF05] = function (address:uint, data:uint):void {
				memory[0xFF05] = data;
			}
			this.memoryHighWriter[0x6] = this.memoryWriter[0xFF06] = function (address:uint, data:uint):void {
				memory[0xFF06] = data;
			}
			this.memoryHighWriter[0x7] = this.memoryWriter[0xFF07] = function (address:uint, data:uint):void {
				memory[0xFF07] = data & 0x07;
				TIMAEnabled = (data & 0x04) == 0x04;
				TACClocker = Math.pow(4, ((data & 0x3) != 0) ? (data & 0x3) : 4) << 2;
			}
			this.memoryHighWriter[0xF] = this.memoryWriter[0xFF0F] = function (address:uint, data:uint):void {
				interruptsRequested = data;
				checkIRQMatching();
			}
			this.memoryHighWriter[0x10] = this.memoryWriter[0xFF10] = function (address:uint, data:uint):void {
				if (soundMasterEnabled) {
					audioJIT();
					if (channel1decreaseSweep && (data & 0x08) == 0) {
						if (channel1numSweep != channel1frequencySweepDivider) {
							channel1Fault |= 0x2;
						}
					}
					channel1lastTimeSweep = channel1timeSweep = (((data & 0x70) >> 4) * channel1TimeSweepPreMultiplier) | 0;
					channel1frequencySweepDivider = channel1numSweep = data & 0x07;
					channel1decreaseSweep = ((data & 0x08) == 0x08);
					if (channel1numSweep == 0 && channel1lastTimeSweep > 0 && channel1decreaseSweep) {
						channel1Fault |= 0x1;
					}
					else {
						channel1Fault &= 0x1;
					}
					memory[0xFF10] = data;
				}
			}
			this.memoryHighWriter[0x11] = this.memoryWriter[0xFF11] = function (address:uint, data:uint):void {
				if (soundMasterEnabled || !cGBC) {
					if (soundMasterEnabled) {
						audioJIT();
					}
					else {
						data &= 0x3F;
					}
					channel1adjustedDuty = dutyLookup[data >> 6];
					channel1totalLength = (0x40 - (data & 0x3F)) * audioTotalLengthMultiplier;
					memory[0xFF11] = data & 0xC0;
				}
			}
			this.memoryHighWriter[0x12] = this.memoryWriter[0xFF12] = function (address:uint, data:uint):void {
				if (soundMasterEnabled) {
					audioJIT();
					if (data < 0x08) {
						channel1currentVolume = channel1envelopeVolume = 0;
					}
					else if ((channel1consecutive || channel1totalLength > 0) && channel1envelopeSweeps == 0) {
						if (((memory[0xFF12] ^ data) & 0x8) == 0x8) {
							if ((memory[0xFF12] & 0x8) == 0) {
								if ((memory[0xFF12] & 0x7) == 0x7) {
									channel1envelopeVolume += 2;
								}
								else {
									++channel1envelopeVolume;
								}
							}
							channel1envelopeVolume = (16 - channel1envelopeVolume) & 0xF;
						}
						else if ((memory[0xFF12] & 0xF) == 0x8) {
							channel1envelopeVolume = (1 + channel1envelopeVolume) & 0xF;
						}
						channel1currentVolume = channel1envelopeVolume / 0x1E;
					}
					channel1envelopeType = ((data & 0x08) == 0x08);
					memory[0xFF12] = data;
				}
			}
			this.memoryHighWriter[0x13] = this.memoryWriter[0xFF13] = function (address:uint, data:uint):void {
				if (soundMasterEnabled) {
					audioJIT();
					channel1frequency = (channel1frequency & 0x700) | data;
					channel1adjustedFrequencyPrep = preChewedAudioComputationMultiplier / (0x800 - channel1frequency);
					memory[0xFF13] = data;
				}
			}
			this.memoryHighWriter[0x14] = this.memoryWriter[0xFF14] = function (address:uint, data:uint):void {
				if (soundMasterEnabled) {
					audioJIT();
					channel1consecutive = ((data & 0x40) == 0x0);
					channel1frequency = ((data & 0x7) << 8) | (channel1frequency & 0xFF);
					if (data > 0x7F) {
						channel1timeSweep = channel1lastTimeSweep;
						channel1numSweep = channel1frequencySweepDivider;
						var nr12:uint = memory[0xFF12];
						if (nr12 > 0x07) {
							channel1envelopeVolume = nr12 >> 4;
							channel1currentVolume = channel1envelopeVolume / 0x1E;
							channel1envelopeSweeps = nr12 & 0x7;
							channel1volumeEnvTime = channel1volumeEnvTimeLast = channel1envelopeSweeps * volumeEnvelopePreMultiplier;
							if (channel1totalLength <= 0) {
								channel1totalLength = 0x40 * audioTotalLengthMultiplier;
							}
						}
						if ((data & 0x40) == 0x40) {
							memory[0xFF26] |= 0x1;
						}
						channel1ShadowFrequency = channel1frequency;
						channel1Fault &= 0x2;
					}
					if (channel1numSweep == 0 && channel1lastTimeSweep > 0 && channel1decreaseSweep) {
						channel1Fault |= 0x1;
					}
					else {
						channel1Fault &= 0x1;
					}
					channel1adjustedFrequencyPrep = preChewedAudioComputationMultiplier / (0x800 - channel1frequency);
					memory[0xFF14] = data & 0x40;
				}
			}
			this.memoryHighWriter[0x16] = this.memoryWriter[0xFF16] = function (address:uint, data:uint):void {
				if (soundMasterEnabled || !cGBC) {
					if (soundMasterEnabled) {
						audioJIT();
					}
					else {
						data &= 0x3F;
					}
					channel2adjustedDuty = dutyLookup[data >> 6];
					channel2totalLength = (0x40 - (data & 0x3F)) * audioTotalLengthMultiplier;
					memory[0xFF16] = data & 0xC0;
				}
			}
			this.memoryHighWriter[0x17] = this.memoryWriter[0xFF17] = function (address:uint, data:uint):void {
				if (soundMasterEnabled) {
					audioJIT();
					if (data < 0x08) {
						channel2currentVolume = channel2envelopeVolume = 0;
					}
					else if ((channel2consecutive || channel2totalLength > 0) && channel2envelopeSweeps == 0) {
						if (((memory[0xFF17] ^ data) & 0x8) == 0x8) {
							if ((memory[0xFF17] & 0x8) == 0) {
								if ((memory[0xFF17] & 0x7) == 0x7) {
									channel2envelopeVolume += 2;
								}
								else {
									++channel2envelopeVolume;
								}
							}
							channel2envelopeVolume = (16 - channel2envelopeVolume) & 0xF;
						}
						else if ((memory[0xFF17] & 0xF) == 0x8) {
							channel2envelopeVolume = (1 + channel2envelopeVolume) & 0xF;
						}
						channel2currentVolume = channel2envelopeVolume / 0x1E;
					}
					channel2envelopeType = ((data & 0x08) == 0x08);
					memory[0xFF17] = data;
				}
			}
			this.memoryHighWriter[0x18] = this.memoryWriter[0xFF18] = function (address:uint, data:uint):void {
				if (soundMasterEnabled) {
					audioJIT();
					channel2frequency = (channel2frequency & 0x700) | data;
					channel2adjustedFrequencyPrep = preChewedAudioComputationMultiplier / (0x800 - channel2frequency);
					memory[0xFF18] = data;
				}
			}
			this.memoryHighWriter[0x19] = this.memoryWriter[0xFF19] = function (address:uint, data:uint):void {
				if (soundMasterEnabled) {
					audioJIT();
					if (data > 0x7F) {
						var nr22:uint = memory[0xFF17];
						if (nr22 > 0x7) {
							channel2envelopeVolume = nr22 >> 4;
							channel2currentVolume = channel2envelopeVolume / 0x1E;
							channel2envelopeSweeps = nr22 & 0x7;
							channel2volumeEnvTime = channel2volumeEnvTimeLast = channel2envelopeSweeps * volumeEnvelopePreMultiplier;
							if (channel2totalLength <= 0) {
								channel2totalLength = 0x40 * audioTotalLengthMultiplier;
							}
						}
						if ((data & 0x40) == 0x40) {
							memory[0xFF26] |= 0x2;
						}
					}
					channel2consecutive = ((data & 0x40) == 0x0);
					channel2frequency = ((data & 0x7) << 8) | (channel2frequency & 0xFF);
					channel2adjustedFrequencyPrep = preChewedAudioComputationMultiplier / (0x800 - channel2frequency);
					memory[0xFF19] = data & 0x40;
				}
			}
			this.memoryHighWriter[0x1A] = this.memoryWriter[0xFF1A] = function (address:uint, data:uint):void {
				if (soundMasterEnabled) {
					audioJIT();
					if (!channel3canPlay && data >= 0x80) {
						channel3Tracker = 0;
					}
					channel3canPlay = (data > 0x7F);
					if (channel3canPlay && memory[0xFF1A] > 0x7F && !channel3consecutive) {
						memory[0xFF26] |= 0x4;
					}
					memory[0xFF1A] = data & 0x80;
				}
			}
			this.memoryHighWriter[0x1B] = this.memoryWriter[0xFF1B] = function (address:uint, data:uint):void {
				if (soundMasterEnabled || !cGBC) {
					if (soundMasterEnabled) {
						audioJIT();
					}
					channel3totalLength = (0x100 - data) * audioTotalLengthMultiplier;
					memory[0xFF1B] = data;
				}
			}
			this.memoryHighWriter[0x1C] = this.memoryWriter[0xFF1C] = function (address:uint, data:uint):void {
				if (soundMasterEnabled) {
					audioJIT();
					channel3patternType = memory[0xFF1C] = data & 0x60;
				}
			}
			this.memoryHighWriter[0x1D] = this.memoryWriter[0xFF1D] = function (address:uint, data:uint):void {
				if (soundMasterEnabled) {
					audioJIT();
					channel3frequency = (channel3frequency & 0x700) | data;
					channel3adjustedFrequencyPrep = preChewedWAVEAudioComputationMultiplier / (0x800 - channel3frequency);
					memory[0xFF1D] = data;
				}
			}
			this.memoryHighWriter[0x1E] = this.memoryWriter[0xFF1E] = function (address:uint, data:uint):void {
				if (soundMasterEnabled) {
					audioJIT();
					if (data > 0x7F) {
						if (channel3totalLength <= 0) {
							channel3totalLength = 0x100 * audioTotalLengthMultiplier;
						}
						channel3Tracker = 0;
						if ((data & 0x40) == 0x40) {
							memory[0xFF26] |= 0x4;
						}
					}
					channel3consecutive = ((data & 0x40) == 0x0);
					channel3frequency = ((data & 0x7) << 8) | (channel3frequency & 0xFF);
					channel3adjustedFrequencyPrep = preChewedWAVEAudioComputationMultiplier / (0x800 - channel3frequency);
					memory[0xFF1E] = data & 0x40;
				}
			}
			this.memoryHighWriter[0x20] = this.memoryWriter[0xFF20] = function (address:uint, data:uint):void {
				if (soundMasterEnabled || !cGBC) {
					if (soundMasterEnabled) {
						audioJIT();
					}
					channel4totalLength = (0x40 - (data & 0x3F)) * audioTotalLengthMultiplier;
					memory[0xFF20] = data | 0xC0;
				}
			}
			this.memoryHighWriter[0x21] = this.memoryWriter[0xFF21] = function (address:uint, data:uint):void {
				if (soundMasterEnabled) {
					audioJIT();
					if (data < 0x08) {
						channel4currentVolume = channel4envelopeVolume = 0;
					}
					channel4envelopeType = ((data & 0x08) == 0x08);
					memory[0xFF21] = data;
				}
			}
			this.memoryHighWriter[0x22] = this.memoryWriter[0xFF22] = function (address:uint, data:uint):void {
				if (soundMasterEnabled) {
					audioJIT();
					channel4adjustedFrequencyPrep = whiteNoiseFrequencyPreMultiplier / Math.max(data & 0x7, 0.5) / Math.pow(2, (data >> 4) + 1);
					var bitWidth:uint = (data & 0x8);
					if ((bitWidth == 0x8 && noiseTableLength == 0x8000) || (bitWidth == 0 && noiseTableLength == 0x80)) {
						channel4lastSampleLookup = 0;
						noiseTableLength = (bitWidth == 0x8) ? 0x80 : 0x8000;
						channel4VolumeShifter = (bitWidth == 0x8) ? 7 : 15;
						channel4currentVolume = channel4envelopeVolume << channel4VolumeShifter;
						noiseSampleTable = (bitWidth == 0x8) ? LSFR7Table : LSFR15Table;
					}
					memory[0xFF22] = data;
				}
			}
			this.memoryHighWriter[0x23] = this.memoryWriter[0xFF23] = function (address:uint, data:uint):void {
				if (soundMasterEnabled) {
					audioJIT();
					memory[0xFF23] = data;
					channel4consecutive = ((data & 0x40) == 0x0);
					if (data > 0x7F) {
						var nr42:uint = memory[0xFF21];
						if (nr42 > 0x7) {
							channel4envelopeVolume = nr42 >> 4;
							channel4currentVolume = channel4envelopeVolume << channel4VolumeShifter;
							channel4envelopeSweeps = nr42 & 0x7;
							channel4volumeEnvTime = channel4volumeEnvTimeLast = channel4envelopeSweeps * volumeEnvelopePreMultiplier;
							if (channel4totalLength <= 0) {
								channel4totalLength = 0x40 * audioTotalLengthMultiplier;
							}
						}
						if ((data & 0x40) == 0x40) {
							memory[0xFF26] |= 0x8;
						}
					}
				}
			}
			this.memoryHighWriter[0x24] = this.memoryWriter[0xFF24] = function (address:uint, data:uint):void {
				if (soundMasterEnabled && memory[0xFF24] != data) {
					audioJIT();
					memory[0xFF24] = data;
					VinLeftChannelMasterVolume = (((data >> 4) & 0x07) + 1) / 8;
					VinRightChannelMasterVolume = ((data & 0x07) + 1) / 8;
				}
			}
			this.memoryHighWriter[0x25] = this.memoryWriter[0xFF25] = function (address:uint, data:uint):void {
				if (soundMasterEnabled && memory[0xFF25] != data) {
					audioJIT();
					memory[0xFF25] = data;
					rightChannel0 = ((data & 0x01) == 0x01);
					rightChannel1 = ((data & 0x02) == 0x02);
					rightChannel2 = ((data & 0x04) == 0x04);
					rightChannel3 = ((data & 0x08) == 0x08);
					leftChannel0 = ((data & 0x10) == 0x10);
					leftChannel1 = ((data & 0x20) == 0x20);
					leftChannel2 = ((data & 0x40) == 0x40);
					leftChannel3 = (data > 0x7F);
				}
			}
			this.memoryHighWriter[0x26] = this.memoryWriter[0xFF26] = function (address:uint, data:uint):void {
				audioJIT();
				var soundEnabled:uint = (data & 0x80);
				memory[0xFF26] = soundEnabled | (memory[0xFF26] & 0xF);
				if (!soundMasterEnabled && (soundEnabled == 0x80)) {
					memory[0xFF26] = 0;
					soundMasterEnabled = true;
					initializeAudioStartState();
				}
				else if (soundMasterEnabled && (soundEnabled == 0)) {
					memory[0xFF26] = 0;
					soundMasterEnabled = false;
					for (var index:uint = 0xFF10; index < 0xFF26; index++) {
						memoryWriter[index](index, 0);
					}
				}
			}
			this.memoryHighWriter[0x27] = this.memoryWriter[0xFF27] = this.cartIgnoreWrite;
			this.memoryHighWriter[0x28] = this.memoryWriter[0xFF28] = this.cartIgnoreWrite;
			this.memoryHighWriter[0x29] = this.memoryWriter[0xFF29] = this.cartIgnoreWrite;
			this.memoryHighWriter[0x2A] = this.memoryWriter[0xFF2A] = this.cartIgnoreWrite;
			this.memoryHighWriter[0x2B] = this.memoryWriter[0xFF2B] = this.cartIgnoreWrite;
			this.memoryHighWriter[0x2C] = this.memoryWriter[0xFF2C] = this.cartIgnoreWrite;
			this.memoryHighWriter[0x2D] = this.memoryWriter[0xFF2D] = this.cartIgnoreWrite;
			this.memoryHighWriter[0x2E] = this.memoryWriter[0xFF2E] = this.cartIgnoreWrite;
			this.memoryHighWriter[0x2F] = this.memoryWriter[0xFF2F] = this.cartIgnoreWrite;
			this.memoryHighWriter[0x30] = this.memoryWriter[0xFF30] = function (address:uint, data:uint):void {
				if (memory[0xFF30] != data) {
					audioJIT();
					memory[0xFF30] = data;
					channel3PCM[0x20] = (data >> 4) / 0x1E;
					channel3PCM[0x40] = (data >> 5) / 0x1E;
					channel3PCM[0x60] = (data >> 6) / 0x1E;
					channel3PCM[0x21] = (data & 0xF) / 0x1E;
					channel3PCM[0x41] = (data & 0xE) / 0x3C;
					channel3PCM[0x61] = (data & 0xC) / 0x78;
				}
			}
			this.memoryHighWriter[0x31] = this.memoryWriter[0xFF31] = function (address:uint, data:uint):void {
				if (memory[0xFF31] != data) {
					audioJIT();
					memory[0xFF31] = data;
					channel3PCM[0x22] = (data >> 4) / 0x1E;
					channel3PCM[0x42] = (data >> 5) / 0x1E;
					channel3PCM[0x62] = (data >> 6) / 0x1E;
					channel3PCM[0x23] = (data & 0xF) / 0x1E;
					channel3PCM[0x43] = (data & 0xE) / 0x3C;
					channel3PCM[0x63] = (data & 0xC) / 0x78;
				}
			}
			this.memoryHighWriter[0x32] = this.memoryWriter[0xFF32] = function (address:uint, data:uint):void {
				if (memory[0xFF32] != data) {
					audioJIT();
					memory[0xFF32] = data;
					channel3PCM[0x24] = (data >> 4) / 0x1E;
					channel3PCM[0x44] = (data >> 5) / 0x1E;
					channel3PCM[0x64] = (data >> 6) / 0x1E;
					channel3PCM[0x25] = (data & 0xF) / 0x1E;
					channel3PCM[0x45] = (data & 0xE) / 0x3C;
					channel3PCM[0x65] = (data & 0xC) / 0x78;
				}
			}
			this.memoryHighWriter[0x33] = this.memoryWriter[0xFF33] = function (address:uint, data:uint):void {
				if (memory[0xFF33] != data) {
					audioJIT();
					memory[0xFF33] = data;
					channel3PCM[0x26] = (data >> 4) / 0x1E;
					channel3PCM[0x46] = (data >> 5) / 0x1E;
					channel3PCM[0x66] = (data >> 6) / 0x1E;
					channel3PCM[0x27] = (data & 0xF) / 0x1E;
					channel3PCM[0x47] = (data & 0xE) / 0x3C;
					channel3PCM[0x67] = (data & 0xC) / 0x78;
				}
			}
			this.memoryHighWriter[0x34] = this.memoryWriter[0xFF34] = function (address:uint, data:uint):void {
				if (memory[0xFF34] != data) {
					audioJIT();
					memory[0xFF34] = data;
					channel3PCM[0x28] = (data >> 4) / 0x1E;
					channel3PCM[0x48] = (data >> 5) / 0x1E;
					channel3PCM[0x68] = (data >> 6) / 0x1E;
					channel3PCM[0x29] = (data & 0xF) / 0x1E;
					channel3PCM[0x49] = (data & 0xE) / 0x3C;
					channel3PCM[0x69] = (data & 0xC) / 0x78;
				}
			}
			this.memoryHighWriter[0x35] = this.memoryWriter[0xFF35] = function (address:uint, data:uint):void {
				if (memory[0xFF35] != data) {
					audioJIT();
					memory[0xFF35] = data;
					channel3PCM[0x2A] = (data >> 4) / 0x1E;
					channel3PCM[0x4A] = (data >> 5) / 0x1E;
					channel3PCM[0x6A] = (data >> 6) / 0x1E;
					channel3PCM[0x2B] = (data & 0xF) / 0x1E;
					channel3PCM[0x4B] = (data & 0xE) / 0x3C;
					channel3PCM[0x6B] = (data & 0xC) / 0x78;
				}
			}
			this.memoryHighWriter[0x36] = this.memoryWriter[0xFF36] = function (address:uint, data:uint):void {
				if (memory[0xFF36] != data) {
					audioJIT();
					memory[0xFF36] = data;
					channel3PCM[0x2C] = (data >> 4) / 0x1E;
					channel3PCM[0x4C] = (data >> 5) / 0x1E;
					channel3PCM[0x6C] = (data >> 6) / 0x1E;
					channel3PCM[0x2D] = (data & 0xF) / 0x1E;
					channel3PCM[0x4D] = (data & 0xE) / 0x3C;
					channel3PCM[0x6D] = (data & 0xC) / 0x78;
				}
			}
			this.memoryHighWriter[0x37] = this.memoryWriter[0xFF37] = function (address:uint, data:uint):void {
				if (memory[0xFF37] != data) {
					audioJIT();
					memory[0xFF37] = data;
					channel3PCM[0x2E] = (data >> 4) / 0x1E;
					channel3PCM[0x4E] = (data >> 5) / 0x1E;
					channel3PCM[0x6E] = (data >> 6) / 0x1E;
					channel3PCM[0x2F] = (data & 0xF) / 0x1E;
					channel3PCM[0x4F] = (data & 0xE) / 0x3C;
					channel3PCM[0x6F] = (data & 0xC) / 0x78;
				}
			}
			this.memoryHighWriter[0x38] = this.memoryWriter[0xFF38] = function (address:uint, data:uint):void {
				if (memory[0xFF38] != data) {
					audioJIT();
					memory[0xFF38] = data;
					channel3PCM[0x30] = (data >> 4) / 0x1E;
					channel3PCM[0x50] = (data >> 5) / 0x1E;
					channel3PCM[0x70] = (data >> 6) / 0x1E;
					channel3PCM[0x31] = (data & 0xF) / 0x1E;
					channel3PCM[0x51] = (data & 0xE) / 0x3C;
					channel3PCM[0x71] = (data & 0xC) / 0x78;
				}
			}
			this.memoryHighWriter[0x39] = this.memoryWriter[0xFF39] = function (address:uint, data:uint):void {
				if (memory[0xFF39] != data) {
					audioJIT();
					memory[0xFF39] = data;
					channel3PCM[0x32] = (data >> 4) / 0x1E;
					channel3PCM[0x52] = (data >> 5) / 0x1E;
					channel3PCM[0x72] = (data >> 6) / 0x1E;
					channel3PCM[0x33] = (data & 0xF) / 0x1E;
					channel3PCM[0x53] = (data & 0xE) / 0x3C;
					channel3PCM[0x73] = (data & 0xC) / 0x78;
				}
			}
			this.memoryHighWriter[0x3A] = this.memoryWriter[0xFF3A] = function (address:uint, data:uint):void {
				if (memory[0xFF3A] != data) {
					audioJIT();
					memory[0xFF3A] = data;
					channel3PCM[0x34] = (data >> 4) / 0x1E;
					channel3PCM[0x54] = (data >> 5) / 0x1E;
					channel3PCM[0x74] = (data >> 6) / 0x1E;
					channel3PCM[0x35] = (data & 0xF) / 0x1E;
					channel3PCM[0x55] = (data & 0xE) / 0x3C;
					channel3PCM[0x75] = (data & 0xC) / 0x78;
				}
			}
			this.memoryHighWriter[0x3B] = this.memoryWriter[0xFF3B] = function (address:uint, data:uint):void {
				if (memory[0xFF3B] != data) {
					audioJIT();
					memory[0xFF3B] = data;
					channel3PCM[0x36] = (data >> 4) / 0x1E;
					channel3PCM[0x56] = (data >> 5) / 0x1E;
					channel3PCM[0x76] = (data >> 6) / 0x1E;
					channel3PCM[0x37] = (data & 0xF) / 0x1E;
					channel3PCM[0x57] = (data & 0xE) / 0x3C;
					channel3PCM[0x77] = (data & 0xC) / 0x78;
				}
			}
			this.memoryHighWriter[0x3C] = this.memoryWriter[0xFF3C] = function (address:uint, data:uint):void {
				if (memory[0xFF3C] != data) {
					audioJIT();
					memory[0xFF3C] = data;
					channel3PCM[0x38] = (data >> 4) / 0x1E;
					channel3PCM[0x58] = (data >> 5) / 0x1E;
					channel3PCM[0x78] = (data >> 6) / 0x1E;
					channel3PCM[0x39] = (data & 0xF) / 0x1E;
					channel3PCM[0x59] = (data & 0xE) / 0x3C;
					channel3PCM[0x79] = (data & 0xC) / 0x78;
				}
			}
			this.memoryHighWriter[0x3D] = this.memoryWriter[0xFF3D] = function (address:uint, data:uint):void {
				if (memory[0xFF3D] != data) {
					audioJIT();
					memory[0xFF3D] = data;
					channel3PCM[0x3A] = (data >> 4) / 0x1E;
					channel3PCM[0x5A] = (data >> 5) / 0x1E;
					channel3PCM[0x7A] = (data >> 6) / 0x1E;
					channel3PCM[0x3B] = (data & 0xF) / 0x1E;
					channel3PCM[0x5B] = (data & 0xE) / 0x3C;
					channel3PCM[0x7B] = (data & 0xC) / 0x78;
				}
			}
			this.memoryHighWriter[0x3E] = this.memoryWriter[0xFF3E] = function (address:uint, data:uint):void {
				if (memory[0xFF3E] != data) {
					audioJIT();
					memory[0xFF3E] = data;
					channel3PCM[0x3C] = (data >> 4) / 0x1E;
					channel3PCM[0x5C] = (data >> 5) / 0x1E;
					channel3PCM[0x7C] = (data >> 6) / 0x1E;
					channel3PCM[0x3D] = (data & 0xF) / 0x1E;
					channel3PCM[0x5D] = (data & 0xE) / 0x3C;
					channel3PCM[0x7D] = (data & 0xC) / 0x78;
				}
			}
			this.memoryHighWriter[0x3F] = this.memoryWriter[0xFF3F] = function (address:uint, data:uint):void {
				if (memory[0xFF3F] != data) {
					audioJIT();
					memory[0xFF3F] = data;
					channel3PCM[0x3E] = (data >> 4) / 0x1E;
					channel3PCM[0x5E] = (data >> 5) / 0x1E;
					channel3PCM[0x7E] = (data >> 6) / 0x1E;
					channel3PCM[0x3F] = (data & 0xF) / 0x1E;
					channel3PCM[0x5F] = (data & 0xE) / 0x3C;
					channel3PCM[0x7F] = (data & 0xC) / 0x78;
				}
			}
			this.memoryHighWriter[0x42] = this.memoryWriter[0xFF42] = function (address:uint, data:uint):void {
				if (backgroundY != data) {
					midScanLineJIT();
					backgroundY = data;
				}
			}
			this.memoryHighWriter[0x43] = this.memoryWriter[0xFF43] = function (address:uint, data:uint):void {
				if (backgroundX != data) {
					midScanLineJIT();
					backgroundX = data;
				}
			}
			this.memoryHighWriter[0x44] = this.memoryWriter[0xFF44] = function (address:uint, data:uint):void {
				if (LCDisOn) {
					modeSTAT = 2;
					midScanlineOffset = -1;
					totalLinesPassed = currentX = queuedScanLines = lastUnrenderedLine = LCDTicks = STATTracker = actualScanLine = memory[0xFF44] = 0;
				}
			}
			this.memoryHighWriter[0x45] = this.memoryWriter[0xFF45] = function (address:uint, data:uint):void {
				if (memory[0xFF45] != data) {
					memory[0xFF45] = data;
					if (LCDisOn) {
						matchLYC();
					}
				}
			}
			this.memoryHighWriter[0x4A] = this.memoryWriter[0xFF4A] = function (address:uint, data:uint):void {
				if (windowY != data) {
					midScanLineJIT();
					windowY = data;
				}
			}
			this.memoryHighWriter[0x4B] = this.memoryWriter[0xFF4B] = function (address:uint, data:uint):void {
				if (memory[0xFF4B] != data) {
					midScanLineJIT();
					memory[0xFF4B] = data;
					windowX = data - 7;
				}
			}
			memoryHighWriter[0x72] = this.memoryWriter[0xFF72] = function (address:uint, data:uint):void {
				memory[0xFF72] = data;
			}
			this.memoryHighWriter[0x73] = this.memoryWriter[0xFF73] = function (address:uint, data:uint):void {
				memory[0xFF73] = data;
			}
			this.memoryHighWriter[0x75] = this.memoryWriter[0xFF75] = function (address:uint, data:uint):void {
				memory[0xFF75] = data;
			}
			this.memoryHighWriter[0x76] = this.memoryWriter[0xFF76] = this.cartIgnoreWrite;
			this.memoryHighWriter[0x77] = this.memoryWriter[0xFF77] = this.cartIgnoreWrite;
			this.memoryHighWriter[0xFF] = this.memoryWriter[0xFFFF] = function (address:uint, data:uint):void {
				interruptsEnabled = data;
				checkIRQMatching();
			}
			this.recompileModelSpecificIOWriteHandling();
			this.recompileBootIOWriteHandling();
		}
		
		public	function recompileModelSpecificIOWriteHandling():void
		{
			if (this.cGBC) {
				this.memoryHighWriter[0x2] = this.memoryWriter[0xFF02] = function (address:uint, data:uint):void {
					if (((data & 0x1) == 0x1)) {
						memory[0xFF02] = (data & 0x7F);
						serialTimer = ((data & 0x2) == 0) ? 4096 : 128;
						serialShiftTimer = serialShiftTimerAllocated = ((data & 0x2) == 0) ? 512 : 16;
					}
					else {
						memory[0xFF02] = data;
						serialShiftTimer = serialShiftTimerAllocated = serialTimer = 0;
					}
				}
				this.memoryHighWriter[0x40] = this.memoryWriter[0xFF40] = function (address:uint, data:uint):void {
					if (memory[0xFF40] != data) {
						midScanLineJIT();
						var temp_var:uint = (data > 0x7F);
						if (temp_var != LCDisOn) {
							LCDisOn = temp_var;
							memory[0xFF41] &= 0x78;
							midScanlineOffset = -1;
							totalLinesPassed = currentX = queuedScanLines = lastUnrenderedLine = STATTracker = LCDTicks = actualScanLine = memory[0xFF44] = 0;
							if (LCDisOn) {
								modeSTAT = 2;
								matchLYC();
								LCDCONTROL = LINECONTROL;
							}
							else {
								modeSTAT = 0;
								LCDCONTROL = DISPLAYOFFCONTROL;
								DisplayShowOff();
							}
							interruptsRequested &= 0xFD;
						}
						gfxWindowCHRBankPosition = ((data & 0x40) == 0x40) ? 0x400 : 0;
						gfxWindowDisplay = ((data & 0x20) == 0x20);
						gfxBackgroundBankOffset = ((data & 0x10) == 0x10) ? 0 : 0x80;
						gfxBackgroundCHRBankPosition = ((data & 0x08) == 0x08) ? 0x400 : 0;
						gfxSpriteNormalHeight = ((data & 0x04) == 0);
						gfxSpriteShow = ((data & 0x02) == 0x02);
						BGPriorityEnabled = ((data & 0x01) == 0x01);
						priorityFlaggingPathRebuild();
						memory[0xFF40] = data;
					}
				}
				this.memoryHighWriter[0x41] = this.memoryWriter[0xFF41] = function (address:uint, data:uint):void {
					LYCMatchTriggerSTAT = ((data & 0x40) == 0x40);
					mode2TriggerSTAT = ((data & 0x20) == 0x20);
					mode1TriggerSTAT = ((data & 0x10) == 0x10);
					mode0TriggerSTAT = ((data & 0x08) == 0x08);
					memory[0xFF41] = data & 0x78;
				}
				this.memoryHighWriter[0x46] = this.memoryWriter[0xFF46] = function (address:uint, data:uint):void {
					memory[0xFF46] = data;
					if (data < 0xE0) {
						data <<= 8;
						address = 0xFE00;
						var stat:uint = modeSTAT;
						modeSTAT = 0;
						var newData:uint = 0;
						do {
							newData = memoryReader[data](data++);
							if (newData != memory[address]) {
								modeSTAT = stat;
								graphicsJIT();
								modeSTAT = 0;
								memory[address++] = newData;
								break;
							}
						} while (++address < 0xFEA0);
						if (address < 0xFEA0) {
							do {
								memory[address++] = memoryReader[data](data++);
								memory[address++] = memoryReader[data](data++);
								memory[address++] = memoryReader[data](data++);
								memory[address++] = memoryReader[data](data++);
							} while (address < 0xFEA0);
						}
						modeSTAT = stat;
					}
				}
				this.memoryHighWriter[0x4D] = this.memoryWriter[0xFF4D] = function (address:uint, data:uint):void {
					memory[0xFF4D] = (data & 0x7F) | (memory[0xFF4D] & 0x80);
				}
				this.memoryHighWriter[0x4F] = this.memoryWriter[0xFF4F] = function (address:uint, data:uint):void {
					currVRAMBank = data & 0x01;
					if (currVRAMBank > 0) {
						BGCHRCurrentBank = BGCHRBank2;
					}
					else {
						BGCHRCurrentBank = BGCHRBank1;
					}
				}
				this.memoryHighWriter[0x51] = this.memoryWriter[0xFF51] = function (address:uint, data:uint):void {
					if (!hdmaRunning) {
						memory[0xFF51] = data;
					}
				}
				this.memoryHighWriter[0x52] = this.memoryWriter[0xFF52] = function (address:uint, data:uint):void {
					if (!hdmaRunning) {
						memory[0xFF52] = data & 0xF0;
					}
				}
				this.memoryHighWriter[0x53] = this.memoryWriter[0xFF53] = function (address:uint, data:uint):void {
					if (!hdmaRunning) {
						memory[0xFF53] = data & 0x1F;
					}
				}
				this.memoryHighWriter[0x54] = this.memoryWriter[0xFF54] = function (address:uint, data:uint):void {
					if (!hdmaRunning) {
						memory[0xFF54] = data & 0xF0;
					}
				}
				this.memoryHighWriter[0x55] = this.memoryWriter[0xFF55] = function (address:uint, data:uint):void {
					if (!hdmaRunning) {
						if ((data & 0x80) == 0) {
							DMAWrite((data & 0x7F) + 1);
							memory[0xFF55] = 0xFF;
						}
						else {
							hdmaRunning = true;
							memory[0xFF55] = data & 0x7F;
						}
					}
					else if ((data & 0x80) == 0) {
						hdmaRunning = false;
						memory[0xFF55] |= 0x80;
					}
					else {
						memory[0xFF55] = data & 0x7F;
					}
				}
				this.memoryHighWriter[0x68] = this.memoryWriter[0xFF68] = function (address:uint, data:uint):void {
					memory[0xFF69] = gbcBGRawPalette[data & 0x3F];
					memory[0xFF68] = data;
				}
				this.memoryHighWriter[0x69] = this.memoryWriter[0xFF69] = function (address:uint, data:uint):void {
					updateGBCBGPalette(memory[0xFF68] & 0x3F, data);
					if (memory[0xFF68] > 0x7F) {
						var next:uint = ((memory[0xFF68] + 1) & 0x3F);
						memory[0xFF68] = (next | 0x80);
						memory[0xFF69] = gbcBGRawPalette[next];
					}
					else {
						memory[0xFF69] = data;
					}
				}
				this.memoryHighWriter[0x6A] = this.memoryWriter[0xFF6A] = function (address:uint, data:uint):void {
					memory[0xFF6B] = gbcOBJRawPalette[data & 0x3F];
					memory[0xFF6A] = data;
				}
				this.memoryHighWriter[0x6B] = this.memoryWriter[0xFF6B] = function (address:uint, data:uint):void {
					updateGBCOBJPalette(memory[0xFF6A] & 0x3F, data);
					if (memory[0xFF6A] > 0x7F) {
						var next:uint = ((memory[0xFF6A] + 1) & 0x3F);
						memory[0xFF6A] = (next | 0x80);
						memory[0xFF6B] = gbcOBJRawPalette[next];
					}
					else {
						memory[0xFF6B] = data;
					}
				}
				this.memoryHighWriter[0x70] = this.memoryWriter[0xFF70] = function (address:uint, data:uint):void {
					var addressCheck:uint = (memory[0xFF51] << 8) | memory[0xFF52];
					if (!hdmaRunning || addressCheck < 0xD000 || addressCheck >= 0xE000) {
						gbcRamBank = Math.max(data & 0x07, 1);
						gbcRamBankPosition = ((gbcRamBank - 1) << 12) - 0xD000;
						gbcRamBankPositionECHO = gbcRamBankPosition - 0x2000;
					}
					memory[0xFF70] = data;
				}
				this.memoryHighWriter[0x74] = this.memoryWriter[0xFF74] = function (address:uint, data:uint):void {
					memory[0xFF74] = data;
				}
			}
			else {
				this.memoryHighWriter[0x2] = this.memoryWriter[0xFF02] = function (address:uint, data:uint):void {
					if (((data & 0x1) == 0x1)) {
						memory[0xFF02] = (data & 0x7F);
						serialTimer = 4096;
						serialShiftTimer = serialShiftTimerAllocated = 512;
					}
					else {
						memory[0xFF02] = data;
						serialShiftTimer = serialShiftTimerAllocated = serialTimer = 0;
					}
				}
				this.memoryHighWriter[0x40] = this.memoryWriter[0xFF40] = function (address:uint, data:uint):void {
					if (memory[0xFF40] != data) {
						midScanLineJIT();
						var temp_var:uint = (data > 0x7F);
						if (temp_var != LCDisOn) {
							LCDisOn = temp_var;
							memory[0xFF41] &= 0x78;
							midScanlineOffset = -1;
							totalLinesPassed = currentX = queuedScanLines = lastUnrenderedLine = STATTracker = LCDTicks = actualScanLine = memory[0xFF44] = 0;
							if (LCDisOn) {
								modeSTAT = 2;
								matchLYC();
								LCDCONTROL = LINECONTROL;
							}
							else {
								modeSTAT = 0;
								LCDCONTROL = DISPLAYOFFCONTROL;
								DisplayShowOff();
							}
							interruptsRequested &= 0xFD;
						}
						gfxWindowCHRBankPosition = ((data & 0x40) == 0x40) ? 0x400 : 0;
						gfxWindowDisplay = (data & 0x20) == 0x20;
						gfxBackgroundBankOffset = ((data & 0x10) == 0x10) ? 0 : 0x80;
						gfxBackgroundCHRBankPosition = ((data & 0x08) == 0x08) ? 0x400 : 0;
						gfxSpriteNormalHeight = ((data & 0x04) == 0);
						gfxSpriteShow = (data & 0x02) == 0x02;
						bgEnabled = ((data & 0x01) == 0x01);
						memory[0xFF40] = data;
					}
				}
				this.memoryHighWriter[0x41] = this.memoryWriter[0xFF41] = function (address:uint, data:uint):void {
					LYCMatchTriggerSTAT = ((data & 0x40) == 0x40);
					mode2TriggerSTAT = ((data & 0x20) == 0x20);
					mode1TriggerSTAT = ((data & 0x10) == 0x10);
					mode0TriggerSTAT = ((data & 0x08) == 0x08);
					memory[0xFF41] = data & 0x78;
					if ((!usedBootROM || !usedGBCBootROM) && LCDisOn && modeSTAT < 2) {
						interruptsRequested |= 0x2;
						checkIRQMatching();
					}
				}
				this.memoryHighWriter[0x46] = this.memoryWriter[0xFF46] = function (address:uint, data:uint):void {
					memory[0xFF46] = data;
					if (data > 0x7F && data < 0xE0) {
						data <<= 8;
						address = 0xFE00;
						var stat:uint = modeSTAT;
						modeSTAT = 0;
						var newData:uint = 0;
						do {
							newData = memoryReader[data](data++);
							if (newData != memory[address]) {
								modeSTAT = stat;
								graphicsJIT();
								modeSTAT = 0;
								memory[address++] = newData;
								break;
							}
						} while (++address < 0xFEA0);
						if (address < 0xFEA0) {
							do {
								memory[address++] = memoryReader[data](data++);
								memory[address++] = memoryReader[data](data++);
								memory[address++] = memoryReader[data](data++);
								memory[address++] = memoryReader[data](data++);
							} while (address < 0xFEA0);
						}
						modeSTAT = stat;
					}
				}
				this.memoryHighWriter[0x47] = this.memoryWriter[0xFF47] = function (address:uint, data:uint):void {
					if (memory[0xFF47] != data) {
						midScanLineJIT();
						updateGBBGPalette(data);
						memory[0xFF47] = data;
					}
				}
				this.memoryHighWriter[0x48] = this.memoryWriter[0xFF48] = function (address:uint, data:uint):void {
					if (memory[0xFF48] != data) {
						midScanLineJIT();
						updateGBOBJPalette(0, data);
						memory[0xFF48] = data;
					}
				}
				this.memoryHighWriter[0x49] = this.memoryWriter[0xFF49] = function (address:uint, data:uint):void {
					if (memory[0xFF49] != data) {
						midScanLineJIT();
						updateGBOBJPalette(4, data);
						memory[0xFF49] = data;
					}
				}
				this.memoryHighWriter[0x4D] = this.memoryWriter[0xFF4D] = function (address:uint, data:uint):void {
					memory[0xFF4D] = data;
				}
				this.memoryHighWriter[0x4F] = this.memoryWriter[0xFF4F] = this.cartIgnoreWrite;
				this.memoryHighWriter[0x55] = this.memoryWriter[0xFF55] = this.cartIgnoreWrite;
				this.memoryHighWriter[0x68] = this.memoryWriter[0xFF68] = this.cartIgnoreWrite;
				this.memoryHighWriter[0x69] = this.memoryWriter[0xFF69] = this.cartIgnoreWrite;
				this.memoryHighWriter[0x6A] = this.memoryWriter[0xFF6A] = this.cartIgnoreWrite;
				this.memoryHighWriter[0x6B] = this.memoryWriter[0xFF6B] = this.cartIgnoreWrite;
				this.memoryHighWriter[0x6C] = this.memoryWriter[0xFF6C] = this.cartIgnoreWrite;
				this.memoryHighWriter[0x70] = this.memoryWriter[0xFF70] = this.cartIgnoreWrite;
				this.memoryHighWriter[0x74] = this.memoryWriter[0xFF74] = this.cartIgnoreWrite;
			}
		}
		
		public	function recompileBootIOWriteHandling():void
		{
			if (this.inBootstrap) {
				this.memoryHighWriter[0x50] = this.memoryWriter[0xFF50] = function (address:uint, data:uint):void {
					trace("Boot ROM reads blocked: Bootstrap process has ended.", 0);
					inBootstrap = false;
					disableBootROM();
					memory[0xFF50] = data;
				}
				if (this.cGBC) {
					this.memoryHighWriter[0x6C] = this.memoryWriter[0xFF6C] = function (address:uint, data:uint):void {
						if (inBootstrap) {
							cGBC = ((data & 0x1) == 0);
							if (name + gameCode + ROM[0x143] == "Game and Watch 50") {
								cGBC = true;
								trace("Created a boot exception for Game and Watch Gallery 2 (GBC ID byte is wrong on the cartridge).", 1);
							}
							trace("Booted to GBC Mode: " + cGBC.toString(), 0);
						}
						memory[0xFF6C] = data;
					}
				}
			}
			else {
				this.memoryHighWriter[0x50] = this.memoryWriter[0xFF50] = this.cartIgnoreWrite;
			}
		}
		
/*		public	function toTypedArray(baseArray:Vector.<uint>, memtype:String):*
		{
			var typedArrayTemp:*;
			
			try {
				if (settings.disallowTypedArray) {
					return baseArray;
				}
				if (!baseArray || !baseArray.length) {
					return [];
				}
				var length:uint = baseArray.length;
				switch (memtype) {
					case "uint8":
						typedArrayTemp = new Vector.<uint>(length);
						break;
					case "int32":
						typedArrayTemp = new Vector.<int>(length);
						break;
					case "float32":
						typedArrayTemp = new Vector.<Number>(length);
				}
				for (var index:uint = 0; index < length; index++) {
					typedArrayTemp[index] = baseArray[index];
				}
				return typedArrayTemp;
			}
			catch (error:Error) {
				trace("Could not convert an array to a typed array: " + error.message, 1);
				return baseArray;
			}
		}*/
		
		public	function getVector(length:uint, defaultValue:*, numberType:String):*
		{
			var result:*;
			switch (numberType) {
				case "uint8":
					result = new Vector.<uint>(length);
					break;
				case "int32":
					result = new Vector.<int>(length);
					break;
				case "float32":
					result = new Vector.<Number>(length);
			}
			
			var i:uint = 0;
			while (i < length) {
				result[i++] = defaultValue;
			}
			return result;
		}
		
		public	function toVector(array:Array, type:String):*
		{
			var result:*;
			switch (type)
			{
				case "uint":
					result = new Vector.<uint>(array.length);
					break;
				case "number":
					result = new Vector.<Number>(array.length);
					break;
				case "function":
					result = new Vector.<Function>(array.length);
					break;
			}
			var i:uint = 0;
			var total:uint = array.length;
			while (i<total)
			{
				result[i] = array[i++];
			}
			return result;
		}
	}
}