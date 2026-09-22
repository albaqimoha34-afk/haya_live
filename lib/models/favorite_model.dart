// نموذج المفضلة - يربط بين المستخدم والمباراة التي أضافها للمفضلة
class FavoriteModel {
  final int? id;
  final int userId;
  final int matchId;

  FavoriteModel({
    this.id,
    required this.userId,
    required this.matchId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'match_id': matchId,
    };
  }

  factory FavoriteModel.fromMap(Map<String, dynamic> map) {
    return FavoriteModel(
      id: map['id'],
      userId: map['user_id'],
      matchId: map['match_id'],
    );
  }
}
