import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/auth_service.dart';
import 'providers/explain_provider.dart';
import 'providers/application_provider.dart';
import 'providers/recruiter_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/employer_dashboard.dart';
import 'screens/candidate_dashboard.dart';
import 'screens/home_screen.dart';
import 'screens/explain_screen.dart';
import 'screens/my_applications_screen.dart';
import 'screens/applicants_screen.dart';
import 'screens/job_list_screen.dart';
import 'screens/job_detail_screen.dart';
import 'providers/job_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService();
  await authService.loadToken();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        // ExplainProvider lives at root so it survives navigation
        ChangeNotifierProvider(create: (_) => ExplainProvider()),
        // ApplicationProvider at root so applied-job state persists across routes
        ChangeNotifierProvider(create: (_) => ApplicationProvider()),
        // RecruiterProvider scoped at root (one job at a time is fine for demo)
        ChangeNotifierProvider(create: (_) => RecruiterProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);

    _router = GoRouter(
      refreshListenable: authService,
      initialLocation: authService.isAuthenticated
          ? (authService.role == 'recruiter' || authService.role == 'employer' ? '/recruiter' : '/candidate')
          : '/login',
      redirect: (context, state) {
        final isLoggedIn = authService.isAuthenticated;
        final loc = state.matchedLocation;
        final isAuthRoute = loc == '/login' || loc == '/register';

        // Public routes
        final isPublicRoute = loc == '/home' || loc.startsWith('/explain');

        if (!isLoggedIn && !isAuthRoute && !isPublicRoute) return '/login';
        if (isLoggedIn && isAuthRoute) {
          return (authService.role == 'recruiter' || authService.role == 'employer') ? '/recruiter' : '/candidate';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const AuthScreen(isLogin: true),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const AuthScreen(isLogin: false),
        ),
        GoRoute(
          path: '/recruiter',
          builder: (context, state) => const EmployerDashboard(),
        ),
        GoRoute(
          path: '/candidate',
          builder: (context, state) => const CandidateDashboard(),
        ),
        GoRoute(
          path: '/create-job',
          builder: (context, state) => const CreateJobScreen(),
        ),
        GoRoute(
          path: '/jobs',
          builder: (context, state) => const JobListScreen(),
        ),
        GoRoute(
          path: '/jobs/:jobId',
          builder: (context, state) {
            final jobId = int.tryParse(state.pathParameters['jobId'] ?? '') ?? 0;
            return JobDetailScreen(jobId: jobId);
          },
        ),
        // ── Legacy/Compatibility Routes ────────────────────────────────────
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/explain/:jobId',
          builder: (context, state) {
            final jobId = int.tryParse(state.pathParameters['jobId'] ?? '') ?? 0;
            final jobTitle = state.extra as String? ?? 'Job Details';
            return ChangeNotifierProvider(
              create: (_) => ExplainProvider(),
              child: ExplainScreen(jobId: jobId, jobTitle: jobTitle),
            );
          },
        ),
        GoRoute(
          path: '/my-applications',
          builder: (context, state) => const MyApplicationsScreen(),
        ),
        GoRoute(
          path: '/applicants/:jobId',
          builder: (context, state) {
            final jobId    = int.tryParse(state.pathParameters['jobId'] ?? '') ?? 0;
            final jobTitle = state.extra as String? ?? 'Job';
            return ChangeNotifierProvider(
              create: (_) => RecruiterProvider(),
              child: ApplicantsScreen(jobId: jobId, jobTitle: jobTitle),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShadApp.router(
      title: 'AI Job Match Platform',
      debugShowCheckedModeBanner: false,
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(
          primary: Color(0xFF6C63FF),
          background: Color(0xFF0F0F16),
          foreground: Colors.white,
          card: Color(0xFF1E1E2C),
        ),
        textTheme: ShadTextTheme.fromGoogleFont(GoogleFonts.outfit),
      ),
      themeMode: ThemeMode.dark,
      routerConfig: _router,
    );
  }
}
