package enet;

/*
@:include("enet/kha_enet.h")
@:unreflective
@:native("enet::ENetAddress")
extern class ENetAddressNative {
    public var host:Int;
    public var port:Int;
}

@:include("enet/kha_enet.h")
@:native("cpp::Struct<enet::ENetAddress>")
extern class ENetAddress extends ENetAddressNative {}

@include("enet/kha_enet.h")
@:unreflective
@:native("cpp::Reference<enet::ENetAddress>")
extern class ENetAddressRef extends ENetAddressNative {}

*/
@:include("enet/fartfile.h")
@:unreflective
@:native("fart::CoolStruct")
extern class NativeCoolClass {    
    public var o:Int;
    public var a:Int;
}

@:include("enet/fartfile.h")
@:native("cpp::Struct<fart::CoolStruct>")
extern class CoolClass extends NativeCoolClass {}

@:include("enet/fartfile.h")
@:unreflective
@:native("cpp::Reference<fart::CoolStruct>")
extern class CoolClassRef extends NativeCoolClass {}


/*
@:include("enet/kha_enet.h")
@:unreflective
@:native("cpp::Struct<enet:::ENetHost>")
extern class ENetHost {
    public var channelLimit:Int;
    
    public var totalReceivedData:cpp.UInt32;
    public var totalReceivedPackets:cpp.UInt32;
    public var totalSentData:cpp.UInt32;
    public var totalSentPackets:cpp.UInt32;
}

@include("enet/kha_enet.h")
@:unreflective
@:native("::ENetHost*")
extern class ENetHostRef extends ENetHost {}


@:include("enet/kha_enet.h")
@:unreflective
@:native("cpp::Struct<::ENetEvent>")
extern class ENetEvent {
    public var channelID:cpp.UInt16;
    public var data:cpp.UInt32;
    //ENetPacket * 	packet;
    //ENetPeer * 	peer;
    //ENetEventType 	type;
}

@include("enet/kha_enet.h")
@:unreflective
@:native("::ENetEvent*")
extern class ENetEventRef extends ENetEvent {}

*/
@:include("enet/fartfile.h")
extern class ENet {
 /*   public static inline var ENET_HOST_ANY = 0;
    public static inline var ENET_PORT_ANY = 0;
    public static inline var ENET_HOST_BROADCAST:cpp.UInt32 = 0xFFFFFFFF;
  
    @:unreflective
    @:native("::enet_initialize")
    public static function initialize():Int;
    
    @:unreflective
    @:native("::enet_deinitialize")
    public static function deinitialize():Void;
  */  
   /* @:unreflective
    @:native("enet::enet_host_create")
    public static function createHost(address:ENetAddressRef):Bool;//, peerCount:Int, channelLimit:Int, incomingBandwidth:Int = 0, outgoingBandwidth:Int = 0):Bool;//ENetHostRef;    
*/

    @:unreflective
    @:native("fart::TestFunc")
    public static function TestFunc(a:CoolClassRef):Bool;
    //@:native("::enet_host_service")
    //public static function hostService(host:ENetHostRef, event:ENetEventRef, timeout:UInt32):Int;

    //@:native("enet_host_destroy")
    //public static function destroyHost(host:ENetHostRef):Void;
}
