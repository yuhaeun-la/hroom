import 'package:flutter/material.dart';

class MentoringThermometer extends StatefulWidget {
  final double temperature; // 0-100
  final Color color;
  final String status;

  const MentoringThermometer({
    super.key,
    required this.temperature,
    required this.color,
    required this.status,
  });

  @override
  State<MentoringThermometer> createState() => _MentoringThermometerState();
}

class _MentoringThermometerState extends State<MentoringThermometer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.temperature,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '온도계',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return SizedBox(
                height: 200,
                width: 80,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // 온도계 배경
                    Container(
                      width: 20,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // 온도계 눈금
                    Positioned(
                      left: 25,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildScale('100°', true),
                          _buildScale('80°', false),
                          _buildScale('60°', false),
                          _buildScale('40°', false),
                          _buildScale('20°', false),
                          _buildScale('0°', true),
                        ],
                      ),
                    ),
                    // 온도 표시
                    Container(
                      width: 20,
                      height: 180 * (_animation.value / 100),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: _getGradientColors(_animation.value),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // 온도계 구
                    Positioned(
                      bottom: -10,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: widget.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.color.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${_animation.value.toInt()}°',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.color.withOpacity(0.3)),
            ),
            child: Text(
              widget.status,
              style: TextStyle(
                color: widget.color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildTemperatureDescription(),
        ],
      ),
    );
  }

  Widget _buildScale(String label, bool isMajor) {
    return Row(
      children: [
        Container(
          width: isMajor ? 8 : 4,
          height: 1,
          color: Colors.grey[400],
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: isMajor ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  List<Color> _getGradientColors(double temperature) {
    if (temperature >= 70) {
      return [
        const Color(0xFFDC2626), // 빨간색
        const Color(0xFFF59E0B), // 주황색
      ];
    } else if (temperature >= 40) {
      return [
        const Color(0xFFF59E0B), // 주황색
        const Color(0xFFFDE047), // 노란색
      ];
    } else {
      return [
        const Color(0xFF3B82F6), // 파란색
        const Color(0xFF06B6D4), // 청록색
      ];
    }
  }

  Widget _buildTemperatureDescription() {
    String description;
    if (widget.temperature >= 70) {
      description = '서로에 대한 관심과 애정이\n매우 높은 상태입니다';
    } else if (widget.temperature >= 40) {
      description = '건강한 관계를 유지하고\n있습니다';
    } else {
      description = '열심히 해봐요!';
    }

    return Text(
      description,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
        height: 1.4,
      ),
    );
  }
}
