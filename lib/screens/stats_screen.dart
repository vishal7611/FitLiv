import 'package:flutter/material.dart';
import '../models/workout_session.dart';
import '../services/workout_storage_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<WorkoutSession> _allSessions = [];
  Map<String, dynamic> _totalStats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final sessions = await WorkoutStorageService.getSessions();
    sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Most recent first

    int totalReps = 0;
    int totalGoodReps = 0;
    double totalDuration = 0;
    
    for (var s in sessions) {
      totalReps += s.reps;
      totalGoodReps += s.goodReps;
      totalDuration += s.durationInSeconds;
    }

    setState(() {
      _allSessions = sessions;
      _totalStats = {
        'totalReps': totalReps,
        'totalSessions': sessions.length,
        'totalDuration': totalDuration,
        'avgEfficiency': sessions.isEmpty ? 0.0 : (totalGoodReps / totalReps) * 100,
      };
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
                  : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF151B2E), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          const Text('Performance Report', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        height: 48,
        decoration: BoxDecoration(color: const Color(0xFF151B2E), borderRadius: BorderRadius.circular(16)),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF7B2FFF)]),
            borderRadius: BorderRadius.circular(12),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [Tab(text: 'Analysis'), Tab(text: 'Log Book')],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_allSessions.isEmpty) return _buildEmptyState();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildStatCard('Total Reps', '${_totalStats['totalReps']}', Icons.repeat, const Color(0xFF00E5FF)),
              _buildStatCard('Workouts', '${_totalStats['totalSessions']}', Icons.fitness_center, const Color(0xFF7B2FFF)),
              _buildStatCard('Efficiency', '${_totalStats['avgEfficiency'].toStringAsFixed(1)}%', Icons.bolt, Colors.greenAccent),
              _buildStatCard('Time', '${(_totalStats['totalDuration'] / 60).toStringAsFixed(1)}m', Icons.timer, Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF00E5FF).withOpacity(0.1), const Color(0xFF7B2FFF).withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text('Overall Form Quality', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: _totalStats['avgEfficiency'] / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                ),
              ),
              Text('${_totalStats['avgEfficiency'].toStringAsFixed(0)}%', 
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Your technique is improving!', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151B2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_allSessions.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _allSessions.length,
      itemBuilder: (context, index) {
        final session = _allSessions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF151B2E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF00E5FF).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.fitness_center, color: Color(0xFF00E5FF), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.exerciseName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(session.formattedDate, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  Text('${session.reps} Reps', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(color: Colors.white10, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHistoryMetric(Icons.bolt, '${session.efficiency.toStringAsFixed(0)}%', 'Form'),
                  _buildHistoryMetric(Icons.timer, '${session.durationInSeconds.toStringAsFixed(0)}s', 'Time'),
                  _buildHistoryMetric(Icons.favorite, '${session.heartRate ?? "--"}', 'BPM'),
                  _buildHistoryMetric(Icons.water_drop, '${session.bloodOxygen ?? "--"}%', 'SpO2'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryMetric(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white54),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _buildEmptyState({String message = "No workouts recorded yet."}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 64, color: Colors.white10),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }
}
