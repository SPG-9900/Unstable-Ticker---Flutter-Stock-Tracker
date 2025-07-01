// File: mock_server.dart

import 'dart:io';

import 'dart:convert';

import 'dart:async';

import 'dart:math';

final Map<String, double> _stocks = {
  'AAPL': 150.00,

  'GOOG': 2800.00,

  'TSLA': 700.00,

  'MSFT': 300.00,

  'AMZN': 3400.00,
};

final Random _random = Random();

final List<WebSocket> _sockets = [];

void main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);

  print('Server listening on ws://${server.address.host}:${server.port}');

  server.listen((HttpRequest req) {
    if (req.uri.path == '/ws') {
      WebSocketTransformer.upgrade(req).then((WebSocket socket) {
        _handleSocket(socket);
      });
    }
  });

  Timer.periodic(const Duration(seconds: 1), (timer) {
    _updateAndBroadcast();
  });
}

void _handleSocket(WebSocket socket) {
  print('Client connected!');

  _sockets.add(socket);

  if (_random.nextDouble() < 0.5) {
    final disconnectTime = Duration(seconds: 10 + _random.nextInt(20));

    Timer(disconnectTime, () {
      if (_sockets.contains(socket)) {
        print('Simulating a network drop for a client.');

        socket.close();
      }
    });
  }

  socket.listen(
    (data) {},

    onDone: () {
      print('Client disconnected!');

      _sockets.remove(socket);
    },

    onError: (error) {
      print('Client error: $error');

      _sockets.remove(socket);
    },
  );
}

void _updateAndBroadcast() {
  _stocks.forEach((ticker, price) {
    final change = (_random.nextDouble() * 2 - 1) * (price * 0.01);

    _stocks[ticker] = max(0, price + change);
  });

  final data = _stocks.entries
      .map((e) => {'ticker': e.key, 'price': e.value.toStringAsFixed(2)})
      .toList();

  // Failure Case 1: Malformed JSON

  if (_random.nextDouble() < 0.1) {
    print('>>> Sending malformed data...');

    for (final socket in _sockets) {
      socket.add('{"ticker": "MSFT", "price": }');
    }

    return;
  }

  // Failure Case 2: Logically Anomalous Data (NEW)

  if (_random.nextDouble() < 0.08) {
    print('>>> Sending anomalous price for GOOG...');

    final anomalousData = List<Map<String, String>>.from(data);

    final googIndex = anomalousData.indexWhere((d) => d['ticker'] == 'GOOG');

    if (googIndex != -1) {
      // Price drops by over 95%, which is syntactically valid but logically suspect

      anomalousData[googIndex]['price'] = (_stocks['GOOG']! / 20)
          .toStringAsFixed(2);
    }

    for (final socket in _sockets) {
      socket.add(jsonEncode(anomalousData));
    }

    return;
  }

  // Good Data Broadcast

  if (_sockets.isNotEmpty) {
    print('Broadcasting price updates...');

    for (final socket in _sockets) {
      socket.add(jsonEncode(data));
    }
  }
}
