import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() => runApp(MoodChangerApp());

class MoodChangerApp extends StatefulWidget {
  @override
  _MoodChangerAppState createState() => _MoodChangerAppState();
}

class _MoodChangerAppState extends State<MoodChangerApp> with SingleTickerProviderStateMixin {
  // State variables
  final List<String> moods = ['😀', '😐', '😢', '😡', '😍'];
  int moodIndex = 0;
  double brightness = 1.0;
  double _opacity = 1.0;
  bool _animating = false;
  double _scale = 1.0;
  int _moodChangeCount = 0;
  int? _favoriteMoodIndex;
  bool isDarkMode = false;

  // Theme colors
  final List<ColorTheme> _themes = [
    ColorTheme('Cam 🍊', Colors.orange),
    ColorTheme('Xanh dương 🌊', Colors.blue),
    ColorTheme('Hồng 💗', Colors.pink),
    ColorTheme('Tím 🔮', Colors.purple),
    ColorTheme('Xanh lá 🌿', Colors.green),
  ];
  int _currentThemeIndex = 0;

  // Animation controller
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    )..addListener(() {
        setState(() {
          _scale = _scaleAnimation.value;
        });
      });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  // Swipe ngang: Đổi mood kế tiếp
  void _changeMood() {
    setState(() {
      moodIndex = (moodIndex + 1) % moods.length;
      _moodChangeCount++;
    });
    _playScaleAnimation();
  }

  // Tap: Fade animation
  void _animateEmoji() {
    if (_animating) return;
    setState(() {
      _animating = true;
      _opacity = 0.0;
    });

    _playScaleAnimation();

    Future.delayed(Duration(milliseconds: 180), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
        Future.delayed(Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _animating = false;
            });
          }
        });
      }
    });
  }

  // Double tap: Random mood
  void _randomMood() {
    final random = Random();
    int newIndex;
    do {
      newIndex = random.nextInt(moods.length);
    } while (newIndex == moodIndex && moods.length > 1);

    setState(() {
      moodIndex = newIndex;
      _moodChangeCount++;
    });
    _playScaleAnimation();
  }

  // Long press: Reset tất cả
  void _resetMood() {
    setState(() {
      moodIndex = 0;
      brightness = 1.0;
      _moodChangeCount = 0;
      _favoriteMoodIndex = null;
    });
    _scaleController.forward().then((_) => _scaleController.reverse());
  }

  // Toggle favorite emoji
  void _toggleFavorite() {
    setState(() {
      if (_favoriteMoodIndex == moodIndex) {
        _favoriteMoodIndex = null;
      } else {
        _favoriteMoodIndex = moodIndex;
      }
    });
  }

  // Đổi theme màu
  void _changeTheme() {
    setState(() {
      _currentThemeIndex = (_currentThemeIndex + 1) % _themes.length;
    });
  }

  // Scale animation (bounce effect)
  void _playScaleAnimation() {
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
  }

  // Vuốt dọc: Zoom in/out
  void _handleVerticalDrag(DragUpdateDetails details) {
    setState(() {
      _scale = (_scale - details.primaryDelta! / 500).clamp(0.5, 2.0);
    });
  }

  // Tính màu nền (HSL color space)
  Color get backgroundColor {
    final base = HSLColor.fromColor(_themes[_currentThemeIndex].color);
    final adjusted = base.withLightness(
      (0.15 + (brightness * 0.85)).clamp(0.08, 0.95),
    );
    return adjusted.toColor();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Changer Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
      home: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,

          // Gesture handlers
          onTap: _animateEmoji,
          onDoubleTap: _randomMood,
          onLongPress: _resetMood,
          onHorizontalDragEnd: (_) => _changeMood(),
          onVerticalDragUpdate: _handleVerticalDrag,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            color: backgroundColor,
            child: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Emoji với scale animation
                        Transform.scale(
                          scale: _scale,
                          child: AnimatedOpacity(
                            duration: Duration(milliseconds: 300),
                            opacity: _opacity,
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Text(
                                  moods[moodIndex],
                                  style: TextStyle(fontSize: 120),
                                ),
                                if (_favoriteMoodIndex == moodIndex)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Text(
                                      '⭐',
                                      style: TextStyle(fontSize: 30),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 30),
                        // Mood counter
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Đã đổi mood: $_moodChangeCount lần',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        SizedBox(height: 40),
                        // Controls
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Column(
                            children: [
                              // Slider độ sáng
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Độ sáng nền',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${(brightness * 100).round()}%',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),


                              Slider(
                                value: brightness,
                                onChanged: (val) {
                                  setState(() => brightness = val);
                                },
                                min: 0.2,
                                max: 1.0,
                                activeColor: Colors.white,
                                inactiveColor: Colors.white38,
                              ),
                              SizedBox(height: 10),

                              // Theme picker
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Màu nền',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Material(
                                    color: Colors.transparent,

                                    child: InkWell(
                                      onTap: _changeTheme,
                                      borderRadius: BorderRadius.circular(15),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(15),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: Text(
                                          _themes[_currentThemeIndex].name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              // Dark mode switch
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Chế độ tối',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Switch(
                                    value: isDarkMode,
                                    activeColor: Colors.deepPurple,
                                    onChanged: (bool value) {
                                      setState(() {
                                        isDarkMode = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              // Hướng dẫn
                              Text(
                                '👆 Tap: Fade effect\n'
                                '👆👆 Double tap: Random mood\n'
                                '👆 Long press: Reset tất cả\n'
                                '👈👉 Vuốt ngang: Đổi mood\n'
                                '👆👇 Vuốt dọc: Zoom in/out',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Favorite button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.transparent,
                      shape: CircleBorder(),
                      child: InkWell(
                        onTap: _toggleFavorite,
                        customBorder: CircleBorder(),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _favoriteMoodIndex == moodIndex ? '⭐' : '☆',
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class ColorTheme {
  final String name;
  final Color color;

  ColorTheme(this.name, this.color);
}