import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'water_history_page.dart'; // Import the WateringHistoryPage
import 'pot_model.dart';

class MonitoringScreen extends StatefulWidget {
  final Pot pot;

  const MonitoringScreen({super.key, required this.pot});

  @override
  _MonitoringScreenState createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  double waterLevel = 0.0;
  double humidity = 0.0;
  double temperature = 0.0;
  double soilMoisture = 0.0;
  Timer? _timer;
  bool isPumpOn = false;

  @override
  void initState() {
    super.initState();
    fetchDataFromThingSpeak();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => fetchDataFromThingSpeak());
  }

  Future<void> fetchDataFromThingSpeak() async {
    final url = Uri.parse('https://api.thingspeak.com/channels/${widget.pot.channelId}/feeds.json?api_key=${widget.pot.apiKey}&results=2');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          waterLevel = math.max(0.0, double.tryParse(data['feeds'].last['field1'].toString()) ?? 0.0);
          humidity = math.max(0.0, double.tryParse(data['feeds'].last['field2'].toString()) ?? 0.0);
          temperature = math.max(0.0, double.tryParse(data['feeds'].last['field3'].toString()) ?? 0.0);
          soilMoisture = math.max(0.0, double.tryParse(data['feeds'].last['field4'].toString()) ?? 0.0);
        });
      } else {
        print('Failed to fetch data from ThingSpeak: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data from ThingSpeak: $e');
    }
  }

  Future<void> sendPumpStateToESP(bool state) async {
    final url = Uri.parse('http://${widget.pot.ipAddress}/togglePump?state=${state ? 1 : 0}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        print('Pump state set successfully.');
      } else {
        print('Failed to set pump state: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending pump state to ESP8266: $e');
    }
  }

  Widget _buildParameterCard(String title, double value, Color color, double width, double height, {double strokeWidth = 20.0}) {
    final displayValue = value.clamp(0.0, 100.0);

    return Card(
      color: color,
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            if (title == 'WATER LEVEL')
              LayoutBuilder(
                builder: (context, constraints) {
                  final minDimension = math.min(constraints.maxWidth, constraints.maxHeight);
                  final circleSize = minDimension * 0.5;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: circleSize,
                        height: circleSize,
                        child: CircularProgressIndicator(
                          value: displayValue / 100,
                          backgroundColor: Colors.green[300],
                          valueColor: const AlwaysStoppedAnimation(Colors.blue),
                          strokeWidth: strokeWidth,
                        ),
                      ),
                      Text(
                        '${displayValue.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: minDimension * 0.15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
              ),
            if (title == 'SOIL MOISTURE')
              LayoutBuilder(
                builder: (context, constraints) {
                  final minDimension = math.min(constraints.maxWidth, constraints.maxHeight);
                  final circleWidth = minDimension * 0.5;
                  final circleHeight = minDimension * 0.5;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressBar(
                        progress: displayValue,
                        strokeWidth: strokeWidth,
                        progressColor: Colors.blue,
                        backgroundColor: Colors.green[300]!,
                        width: circleWidth,
                        height: circleHeight,
                      ),
                      Text(
                        '${displayValue.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: minDimension * 0.15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
              ),
            if (title != 'WATER LEVEL' && title != 'SOIL MOISTURE')
              Text(
                '${displayValue.toStringAsFixed(0)}${title == 'TEMPERATURE' ? '°C' : '%'}',
                style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final appBarHeight = AppBar().preferredSize.height;
    final padding = MediaQuery.of(context).padding;
    final availableHeight = screenSize.height - appBarHeight - padding.top - padding.bottom;

    final cardWidth = screenSize.width * 0.9;
    final cardHeightWaterLevel = screenSize.height * 0.4;
    final cardHeightSoilMoisture = screenSize.height * 0.4;
    final cardHeightHumidityTemperature = screenSize.height * 0.2;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Monitoring ${widget.pot.name}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.history, size: 30),
            onPressed: () {
              // Navigate to WateringHistoryPage with the specific pot data
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WateringHistoryPage(pot: widget.pot),
                ),
              );
            },
          ),
          SizedBox(
            width: 60,
            height: 40,
            child: IconButton(
              icon: Icon(isPumpOn ? Icons.toggle_on : Icons.toggle_off, size: 40),
              onPressed: () async {
                setState(() {
                  isPumpOn = !isPumpOn;
                });
                await sendPumpStateToESP(isPumpOn);
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.blue, Colors.blueAccent],
            ),
          ),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              _buildParameterCard('WATER LEVEL', waterLevel, const Color.fromARGB(255, 76, 175, 80), cardWidth, cardHeightWaterLevel, strokeWidth: 30.0),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildParameterCard('HUMIDITY', humidity, const Color.fromARGB(255, 76, 175, 80), screenSize.width * 0.4, cardHeightHumidityTemperature),
                  _buildParameterCard('TEMPERATURE', temperature, const Color.fromARGB(255, 76, 175, 80), screenSize.width * 0.4, cardHeightHumidityTemperature),
                ],
              ),
              const SizedBox(height: 16),
              _buildParameterCard('SOIL MOISTURE', soilMoisture, const Color.fromARGB(255, 76, 175, 80), cardWidth, cardHeightSoilMoisture, strokeWidth: 20.0),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class CircularProgressBar extends StatelessWidget {
  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;
  final double width;
  final double height;

  const CircularProgressBar({super.key, 
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.backgroundColor,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final displayProgress = progress.clamp(0.0, 100.0);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CircularPainter(
          progress: displayProgress,
          strokeWidth: strokeWidth,
          progressColor: progressColor,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }
}

class _CircularPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;

  _CircularPainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double radius = size.width / 2;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    canvas.drawCircle(
      Offset(centerX, centerY),
      radius - (strokeWidth / 2),
      backgroundPaint,
    );

    final double sweepAngle = 2 * math.pi * (progress / 100);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius - (strokeWidth / 2)),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
