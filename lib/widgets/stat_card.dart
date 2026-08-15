import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String titre;
  final String valeur;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.titre,
    required this.valeur,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor:
          color.withValues(
        alpha: 0.25,
      ),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              color.withValues(
                alpha: 0.06,
              ),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding:
            const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 12,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              padding:
                  const EdgeInsets.all(
                14,
              ),
              decoration:
                  BoxDecoration(
                color:
                    color.withValues(
                  alpha: 0.15,
                ),
                shape:
                    BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            FittedBox(
              child: Text(
                valeur,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              titre,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w600,
                color:
                    Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}