import 'package:socket_io_client/socket_io_client.dart';

class ClientIO {
  // instance of Socket
  Socket? socket;

  ClientIO._();
  static final instance = ClientIO._();

  // Inicia la conexion con el servidor, el webSocketUrl  es una URL HTTP en el puerto 5000, y el callerId es el id del cliente, este ID se genera aleatoriamente
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
