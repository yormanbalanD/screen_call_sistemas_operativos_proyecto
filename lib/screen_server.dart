import 'dart:io';

import 'package:socket_io_client/socket_io_client.dart';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:video_call/signalling.services.dart';

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

  Socket? socket;
  final _rtcVideoRenderer = RTCVideoRenderer();
  MediaStream? _mediaStream;
  RTCPeerConnection? _rtcPeerConnection;

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

    socket = SignallingService.instance
        .init(websocketUrl: "http://192.168.1.101:5000");

    SignallingService.instance.socket!.on("newCall", (data) {
      if (mounted) {
        // set SDP Offer of incoming call
        setState(() => incomingSDPOffer = data);
      }
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

    // listen for Remote IceCandidate
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

    // create SDP answer
    RTCSessionDescription answer = await _rtcPeerConnection!.createAnswer();

    // set SDP answer as localDescription for peerConnection
    _rtcPeerConnection!.setLocalDescription(answer);

    // send SDP answer to remote peer over signalling
    socket!.emit("answerCall", {
      "callerId": incomingSDPOffer["callerId"],
      "sdpAnswer": answer.toMap(),
    });

    setState(() {
      incomingSDPOffer = null;
    });
  }

  _leaveCall() {
    _rtcPeerConnection!.close();

    SignallingService.instance.close();

    Navigator.pop(context);

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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(children: [
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                        onPressed: () {
                          _toggleMic();
                        },
                        label: Icon(
                          (_isMicOn ? Icons.mic : Icons.mic_off),
                          size: 40,
                          color: (_isMicOn ? Colors.green : Colors.red),
                        ),
                        style: circularButton),
                    const SizedBox(height: 20),
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
                  const SizedBox(
                    width: 30,
                  ),
                  Column(children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _leaveCall();
                      },
                      label: const Icon(
                        Icons.call_end,
                        size: 40,
                        color: Colors.red,
                      ),
                      style: circularButton,
                    )
                  ])
                ],
              ),
              Expanded(
                child: Stack(children: [
                  Padding(
                    padding: const EdgeInsets.all(25),
                    child: RTCVideoView(
                      _rtcVideoRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ]),
              ),
              if (incomingSDPOffer != null)
                Positioned(
                  child: ListTile(
                    title: Text(
                      "Incoming Call from ${incomingSDPOffer["callerId"]}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.call_end),
                          color: Colors.redAccent,
                          onPressed: () {
                            setState(() => incomingSDPOffer = null);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.call),
                          color: Colors.greenAccent,
                          onPressed: () {
                            _acceptCall();
                          },
                        )
                      ],
                    ),
                  ),
                )
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
  }
}
