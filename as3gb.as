package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.net.FileReference;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.utils.ByteArray;
	
	[SWF(width="160", height="204", frameRate="60", backgroundColor="0x0")]
	public class as3gb extends Sprite
	{
//		[Embed(source="../rom/Kirby.gb", mimeType="application/octet-stream")]
//		[Embed(source="../rom/eur-zosm.gbc", mimeType="application/octet-stream")]
//		[Embed(source="../rom/MGS.gbc", mimeType="application/octet-stream")]
//		[Embed(source="../rom/FFL3.gb", mimeType="application/octet-stream")]
//		[Embed(source="../rom/DQ3K.gbc", mimeType="application/octet-stream")]
//		[Embed(source="../rom/DQ12K.gbc", mimeType="application/octet-stream")]
//		[Embed(source="../rom/DQ3J.gbc", mimeType="application/octet-stream")]
//		[Embed(source="../rom/DQM.gbc", mimeType="application/octet-stream")]
//		[Embed(source="../rom/CVR.gb", mimeType="application/octet-stream")]
//		[Embed(source="../rom/DT.gb", mimeType="application/octet-stream")]
//		[Embed(source="../rom/GG.gbc", mimeType="application/octet-stream")]
//		[Embed(source="../rom/Gradius.gb", mimeType="application/octet-stream")]
		[Embed(source="../rom/Tetris.gb", mimeType="application/octet-stream")]
		private	var ROM:Class;
		
		private	var gbio:GameBoy;
		private	var rom	:ByteArray;
		
		public function as3gb()
		{
			gbio = new GameBoy();
			rom	= new ROM();
			
			addChild(gbio);
			gbio.start(rom);
			
			/**
			 * button for save SRAM
			 */
			addChild(genButton("save sram", 0xFF88FF, new Rectangle(0,144,80,20), function (event:MouseEvent):void{
				var ba:ByteArray = gbio.saveSRAM();
				var f:FileReference = new FileReference();
				if (ba.length>0)
					f.save(ba, "noname.sram");
			}));
			/**
			 * button for load SRAM
			 */
			addChild(genButton("load sram", 0x88FFFF, new Rectangle(80,144,80,20), function (event:MouseEvent):void{
				var f:FileReference = new FileReference();
				f.addEventListener(Event.SELECT, function(event:Event):void{
					f.addEventListener(Event.COMPLETE, function(event:Event):void{
					gbio.openSRAM(f.data);
					});
					f.load();
				});
				f.browse();
			}));
			/**
			 * button for save machine's current state
			 */
			addChild(genButton("save state", 0xFF8888, new Rectangle(0,164,80,20), function (event:MouseEvent):void{
				var ba:ByteArray = gbio.saveState();
				var f:FileReference = new FileReference();
				if (ba.length>0)
					f.save(ba, "noname.state");
			}));
			/**
			 * button for load machine's state
			 */
			addChild(genButton("load state", 0xFFFF88, new Rectangle(80,164,80,20), function (event:MouseEvent):void{
				var f:FileReference = new FileReference();
				f.addEventListener(Event.SELECT, function(event:Event):void{
					f.addEventListener(Event.COMPLETE, function(event:Event):void{
						gbio.openState(f.data, f.name);
					});
					f.load();
				});
				f.browse();
			}));
			/**
			 * button for load ROM
			 */
			addChild(genButton("load ROM(.gb or .gbc) FILE", 0x88FF88, new Rectangle(0,184,160,20), function (event:MouseEvent):void{
				var f:FileReference = new FileReference();
				f.addEventListener(Event.SELECT, function(event:Event):void{
					f.addEventListener(Event.COMPLETE, function(event:Event):void{
						gbio.start(f.data);
					});
					f.load();
				});
				f.browse();
			}));
		}
		
		private	function genButton(label:String, color:uint, rect:Rectangle, handler:Function):Sprite
		{
			var result:Sprite = new Sprite();
			var tf:TextField = new TextField();
			
			tf.autoSize = TextFieldAutoSize.LEFT;
			tf.text = label;
			tf.htmlText = "<a link='..'>" + label + "</a>";
			result.buttonMode = true;
			result.graphics.beginFill(color);
			result.graphics.drawRect(0,0,rect.width,rect.height);
			result.graphics.endFill();
			result.addEventListener(MouseEvent.CLICK, handler);
			result.x = rect.x;
			result.y = rect.y;
			result.addChild(tf);
			return result;
		}

	}
}