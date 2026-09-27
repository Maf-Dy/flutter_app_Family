import 'package:flutter/material.dart';

import '../../../../core/router/app_router.dart';
import '../widgets/bowl.dart';
import '../widgets/how_to_play_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(child: _Wordmark()),
                  IconButton(
                    tooltip: 'How to play',
                    onPressed: () => showHowToPlay(context),
                    icon: const Icon(Icons.help_outline_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: Bowl()),
                        const SizedBox(height: 16),
                        Text('Who wrote\nwhat?', textAlign: TextAlign.center, style: theme.textTheme.displaySmall),
                        const SizedBox(height: 10),
                        Text(
                          'Everyone secretly drops a name in the bowl. Then put the phone down and play.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 24),
                        const _HostButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      label: 'Family',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('family', style: theme.textTheme.headlineMedium?.copyWith(fontSize: 26, letterSpacing: -1)),
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 7),
            child: CircleAvatar(radius: 3.5, backgroundColor: theme.colorScheme.tertiary),
          ),
        ],
      ),
    );
  }
}

class _HostButton extends StatelessWidget {
  const _HostButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.primary,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.room),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.onPrimary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.wifi_rounded, color: scheme.onPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Host a room', style: theme.textTheme.titleLarge?.copyWith(color: scheme.onPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      'Friends join from their phone\'s browser. No app, no internet needed.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimary.withValues(alpha: 0.85),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
