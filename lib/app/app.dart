import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/library/presentation/views/library_page.dart';
import '../features/library/presentation/viewmodels/library_view_model.dart';
import 'di/injection.dart';
import 'theme/app_theme.dart';

class InteractiveReadingApp extends StatelessWidget {
  const InteractiveReadingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LibraryViewModel>(
      create: (_) => sl.createLibraryViewModel(),
      child: MaterialApp(
        title: 'Interactive Reading',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const LibraryPage(),
      ),
    );
  }
}
