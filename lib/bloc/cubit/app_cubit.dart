import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  late String? username;
  late int themeColor;
  late String? currency;

  static Future<AppState> getState() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      AppState appState = AppState();
      appState.themeColor = prefs.getInt("themeColor") ?? Colors.green.value;
      appState.username = prefs.getString("username");
      appState.currency = prefs.getString("currency");

      return appState;
    } catch (e) {
      // Fallback to default state if SharedPreferences fails
      AppState appState = AppState();
      appState.themeColor = Colors.green.value;
      appState.username = null;
      appState.currency = null;
      return appState;
    }
  }
}

class AppCubit extends Cubit<AppState> {
  AppCubit(AppState initialState) : super(initialState);

  Future<void> updateUsername(username) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("username", username);
    emit(await AppState.getState());
  }

  Future<void> updateCurrency(currency) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("currency", currency);
    emit(await AppState.getState());
  }

  Future<void> updateThemeColor(int color) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt("themeColor", color);
    emit(await AppState.getState());
  }

  Future<void> reset() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("currency");
    await prefs.remove("themeColor");
    await prefs.remove("username");
    emit(await AppState.getState());
  }
}
