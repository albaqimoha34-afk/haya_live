import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/match_model.dart';
import '../models/user_model.dart';
import 'add_edit_match_screen.dart';

class MatchDetailsScreen extends StatefulWidget {
  final MatchModel match;
  final String competitionName;
  final UserModel currentUser;

  const MatchDetailsScreen({
    super.key,
    required this.match,
    required this.competitionName,
    required this.currentUser,
  });

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  final _dbHelper = DBHelper();
  late MatchModel _match;
  bool _isFavorite = false;
  bool _dataChanged = false;

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final fav = await _dbHelper.isFavorite(widget.currentUser.id!, _match.id!);
    setState(() => _isFavorite = fav);
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await _dbHelper.removeFavorite(widget.currentUser.id!, _match.id!);
    } else {
      await _dbHelper.addFavorite(widget.currentUser.id!, _match.id!);
    }
    setState(() => _isFavorite = !_isFavorite);
    _dataChanged = true;
  }

  Future<void> _editMatch() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditMatchScreen(existingMatch: _match)),
    );
    if (updated == true) {
      final refreshed = await _dbHelper.getAllMatches();
      final newMatch = refreshed.where((m) => m.id == _match.id);
      if (newMatch.isNotEmpty) {
        setState(() => _match = newMatch.first);
      }
      _dataChanged = true;
    }
  }

  Future<void> _deleteMatch() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المباراة'),
        content: const Text('هل أنت متأكد أنك تريد حذف هذه المباراة؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _dbHelper.deleteMatch(_match.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف المباراة بنجاح')),
    );
    Navigator.pop(context, true);
  }

  Color _statusColor() {
    switch (_match.status) {
      case 'live':
        return Colors.red;
      case 'finished':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  String _statusLabel() {
    switch (_match.status) {
      case 'live':
        return 'مباشر الآن';
      case 'finished':
        return 'انتهت المباراة';
      default:
        return 'لم تبدأ بعد';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _dataChanged);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل المباراة'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _dataChanged),
          ),
          actions: [
            IconButton(
              icon: Icon(_isFavorite ? Icons.star : Icons.star_border,
                  color: _isFavorite ? Colors.amber : null),
              onPressed: _toggleFavorite,
            ),
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _editMatch),
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _deleteMatch),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(widget.competitionName, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 6),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_statusLabel(),
                      style: TextStyle(color: _statusColor(), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _teamColumn(_match.homeTeam, _match.homeLogoUrl),
                  Column(
                    children: [
                      Text(
                        _match.status == 'upcoming'
                            ? _match.matchTime
                            : '${_match.homeScore} - ${_match.awayScore}',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  _teamColumn(_match.awayTeam, _match.awayLogoUrl),
                ],
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _infoRow(Icons.calendar_today, 'التاريخ', _match.matchDate),
                      const Divider(),
                      _infoRow(Icons.access_time, 'الوقت', _match.matchTime),
                      const Divider(),
                      _infoRow(Icons.stadium_outlined, 'الملعب', _match.stadium),
                      const Divider(),
                      _infoRow(Icons.sports_outlined, 'الحكم', _match.referee),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamColumn(String name, String logoUrl) {
    return Column(
      children: [
        Image.network(
          logoUrl,
          width: 64,
          height: 64,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.shield, size: 64, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 110,
          child: Text(name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
