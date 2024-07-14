import 'package:socket_io/socket_io.dart';

class ServerIO {
  ServerIO._();
  static final instance = ServerIO._();
  Server? _server;

  init() {
    _server = Server();

    _server!.listen(5000);

    return _server;
  }

  close() {
    _server!.close();
  }
}
