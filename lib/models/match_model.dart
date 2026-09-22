// نموذج المباراة - يمثل صف واحد في جدول matches
// status يمكن أن تكون: upcoming (لم تبدأ) - live (مباشر) - finished (انتهت)
class MatchModel {
  final int? id;
  final int competitionId;
  final String homeTeam;
  final String awayTeam;
  final String homeLogoUrl;
  final String awayLogoUrl;
  final int homeScore;
  final int awayScore;
  final String matchDate; // بصيغة yyyy-MM-dd
  final String matchTime; // بصيغة HH:mm
  final String stadium;
  final String referee;
  final String status;

  MatchModel({
    this.id,
    required this.competitionId,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeLogoUrl,
    required this.awayLogoUrl,
    required this.homeScore,
    required this.awayScore,
    required this.matchDate,
    required this.matchTime,
    required this.stadium,
    required this.referee,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'competition_id': competitionId,
      'home_team': homeTeam,
      'away_team': awayTeam,
      'home_logo_url': homeLogoUrl,
      'away_logo_url': awayLogoUrl,
      'home_score': homeScore,
      'away_score': awayScore,
      'match_date': matchDate,
      'match_time': matchTime,
      'stadium': stadium,
      'referee': referee,
      'status': status,
    };
  }

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    return MatchModel(
      id: map['id'],
      competitionId: map['competition_id'],
      homeTeam: map['home_team'],
      awayTeam: map['away_team'],
      homeLogoUrl: map['home_logo_url'],
      awayLogoUrl: map['away_logo_url'],
      homeScore: map['home_score'],
      awayScore: map['away_score'],
      matchDate: map['match_date'],
      matchTime: map['match_time'],
      stadium: map['stadium'],
      referee: map['referee'],
      status: map['status'],
    );
  }
}
