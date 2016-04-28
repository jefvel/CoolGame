package enet;

import cpp.Int16;
import cpp.Int32;
import cpp.UInt8;
import cpp.UInt16;
import cpp.UInt32;

@:include("enet/kha_enet.h")
@:native("cpp::Struct<ENetAddress>")
extern class ENetAddress {
    public var host:UInt32;
    public var port:UInt16;
}

@include("enet/kha_enet.h")
@:native("ENetAddress")
extern class ENetAddressRef {}


@:include("enet/kha_enet.h")
@:native("cpp::Struct<ENetHost>")
extern class ENetHost {
    public var channelLimit:Int;
    
    public var totalReceivedData:UInt32;
    public var totalReceivedPackets:UInt32;
    public var totalSentData:UInt32;
    public var totalSentPackets:UInt32;
}

@include("enet/kha_enet.h")
@:native("ENetHost*")
extern class ENetHostRef extends ENetHost {}


@:include("enet/kha_enet.h")
@:native("cpp::Struct<ENetEvent>")
extern class ENetEvent {
    public var channelID:UInt16;
    public var data:UInt32;
    //ENetPacket * 	packet;
    //ENetPeer * 	peer;
    //ENetEventType 	type;
}

@include("enet/kha_enet.h")
@:native("ENetEvent*")
extern class ENetEventRef extends ENetEvent {}


@:include("enet/kha_enet.h")
@:unreflective
extern class ENet {
    public static inline var ENET_HOST_ANY = 0;
    public static inline var ENET_PORT_ANY = 0;
    public static inline var ENET_HOST_BROADCAST:UInt32 = 0xFFFFFFFF;
  
    @:native("::enet_initialize")
    public static function initialize():Int;
    
    @:native("::enet_deinitialize")
    public static function deinitialize():Void;
    
    @:native("enet::enet_host_create_wrapper")
    public static function createHost(address:ENetAddress, peerCount:Int, channelLimit:Int, incomingBandwidth:Int = 0, outgoingBandwidth:Int = 0):ENetHostRef;    

    //@:native("::enet_host_service")
    //public static function hostService(host:ENetHostRef, event:ENetEventRef, timeout:UInt32):Int;

    //@:native("enet_host_destroy")
    //public static function destroyHost(host:ENetHostRef):Void;
}
