import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:socket_io/socket_io.dart';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:video_call/connection/server.dart';

class ServerScreen extends StatefulWidget {
  final dynamic offer;
  const ServerScreen({super.key, this.offer});

  @override
  State<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  bool _isMicOn = false;
  bool _isScreenShareOn = true;

  dynamic incomingSDPOffer;

  Server? _server;

  final _rtcVideoRenderer = RTCVideoRenderer();
  MediaStream? _mediaStream;
  RTCPeerConnection? _rtcPeerConnection;
  String? _callerId;

  List<RTCIceCandidate> rtcIceCadidate = [];
  String _ipLocal = "";

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void _getIpLocal() async {
    for (var interface in await NetworkInterface.list()) {
      print(interface.addresses);
      _ipLocal = interface.addresses[0].address;
      setState(() {});
      return;
    }
  }

  void _toggleMic() {
    _isMicOn = !_isMicOn;

    _mediaStream?.getAudioTracks().forEach((track) {
      track.enabled = _isMicOn;
    });

    setState(() => {});
  }

  void _toggleScreenShare() {
    _isScreenShareOn = !_isScreenShareOn;

    _mediaStream?.getVideoTracks().forEach((track) {
      track.enabled = _isScreenShareOn;
    });
    setState(() => {});
  }

  @override
  void initState() {
    _rtcVideoRenderer.initialize();

    _getIpLocal();

    _server = ServerIO.instance.init();

    _server!.on("connection", (socket) {
      String callerId = socket.handshake['query']['callerId'];
      socket.join(callerId);

      socket.on("makeCall", (data) {
        var sdpOffer = data['sdpOffer'];

        if (mounted) {
          // set SDP Offer of incoming call
          setState(() => incomingSDPOffer = {
                "callerId": callerId,
                "sdpOffer": sdpOffer,
              });
        }
        showDialog(
            context: context,
            builder: (context) {
              return CupertinoAlertDialog(
                title: const Text('Solucitud Entrante'),
                content: const Text(
                    "Un usuario desea observar su pantalla. ¿Desea aceptar?"),
                actions: [
                  CupertinoDialogAction(
                      child: const Text('Aceptar'),
                      onPressed: () {
                        _acceptCall();
                        Navigator.pop(context);
                      }),
                  CupertinoDialogAction(
                      child: const Text('Rechazar'),
                      onPressed: () {
                        Navigator.pop(context);
                      }),
                ],
              );
            });
      });

      socket!.on("IceCandidate", (data) {
        String candidate = data["iceCandidate"]["candidate"];
        String sdpMid = data["iceCandidate"]["id"];
        int sdpMLineIndex = data["iceCandidate"]["label"];

        // add iceCandidate
        _rtcPeerConnection!.addCandidate(RTCIceCandidate(
          candidate,
          sdpMid,
          sdpMLineIndex,
        ));
      });
    });

    _setupPeerConnection();
    super.initState();
  }

  _setupPeerConnection() async {
    FlutterBackgroundService().invoke('setAsForeground');

    _rtcPeerConnection = await createPeerConnection({
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302'
          ]
        }
      ]
    });

    _rtcPeerConnection!.onTrack = (event) {
      _rtcVideoRenderer.srcObject = event.streams[0];
      setState(() {});
    };

    _mediaStream = await navigator.mediaDevices
        .getDisplayMedia({'video': _isScreenShareOn, 'audio': _isMicOn});

    _mediaStream!.getTracks().forEach((track) {
      _rtcPeerConnection!.addTrack(track, _mediaStream!);
    });

    _rtcVideoRenderer.srcObject = _mediaStream;
    setState(() {});
  }

  _acceptCall() async {
    await _rtcPeerConnection!.setRemoteDescription(
      RTCSessionDescription(incomingSDPOffer["sdpOffer"]["sdp"],
          incomingSDPOffer["sdpOffer"]["type"]),
    );

    // create SDP answer
    RTCSessionDescription answer = await _rtcPeerConnection!.createAnswer();

    // set SDP answer as localDescription for peerConnection
    _rtcPeerConnection!.setLocalDescription(answer);

    _server!.to(incomingSDPOffer["callerId"]).emit("callAnswered", {
      "callee": '1',
      "sdpAnswer": answer.toMap(),
    });

    setState(() {
      incomingSDPOffer = null;
    });
  }

  _leaveCall(BuildContext ctx) {
    showDialog(
        context: ctx,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text('Advertencia'),
            content: const Text(
                "¿Desea terminar la llamada? Al hacerlo se cerrara la aplicacion."),
            actions: [
              CupertinoDialogAction(
                  child: const Text('Si'),
                  onPressed: () {
                    SystemNavigator.pop();
                  }),
              CupertinoDialogAction(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
            ],
          );
        });

    setState(() {
      incomingSDPOffer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    const styleText = TextStyle(
        fontSize: 26, fontWeight: FontWeight.w600, color: Colors.white);
    final circularButton = ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(20), backgroundColor: Colors.white);

    return Scaffold(
      body: Padding(
        padding:
            const EdgeInsets.only(top: 20, bottom: 20, left: 20, right: 20),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "IP LOCAL: $_ipLocal",
                style: styleText,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _leaveCall(context);
                      },
                      label: const Icon(
                        Icons.call_end,
                        size: 40,
                        color: Colors.red,
                      ),
                      style: circularButton,
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                        onPressed: () {
                          _toggleScreenShare();
                        },
                        label: Icon(
                          (_isScreenShareOn
                              ? Icons.screen_share
                              : Icons.stop_screen_share),
                          size: 40,
                          color: (_isScreenShareOn ? Colors.green : Colors.red),
                        ),
                        style: circularButton),
                  ]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _isMicOn = false;
    _isScreenShareOn = true;
    _mediaStream?.getTracks().forEach((track) {
      track.stop();
    });
    _mediaStream?.dispose();
    _rtcPeerConnection!.close();
    ServerIO.instance.close();
  }
}
