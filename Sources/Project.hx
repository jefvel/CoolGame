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

import graphics.Sprite;

class Project {
	var image:Image;
	var font:kha.Font;
	var ui:Zui;
	
	public function new() {
		Scheduler.addTimeTask(update, 0, 1 / 120);
		Assets.loadEverything(loaded);
	}
	
	var config:Dynamic;
	var o:Sprite;
	
	function loaded(){
		o = new Sprite();
		var o = Assets.blobs.game_json;
		config = Json.parse(o.toString());
		image = Assets.images.guy;
		font = Assets.fonts.RobotoCondensed_Regular;
		ui = new Zui(font, 17, 16, 0, 2.0);
		System.notifyOnRender(render);
	}

	function update(): Void {
		
	}

	var i = 0.0;
	var name = "Olle";
	var checked = true;
	function render(framebuffer: Framebuffer): Void {
		i += 0.05;
		i %= 6;
		
		var fb = framebuffer.g2;
		
		fb.begin();
		
		if(checked){
			fb.drawScaledSubImage(image, Std.int(i) * 32, 0, 32, 32, 20, 300, 128, 128);
		}
		
		framebuffer.g2.font = font;
		fb.fontSize = Std.int(System.windowHeight() / 20);
		framebuffer.g2.drawString("Super Tech Demo", 30,  30);
		
		fb.color = kha.Color.Green;
		fb.drawLine(0, 0, 100, 100, 2);
		
		fb.end();
	
		ui.begin(fb);
		
    	// window() returns true if redraw is needed - windows are cached into textures
		if (ui.window(Id.window(), System.windowWidth() - 512, 5, 250, 600)) {
			if (ui.node(Id.node(), "Node", 0, true)) {
				ui.indent();
				ui.separator();
				ui.text("Text");
				name = ui.textInput(Id.textInput(), name, "Username");
				if(ui.button("GOGEL!")){
					trace("asdf");
					kha.input.Mouse.get().hideSystemCursor();
				}
				
				checked = ui.check(Id.check(), "Check Box", checked);
				var id = Id.radio();
				ui.radio(id, Id.pos(), "Radio 1");
				ui.radio(id, Id.pos(), "Radio 2");
				ui.radio(id, Id.pos(), "Radio 3");
				if (ui.node(Id.node(), "Nested Node")) {
					ui.indent();
					ui.separator();
					ui.text("Row");
					ui.row([2/5, 2/5, 1/5]);
					ui.button("A");
					ui.button("B");
					ui.check(Id.check(), "C");
					ui.text("Simple list");
					Ext.list(ui, Id.list(), ["Item 1", "Item 2", "Item 3", "Item 3", "Item 3", "Item 3", "Item 3", "Item 3", "Item 3"]);
					
					ui.unindent();
					if (ui.node(Id.node(), "Nested Node")) {
						ui.indent();
						ui.separator();
						ui.text("Row");
						ui.row([2/5, 2/5, 1/5]);
						ui.button("A");
						ui.button("B");
						ui.check(Id.check(), "C");
						ui.text("Simple list");
						Ext.list(ui, Id.list(), ["Item 1", "Item 2", "Item 3"]);
						ui.unindent();
					}
				}
				ui.unindent();
			}
		}
		ui.end();
	}
}
