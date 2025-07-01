import 'package:flutter/material.dart';
import 'package:unstable_ticker/models/stock.dart';

class StockListItem extends StatelessWidget {
  final Stock stock;

  const StockListItem({super.key, required this.stock});

  Color _getPriceColor(double newPrice, double? oldPrice) {
    if (oldPrice == null || newPrice == oldPrice) {
      return Colors.black; // No change or initial state
    } else if (newPrice > oldPrice) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              stock.ticker,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            // Use AnimatedBuilder to rebuild only the price and anomaly icon
            AnimatedBuilder(
              animation: Listenable.merge([
                stock.priceNotifier,
                stock.isAnomalousNotifier,
              ]),
              builder: (context, child) {
                final currentPrice = stock.priceNotifier.value;
                final isCurrentAnomalous = stock.isAnomalousNotifier.value;
                final priceColor = _getPriceColor(currentPrice, stock.oldPrice);

                return Row(
                  children: [
                    TweenAnimationBuilder<Color?>(
                      // Using TweenAnimationBuilder for color flashing
                      duration: const Duration(milliseconds: 300),
                      tween: ColorTween(
                        begin: priceColor,
                        end: Colors.black, // Flash to black
                      ),
                      builder: (context, color, child) {
                        return Text(
                          '${currentPrice.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 20, color: color),
                        );
                      },
                    ),
                    if (isCurrentAnomalous)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.warning, color: Colors.orange),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
