import 'package:example/screens/home_screen.dart';
import 'package:flutter/material.dart';

import 'config/app_config.dart';

class TaskTrackerApp extends StatelessWidget {
  const TaskTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: AppConfig.enableDarkMode ? Brightness.dark : Brightness.light,
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: AppConfig.isDevelopment(),
    );
  }
}

class AppInfoBanner extends StatelessWidget {
  const AppInfoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // Only show debug info in development or staging
    if (!AppConfig.showDebugInfo()) {
      return SizedBox.shrink();
    }

    return Container(
      color: Colors.amber,
      padding: EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline),
          SizedBox(width: 8),
          Text(
            'Environment: ${AppConfig.environment} | '
                'API: ${AppConfig.apiBaseUrl.split('/').last}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}