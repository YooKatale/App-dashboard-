import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Service to handle network errors and offline states with user-friendly messages
class ErrorHandlerService {
  // Support contact information
  static const String whatsappSupport = '+256786118137';
  static const String emailSupport = 'info@yookatale.app';
  static const String webappUrl = 'https://yookatale.app';

  /// Check if device is online
  static Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Get user-friendly error message from exception
  static String getErrorMessage(dynamic error, {String? customMessage}) {
    if (customMessage != null && customMessage.isNotEmpty) {
      return customMessage;
    }

    final errorString = error.toString().toLowerCase();

    // Network/Connection errors
    if (error is SocketException || 
        errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network is unreachable')) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (error is http.ClientException ||
        errorString.contains('connection refused') ||
        errorString.contains('connection timed out')) {
      return 'Unable to connect to server. Please check your internet connection.';
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return 'Request timed out. Your connection seems slow. Please try again.';
    }

    // HTTP errors
    if (errorString.contains('404')) {
      return 'The requested resource was not found. Please try again later.';
    }

    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Your session has expired. Please login again.';
    }

    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'You don\'t have permission to perform this action.';
    }

    if (errorString.contains('500') || errorString.contains('internal server error')) {
      return 'Server error occurred. Our team has been notified. Please try again later.';
    }

    if (errorString.contains('503') || errorString.contains('service unavailable')) {
      return 'Service temporarily unavailable. Please try again in a few moments.';
    }

    // Format errors
    if (errorString.contains('format exception') || errorString.contains('invalid')) {
      return 'Invalid data format. Please try again.';
    }

    // Generic fallback
    if (errorString.contains('exception')) {
      return 'Something went wrong. Please try again or contact support if the problem persists.';
    }

    return 'An unexpected error occurred. Please try again or contact support.';
  }

  /// Show error dialog with support options
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    bool showSupportOptions = true,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
            if (showSupportOptions) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Need help? Contact our support:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              _SupportOption(
                icon: Icons.chat,
                label: 'WhatsApp Support',
                value: whatsappSupport,
                onTap: () => _openWhatsApp(context),
              ),
              const SizedBox(height: 8),
              _SupportOption(
                icon: Icons.email,
                label: 'Email Support',
                value: emailSupport,
                onTap: () => _openEmail(context),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar
  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show offline banner
  static void showOfflineBanner(BuildContext context) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'You are currently offline. Some features may not be available.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: const Text(
              'DISMISS',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle API errors with retry option
  static Future<T?> handleApiError<T>(
    BuildContext context,
    Future<T> Function() apiCall, {
    String? customErrorMessage,
    bool showRetry = true,
  }) async {
    try {
      // Check if online first
      final isConnected = await isOnline();
      if (!isConnected) {
        if (context.mounted) {
          showErrorDialog(
            context,
            title: 'No Internet Connection',
            message: 'Please check your internet connection and try again.',
          );
        }
        return null;
      }

      return await apiCall();
    } catch (e) {
      if (context.mounted) {
        final errorMessage = getErrorMessage(e, customMessage: customErrorMessage);
        
        if (showRetry) {
          final shouldRetry = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Error'),
                ],
              ),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );

          if (shouldRetry == true) {
            return handleApiError(context, apiCall, customErrorMessage: customErrorMessage);
          }
        } else {
          showErrorSnackBar(context, message: errorMessage);
        }
      }
      return null;
    }
  }

  static Future<void> _openWhatsApp(BuildContext context) async {
    Navigator.of(context).pop();
    final url = Uri.parse('https://wa.me/$whatsappSupport');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp. Please contact $whatsappSupport manually.'),
          ),
        );
      }
    }
  }

  static Future<void> _openEmail(BuildContext context) async {
    Navigator.of(context).pop();
    final url = Uri.parse('mailto:$emailSupport?subject=Support Request');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open email. Please contact $emailSupport manually.'),
          ),
        );
      }
    }
  }
}

class _SupportOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SupportOption({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color.fromRGBO(24, 95, 45, 1)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
