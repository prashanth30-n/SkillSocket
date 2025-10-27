import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';


class HistoryDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const HistoryDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final int completedClasses = data['completed'] ?? 0;
    final int totalClasses = data['total'] ?? 1;

    final Map<String, double> chartData = {
      "Completed": completedClasses.toDouble(),
      "Remaining": (totalClasses - completedClasses).toDouble(),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(data['title'] ?? "Detail",style: TextStyle(color: Colors.white),),
        backgroundColor: Color(0xFF123b53),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pie Chart
              Center(
                child: PieChart(
                  dataMap: chartData,
                  animationDuration: Duration(milliseconds: 800),
                  chartType: ChartType.ring,
                  chartRadius: 150,
                  ringStrokeWidth: 30,
                  colorList: [Color(0xFF66B7D2), Color(0xFFB6E1F0)],
                  chartValuesOptions: ChartValuesOptions(
                    showChartValuesInPercentage: true,
                    showChartValueBackground: false,
                    showChartValuesOutside: false,
                    chartValueStyle: TextStyle(fontWeight: FontWeight.bold,color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                  legendOptions: LegendOptions(
                    legendPosition: LegendPosition.bottom,
                    showLegends: true,
                    legendTextStyle: TextStyle(fontSize: 14),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Numeric Info
              Text(
                "Progress:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                "$completedClasses out of $totalClasses classes completed",
                style: TextStyle(fontSize: 16),
              ),
              Divider(height: 32),

              // Session Info
              Text("Type: ${data['type']}", style: TextStyle(fontSize: 18)),
              Text("Date: ${data['date']}", style: TextStyle(fontSize: 18)),
              Text("Time: ${data['time']}", style: TextStyle(fontSize: 18)),
              Text("Status: ${data['status']}", style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
              Text("Description:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(data['description'] ?? "No description provided.", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
