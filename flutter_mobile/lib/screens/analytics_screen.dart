import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/corridor.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ApiService _apiService = ApiService();
  AnalyticsSummary? _summary;
  Map<String, dynamic>? _criteriaData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final summary = await _apiService.fetchAnalyticsSummary();
    final criteria = await _apiService.fetchSuccessCriteria();
    setState(() {
      _summary = summary;
      _criteriaData = criteria;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final criteriaList = (_criteriaData?['criteria'] as List<dynamic>?) ?? [];
    final passedCount = _criteriaData?['passed'] ?? 0;
    final totalCount = _criteriaData?['totalCriteria'] ?? 12;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.only(top: 44, left: 16, right: 16, bottom: 12),
            color: const Color(0xFF075985),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📊 System Analytics & Evaluation',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadData,
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Overview Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'PROTOTYPE EVALUATION',
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: passedCount == totalCount ? const Color(0x3310B981) : const Color(0x33EAB308),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: passedCount == totalCount ? const Color(0xFF10B981) : const Color(0xFFEAB308)),
                                  ),
                                  child: Text(
                                    '$passedCount / $totalCount PASSED',
                                    style: TextStyle(
                                      color: passedCount == totalCount ? const Color(0xFF34D399) : const Color(0xFFFDE047),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryItem('Vehicles', '${_summary?.totalVehiclesEvaluated ?? 0}'),
                                _buildSummaryItem('Alerts', '${_summary?.totalAlertsDispatched ?? 0}'),
                                _buildSummaryItem('Avg Clear', '${_summary?.averageClearanceTimeSeconds.toStringAsFixed(1) ?? "0.0"}s'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'SUCCESS CRITERIA CHECKLIST',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 8),

                      ...criteriaList.map((item) {
                        final status = item['status']?.toString() ?? 'FAIL';
                        final isPass = status == 'PASS';
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isPass ? const Color(0x3310B981) : const Color(0x33EF4444)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isPass ? Icons.check_circle : Icons.cancel,
                                color: isPass ? const Color(0xFF34D399) : const Color(0xFFF87171),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name']?.toString() ?? '',
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['notes']?.toString() ?? '',
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
      ],
    );
  }
}
