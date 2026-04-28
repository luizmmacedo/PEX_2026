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

  Stream<int> streamTotalAlunos(String uidTransportador) {
    return _db
        .collection('alunos')
        .where('id_transportador', isEqualTo: uidTransportador)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> marcarPresenca(
      String alunoId, int statusPresenca, String trajeto) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final existing = await _db
        .collection('presenca_diaria')
        .where('id_crianca', isEqualTo: alunoId)
        .where('trajeto', isEqualTo: trajeto)
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('data', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.update({
        'presenca': statusPresenca,
        'data': FieldValue.serverTimestamp(),
      });
    } else {
      await _db.collection('presenca_diaria').add({
        'id_crianca': alunoId,
        'trajeto': trajeto,
        'data': FieldValue.serverTimestamp(),
        'presenca': statusPresenca,
      });
    }
  }

  Stream<int?> streamPresencaHoje(String alunoId, String trajeto) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _db
        .collection('presenca_diaria')
        .where('id_crianca', isEqualTo: alunoId)
        .where('trajeto', isEqualTo: trajeto)
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('data', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('data', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return snap.docs.first.data()['presenca'] as int?;
    });
  }

  Stream<List<Map<String, dynamic>>> streamEscolas(String uidTransportador) {
    return _db
        .collection('escolas')
        .where('id_transportador', isEqualTo: uidTransportador)
        .snapshots()
        .map((snap) {
      final lista = snap.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList();
      lista.sort((a, b) =>
          (a['nome'] as String).compareTo(b['nome'] as String));
      return lista;
    });
  }

  Future<void> adicionarEscola(String uidTransportador, String nome) async {
    final existing = await _db
        .collection('escolas')
        .where('id_transportador', isEqualTo: uidTransportador)
        .where('nome_lower', isEqualTo: nome.trim().toLowerCase())
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    await _db.collection('escolas').add({
      'nome': nome.trim(),
      'nome_lower': nome.trim().toLowerCase(),
      'id_transportador': uidTransportador,
      'criado_em': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removerEscola(String escolaId) async {
    await _db.collection('escolas').doc(escolaId).delete();
  }
}