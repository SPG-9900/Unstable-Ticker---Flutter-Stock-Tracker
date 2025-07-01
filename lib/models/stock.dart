import 'package:flutter/foundation.dart';

class Stock {
  final String ticker;
  final ValueNotifier<double> priceNotifier;
  final ValueNotifier<bool> isAnomalousNotifier;
  double? _oldPrice; // Internal field to store the previous price for animation

  Stock({
    required this.ticker,
    required double initialPrice,
    bool isAnomalous = false,
  }) : priceNotifier = ValueNotifier(initialPrice),
       isAnomalousNotifier = ValueNotifier(isAnomalous);

  // Method to update price and manage oldPrice for animation
  void updatePrice(double newPrice, {bool isAnomalous = false}) {
    _oldPrice = priceNotifier.value;
    priceNotifier.value = newPrice;
    isAnomalousNotifier.value = isAnomalous;
  }

  double? get oldPrice => _oldPrice;

  void dispose() {
    priceNotifier.dispose();
    isAnomalousNotifier.dispose();
  }
}
