package com.mobswing.gb
{
 import flash.display.Sprite;
 import flash.display.Stage;
 import flash.events.Event;
 import flash.events.EventDispatcher;
 import flash.events.KeyboardEvent;
 import flash.events.MouseEvent;
 import flash.utils.getTimer;
 
 public class PseudoThread extends EventDispatcher
 {
 	private	static var hash:Object;
 	public	static function getThread(id:String):PseudoThread
 	{
 		return hash[id] as PseudoThread;
 	}
 	
	public	var RENDER_DEDUCTION:int = 1;

	private var sm		:Stage;
	private var fn		:Function;
	private var obj		:Object;
	private var thread	:Sprite;
	private var start	:Number;
	private var fr		:Number;
	private var due		:Number;

	private var locked	:Boolean;
	private var alive	:Boolean = true;
	 
	 public function PseudoThread(sm:Stage, threadFunction:Function, threadObject:Object, id:String)
	 {
	 	this.sm = sm;
		fn = threadFunction;
		obj = threadObject;
		locked = false;

		sm.addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 100);

		thread = new Sprite();
		sm.addChild(thread);
		thread.addEventListener(Event.RENDER, renderHandler);
		
		fr = Math.floor(1000 / thread.stage.frameRate);
		
		if (hash == null) hash = new Object();
		hash[id] = this;
	 }
	 
	 public	function isAlive():Boolean
	 {
	 	return this.alive;
	 }

	public	function lock():void
	{
		this.locked = true;
	}

	public	function unlock():void
	{
		this.locked = false;
	}

	 private function enterFrameHandler(event:Event):void
	 {
		due = getTimer() + fr;
		thread.stage.invalidate();
		thread.graphics.clear();
		thread.graphics.moveTo(0, 0);
		thread.graphics.lineTo(0, 0);	
	 }

	 private function renderHandler(event:Event):void
	 {
		while (getTimer() < due)
		{
			if (this.locked)
				continue;
			 
			if (!fn(obj))
			{
				if (!thread.parent)
					return;

				destroy();
			} 
		}
	 }
	 
	public	function destroy():void
	 {
		sm.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
		sm.removeChild(thread);
		thread.removeEventListener(Event.RENDER, renderHandler);
		this.alive = false;
		dispatchEvent(new Event(Event.COMPLETE));
	 }
 } 
}
