import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// 位置情報を取得できないときに表示する画面（設定を開くボタン付き）
class LocationErrorView extends StatelessWidget {
  const LocationErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('位置情報を取得できません'),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => Geolocator.openAppSettings(),
              icon: const Icon(Icons.settings),
              label: const Text('設定を開く'),
            ),
          ],
        ),
      ),
    );
  }
}
