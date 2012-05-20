package
{
	import flash.ui.Keyboard;

	public class Setting
	{
		public	var enableSound			:Boolean;	//Turn on sound.
		public	var forceMonoSound		:Boolean;	//Force Mono sound.
		public	var priorityGameBoy		:Boolean;	//Give priority to GameBoy mode
		public	var right				:uint;
		public	var left				:uint;
		public	var up					:uint;
		public	var down				:uint;
		public	var a					:uint;
		public	var b					:uint;
		public	var select				:uint;
		public	var start				:uint;
		public	var colorizeGameBoy		:Boolean;	//Colorize GB mode?
		public	var disallowTypedArray	:Boolean;	//Disallow typed arrays?
		public	var emulatorInterval	:Number;	//Interval for the emulator loop.
		public	var minAudioIteration	:Number;	//Audio buffer minimum span amount over x interpreter iterations.
		public	var maxAudioIteration	:Number;	//Audio buffer maximum span amount over x interpreter iterations.
		public	var overrideMBC1		:Boolean;	//Override to allow for MBC1 instead of ROM only (compatibility for broken 3rd-party cartridges).
		public	var overrideMBC			:Boolean;	//Override MBC RAM disabling and always allow reading and writing to the banks.
		public	var useGBCBios			:Boolean;	//Use the GBC BIOS?
		public	var useGBBootROM		:Boolean;	//Use the GameBoy boot ROM instead of the GameBoy Color boot ROM.
		public	var sampleRate			:Number;	//Sample Rate
		public	var volume				:Number;	//Volume level set.
		
		public function Setting()
		{
			this.enableSound		= true;
			this.forceMonoSound		= false;
			this.priorityGameBoy	= false;
			this.right				= Keyboard.RIGHT;
			this.left				= Keyboard.LEFT;
			this.up					= Keyboard.UP;
			this.down				= Keyboard.DOWN;
			this.a					= Keyboard.PERIOD;
			this.b					= Keyboard.COMMA;
			this.select				= Keyboard.SHIFT;
			this.start				= Keyboard.ENTER;
			this.colorizeGameBoy	= false;
			this.disallowTypedArray	= false;
			this.emulatorInterval	= 10;
			this.minAudioIteration	= 10;
			this.maxAudioIteration	= 25;
			this.overrideMBC1		= false;
			this.overrideMBC		= false;
			this.useGBCBios			= true;
			this.useGBBootROM		= false;
			this.sampleRate			= 0x40000;
			this.volume				= 1;
		}
		
		public	function matchKey(key:uint):int
		{
			switch (key)
			{
			case this.right:
				return 0;
			case this.left:
				return 1;
			case this.up:
				return 2;
			case this.down:
				return 3;
			case this.a:
				return 4;
			case this.b:
				return 5;
			case this.select:
				return 6;
			case this.start:
				return 7;
			default:
				return -1;
			}
		}
	}
}