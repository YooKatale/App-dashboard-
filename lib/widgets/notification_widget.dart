import 'package:flutter/material.dart';

class CustomAlertDialog extends StatelessWidget {
  final VoidCallback onDeny;
  final VoidCallback onAllow;

  const CustomAlertDialog({
    super.key,
    required this.onDeny,
    required this.onAllow,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Get Notified!',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Image.asset(
                  'assets/animated-bell.gif',
                  height: MediaQuery.of(context).size.height * 0.3,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Allow Awesome Notifications to send you beautiful notifications!',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onDeny,
          child: Text(
            'Deny',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.red,
                ),
          ),
        ),
        TextButton(
          onPressed: onAllow,
          child: Text(
            'Allow',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.deepPurple,
                ),
          ),
        ),
      ],
    );
  }
}
