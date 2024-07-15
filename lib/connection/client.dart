import 'package:socket_io_client/socket_io_client.dart';

class ClientIO {
  // instance of Socket
  Socket? socket;

  ClientIO._();
  static final instance = ClientIO._();

  init({required String websocketUrl, required String callerId}) {
    // init Socket
    socket = io(websocketUrl, {
      "transports": ['websocket'],
      "query": {"callerId": callerId}
    });

    return socket;
  }

  close() {
    socket?.close();
  }
}
