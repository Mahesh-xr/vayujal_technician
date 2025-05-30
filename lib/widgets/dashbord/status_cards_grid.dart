import 'package:flutter/material.dart';
import 'status_card.dart';

class StatusCardsGrid extends StatelessWidget {
  const StatusCardsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: const [
        StatusCard(title: 'Total Requests', count: '25', accentColor: Colors.blue),
        StatusCard(title: 'Pending', count: '8', accentColor: Colors.orange),
        StatusCard(title: 'In Progress', count: '12', accentColor: Colors.green),
        StatusCard(title: 'Completed', count: '5', accentColor: Colors.purple),
      ],
    );
  }
}