// نموذج البطولة - يمثل صف واحد في جدول competitions
class CompetitionModel {
  final int? id;
  final String name;
  final String logoUrl;

  CompetitionModel({
    this.id,
    required this.name,
    required this.logoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logo_url': logoUrl,
    };
  }

  factory CompetitionModel.fromMap(Map<String, dynamic> map) {
    return CompetitionModel(
      id: map['id'],
      name: map['name'],
      logoUrl: map['logo_url'],
    );
  }
}
