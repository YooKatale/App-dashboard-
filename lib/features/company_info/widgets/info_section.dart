import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class InfoSection extends StatelessWidget {
  const InfoSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            FaIcon(
              FontAwesomeIcons.phoneFlip,
              color: Colors.white,
            ),
            SizedBox(width: 4),
            Text(
              '+256786118137',
              style: TextStyle(color: Colors.white, fontFamily: 'Cabin'),
            )
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            FaIcon(
              FontAwesomeIcons.envelope,
              color: Colors.white,
            ),
            SizedBox(width: 4),
            Text(
              'info@yookatale.app',
              style: TextStyle(
                color: Colors.white,
                // fontFamily: 'Cabin'
              ),
            )
          ],
        ),
      ],
    );
  }
}
