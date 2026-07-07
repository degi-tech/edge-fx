import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class DerivService {
  WebSocketChannel? _channel;
  final String appId;
  final String _url = 'wss://ws.derivws.com/websockets/v3?app_id=';

  final _tickController = StreamController<Map<String, dynamic>>.broadcast();
  final _authController = StreamController<Map<String, dynamic>>.broadcast();
  final _msgController = StreamController<String>.broadcast();
  
  Stream<Map<String, dynamic>> get tickStream => _tickController.stream;
  Stream<Map<String, dynamic>> get authStream => _authController.stream;
  Stream<String> get messageStream => _msgController.stream;

  DerivService({this.appId = '33LkncGXigSRqxUn4iEfO'});

  void connect() {
    if (_channel != null) return;
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse('$_url$appId'));
      _channel!.stream.listen((message) {
        final data = jsonDecode(message);
        
        if (data['error'] != null) {
          _msgController.add('Error: ${data['error']['message']}');
        }

        final type = data['msg_type'];
        if (type == 'tick') {
          _tickController.add(data['tick']);
        } else if (type == 'authorize') {
          _authController.add(data['authorize']);
          _msgController.add('Authorized: ${data['authorize']['fullname']}');
          // Subscribe to balance updates once authorized
          _channel!.sink.add(jsonEncode({"balance": 1, "subscribe": 1}));
        } else if (type == 'balance') {
          _authController.add({'balance': data['balance']['balance'], 'currency': data['balance']['currency']});
        } else if (type == 'buy') {
          _msgController.add('Trade Successful: ${data['buy']['contract_id']}');
        }
      }, onError: (error) {
        _msgController.add('Connection Error: $error');
        _channel = null;
      }, onDone: () {
        _msgController.add('Connection Closed');
        _channel = null;
      });
    } catch (e) {
      _msgController.add('Connect Failed: $e');
    }
  }

  void authorize(String token) {
    if (_channel == null) connect();
    
    // Small delay to ensure the connection is established before sending auth
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_channel != null) {
        _channel!.sink.add(jsonEncode({"authorize": token}));
      }
    });
  }

  void subscribeTicks(String symbol) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({"ticks": symbol, "subscribe": 1}));
    }
  }

  void buy(String symbol, double amount, String type) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({
        "buy": 1,
        "price": amount,
        "parameters": {
          "amount": amount,
          "basis": "stake",
          "contract_type": type == 'Rise' ? 'CALL' : 'PUT',
          "currency": "USD",
          "duration": 5,
          "duration_unit": "t",
          "symbol": symbol
        }
      }));
    }
  }

  void dispose() {
    _channel?.sink.close();
    _tickController.close();
    _authController.close();
    _msgController.close();
  }
}
