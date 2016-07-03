package;

import kha.System;

class Main {
	public static function main() {
		var windowOptions:kha.WindowOptions = {
			width: 500,
			height: 320,
			mode:Window,
			windowedModeOptions: {
				resizable: true,
				maximizable: true,
				minimizable:true
			}
		};
		
		var o = [windowOptions];	
		System.initEx("Bonk", o, WindowInit, KhaInit);
	}
	
	static function WindowInit(i:Int) {
	}
	
	static function KhaInit() {
		new AudioApp();
	}
}
