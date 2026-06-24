import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/data/datasources/biometric_datasource.dart';
import 'features/auth/domain/usecases/authenticate_user.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/steps/presentation/widgets/step_counter_widget.dart';
import 'features/tracking/presentation/widgets/route_map_widget.dart';
import 'features/activity/presentation/widgets/activity_monitor_widget.dart';
import 'features/history/data/datasources/history_local_datasource.dart';
import 'features/history/presentation/bloc/history_bloc.dart';
import 'features/history/presentation/pages/history_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FitnessApp());
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    final biometricDataSource = BiometricDataSourceImpl();
    final authenticateUser = AuthenticateUser(biometricDataSource);

    return MaterialApp(
      title: 'Fitness Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF6B00),
          secondary: Color(0xFFFF8C38),
          surface: Color(0xFFFFFFFF),
          onPrimary: Color(0xFFFFFFFF),
          onSurface: Color(0xFF0A0A0A),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFFFF),
          foregroundColor: Color(0xFF0A0A0A),
          elevation: 0,
          shadowColor: Color(0x0A000000),
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Color(0xFF0A0A0A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFFFF),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE8E8E8), width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B00),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          indicatorColor: Color(0xFFFF6B00),
          labelColor: Color(0xFFFF6B00),
          unselectedLabelColor: Color(0xFF999999),
          indicatorSize: TabBarIndicatorSize.label,
        ),
        dividerColor: const Color(0xFFE8E8E8),
      ),
      home: BlocProvider(
        create: (_) => AuthBloc(authenticateUser),
        child: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isAuthenticated = false;

  void _onAuthSuccess() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return const HomePage();
    }
    return LoginPage(onAuthSuccess: _onAuthSuccess);
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HistoryBloc(HistoryLocalDatasource())
        ..add(HistoryLoadRequested()),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            systemOverlayStyle: SystemUiOverlayStyle.light,
            title: const Row(
              children: [
                Icon(Icons.bolt, color: Color(0xFFFF6B00)),
                SizedBox(width: 8),
                Text('Fitness Tracker', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            backgroundColor: const Color(0xFF0A0A0A),
            foregroundColor: Colors.white,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(49.0),
              child: Column(
                children: [
                  const TabBar(
                    indicatorColor: Color(0xFFFF6B00),
                    labelColor: Color(0xFFFF6B00),
                    unselectedLabelColor: Color(0xFF999999),
                    tabs: [
                      Tab(icon: Icon(Icons.bolt), text: 'Actividad'),
                      Tab(icon: Icon(Icons.bar_chart), text: 'Historial'),
                    ],
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFF1A1A1A)),
                ],
              ),
            ),
          ),
          body: const TabBarView(
            children: [
              _ActivityTab(),
              HistoryPage(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTab extends StatefulWidget {
  const _ActivityTab();

  @override
  State<_ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<_ActivityTab> {
  static const List<String> _quotes = [
    '"Siempre parece imposible hasta que se hace." — Nelson Mandela',
    '"No cuentes los días, haz que los días cuenten." — Muhammad Ali',
    '"La excelencia no es un acto, sino un hábito." — Will Durant',
    '"La suerte es lo que sucede cuando la preparación se encuentra con la oportunidad." — Séneca',
    '"La mejor manera de empezar es dejar de hablar y comenzar a hacer." — Walt Disney',
    '"El futuro depende de lo que hagas hoy." — Mahatma Gandhi',
    '"La perseverancia conquista todas las cosas." — Benjamin Franklin',
    '"La energía y la persistencia conquistan todas las cosas." — Benjamin Franklin',
    '"El éxito es la suma de pequeños esfuerzos repetidos cada día." — Robert Collier',
  ];

  late final String _quote;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _quote = _quotes[random.nextInt(_quotes.length)];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Banner de bienvenida
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Saludos atleta! 💪',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _quote,
                  style: const TextStyle(
                    color: Color(0xFFFF6B00),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const ActivityMonitorWidget(),
          const SizedBox(height: 12),
          const StepCounterWidget(),
          const SizedBox(height: 12),
          const RouteMapWidget(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
