import 'package:flutter/material.dart';

/// POI タップ時に表示するボトムシート（GPX 用）。名前と説明を表示。
void showPoiDetailSheet(
  BuildContext context, {
  String? name,
  String? description,
}) {
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.zero,
    ),
    builder: (context) {
      return SizedBox(
        width: double.infinity,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (name != null && name.isNotEmpty) ...[
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                ],
                if (description != null && description.isNotEmpty)
                  Text(description),
              ],
            ),
          ),
        ),
      );
    },
  );
}
