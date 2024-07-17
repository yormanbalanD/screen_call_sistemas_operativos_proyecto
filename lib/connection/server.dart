import 'package:socket_io/socket_io.dart';

class ServerIO {
  ServerIO._();
  static final instance = ServerIO._();
  Server? _server;

  // Inicia el servidor y lo mantiene en escucha por espera de respuesta
  init() {
    _server = Server();

    _server!.listen(5000);

    return _server;
  }

  close() {
    _server!.close();
  }
}
