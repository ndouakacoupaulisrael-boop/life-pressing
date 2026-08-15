import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(
              alpha: 0.25,
            ),
            blurRadius: 15,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor:
                Colors.white,
            child: Icon(
              Icons
                  .local_laundry_service,
              size: 42,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Life Pressing',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Gestion intelligente de votre pressing',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color:
                  Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}