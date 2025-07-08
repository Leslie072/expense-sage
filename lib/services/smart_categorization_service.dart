import 'package:expense_sage/model/category.model.dart';
import 'package:expense_sage/model/payment.model.dart';
import 'package:expense_sage/dao/payment_dao.dart';
import 'package:expense_sage/dao/category_dao.dart';
import 'package:flutter/foundation.dart' hide Category;

class CategorySuggestion {
  final Category category;
  final double confidence;
  final String reason;

  CategorySuggestion({
    required this.category,
    required this.confidence,
    required this.reason,
  });
}

class SmartCategorizationService {
  static final PaymentDao _paymentDao = PaymentDao();
  static final CategoryDao _categoryDao = CategoryDao();

  // Keywords for different categories
  static const Map<String, List<String>> _categoryKeywords = {
    'Food': [
      'restaurant',
      'cafe',
      'pizza',
      'burger',
      'coffee',
      'starbucks',
      'mcdonald',
      'kfc',
      'subway',
      'domino',
      'grocery',
      'supermarket',
      'food',
      'dining',
      'lunch',
      'dinner',
      'breakfast',
      'snack',
      'bakery',
      'deli',
      'bistro'
    ],
    'Transportation': [
      'uber',
      'lyft',
      'taxi',
      'bus',
      'train',
      'metro',
      'subway',
      'gas',
      'fuel',
      'petrol',
      'parking',
      'toll',
      'car',
      'vehicle',
      'transport',
      'airline',
      'flight',
      'airport',
      'rental',
      'bike',
      'scooter'
    ],
    'Shopping': [
      'amazon',
      'walmart',
      'target',
      'mall',
      'store',
      'shop',
      'retail',
      'clothing',
      'shoes',
      'electronics',
      'book',
      'online',
      'purchase',
      'buy',
      'order',
      'delivery',
      'shopping',
      'market',
      'boutique'
    ],
    'Entertainment': [
      'movie',
      'cinema',
      'theater',
      'netflix',
      'spotify',
      'game',
      'gaming',
      'concert',
      'show',
      'event',
      'ticket',
      'entertainment',
      'fun',
      'leisure',
      'club',
      'bar',
      'pub',
      'party',
      'festival',
      'amusement',
      'recreation'
    ],
    'Utilities': [
      'electric',
      'electricity',
      'water',
      'gas',
      'internet',
      'phone',
      'mobile',
      'cable',
      'wifi',
      'utility',
      'bill',
      'service',
      'provider',
      'telecom',
      'heating',
      'cooling',
      'trash',
      'waste',
      'sewer',
      'maintenance'
    ],
    'Healthcare': [
      'doctor',
      'hospital',
      'clinic',
      'pharmacy',
      'medicine',
      'medical',
      'health',
      'dental',
      'dentist',
      'insurance',
      'prescription',
      'treatment',
      'therapy',
      'checkup',
      'surgery',
      'emergency',
      'ambulance',
      'nurse'
    ],
    'Education': [
      'school',
      'university',
      'college',
      'tuition',
      'education',
      'course',
      'class',
      'training',
      'workshop',
      'seminar',
      'book',
      'supplies',
      'student',
      'learning',
      'certification',
      'degree',
      'academic'
    ],
    'Housing': [
      'rent',
      'mortgage',
      'property',
      'home',
      'house',
      'apartment',
      'condo',
      'real estate',
      'landlord',
      'tenant',
      'housing',
      'residence',
      'dwelling',
      'lease',
      'deposit',
      'maintenance',
      'repair',
      'renovation',
      'furniture'
    ],
    'Personal Care': [
      'salon',
      'spa',
      'haircut',
      'beauty',
      'cosmetic',
      'skincare',
      'makeup',
      'personal',
      'care',
      'hygiene',
      'grooming',
      'massage',
      'manicure',
      'pedicure',
      'barber',
      'wellness',
      'fitness',
      'gym',
      'yoga'
    ],
    'Financial': [
      'bank',
      'atm',
      'fee',
      'charge',
      'interest',
      'loan',
      'credit',
      'debit',
      'transfer',
      'payment',
      'finance',
      'investment',
      'savings',
      'account',
      'financial',
      'money',
      'cash',
      'withdrawal',
      'deposit'
    ]
  };

  // Common merchant patterns
  static const Map<String, String> _merchantPatterns = {
    'AMZN': 'Shopping',
    'AMAZON': 'Shopping',
    'WALMART': 'Shopping',
    'TARGET': 'Shopping',
    'STARBUCKS': 'Food',
    'MCDONALD': 'Food',
    'UBER': 'Transportation',
    'LYFT': 'Transportation',
    'NETFLIX': 'Entertainment',
    'SPOTIFY': 'Entertainment',
    'PAYPAL': 'Financial',
    'VENMO': 'Financial',
    'CASHAPP': 'Financial',
  };

  // Amount-based patterns (in USD, adjust for other currencies)
  static const Map<String, List<double>> _amountPatterns = {
    'Food': [5.0, 50.0], // Typical food expenses
    'Transportation': [2.0, 100.0], // Typical transport costs
    'Utilities': [20.0, 300.0], // Typical utility bills
    'Entertainment': [10.0, 100.0], // Typical entertainment costs
    'Healthcare': [20.0, 500.0], // Typical medical costs
  };

  static Future<List<CategorySuggestion>> suggestCategories({
    required String title,
    required String description,
    required double amount,
    int maxSuggestions = 3,
  }) async {
    try {
      final categories = await _categoryDao.find(withSummery: false);
      final recentPayments = await _paymentDao.find();

      List<CategorySuggestion> suggestions = [];

      // 1. Keyword-based matching
      suggestions.addAll(_getKeywordBasedSuggestions(
        title: title,
        description: description,
        categories: categories,
      ));

      // 2. Merchant pattern matching
      suggestions.addAll(_getMerchantBasedSuggestions(
        title: title,
        description: description,
        categories: categories,
      ));

      // 3. Amount-based suggestions
      suggestions.addAll(_getAmountBasedSuggestions(
        amount: amount,
        categories: categories,
      ));

      // 4. Historical pattern matching
      suggestions.addAll(await _getHistoricalSuggestions(
        title: title,
        description: description,
        amount: amount,
        recentPayments: recentPayments,
        categories: categories,
      ));

      // 5. Frequency-based suggestions
      suggestions.addAll(await _getFrequencyBasedSuggestions(
        recentPayments: recentPayments,
        categories: categories,
      ));

      // Combine and rank suggestions
      Map<String, CategorySuggestion> combinedSuggestions = {};

      for (var suggestion in suggestions) {
        String key = suggestion.category.name;
        if (combinedSuggestions.containsKey(key)) {
          // Combine confidence scores
          double combinedConfidence =
              (combinedSuggestions[key]!.confidence + suggestion.confidence) /
                  2;
          combinedSuggestions[key] = CategorySuggestion(
            category: suggestion.category,
            confidence: combinedConfidence,
            reason: '${combinedSuggestions[key]!.reason}, ${suggestion.reason}',
          );
        } else {
          combinedSuggestions[key] = suggestion;
        }
      }

      // Sort by confidence and return top suggestions
      List<CategorySuggestion> finalSuggestions =
          combinedSuggestions.values.toList();
      finalSuggestions.sort((a, b) => b.confidence.compareTo(a.confidence));

      return finalSuggestions.take(maxSuggestions).toList();
    } catch (e) {
      debugPrint('Error in smart categorization: $e');
      return [];
    }
  }

  static List<CategorySuggestion> _getKeywordBasedSuggestions({
    required String title,
    required String description,
    required List<Category> categories,
  }) {
    List<CategorySuggestion> suggestions = [];
    String searchText = '$title $description'.toLowerCase();

    for (var entry in _categoryKeywords.entries) {
      String categoryName = entry.key;
      List<String> keywords = entry.value;

      int matchCount = 0;
      List<String> matchedKeywords = [];

      for (String keyword in keywords) {
        if (searchText.contains(keyword.toLowerCase())) {
          matchCount++;
          matchedKeywords.add(keyword);
        }
      }

      if (matchCount > 0) {
        // Find matching category
        Category? matchingCategory = categories.firstWhere(
          (cat) => cat.name.toLowerCase().contains(categoryName.toLowerCase()),
          orElse: () => categories.firstWhere(
            (cat) =>
                categoryName.toLowerCase().contains(cat.name.toLowerCase()),
            orElse: () => categories.first,
          ),
        );

        double confidence = (matchCount / keywords.length) * 0.8 + 0.2;
        confidence = confidence.clamp(0.0, 1.0);

        suggestions.add(CategorySuggestion(
          category: matchingCategory,
          confidence: confidence,
          reason: 'Keywords: ${matchedKeywords.join(", ")}',
        ));
      }
    }

    return suggestions;
  }

  static List<CategorySuggestion> _getMerchantBasedSuggestions({
    required String title,
    required String description,
    required List<Category> categories,
  }) {
    List<CategorySuggestion> suggestions = [];
    String searchText = '$title $description'.toUpperCase();

    for (var entry in _merchantPatterns.entries) {
      String pattern = entry.key;
      String categoryName = entry.value;

      if (searchText.contains(pattern)) {
        Category? matchingCategory = categories.firstWhere(
          (cat) => cat.name.toLowerCase().contains(categoryName.toLowerCase()),
          orElse: () => categories.firstWhere(
            (cat) =>
                categoryName.toLowerCase().contains(cat.name.toLowerCase()),
            orElse: () => categories.first,
          ),
        );

        suggestions.add(CategorySuggestion(
          category: matchingCategory,
          confidence: 0.9,
          reason: 'Merchant pattern: $pattern',
        ));
      }
    }

    return suggestions;
  }

  static List<CategorySuggestion> _getAmountBasedSuggestions({
    required double amount,
    required List<Category> categories,
  }) {
    List<CategorySuggestion> suggestions = [];

    for (var entry in _amountPatterns.entries) {
      String categoryName = entry.key;
      List<double> range = entry.value;

      if (amount >= range[0] && amount <= range[1]) {
        Category? matchingCategory = categories.firstWhere(
          (cat) => cat.name.toLowerCase().contains(categoryName.toLowerCase()),
          orElse: () => categories.firstWhere(
            (cat) =>
                categoryName.toLowerCase().contains(cat.name.toLowerCase()),
            orElse: () => categories.first,
          ),
        );

        // Calculate confidence based on how well the amount fits the typical range
        double midpoint = (range[0] + range[1]) / 2;
        double distance = (amount - midpoint).abs();
        double maxDistance = (range[1] - range[0]) / 2;
        double confidence = 1.0 - (distance / maxDistance);
        confidence = (confidence * 0.5 + 0.3).clamp(0.0, 1.0);

        suggestions.add(CategorySuggestion(
          category: matchingCategory,
          confidence: confidence,
          reason: 'Amount pattern (\$${range[0]}-\$${range[1]})',
        ));
      }
    }

    return suggestions;
  }

  static Future<List<CategorySuggestion>> _getHistoricalSuggestions({
    required String title,
    required String description,
    required double amount,
    required List<Payment> recentPayments,
    required List<Category> categories,
  }) async {
    List<CategorySuggestion> suggestions = [];
    String searchText = '$title $description'.toLowerCase();

    // Look for similar transactions in history
    Map<Category, int> categoryMatches = {};

    for (Payment payment in recentPayments) {
      String paymentText =
          '${payment.title} ${payment.description}'.toLowerCase();

      // Simple similarity check
      List<String> searchWords = searchText.split(' ');
      List<String> paymentWords = paymentText.split(' ');

      int commonWords = 0;
      for (String word in searchWords) {
        if (word.length > 2 && paymentWords.contains(word)) {
          commonWords++;
        }
      }

      if (commonWords > 0) {
        categoryMatches[payment.category] =
            (categoryMatches[payment.category] ?? 0) + commonWords;
      }
    }

    // Convert to suggestions
    for (var entry in categoryMatches.entries) {
      double confidence =
          (entry.value / searchText.split(' ').length).clamp(0.0, 0.8);

      suggestions.add(CategorySuggestion(
        category: entry.key,
        confidence: confidence,
        reason: 'Similar past transactions',
      ));
    }

    return suggestions;
  }

  static Future<List<CategorySuggestion>> _getFrequencyBasedSuggestions({
    required List<Payment> recentPayments,
    required List<Category> categories,
  }) async {
    List<CategorySuggestion> suggestions = [];

    // Count category usage frequency
    Map<Category, int> categoryFrequency = {};

    for (Payment payment in recentPayments) {
      categoryFrequency[payment.category] =
          (categoryFrequency[payment.category] ?? 0) + 1;
    }

    // Get top 3 most used categories
    List<MapEntry<Category, int>> sortedEntries =
        categoryFrequency.entries.toList();
    sortedEntries.sort((a, b) => b.value.compareTo(a.value));

    for (int i = 0; i < sortedEntries.length && i < 3; i++) {
      var entry = sortedEntries[i];
      double confidence = 0.3 - (i * 0.1); // Decreasing confidence

      suggestions.add(CategorySuggestion(
        category: entry.key,
        confidence: confidence,
        reason: 'Frequently used (${entry.value} times)',
      ));
    }

    return suggestions;
  }

  static Future<void> learnFromUserChoice({
    required String title,
    required String description,
    required double amount,
    required Category chosenCategory,
  }) async {
    // This could be expanded to store user preferences and improve suggestions
    // For now, we'll just log the choice for future ML model training
    debugPrint(
        'User chose ${chosenCategory.name} for "$title" - $description (\$${amount.toStringAsFixed(2)})');

    // In a real implementation, you might:
    // 1. Store this choice in a local database
    // 2. Send anonymized data to a server for ML model training
    // 3. Update local keyword weights based on user choices
  }
}
