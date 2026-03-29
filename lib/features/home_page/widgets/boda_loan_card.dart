import 'package:flutter/material.dart';

const _kPrimary = Color(0xFF0B2416);
const _kAccent  = Color(0xFF2ECC71);

class BodaLoanCard extends StatelessWidget {
  const BodaLoanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/subscription'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 22),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _kPrimary,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned(
              right: -15,
              bottom: -15,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _kAccent.withOpacity(0.08), width: 20),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _kAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: _kAccent.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.electric_rickshaw_rounded, color: _kAccent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOOKATALE BODA LOAN',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: _kAccent),
                      ),
                      const SizedBox(height: 3),
                      const Text('Get Delivery Credit Fast', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Raleway')),
                      const SizedBox(height: 2),
                      Text('Apply in 2 minutes · Instant approval', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45))),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: _kAccent, borderRadius: BorderRadius.circular(18)),
                  child: const Text('Apply Now', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: _kPrimary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
