import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart for charting
import 'pot_model.dart'; // Import Pot model

class WateringHistoryPage extends StatefulWidget {
  final Pot pot;

  const WateringHistoryPage({super.key, required this.pot});

  @override
  _WateringHistoryPageState createState() => _WateringHistoryPageState();
}

class _WateringHistoryPageState extends State<WateringHistoryPage> {
  List<FlSpot> field1Data = [];
  List<FlSpot> field2Data = [];
  List<FlSpot> field3Data = [];
  List<FlSpot> field4Data = [];

  @override
  void initState() {
    super.initState();
    fetchWateringHistory();
  }

  Future<void> fetchWateringHistory() async {
    final url = Uri.parse('https://api.thingspeak.com/channels/${widget.pot.channelId}/feeds.json?api_key=${widget.pot.apiKey}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final feeds = data['feeds'] as List<dynamic>;

        setState(() {
          field1Data = _processData(feeds, 'field1');
          field2Data = _processData(feeds, 'field2');
          field3Data = _processData(feeds, 'field3');
          field4Data = _processData(feeds, 'field4');
        });
      } else {
        print('Failed to fetch watering history: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching watering history: $e');
    }
  }

  List<FlSpot> _processData(List<dynamic> feeds, String fieldName) {
    return feeds
        .map((feed) {
      final timestamp = DateTime.parse(feed['created_at']);
      final value = double.tryParse(feed[fieldName].toString()) ?? 0.0;
      final cappedValue = value.clamp(0.0, 100.0); // Cap values between 0 and 100
      return FlSpot(
        timestamp.millisecondsSinceEpoch.toDouble(),
        cappedValue,
      );
    })
        .toList();
  }

  Widget _buildChart(List<FlSpot> data, Color color, String title) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium ?? const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200, // Set a fixed height for each chart
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 0, // Space for bottom titles
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 5, // Space from the axis
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30, // Space for left titles
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8, // Space from the axis
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false), // Hide top titles
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false), // Hide right titles
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: const Color(0xff37434d),
                      width: 1,
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data,
                      isCurved: false,
                      color: color,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                      barWidth: 2, // Adjust this if needed
                    ),
                  ],
                  minX: data.isNotEmpty ? data.first.x : 0,
                  maxX: data.isNotEmpty ? data.last.x : 1,
                  minY: 0, // Set minY to 0
                  maxY: 100, // Set maxY to 100
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Watering History for ${widget.pot.name}'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            _buildChart(field1Data, Colors.blue, 'Water Level Chart'),
            _buildChart(field2Data, Colors.green, 'Humidity Level Chart'),
            _buildChart(field3Data, Colors.red, 'Temperature Level Chart'),
            _buildChart(field4Data, Colors.orange, 'Soil Moisture Level Chart'),
          ],
        ),
      ),
    );
  }
}
