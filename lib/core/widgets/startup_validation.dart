// Startup validation widget — validates Supabase before showing the app.
//
// This widget ensures that Supabase is properly initialized before
// the main application is displayed. If validation fails, it shows
// a user-friendly error screen with retry capability.

import 'package:flutter/material.dart';
import '../config/supabase_config.dart';

/// Widget that validates Supabase initialization before showing the app.
///
/// Shows a loading indicator during validation, the child widget on
/// success, or an error screen with retry button on failure.
class StartupValidation extends StatefulWidget {
  /// The widget to show after successful validation.
  final Widget child;

  const StartupValidation({super.key, required this.child});

  @override
  State<StartupValidation> createState() => _StartupValidationState();
}

class _StartupValidationState extends State<StartupValidation> {
  String? _errorMessage;
  bool _isValidating = true;

  @override
  void initState() {
    super.initState();
    _validate();
  }

  Future<void> _validate() async {
    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      // Initialize Supabase with environment variables from --dart-define flags
      await initializeSupabase();

      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidating = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isValidating) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    return widget.child;
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Initializing GROUPE NIKEFA...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Error'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to Initialize',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'The application could not connect to the database. '
              'Please check your configuration.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _errorMessage ?? 'Unknown error',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _validate,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'If this problem persists, contact support.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
