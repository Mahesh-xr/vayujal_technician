import 'package:flutter/material.dart';
import 'action_button.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            
            Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const QuickActionsSection()),
        );
          },
          child: ActionButton(
            title: 'View Tasks', 
            onPressed: () {


              Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const QuickActionsSection()),
        );
              
            },
          ),
        ),
        const SizedBox(height: 12),
         ActionButton(
          onPressed: () {
            
          },
          title: 'Pending Services', 
        ),
       
      ],
    );
  }
}