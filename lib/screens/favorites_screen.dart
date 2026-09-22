import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/match_model.dart';
import '../models/competition_model.dart';
import '../models/user_model.dart';
import '../widgets/match_card.dart';
import 'match_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final UserModel currentUser;

  const FavoritesScreen({super.key, required this.currentUser});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _dbHelper = DBHelper();
  List<MatchModel> _favoriteMatches = [];
  Map<int, CompetitionModel> _competitionsById = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final competitions = await _dbHelper.getCompetitions();
    final favorites = await _dbHelper.getFavoriteMatches(widget.currentUser.id!);
    setState(() {
      _competitionsById = {for (var c in competitions) c.id!: c};
      _favoriteMatches = favorites;
      _isLoading = false;
    });
  }

  Future<void> _removeFavorite(MatchModel match) async {
    await _dbHelper.removeFavorite(widget.currentUser.id!, match.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت إزالة المباراة من المفضلة')),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteMatches.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'لا توجد مباريات في المفضلة بعد\nاضغط على أيقونة النجمة داخل أي مباراة لإضافتها هنا',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: _favoriteMatches.length,
                    itemBuilder: (context, index) {
                      final match = _favoriteMatches[index];
                      final competitionName = _competitionsById[match.competitionId]?.name ?? '';
                      return MatchCard(
                        match: match,
                        competitionName: competitionName,
                        isFavorite: true,
                        onFavoriteToggle: () => _removeFavorite(match),
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
    );
  }
}
