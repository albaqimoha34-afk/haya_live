import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/competition_model.dart';
import '../models/user_model.dart';
import 'all_matches_screen.dart';

// شاشة البطولات - تعرض البطولات في شبكة (GridView) وتفتح عند الضغط
// قائمة مباريات تلك البطولة فقط (بالاستفادة من فلتر AllMatchesScreen)
class CompetitionsScreen extends StatefulWidget {
  final UserModel currentUser;

  const CompetitionsScreen({super.key, required this.currentUser});

  @override
  State<CompetitionsScreen> createState() => _CompetitionsScreenState();
}

class _CompetitionsScreenState extends State<CompetitionsScreen> {
  final _dbHelper = DBHelper();
  List<CompetitionModel> _competitions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _dbHelper.getCompetitions();
    setState(() {
      _competitions = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('البطولات')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _competitions.isEmpty
              ? const Center(child: Text('لا توجد بطولات مضافة حاليًا', style: TextStyle(color: Colors.grey)))
              : GridView.builder(
                  padding: const EdgeInsets.all(14),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _competitions.length,
                  itemBuilder: (context, index) {
                    final competition = _competitions[index];
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AllMatchesScreen(
                                currentUser: widget.currentUser,
                                fixedCompetitionId: competition.id,
                                fixedCompetitionName: competition.name,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                competition.logoUrl,
                                width: 60,
                                height: 60,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.emoji_events, size: 60, color: Colors.amber),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                competition.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
