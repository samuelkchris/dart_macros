import 'package:flutter/material.dart';

import 'app.dart';
import 'config/app_config.dart';

void main() {

  AppConfig.initialize();
  // Run the app
  runApp(TaskTrackerApp());
}