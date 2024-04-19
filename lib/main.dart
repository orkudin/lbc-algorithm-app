import 'package:flutter/material.dart';
import 'package:lbc_algorithm/screen/lbc_algorithm.dart';

final colorScheme = ColorScheme.fromSeed(
  brightness: Brightness.dark,
  seedColor: const Color.fromARGB(255, 179, 131, 190),
  background: const Color.fromARGB(255, 56, 49, 66),
  surface: const Color.fromARGB(255, 73, 42, 80),
);

final theme = ThemeData.dark().copyWith(
  useMaterial3: true,
  colorScheme: colorScheme,
  scaffoldBackgroundColor: colorScheme.background,
  textTheme: const TextTheme().copyWith(
    titleSmall: const TextStyle(fontFamily: 'Varela'),
    titleMedium: const TextStyle(fontFamily: 'Varela'),
    titleLarge: const TextStyle(fontFamily: 'Varela'),
  ),
);

void main() {
  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'LBC-3 Algorithm App',
        theme: theme,
        home: const LBC_AlgorithmScreen());
  }
}
