import 'package:flutter/material.dart';
import '../models/match_model.dart';

// بطاقة مباراة واحدة - تُستخدم في الرئيسية، كل المباريات، والمفضلة
// تعرض: اسم البطولة، الفريقين وشعاريهما، النتيجة أو الوقت، وحالة المباراة
class MatchCard extends StatelessWidget {
  final MatchModel match;
  final String competitionName;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const MatchCard({
    super.key,
    required this.match,
    required this.competitionName,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  Color _statusColor() {
    switch (match.status) {
      case 'live':
        return Colors.red;
      case 'finished':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  String _statusLabel() {
    switch (match.status) {
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // شريط علوي: اسم البطولة + حالة المباراة + زر المفضلة
              Row(
                children: [
                  Expanded(
                    child: Text(
                      competitionName,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor().withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(),
                      style: TextStyle(fontSize: 11, color: _statusColor(), fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (onFavoriteToggle != null)
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.star : Icons.star_border,
                        color: isFavorite ? Colors.amber : Colors.grey,
                      ),
                      onPressed: onFavoriteToggle,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // صف الفريقين والنتيجة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _teamColumn(match.homeTeam, match.homeLogoUrl),
                  Column(
                    children: [
                      Text(
                        match.status == 'upcoming'
                            ? match.matchTime
                            : '${match.homeScore} - ${match.awayScore}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(match.matchDate, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  _teamColumn(match.awayTeam, match.awayLogoUrl),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamColumn(String name, String logoUrl) {
    return Expanded(
      child: Column(
        children: [
          Image.network(
            logoUrl,
            width: 40,
            height: 40,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.shield, size: 40, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
