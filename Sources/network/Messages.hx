package network;

typedef FrameSnapshot = {
	var id:Int;
	var data:Array<PlayerUpdate>;
}

typedef PlayerUpdate = {
	var x:Int;
	var y:Int;
	var id:Int;
}