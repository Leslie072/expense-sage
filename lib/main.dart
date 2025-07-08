import 'package:expense_sage/app.dart';
import 'package:expense_sage/bloc/cubit/app_cubit.dart';
import 'package:expense_sage/bloc/cubit/auth_cubit.dart';
import 'package:expense_sage/services/preloader_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start preloading services in background
  PreloaderService.initialize();

  // Load app state quickly
  final appState = await AppState.getState();

  runApp(MultiBlocProvider(providers: [
    BlocProvider(create: (_) => AuthCubit()),
    BlocProvider(create: (_) => AppCubit(appState))
  ], child: const App()));
}
