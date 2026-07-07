import 'package:flutter/material.dart';

class TickerBar extends StatelessWidget {
  const TickerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 35,
      color: Colors.black,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          TickerItem(symbol: 'VOL 10', price: '18162.41', change: '+0.45%'),
          TickerItem(symbol: 'VOL 50', price: '152.06', change: '-0.12%'),
          TickerItem(symbol: 'VOL 75', price: '48135.88', change: '+1.20%'),
          TickerItem(symbol: 'VOL 100', price: '1083.78', change: '+0.05%'),
          TickerItem(symbol: 'BULL MARKET', price: '1089.35', change: '+2.1%'),
          TickerItem(symbol: 'BEAR MARKET', price: '1014.23', change: '-1.8%'),
        ],
      ),
    );
  }
}

class TickerItem extends StatelessWidget {
  final String symbol;
  final String price;
  final String change;

  const TickerItem({
    super.key,
    required this.symbol,
    required this.price,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change.startsWith('+');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Text(
            symbol,
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Text(
            price,
            style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            change,
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
