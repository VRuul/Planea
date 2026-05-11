import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

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
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, locProvider, _) {
          return MaterialApp.router(
            title: 'Planea',
            debugShowCheckedModeBanner: false,

            // ── Localizations ──────────────────────────────────
            locale: locProvider.locale, // null = system auto-detect
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              // If the user picked a specific locale, use it
              if (locProvider.locale != null) return locProvider.locale;
              // Otherwise find best match from device locale
              for (final supported in supportedLocales) {
                if (deviceLocale?.languageCode == supported.languageCode) {
                  return supported;
                }
              }
              return supportedLocales.first; // fallback to English
            },

            // ── Theme ──────────────────────────────────────────
            theme: themeProvider.buildTheme(Brightness.light),
            darkTheme: themeProvider.buildTheme(Brightness.dark),
            themeMode: themeProvider.themeMode,

            // ── Router ─────────────────────────────────────────
            routerConfig: AppRouter.router,
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
