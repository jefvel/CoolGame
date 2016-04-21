package;

import kha.Framebuffer;
import kha.graphics2.Graphics;
import kha.Assets;

import zui.Zui;
import zui.Id;
import kha.System;
import kha.Scheduler;

import entity.Line;

class Project2 {
    public var ui:Zui;
    public var line:Line;
    public function new() {
        Assets.loadEverything(loaded);
    }
    function loaded(){ 
        ui = new Zui(Assets.fonts.RobotoCondensed_Regular);
        line = new Line();
		System.notifyOnRender(render);
        Scheduler.addTimeTask(update, 0, 1 / 120);
		//kha.input.Mouse.get().notify(onMouseDown, null, onMouseMove, null);
	}
    public function update():Void {
        line.update();
    }

    public function render(framebuffer:Framebuffer):Void {
        var graphics = framebuffer.g2;
        graphics.begin();
        line.render(graphics);
        gui(graphics);
        graphics.end();
    }

    public function gui(graphics:Graphics):Void {
        ui.begin(graphics);
        if (ui.window(Id.window(), 0, 0, 150, 150)){
            if (ui.node(Id.node(), 'node', 0, true)){
                line.x1 = ui.slider(Id.slider(), 'x1', 0, 1000, true, 1);
                line.x1Sin = ui.slider(Id.slider(), 'sin', 0, 6, true, 100);
                line.y1 = ui.slider(Id.slider(), 'y1', 0, 1000, true, 1);
                line.x2 = ui.slider(Id.slider(), 'x2', 0, 1000, true, 1);
                line.y2 = ui.slider(Id.slider(), 'y2', 0, 1000, true, 1);
            }
        }
        ui.end();
    }
}