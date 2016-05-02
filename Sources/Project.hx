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

import kek.graphics.Sprite;
import kek.G;

class Project {
	var guy:Sprite;
	var font:kha.Font;
	var ui:Zui;
	
	var speed = 1.0;
	var players:Map<Int, entity.Entity>;
		
	var client:network.Client;
	var config:Dynamic;
	var ownEntity:entity.Entity;
	
	var mouseY = 0.0;
	var mouseX = 0.0;
	var mdown = false;
	
	var worldWidth = 0.0;
	var worldHeight = 0.0;
	
	var up = false;
	var down = false;
	var left = false;
	var right = false;
	
	public function new() {
		players = new Map<Int, entity.Entity>();

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
		var i = new Server();
		#end
	
	}
	
	function sendUpdate() {
		if(ownEntity != null){
			client.send({
				id:5,
				x: Std.int(ownEntity.x),
				y: Std.int(ownEntity.y)
			});
		}
	}
	
	private function onMessage(message:Dynamic) {
		switch(message.id) {
			case 0:
				loggedIn(message);
			case 2:
				removePlayer(message.playerId);
			case 3:
				var snapshot:network.Messages.FrameSnapshot = cast message;
				parseSnapshot(snapshot);
		}
	}
	
	function loggedIn(message:Dynamic) {
		var e = new entity.Entity(message.playerId, true);
		worldWidth = message.worldWidth;
		worldHeight = message.worldHeight;
		e.x = message.x;
		e.y = message.y;
		players.set(e.id, e);
		G.camera.centerOn(e.x, e.y);
		ownEntity = e;
	}
	
	function removePlayer(id:Int){
		players.remove(id);
	}
	
	function parseSnapshot(f:network.Messages.FrameSnapshot) {
		for(player in f.data) {
			var p = players.get(player.id);
			if(p == null){
				p = new entity.Entity(player.id);
				p.x = player.x;
				p.y = player.y;
				players.set(p.id, p);
			}
			
			if(p != ownEntity){
				p.tx = player.x;
				p.ty = player.y;
			}
		}
	}

	
	function loaded(){
		guy = new Sprite();
		guy.loadGraphics(Assets.images.guy, 32, 32);
		
		entity.Entity.sprite = guy;
		
		var o = Assets.blobs.game_json;
		config = Json.parse(o.toString());

		speed = config.walkSpeed;
		
		font = Assets.fonts.RobotoCondensed_Regular;
		ui = new Zui(font, 17, 16, 0, 2.0);
		System.notifyOnRender(render);
		kha.input.Mouse.get().notify(onMouseDown, onMouseUp, onMouseMove, null);
		kha.input.Keyboard.get().notify(onKeyDown, onKeyUp);
		if(Gamepad.get() != null){
			Gamepad.get().notify(axis, button);
		}
			
		#if (sys_debug_html5 || sys_html5)
		client = new network.Client(onMessage);
		client.connect(config.serverAddress, function(e:Dynamic) {
			trace("I am connected!");
			Scheduler.addTimeTask(sendUpdate, 0, 1 / 20);
		});
		#end
	}
	
	function onKeyDown(k:kha.Key, i:String):Void {
		if(k == kha.Key.BACK){
			//System.requestShutdown();
		}
		
		switch(k) {
			case kha.Key.LEFT:
				left = true;
			case kha.Key.RIGHT:
				right = true;
			case kha.Key.UP:
				up = true;
			case kha.Key.DOWN:
				down = true;
			default:
		}
		
		if(k == kha.Key.CHAR){
			switch (i) {
				case "a": 
					left = true;
				case "d":
					right = true;
				case "w":
					up = true;
				case "s":
					down = true;
			}
		}
	}
	
	function onKeyUp(k:kha.Key, i:String):Void {
		if(k == kha.Key.BACK){
			//System.requestShutdown();
		}
		
		switch(k) {
			case kha.Key.LEFT:
				left = false;
			case kha.Key.RIGHT:
				right = false;
			case kha.Key.UP:
				up = false;
			case kha.Key.DOWN:
				down = false;
			default:
		}
		
		if(k == kha.Key.CHAR){
			switch (i) {
				case "a": 
					left = false;
				case "d":
					right = false;
				case "w":
					up = false;
				case "s":
					down = false;
			}
		}
	}
	
	function button(button:Int, i:Float):Void {
		trace("Button: " + button + ", v: "+ i);
	}
	
	function axis(axis:Int, value:Float):Void {
		
	}
	
	public function onMouseDown(button:Int, x: Int, y: Int) {
    	mdown = true;
	}
	
	public function onMouseUp(button:Int, x: Int, y: Int) {
    	mdown = false;
	}
	
	public function onMouseMove(x: Int, y: Int, movementX: Int, movementY: Int) {
    	mouseY = y;
		mouseX = x;
	}

	var ay = 0.0;
	var canJump = false;
	function update(): Void {
		for(e in players) {
			e.update();
		}
		
		if(ownEntity != null){
			var vx = 0.0;
			var vy = 0.0;
			ay += 0.2;
			if(mdown && false){
				var p = G.camera.screenToWorld(mouseX, mouseY);
				vx = p.x - ownEntity.x;
				vy = p.y - ownEntity.y;
				
				var l = Math.sqrt(vx * vx + vy * vy);
				vx /= l;
				vy /= l;
				
				vx *= speed;
				vy *= speed;
			}else{
				if(down){
					//vy += speed;
				}
				if(up){
					//vy -= speed;
				}
				
				if(right){
					vx += speed;
				}
				if(left){
					vx -= speed;
				}
			}
			
			if(canJump && up){
				ay = -10;
				canJump = false;
			}
			
			vy += ay;
			
			ownEntity.x += vx;
			ownEntity.y += vy;
			
			ownEntity.x = Math.max(32, ownEntity.x);
			ownEntity.y = Math.max(32, ownEntity.y);
			
			ownEntity.x = Math.min(worldWidth - 32, ownEntity.x);
			
			ownEntity.y = Math.min(worldHeight - 32, ownEntity.y);
			
			if(ownEntity.y > worldHeight - 33) {
				ay = 0;
				if(vy >= 0){
					canJump = true;
				}
			}
			
			G.camera.moveTowards(ownEntity.x, ownEntity.y);
		}
	}
	
	function render(framebuffer: Framebuffer): Void {		
		var fb = framebuffer.g2;
		fb.begin(0xff03A9F4);
		fb.color = 0xffffffff;
		var title = "";
		if(ownEntity != null){
			title += "(x: " + Std.int(ownEntity.x) + ", y: " + Std.int(ownEntity.y) + ")";
		}
		var h = Std.int(System.windowHeight() / 25);
		var w = font.width(h, title);
		
		framebuffer.g2.font = font;
		fb.fontSize = h;
		for(player in players) {
			player.render(fb);
		}
		
		
		
		framebuffer.g2.drawString(title, 25, 20);
		
		fb.color = kha.Color.White;
		fb.drawRect(0 - G.camera.ox, 0 - G.camera.oy, worldWidth, worldHeight, 4);
		
		fb.end();
		/*
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
		*/
	}
}
