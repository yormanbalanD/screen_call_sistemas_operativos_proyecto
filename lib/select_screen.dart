import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_call/join_call.dart';
import 'package:video_call/screen_server.dart';
import 'package:video_call/signalling.services.dart';
import 'package:video_call/call_screen.dart';

class SelectScreen extends StatefulWidget {
  const SelectScreen({super.key});

  @override
  State<SelectScreen> createState() => _SelectScreenState();
}

class _SelectScreenState extends State<SelectScreen> {
  dynamic incomingSDPOffer;
  final remoteCallerIdTextEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // listen for incoming video call
    // SignallingService.instance.socket!.on("newCall", (data) {
    //   if (mounted) {
    //     // set SDP Offer of incoming call
    //     setState(() => incomingSDPOffer = data);
    //   }
    // });
  }

  _createRoom() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ServerScreen()),
    );
  }

  // join Call
  _joinCall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JoinScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final styleButton = ElevatedButton.styleFrom(
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        backgroundColor: Colors.indigo,
        padding:
            const EdgeInsets.only(top: 15, bottom: 15, left: 25, right: 25),
        foregroundColor: Colors.white);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("AniDesk"),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        _joinCall();
                      },
                      style: styleButton,
                      child: const Text('Unirse a una Sala'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _createRoom();
                      },
                      style: styleButton,
                      child: const Text('Crear una Sala'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
