import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/material.dart';
import 'package:video_call/signalling.services.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:video_call/connection/client.dart';

class CallScreen extends StatefulWidget {
  final String ipAddress;
  final dynamic offer;
  const CallScreen({super.key, this.offer, required this.ipAddress});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  // media status
  bool isAudioOn = true, isVideoOn = true, isFrontCameraSelected = true;

  Socket? socket;

  final _remoteRTCVideoRenderer = RTCVideoRenderer();

  RTCPeerConnection? _rtcPeerConnection;

  // list of rtcCandidates to be sent over signalling
  List<RTCIceCandidate> rtcIceCadidates = [];

  @override
  void initState() {
    _remoteRTCVideoRenderer.initialize();

    // initializing renderers

    socket =
        ClientIO.instance.init(websocketUrl: "http://${widget.ipAddress}:5000");

    _setupPeerConnection();
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  _setupPeerConnection() async {
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
      _remoteRTCVideoRenderer.srcObject = event.streams[0];
      setState(() {});
    };

    _rtcPeerConnection!.onIceCandidate =
        (RTCIceCandidate candidate) => rtcIceCadidates.add(candidate);

    socket!.on("callAnswered", (data) async {
      // set SDP answer as remoteDescription for peerConnection
      await _rtcPeerConnection!.setRemoteDescription(
        RTCSessionDescription(
          data["sdpAnswer"]["sdp"],
          "answer",
        ),
      );

      // send iceCandidate generated to remote peer over signalling
      for (RTCIceCandidate candidate in rtcIceCadidates) {
        socket!.emit("IceCandidate", {
          "calleeId": '1',
          "iceCandidate": {
            "id": candidate.sdpMid,
            "label": candidate.sdpMLineIndex,
            "candidate": candidate.candidate
          }
        });
      }
    });

    RTCSessionDescription offer = await _rtcPeerConnection!.createOffer();
    await _rtcPeerConnection!.setLocalDescription(offer);

    socket!.emit('makeCall', {
      "calleeId": '1',
      "sdpOffer": offer.toMap(),
    });
    // for Outgoing Call
  }

  _leaveCall() {
    _rtcPeerConnection!.close();
    ClientIO.instance.close();
    Navigator.pop(context);
  }

  // _toggleMic() {
  //   // change status
  //   isAudioOn = !isAudioOn;
  //   // enable or disable audio track
  //   _localStream?.getAudioTracks().forEach((track) {
  //     track.enabled = isAudioOn;
  //   });
  //   setState(() {});
  // }

  // _toggleCamera() {
  //   // change status
  //   isVideoOn = !isVideoOn;

  //   // enable or disable video track
  //   _localStream?.getVideoTracks().forEach((track) {
  //     track.enabled = isVideoOn;
  //   });
  //   setState(() {});
  // }

  // _switchCamera() {
  //   // change status
  //   isFrontCameraSelected = !isFrontCameraSelected;

  //   // switch camera
  //   _localStream?.getVideoTracks().forEach((track) {
  //     // ignore: deprecated_member_use
  //     track.switchCamera();
  //   });
  //   setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("P2P Call App"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(children: [
                RTCVideoView(
                  _remoteRTCVideoRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(isAudioOn ? Icons.mic : Icons.mic_off),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.call_end),
                    iconSize: 30,
                    onPressed: _leaveCall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.cameraswitch),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(isVideoOn ? Icons.videocam : Icons.videocam_off),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // _remoteRTCVideoRenderer.dispose();
    // _remoteStream.dispose();
    super.dispose();
  }
}
