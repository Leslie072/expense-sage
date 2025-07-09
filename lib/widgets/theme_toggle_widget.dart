import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeToggleWidget extends StatefulWidget {
  final Function(bool isDark)? onThemeChanged;

  const ThemeToggleWidget({
    super.key,
    this.onThemeChanged,
  });

  @override
  State<ThemeToggleWidget> createState() => _ThemeToggleWidgetState();
}

class _ThemeToggleWidgetState extends State<ThemeToggleWidget>
    with TickerProviderStateMixin {
  bool _isDarkMode = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadThemePreference();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    setState(() {
      _isDarkMode = isDark;
      if (_isDarkMode) {
        _animationController.forward();
      }
    });
  }

  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode;
      if (_isDarkMode) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
    
    await prefs.setBool('isDarkMode', _isDarkMode);
    widget.onThemeChanged?.call(_isDarkMode);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isDarkMode ? 'Dark mode enabled' : 'Light mode enabled',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleTheme,
      child: Container(
        width: 60,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: _isDarkMode
                ? [Colors.indigo.shade800, Colors.purple.shade800]
                : [Colors.orange.shade300, Colors.yellow.shade300],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _isDarkMode
                  ? Colors.indigo.shade200
                  : Colors.orange.shade200,
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background icons
            Positioned(
              left: 8,
              top: 6,
              child: Icon(
                Icons.wb_sunny,
                size: 18,
                color: _isDarkMode
                    ? Colors.white.withOpacity(0.3)
                    : Colors.white,
              ),
            ),
            Positioned(
              right: 8,
              top: 6,
              child: Icon(
                Icons.nightlight_round,
                size: 18,
                color: _isDarkMode
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
              ),
            ),
            // Animated toggle
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Positioned(
                  left: _animation.value * 30 + 2,
                  top: 2,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                      size: 16,
                      color: _isDarkMode
                          ? Colors.indigo.shade800
                          : Colors.orange.shade600,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
