import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/match_model.dart';
import '../models/competition_model.dart';
import '../models/user_model.dart';
import '../widgets/stat_card.dart';
import '../widgets/match_card.dart';
import 'match_details_screen.dart';
import 'add_edit_match_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel currentUser;

  const HomeScreen({super.key, required this.currentUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dbHelper = DBHelper();
  List<MatchModel> _todayMatches = [];
  Map<int, CompetitionModel> _competitionsById = {};
  bool _isLoading = true;

  String get _todayDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final competitions = await _dbHelper.getCompetitions();
    final matches = await _dbHelper.getMatchesByDate(_todayDate);

    setState(() {
      _competitionsById = {for (var c in competitions) c.id!: c};
      _todayMatches = matches;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final liveCount = _todayMatches.where((m) => m.status == 'live').length;
    final finishedCount = _todayMatches.where((m) => m.status == 'finished').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('هيا لايف'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditMatchScreen()),
          );
          if (added == true) _loadData();
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.only(top: 12, bottom: 24),
                children: [
                  // صف الإحصائيات
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        StatCard(
                          label: 'مباريات اليوم',
                          value: '${_todayMatches.length}',
                          icon: Icons.calendar_today,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 10),
                        StatCard(
                          label: 'مباشر الآن',
                          value: '$liveCount',
                          icon: Icons.podcasts,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 10),
                        StatCard(
                          label: 'انتهت',
                          value: '$finishedCount',
                          icon: Icons.check_circle_outline,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text('مباريات اليوم', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                  if (_todayMatches.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('لا توجد مباريات مجدولة اليوم', style: TextStyle(color: Colors.grey))),
                    )
                  else
                    ..._todayMatches.map((match) {
                      final competitionName = _competitionsById[match.competitionId]?.name ?? '';
                      return MatchCard(
                        match: match,
                        competitionName: competitionName,
                        onTap: () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MatchDetailsScreen(
                                match: match,
                                competitionName: competitionName,
                                currentUser: widget.currentUser,
                              ),
                            ),
                          );
                          if (changed == true) _loadData();
                        },
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
