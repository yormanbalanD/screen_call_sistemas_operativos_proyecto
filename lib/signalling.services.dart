import 'package:socket_io_client/socket_io_client.dart';

class SignallingService {
  // instance of Socket
  Socket? socket;

  SignallingService._();
  static final instance = SignallingService._();

  init({required String websocketUrl, required String selfCallerID}) {
    // init Socket
    socket = io(websocketUrl, {
      "transports": ['websocket'],
      "query": {"callerId": selfCallerID}
    });

    // listen onConnect event
    socket!.onConnect((data) {
      print("Socket connected !!");
    });

    // listen onConnectError event
    socket!.onConnectError((data) {
      print("Connect Error $data");
    });

    // connect socket
    socket!.connect();
  }
}
