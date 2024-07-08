import 'package:socket_io_client/socket_io_client.dart';

class SignallingService {
  // instance of Socket
  Socket? socket;

  SignallingService._();
  static final instance = SignallingService._();

  init({required String websocketUrl}) {
    // init Socket
    socket = io(websocketUrl, {
      "transports": ['websocket'],
      "query": {"callerId": '1'}
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

    return socket;
  }

  initClient({required String websocketUrl}) {
    // init Socket
    socket = io(websocketUrl, {
      "transports": ['websocket'],
      "query": {"callerId": '2'}
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

    return socket;
  }

  close() {
    socket!.disconnect();
  }
}
