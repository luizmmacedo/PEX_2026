import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Aluno>> getAlunos(
    String uidTransportador,
    String periodo,
    bool isIndoParaEscola,
  ) {
    return _db
        .collection('alunos')
        .where('id_transportador', isEqualTo: uidTransportador)
        .where('periodo', isEqualTo: periodo)
        .snapshots()
        .map((snapshot) {
          final alunos = snapshot.docs
              .map((doc) => Aluno.fromFirestore(doc.data(), doc.id))
              .toList();

          alunos.sort((a, b) => isIndoParaEscola
              ? a.ordemIda.compareTo(b.ordemIda)
              : a.ordemVolta.compareTo(b.ordemVolta));

          return alunos;
        });
  }


  Future<void> marcarPresenca(String alunoId, int statusPresenca) async {
    await _db.collection('presenca_diaria').add({
      'id_crianca': alunoId,
      'data': FieldValue.serverTimestamp(),
      'presenca': statusPresenca,
    });
  }

  Future<int?> getPresencaHoje(String alunoId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = await _db
        .collection('presenca_diaria')
        .where('id_crianca', isEqualTo: alunoId)
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('data', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('data', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first.data()['presenca'] as int?;
  }
}