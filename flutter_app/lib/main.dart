import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/config/theme.dart';
import 'package:dating_app/config/router.dart';
import 'package:dating_app/services/storage_service.dart';
import 'package:dating_app/services/api_service.dart';
import 'package:dating_app/services/ws_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize storage
  final storageService = StorageService();
  await storageService.init();

  runApp(DatingApp(storageService: storageService));
}

class DatingApp extends StatefulWidget {
  final StorageService storageService;

  const DatingApp({super.key, required this.storageService});

  @override
  State<DatingApp> createState() => _DatingAppState();
}

class _DatingAppState extends State<DatingApp> {
  late final ApiService _apiService;
  late final WsService _wsService;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(storage: widget.storageService);
    _wsService = WsService(storage: widget.storageService);
    _appRouter = AppRouter(storage: widget.storageService);
  }

  @override
  void dispose() {
    _apiService.dispose();
    _wsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: widget.storageService),
        Provider<ApiService>.value(value: _apiService),
        Provider<WsService>.value(value: _wsService),
      ],
      child: MaterialApp.router(
        title: 'Flame',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _appRouter.router,
      ),
    );
  }
}
