import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Currency {
  final String code;
  final String name;
  final String symbol;
  final String flag;

  Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: json['code'],
      name: json['name'],
      symbol: json['symbol'],
      flag: json['flag'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'symbol': symbol,
      'flag': flag,
    };
  }
}

class CurrencyHelper {
  static const String _exchangeRateKey = 'exchange_rates';
  static const String _lastUpdateKey = 'exchange_rates_last_update';
  static const Duration _cacheExpiry = Duration(hours: 6);

  static Map<String, Currency> _currencies = {};
  static Map<String, double> _exchangeRates = {};

  // Load currencies from assets
  static Future<void> loadCurrencies() async {
    if (_currencies.isNotEmpty) return;

    try {
      final String response =
          await rootBundle.loadString('assets/currencies.json');
      final Map<String, dynamic> data = json.decode(response);
      final List<dynamic> currencyList = data['currencies'];

      _currencies = {
        for (var currencyData in currencyList)
          currencyData['code']: Currency.fromJson(currencyData)
      };
    } catch (e) {
      print('Error loading currencies: $e');
      // Fallback currencies
      _currencies = {
        'USD': Currency(
            code: 'USD', name: 'US Dollar', symbol: '\$', flag: '🇺🇸'),
        'XAF': Currency(
            code: 'XAF',
            name: 'Central African CFA Franc',
            symbol: 'FCFA',
            flag: '🇨🇲'),
      };
    }
  }

  // Get all available currencies
  static Future<List<Currency>> getAllCurrencies() async {
    await loadCurrencies();
    return _currencies.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // Get currency by code
  static Future<Currency?> getCurrency(String code) async {
    await loadCurrencies();
    return _currencies[code];
  }

  // Format amount with currency
  static String format(
    double amount, {
    String? symbol,
    String? name,
    String? locale,
    int decimalPlaces = 2,
  }) {
    // Use provided symbol or get from currency code
    String currencySymbol = symbol ?? '\$';

    if (name != null && _currencies.containsKey(name)) {
      currencySymbol = _currencies[name]!.symbol;
    }

    // Format based on currency type
    if (name == 'XAF' || name == 'XOF') {
      // CFA Franc formatting (no decimal places typically)
      return '${NumberFormat('#,###', locale ?? 'fr_FR').format(amount)} $currencySymbol';
    } else if (name == 'JPY') {
      // Japanese Yen (no decimal places)
      return '$currencySymbol${NumberFormat('#,###', locale ?? 'ja_JP').format(amount)}';
    } else {
      // Standard formatting with decimals
      return '$currencySymbol${NumberFormat('#,##0.${List.filled(decimalPlaces, '0').join()}', locale ?? 'en_US').format(amount)}';
    }
  }

  // Fetch exchange rates from API
  static Future<void> fetchExchangeRates({String baseCurrency = 'USD'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getString(_lastUpdateKey);

      // Check if cache is still valid
      if (lastUpdate != null) {
        final lastUpdateTime = DateTime.parse(lastUpdate);
        if (DateTime.now().difference(lastUpdateTime) < _cacheExpiry) {
          // Load from cache
          final cachedRates = prefs.getString(_exchangeRateKey);
          if (cachedRates != null) {
            _exchangeRates = Map<String, double>.from(json.decode(cachedRates));
            return;
          }
        }
      }

      // Fetch fresh rates (using a free API like exchangerate-api.com)
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/$baseCurrency'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _exchangeRates = Map<String, double>.from(data['rates']);

        // Cache the rates
        await prefs.setString(_exchangeRateKey, json.encode(_exchangeRates));
        await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      }
    } catch (e) {
      print('Error fetching exchange rates: $e');
      // Use fallback rates if available
      final prefs = await SharedPreferences.getInstance();
      final cachedRates = prefs.getString(_exchangeRateKey);
      if (cachedRates != null) {
        _exchangeRates = Map<String, double>.from(json.decode(cachedRates));
      }
    }
  }

  // Convert amount between currencies
  static Future<double> convertCurrency(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    if (fromCurrency == toCurrency) return amount;

    await fetchExchangeRates();

    if (_exchangeRates.isEmpty) return amount;

    // Convert to USD first, then to target currency
    double usdAmount = amount;
    if (fromCurrency != 'USD') {
      final fromRate = _exchangeRates[fromCurrency];
      if (fromRate == null) return amount;
      usdAmount = amount / fromRate;
    }

    if (toCurrency == 'USD') return usdAmount;

    final toRate = _exchangeRates[toCurrency];
    if (toRate == null) return amount;

    return usdAmount * toRate;
  }

  // Get exchange rate between two currencies
  static Future<double?> getExchangeRate(
      String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) return 1.0;

    await fetchExchangeRates();

    if (_exchangeRates.isEmpty) return null;

    final fromRate = _exchangeRates[fromCurrency] ?? 1.0;
    final toRate = _exchangeRates[toCurrency] ?? 1.0;

    return toRate / fromRate;
  }

  // Format with conversion
  static Future<String> formatWithConversion(
    double amount,
    String fromCurrency,
    String toCurrency, {
    int decimalPlaces = 2,
  }) async {
    final convertedAmount =
        await convertCurrency(amount, fromCurrency, toCurrency);
    return format(convertedAmount,
        name: toCurrency, decimalPlaces: decimalPlaces);
  }
}
