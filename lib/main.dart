import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:go_router/go_router.dart';

import 'core/extensions/l10n_extension.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/seating_provider.dart';
import 'app/app_router.dart';

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Reemplazar con tus credenciales de Supabase Dashboard
  await Supabase.initialize(
    url: 'https://omdfdwqwbkdwvbzcqbrz.supabase.co',
    anonKey: 'sb_publishable_Q-JHinzS8KEgkTJyxzKbZA_IhOW-jDp',
  );

  final localeProvider = LocaleProvider();
  await localeProvider.load();

  final themeProvider = ThemeProvider();
  await themeProvider.load();

  runApp(PlaneaApp(
    localeProvider: localeProvider,
    themeProvider: themeProvider,
  ));
}

class PlaneaApp extends StatelessWidget {
  final LocaleProvider localeProvider;
  final ThemeProvider themeProvider;
  const PlaneaApp({
    super.key, 
    required this.localeProvider,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ThemeProvider>(
          create: (_) => themeProvider,
          update: (_, auth, theme) => theme!..updateUserId(auth.currentUser?.id),
        ),
        ChangeNotifierProxyProvider<AuthProvider, LocaleProvider>(
          create: (_) => localeProvider,
          update: (_, auth, loc) => loc!..updateUserId(auth.currentUser?.id),
        ),
        ChangeNotifierProxyProvider<AuthProvider, EventProvider>(
          create: (_) => EventProvider(),
          update: (_, auth, event) => event!..updateUserId(auth.currentUser?.id),
        ),
        ChangeNotifierProxyProvider<EventProvider, SeatingProvider>(
          create: (_) => SeatingProvider(),
          update: (_, event, seating) => seating!..updateEventId(event.currentEventId),
        ),
        // Creamos el router una sola vez, pero le pasamos el AuthProvider para que reaccione
        ProxyProvider<AuthProvider, GoRouter>(
          update: (context, auth, previous) =>
              previous ?? AppRouter.createRouter(auth),
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
