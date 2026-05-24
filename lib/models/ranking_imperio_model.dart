import 'package:cloud_firestore/cloud_firestore.dart';

class RankingImperioModel {
  const RankingImperioModel({
    required this.id,
    required this.imperioId,
    required this.nombreImperio,
    required this.razaId,
    required this.clanId,
    required this.tagClan,
    required this.valor,
    required this.ranking,
    required this.rankingAnterior,
    required this.ciudades,
    required this.heroes,
    required this.dia,
    required this.actualizadoEn,
  });

  final String id;
  final String imperioId;
  final String nombreImperio;
  final String razaId;
  final String? clanId;
  final String? tagClan;
  final int valor;
  final int ranking;
  final int rankingAnterior;
  final int ciudades;
  final int heroes;
  final int dia;
  final DateTime? actualizadoEn;

  factory RankingImperioModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return RankingImperioModel(
      id: doc.id,
      imperioId: data['imperioId']?.toString() ?? '',
      nombreImperio: data['nombreImperio']?.toString() ?? '',
      razaId: data['razaId']?.toString() ?? '',
      clanId: data['clanId'] as String?,
      tagClan: data['tagClan'] as String?,
      valor: (data['valor'] as num?)?.toInt() ?? 0,
      ranking: (data['ranking'] as num?)?.toInt() ?? 0,
      rankingAnterior: (data['rankingAnterior'] as num?)?.toInt() ?? 0,
      ciudades: (data['ciudades'] as num?)?.toInt() ?? 0,
      heroes: (data['heroes'] as num?)?.toInt() ?? 0,
      dia: (data['dia'] as num?)?.toInt() ?? 0,
      actualizadoEn: (data['actualizadoEn'] as Timestamp?)?.toDate(),
    );
  }

  int get movimiento {
    if (rankingAnterior <= 0) return 0;
    return rankingAnterior - ranking;
  }
}
