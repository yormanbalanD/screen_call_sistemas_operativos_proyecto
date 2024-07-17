import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
  String _callerId = "";

  final _remoteRTCVideoRenderer = RTCVideoRenderer();

  RTCPeerConnection? _rtcPeerConnection;

  // list of rtcCandidates to be sent over signalling
  List<RTCIceCandidate> rtcIceCadidates = [];

  @override
  void initState() {
    _remoteRTCVideoRenderer.initialize();

    // initializing renderers
    _callerId = generarStringNumerico(6);

    socket = ClientIO.instance.init(
        websocketUrl: "http://${widget.ipAddress}:5000", callerId: _callerId);

    // Crea un evento de escucha para cuando el servidor se desconecta del cliente, para cerrar la conexion con el servidor
    socket!.on("disconnect", (data) {
      showDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('Servidor Desconectado'),
              content: const Text(
                  "El servidor se desconectó de la llamada. Desea salir de esta pantalla?"),
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
    });

    // Crea un evento de escucha cuando el cliente tiene un error de conexion con el servidor
    socket!.on("connect_error", (data) {
      socket!.disconnect();
      showDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('Error'),
              content: const Text(
                  "No se pudo conectar con el servidor. Comprueba si la dirección IP es correcta."),
            );
          });
    });

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

    // Crea un evento de escucha para cuando el cliente recibe una respuesta de la llamada, esta respuesta es si acepto o no la llamada
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
        // Despues de recibir una respuesta afirmativa de la llamada, el cliente envia el ICE Candidate a la otra parte
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

    // El cliente emite la llamada al servidor, esta llamada es un Offer de WEBRTC, la cual necesita una respuesta para ser aceptada del servidor
    socket!.emit('makeCall', {
      "calleeId": '1',
      "sdpOffer": offer.toMap(),
    });
    // for Outgoing Call
  }

  _leaveCall() {
    showDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text('Advertencia'),
            content: const Text(
                "¿Desea terminar la llamada? Al hacerlo se cerrara la aplicacion."),
            actions: [
              CupertinoDialogAction(
                  child: const Text('Si'),
                  onPressed: () {
                    socket!.disconnect();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(widget.ipAddress),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration:
                      BoxDecoration(color: Colors.white.withOpacity(0.5)),
                  child: Stack(children: [
                    RTCVideoView(
                      _remoteRTCVideoRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.call_end),
                    iconSize: 40,
                    onPressed: _leaveCall,
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

  String generarStringNumerico(int i) {
// Definimos los números que queremos incluir en el string
    const numeros = '123456789';

    // Creamos un objeto Random para generar números aleatorios
    Random random = Random();

    // Creamos un string vacío para almacenar el string numérico aleatorio
    String stringNumerico = '';

    // Generamos 6 dígitos aleatorios y los agregamos al string
    for (int i = 0; i < 6; i++) {
      int indiceAleatorio = random.nextInt(numeros.length);
      stringNumerico += numeros[indiceAleatorio];
    }

    // Devolvemos el string numérico aleatorio
    return stringNumerico;
  }
}
