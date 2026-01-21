import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brevet Map',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Brevet Map'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  GoogleMapController? mapController;
  Future<Position?>? _positionFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _positionFuture = _getPositionWithPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 設定アプリから戻ってきた等のケースで、状態を再取得して再描画する
      setState(() {
        _positionFuture = _getPositionWithPermission();
      });
    }
  }

  Future<void> _showMessageDialog(
    String title,
    String message, {
    String okText = 'OK',
    VoidCallback? onOk,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onOk?.call();
              },
              child: Text(okText),
            ),
          ],
        );
      },
    );
  }

  Future<Position?> _getPositionWithPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMessageDialog(
          '位置情報が無効です',
          '位置情報サービスがオフになっています。端末の設定でオンにしてください。',
          okText: '設定を開く',
          onOk: Geolocator.openLocationSettings,
        );
      });
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMessageDialog(
          '位置情報の許可が必要です',
          '位置情報の許可が拒否されました。許可しない場合は現在地を表示できません。',
        );
      });
      return null;
    }

    if (permission == LocationPermission.deniedForever) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMessageDialog(
          '位置情報の許可が必要です',
          '位置情報の許可が「今後表示しない」になっています。アプリ設定から許可をオンにしてください。',
          okText: '設定を開く',
          onOk: Geolocator.openAppSettings,
        );
      });
      return null;
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: FutureBuilder<Position?>(
        future: _positionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('位置情報の取得に失敗しました'),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('位置情報を取得できません'),
            );
          }

          final position = snapshot.data!;

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                position.latitude,
                position.longitude,
              ),
              zoom: 14.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          );
        },
      ),
    );
  }
}
