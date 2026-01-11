import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pet_clinic/views/appointment_view.dart';
import 'package:pet_clinic/views/complete_profile_view.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/pet_viewmodel.dart';
import 'viewmodels/appointment_viewmodel.dart';
import 'views/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        /// 🔐 Auth service
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),

        /// 🔐 Auth state
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) =>
              AuthViewModel(context.read<AuthService>()),
        ),

        /// 🐾 Pets
        ChangeNotifierProvider<PetViewModel>(
          create: (_) => PetViewModel(),
        ),

        /// 📅 Appointments
        ChangeNotifierProvider<AppointmentViewModel>(
          create: (_) => AppointmentViewModel(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Paws & Claws',

      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),

      /// 🔑 AuthGate decides Login / MainScaffold
      home: const AuthGate(),

      /// 🧭 App routes
      routes: {
        '/appointment': (context) => const BookVisitView(),
        '/complete-profile': (context) => const CompleteProfileView(), // ✅ Add this
      },
    );
  }
}
