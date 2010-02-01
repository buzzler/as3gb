package com.mobswing.gb
{
	import __AS3__.vec.Vector;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.system.System;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;

	public class As3gb extends Sprite
	{
		private var joystick	:Object;
		private var paused		:Boolean;
	    private var cpuThread	:PseudoThread;
		
		public	function As3gb(cart:Cartridge)
		{
			super();
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
			this.addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
			
			setDemensions();
			setCartridge(cart);
			setJoystick(Keyboard.RIGHT, Keyboard.LEFT, Keyboard.UP, Keyboard.DOWN, 88, 90, Keyboard.SHIFT, Keyboard.ENTER);

			Globals.gb = this;
			Globals.cpu= new CPU();
		}
		
		private	function setDemensions():void
		{
			this.graphics.beginFill(0xFFFFFF, 1);
			this.graphics.drawRect(0,0,Globals.RES_WIDTH,Globals.RES_HEIGHT);
			this.graphics.endFill();
		}
		
		private function onAdded(event:Event):void
		{
			this.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			this.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			
			this.startEmulation();
		}
		
		private	function onRemoved(event:Event):void
		{
			this.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			this.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			
			this.stopEmulation();
		}
		
		private	function onKeyDown(event:KeyboardEvent):void
		{
			if (joystick[event.keyCode.toString()] != undefined)
			{
				Globals.cpu.buttonDown(joystick[event.keyCode.toString()]);
			}
		}
		
		private	function onKeyUp(event:KeyboardEvent):void
		{
			if (joystick[event.keyCode.toString()] != undefined)
			{
				Globals.cpu.buttonUp(joystick[event.keyCode.toString()]);
			}
		}
		
		private	function setJoystick(r:int, l:int, u:int, d:int, a:int, b:int, select:int, start:int):void
		{
			joystick = new Object();
			joystick[r.toString()		] = 0;
			joystick[l.toString()		] = 1;
			joystick[u.toString()		] = 2;
			joystick[d.toString()		] = 3;
			joystick[a.toString()		] = 4;
			joystick[b.toString()		] = 5;
			joystick[select.toString()	] = 6;
			joystick[start.toString()	] = 7;
		}
		
		public	function setCartridge(cart:Cartridge):void
		{
			Globals.cartridge = cart;
		}
		
		public	function startEmulation():void
		{
			Globals.cpu.beforeLoop();
			cpuThread = new PseudoThread(this.stage, Globals.cpu.loop, null, 'CPU');
		}
		
		public	function stopEmulation():void
		{
			if (Globals.cpu.hasBattery())
				saveCartridgeRam();
		}
		
		public	function pauseEmulation():void
		{
			if (cpuThread == null)
				return;
			
			paused = true;
			
			Globals.cpu.terminate();
			while(cpuThread.isAlive()) {
//				Thread.yield();
			}
			cpuThread = null;
		}
		
		public	function resumeEmulation():void
		{
			paused = false;
			Globals.cpu.beforeLoop();
			cpuThread = new PseudoThread(this.stage, Globals.cpu.loop, null, 'CPU');
		}
		
		public	function paint():void
		{
			if (Globals.cpu == null)
				return;
			
			if (Globals.ppu.frameBuffer == null)
			{
				this.graphics.beginFill(0xaaaaaa);
			}
			else
			{
				this.graphics.beginBitmapFill(Globals.ppu.frameBuffer);
			}

			this.graphics.drawRect(0,0, Globals.RES_WIDTH, Globals.RES_HEIGHT);
			this.graphics.endFill();
			Globals.ppu.notifyRepainted();
		}

		public	function saveCartridgeRam():ByteArray
		{
			var ram:Vector.<ByteArrayAdvanced> = Globals.cpu.getCartRam();
			
			var bankCount:int = ram.length;
			var bankSize:int = ram[0].length;
			var size:int = bankCount * bankSize + 13;
			
			var b:ByteArray = new ByteArray();
			b.length = size;
			
			for each (var bank:ByteArrayAdvanced in ram)
			{
				b.writeBytes(bank);
			}
			b.writeBytes(Globals.cpu.getRtcReg(), 0, 5);

			var now:Number = SystemTimer.getCurrentTimeMillis();
			b.writeDouble(now);

			return b;
		}
		
		public	function loadCartridgeRam(b:ByteArray):void
		{
			var ram:Vector.<ByteArrayAdvanced> = Globals.cpu.getCartRam();
			
			var bankCount:int = ram.length;
			var bankSize:int = ram[0].length;
			
			var i:int = 0;
			for each (var bank:ByteArrayAdvanced in ram)
			{
				bank.position = 0;
				bank.writeBytes(b, i * bankSize, bankSize);
			}

			if (b.length == bankCount * bankSize + 13)
			{
				var rtcReg:ByteArrayAdvanced = Globals.cpu.getRtcReg();
				rtcReg.position = 0;
				rtcReg.writeBytes(b, bankCount*bankSize, 5);

				b.position = bankCount * bankSize + 5;
				var time:Number = b.readDouble();
				time = SystemTimer.getCurrentTimeMillis() - time;
				Globals.cpu.rtcSkip(int(time / 1000));
			}
		}
		
		public	function releaseReferences():void
		{
			Globals.cpu.terminate();
			while(cpuThread != null && cpuThread.isAlive())
			{
//				Thread.yield();
			}
			Globals.cpu.releaseReferences();
			Globals.cpu = null;

			System.gc();
		}
	}
}