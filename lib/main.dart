import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:go_router/go_router.dart';

import 'core/extensions/l10n_extension.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/locale_provider.dart';
import 'app/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final localeProvider = LocaleProvider();
  await localeProvider.load(); // restore persisted locale before first frame

  runApp(PlaneaApp(localeProvider: localeProvider));
}

class PlaneaApp extends StatelessWidget {
  final LocaleProvider localeProvider;
  const PlaneaApp({super.key, required this.localeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider.value(value: localeProvider),
        // Creamos el router una sola vez, pero le pasamos el AuthProvider para que reaccione
        ProxyProvider<AuthProvider, GoRouter>(
          update: (context, auth, previous) => previous ?? AppRouter.createRouter(auth),
        ),
      ],
      child: Consumer3<ThemeProvider, LocaleProvider, GoRouter>(
        builder: (context, themeProvider, locProvider, router, _) {
          return MaterialApp.router(
            title: 'Planea',
            debugShowCheckedModeBanner: false,

            // ... (Localizations config) ...
            locale: locProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              if (locProvider.locale != null) return locProvider.locale;
              for (final supported in supportedLocales) {
                if (deviceLocale?.languageCode == supported.languageCode) {
                  return supported;
                }
              }
              return supportedLocales.first;
            },

            // ── Theme ──────────────────────────────────────────
            theme: themeProvider.buildTheme(Brightness.light),
            darkTheme: themeProvider.buildTheme(Brightness.dark),
            themeMode: themeProvider.themeMode,

            // ── Router ─────────────────────────────────────────
            routerConfig: router,
            builder: (context, child) => ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: const [
                Breakpoint(start: 0, end: 480, name: MOBILE),
                Breakpoint(start: 481, end: 900, name: TABLET),
                Breakpoint(start: 901, end: double.infinity, name: DESKTOP),
              ],
            ),
          );
        },
      ),
    );
  }
}
