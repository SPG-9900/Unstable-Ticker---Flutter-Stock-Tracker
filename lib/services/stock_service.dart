import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:unstable_ticker/models/stock.dart';

enum ConnectionStatus { connecting, connected, reconnecting, disconnected }

class StockService {
  WebSocketChannel? _channel;
  final ValueNotifier<ConnectionStatus> connectionStatusNotifier =
      ValueNotifier(ConnectionStatus.disconnected);
  final Map<String, Stock> _stocks = {};
  final ValueNotifier<Map<String, Stock>> stocksNotifier = ValueNotifier({});
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  double _reconnectDelay = 2.0; // Initial delay in seconds

  StockService() {
    _connectWebSocket();
  }

  void _connectWebSocket() {
    connectionStatusNotifier.value = _reconnectAttempt == 0
        ? ConnectionStatus.connecting
        : ConnectionStatus.reconnecting;

    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://127.0.0.1:8080/ws'));

      _channel?.stream.listen(
        (message) {
          _reconnectAttempt = 0;
          _reconnectDelay = 2.0;
          _reconnectTimer?.cancel();
          connectionStatusNotifier.value = ConnectionStatus.connected;
          _handleMessage(message);
        },
        onDone: () {
          debugPrint('WebSocket disconnected');
          connectionStatusNotifier.value = ConnectionStatus.disconnected;
          _reconnect();
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          connectionStatusNotifier.value = ConnectionStatus.disconnected;
          _reconnect();
        },
      );
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      connectionStatusNotifier.value = ConnectionStatus.disconnected;
      _reconnect();
    }
  }

  void _reconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempt++;
    _reconnectDelay = min(30.0, pow(2, _reconnectAttempt + 1).toDouble());

    debugPrint(
      'Attempting to reconnect in ${_reconnectDelay.toInt()} seconds...',
    );
    _reconnectTimer = Timer(Duration(seconds: _reconnectDelay.toInt()), () {
      _connectWebSocket();
    });
  }

  void _handleMessage(dynamic message) {
    try {
      final List<dynamic> rawData = jsonDecode(message);
      bool newStockAdded = false;

      for (var item in rawData) {
        final String ticker = item['ticker'];
        final double newPrice = double.parse(item['price']);

        Stock? existingStock = _stocks[ticker];

        if (existingStock == null) {
          // If stock is new, create it
          _stocks[ticker] = Stock(ticker: ticker, initialPrice: newPrice);
          newStockAdded = true;
        } else {
          // Anomaly Detection: Price change by over X% (e.g., 50% for now)
          // This is a simple heuristic and can be refined.
          final double lastValidPrice = existingStock.priceNotifier.value;
          final double percentageChange =
              ((newPrice - lastValidPrice) / lastValidPrice).abs();

          if (percentageChange > 0.50) {
            // If price changes by more than 50%
            debugPrint(
              'Anomaly detected for $ticker: Last Valid Price $lastValidPrice, New Price $newPrice',
            );
            existingStock.updatePrice(
              lastValidPrice,
              isAnomalous: true,
            ); // Keep old price, mark as anomalous
          } else {
            existingStock.updatePrice(
              newPrice,
              isAnomalous: false,
            ); // Update price normally
          }
        }
      }
      // Notify listeners only if new stocks were added or if all stocks were cleared.
      // Individual stock updates are handled by their ValueNotifiers.
      if (newStockAdded || stocksNotifier.value.isEmpty && _stocks.isNotEmpty) {
        stocksNotifier.value = Map.from(
          _stocks,
        ); // Trigger rebuild for the list if structure changes
      }
    } catch (e) {
      debugPrint('Failed to parse message or handle data: $e');
      // Discard malformed JSON messages safely
    }
  }

  void dispose() {
    _channel?.sink.close();
    _reconnectTimer?.cancel();
    connectionStatusNotifier.dispose();
    stocksNotifier.dispose();
    for (var stock in _stocks.values) {
      stock.dispose();
    }
  }
}
