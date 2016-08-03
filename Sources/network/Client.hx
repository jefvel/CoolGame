package network;

#if sys_html5 || sys_debug_html5
import js.html.WebSocket;
import js.html.MessageEvent;

class Client {
	public var connected:Bool = false;
	var client:WebSocket;
	
	public var id:Int;
	public var x:Int;
	public var y:Int;
	
	private var msgListener:Dynamic -> Void;
	
	public function new(onMessage: Dynamic -> Void) {
		msgListener = onMessage;
	}
	
	public function send(s:Dynamic) {
		client.send(haxe.Json.stringify(s));
	}
	
	public function sendString(s:String){
		client.send(s);
	}
	
	private function onData(d:MessageEvent) {
		var message = haxe.Json.parse(d.data);
		if(msgListener != null) {
			msgListener(message);
		}
	}
	
	public function connect(address:String, onConnect:Dynamic -> Void) {
		client = new 	WebSocket(address);
		client.onmessage = onData;
		client.onopen = function(e) {
			onConnect(e);
		};
	}
}
#else

class Client {
	public var connected:Bool = false;
	
	public var id:Int;
	public var x:Int;
	public var y:Int;
	
	private var msgListener:Dynamic -> Void;
	
	public function new(onMessage: Dynamic -> Void) {
		msgListener = onMessage;
	}
	
	public function send(s:Dynamic) {
		
	}
	
	public function sendString(s:String){
		
	}
	
	private function onData(d) {
		var message = haxe.Json.parse(d.data);
		if(msgListener != null) {
			msgListener(message);
		}
	}
	
	public function connect(address:String, onConnect:Dynamic -> Void) {
		
	}
}
#end