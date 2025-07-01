import 'package:flutter/material.dart';
import 'package:unstable_ticker/models/stock.dart';
import 'package:unstable_ticker/services/stock_service.dart';
import 'package:unstable_ticker/widgets/stock_list_item.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StockService _stockService;

  @override
  void initState() {
    super.initState();
    _stockService = StockService();
  }

  @override
  void dispose() {
    _stockService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unstable Ticker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Unstable Ticker'),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ValueListenableBuilder<ConnectionStatus>(
                valueListenable: _stockService.connectionStatusNotifier,
                builder: (context, status, child) {
                  return Chip(
                    label: Text(status.name.toUpperCase()),
                    backgroundColor: status == ConnectionStatus.connected
                        ? Colors.green[100]
                        : status == ConnectionStatus.connecting ||
                                status == ConnectionStatus.reconnecting
                            ? Colors.orange[100]
                            : Colors.red[100],
                  );
                },
              ),
            ),
          ],
        ),
        body: ValueListenableBuilder<Map<String, Stock>>(
          valueListenable: _stockService.stocksNotifier,
          builder: (context, stocks, child) {
            if (stocks.isEmpty) {
              return const Center(child: Text('Connecting to stock feed...'));
            }
            return ListView.builder(
              itemCount: stocks.length,
              itemBuilder: (context, index) {
                final stock = stocks.values.elementAt(index);
                return StockListItem(stock: stock);
              },
            );
          },
        ),
      ),
    );
  }
}
