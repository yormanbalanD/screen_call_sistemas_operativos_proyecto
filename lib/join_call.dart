import 'package:flutter/material.dart';
import 'package:video_call/call_screen.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  dynamic incomingSDPOffer;
  final remoteIPTextEditingController = TextEditingController();

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

  // join Call
  _joinCall({dynamic offer}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
            ipAddress: remoteIPTextEditingController.text, offer: offer),
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
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: remoteIPTextEditingController,
                      decoration: const InputDecoration(
                        hintText: 'Ingresa la dirección IP de la sala a unirte',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _joinCall();
                      },
                      style: styleButton,
                      child: const Text('Unirse a la Sala'),
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
