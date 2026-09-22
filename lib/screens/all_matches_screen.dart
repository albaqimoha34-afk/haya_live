import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/match_model.dart';
import '../models/competition_model.dart';
import '../models/user_model.dart';
import '../widgets/match_card.dart';
import 'match_details_screen.dart';

// شاشة كل المباريات - تدعم الفلترة حسب البطولة وحسب الحالة
// إذا تم تمرير fixedCompetitionId (قادمة من شاشة البطولات) تُعرض مباريات تلك البطولة فقط بدون فلتر بطولة
class AllMatchesScreen extends StatefulWidget {
  final UserModel currentUser;
  final int? fixedCompetitionId;
  final String? fixedCompetitionName;

  const AllMatchesScreen({
    super.key,
    required this.currentUser,
    this.fixedCompetitionId,
    this.fixedCompetitionName,
  });

  @override
  State<AllMatchesScreen> createState() => _AllMatchesScreenState();
}

class _AllMatchesScreenState extends State<AllMatchesScreen> {
  final _dbHelper = DBHelper();
  List<MatchModel> _allMatches = [];
  List<CompetitionModel> _competitions = [];
  bool _isLoading = true;

  int? _selectedCompetitionId;
  String _selectedStatus = 'all'; // all | upcoming | live | finished

  @override
  void initState() {
    super.initState();
    _selectedCompetitionId = widget.fixedCompetitionId;
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final competitions = await _dbHelper.getCompetitions();
    final matches = await _dbHelper.getAllMatches();
    setState(() {
      _competitions = competitions;
      _allMatches = matches;
      _isLoading = false;
    });
  }

  List<MatchModel> get _filteredMatches {
    return _allMatches.where((m) {
      final competitionOk = _selectedCompetitionId == null || m.competitionId == _selectedCompetitionId;
      final statusOk = _selectedStatus == 'all' || m.status == _selectedStatus;
      return competitionOk && statusOk;
    }).toList();
  }

  String _competitionName(int id) {
    final match = _competitions.where((c) => c.id == id);
    return match.isNotEmpty ? match.first.name : '';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMatches;

    return Scaffold(
      appBar: AppBar(title: Text(widget.fixedCompetitionName ?? 'كل المباريات')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    children: [
                      if (widget.fixedCompetitionId == null)
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            value: _selectedCompetitionId,
                            decoration: const InputDecoration(labelText: 'البطولة'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('كل البطولات')),
                              ..._competitions.map(
                                (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                              ),
                            ],
                            onChanged: (value) => setState(() => _selectedCompetitionId = value),
                          ),
                        ),
                      if (widget.fixedCompetitionId == null) const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(labelText: 'الحالة'),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('الكل')),
                            DropdownMenuItem(value: 'upcoming', child: Text('لم تبدأ')),
                            DropdownMenuItem(value: 'live', child: Text('مباشر')),
                            DropdownMenuItem(value: 'finished', child: Text('انتهت')),
                          ],
                          onChanged: (value) => setState(() => _selectedStatus = value!),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('لا توجد مباريات مطابقة', style: TextStyle(color: Colors.grey)))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final match = filtered[index];
                              final competitionName =
                                  widget.fixedCompetitionName ?? _competitionName(match.competitionId);
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
                                  if (changed == true) _load();
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
