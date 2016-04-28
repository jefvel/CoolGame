package;

import kha.Framebuffer;
import kha.Scheduler;
import kha.System;
import kha.Image;
import kha.Assets;
import haxe.Json;

import zui.Zui;
import zui.Id;
import zui.Ext;

import kha.input.Gamepad;

import graphics.Sprite;

class Project {
	var guy:Sprite;
	var font:kha.Font;
	var ui:Zui;
	
	var curGuy:Int = 0;
	var sprites:Array<Sprite>;
	
	public function new() {
		sprites = new Array<Sprite>();

		Scheduler.addTimeTask(update, 0, 1 / 60);
		Assets.loadEverything(loaded);
		
		System.notifyOnApplicationState(
			function() {}, 
			function() {}, 
			function() {}, 
			function() {}, 
			function() {
				trace("KHA DYING!");
		});
		
		
		#if sys_windows
		//var i = new Server();
		#end
	}
	
	var config:Dynamic;
	var o:Sprite;
	var x = 0.0;
	var y = 0.0;
	var ox = 0.0;
	var oy = 0.0;
	var px = 0.0;
	var py = 0.0;
	
	var  tx = 0.0;
	var ty = 0.0;
	
	function loaded(){
		for(i in 0...1){
			guy = new Sprite(Assets.images.guy);
			guy.x = -100;
			guy.y = -100;
			
			guy.anchorX = 0.5;
			guy.anchorY = 0.5;
			sprites.push(guy);
		}
		
		o = new Sprite();
		var o = Assets.blobs.game_json;
		config = Json.parse(o.toString());
		name = config.username;
		font = Assets.fonts.RobotoCondensed_Regular;
		ui = new Zui(font, 17, 16, 0, 2.0);
		System.notifyOnRender(render);
		kha.input.Mouse.get().notify(onMouseDown, null, onMouseMove, null);
		kha.input.Keyboard.get().notify(onKeyDown, onKeyUp);
		if(Gamepad.get() != null){
			Gamepad.get().notify(axis, button);
		}
	}
	
	function onKeyDown(k:kha.Key, i:String):Void {
		if(k == kha.Key.BACK){
			y -= 50;
			//System.requestShutdown();
		}

	}
	
	function onKeyUp(k:kha.Key, i:String):Void {
		if(k == kha.Key.BACK){
			y += 150;
			//System.requestShutdown();
		}
	}
	
	function button(button:Int, i:Float):Void {
		trace("Button: " + button + ", v: "+ i);
	}
	
	function axis(axis:Int, value:Float):Void {
		//trace("Axis: " + axis + ", v: "+ value);
		switch(axis){
			case 0: 
				ox = value;
			case 1:
				oy = -value;
		}
	}
	var mouseY = 0.0;
	public function onMouseDown(button:Int, x: Int, y: Int) {
    }
	
	public function onMouseMove(x: Int, y: Int, movementX: Int, movementY: Int) {
    	mouseY = y;
		tx = x;
		ty = y;
    }

	function update(): Void {
		//trace("U");
		var l = Math.sqrt(ox * ox + oy * oy);
		if(l > 0.3){
			x += ox * 0.9;
			y += oy * 0.9;
		}
		
		x += (tx - px) * 0.06;
		y += (ty - py) * 0.06;
		
		x *= 0.9;
		y *= 0.9;
		
		px += x;
		py += y;

		
		if(sprites.length > 0){
			curGuy++;
			curGuy = curGuy % sprites.length;
			sprites[curGuy].x = px;
			sprites[curGuy].y = py;
		}
	}
	
	var i = 0.0;
	var name = "Olle";
	var checked = true;
	var colors = [0xffD32F2F, 0xff9C27B0, 0xff03A9F4];
	var curC = 2;
	function render(framebuffer: Framebuffer): Void {
		i = kha.System.time * 1.5;
		
		var fb = framebuffer.g2;
		fb.begin(colors[curC]);
		fb.color = 0xffffffff;
		if(checked){

			for(goy in sprites){
				goy.draw(framebuffer);
			}
			//fb.drawScaledSubImage(image, Std.int(i) * 32, 0, 32, 32, x, y, 128, 128);
		}
	
		var title = "Super Tech Demo";
		var h = Std.int(System.windowHeight() / 15);
		var w = font.width(h, title);
		
		framebuffer.g2.font = font;
		fb.fontSize = h;
		framebuffer.g2.drawString(title, (System.windowWidth() - w) / 2,  (System.windowHeight() - h) / 2 + Math.cos(i) * 8);
		
		fb.end();
		if(mouseY > System.windowHeight() - 220){
			ui.begin(fb);
			
			// window() returns true if redraw is needed - windows are cached into textures
			if (ui.window(Id.window(), Std.int(System.windowWidth() / 2) - 200, Std.int(System.windowHeight() - 220), 400, 200)) {
				name = ui.textInput(Id.textInput(), name, "Username");
				ui.row([0.5, 0.5]);
				checked = ui.check(Id.check(), "Extra Cool", checked);
				ui.check(Id.check(), "Fart", true);
				if(ui.button("Play!")){
					kha.input.Mouse.get().hideSystemCursor();
				}
			}
			
			ui.end();
		}
	}
}
