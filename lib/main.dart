import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '/app.dart';

import 'firebase_options.dart';

FirebaseAnalytics? analytics;
FirebaseAnalyticsObserver? observer;

late final FirebaseApp app;
late final FirebaseAuth? auth;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await preInitialize();

  runApp(ProviderScope(child: MyApp()));
}

Future preInitialize() async {
  app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  auth = FirebaseAuth.instanceFor(app: app);
  analytics = FirebaseAnalytics.instance;
  observer = FirebaseAnalyticsObserver(analytics: analytics!);

  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ),
  );
  // Default settings
  // await remoteConfig.setDefaults(const {
  //   "sitewide_discount": 10,
  //   "first_purchase_discount": 20,
  //   "referral_bonus": 5
  // });

// Fetch and activate the remote settings
  await remoteConfig.fetchAndActivate();

// Listen to real time update on remote config
  if (!kIsWeb) {
    remoteConfig.onConfigUpdated.listen((event) async {
      await remoteConfig.activate();
    });
  }
}
