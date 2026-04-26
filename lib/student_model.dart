class Aluno {
  final String id;
  final String nome;
  final String escola;
  final String enderecoCasa;
  final String periodo;
  final String responsavel;
  final String whatsappResponsavel;
  final int ordemIda;
  final int ordemVolta;
  final String idTransportador;

  Aluno({
    required this.id,
    required this.nome,
    required this.escola,
    required this.enderecoCasa,
    required this.periodo,
    required this.responsavel,
    required this.whatsappResponsavel,
    required this.ordemIda,
    required this.ordemVolta,
    required this.idTransportador,
  });

  factory Aluno.fromFirestore(Map<String, dynamic> data, String id) {
    return Aluno(
      id: id,
      nome: data['nome_aluno'] ?? '',
      escola: data['escola'] ?? '',
      enderecoCasa: data['endereco_casa'] ?? '',
      periodo: data['periodo'] ?? '',
      responsavel: data['responsavel'] ?? '',
      whatsappResponsavel: data['whatsapp_responsavel'] ?? '',
      ordemIda: (data['ordem_ida'] ?? 0) is int
          ? data['ordem_ida']
          : int.tryParse(data['ordem_ida'].toString()) ?? 0,
      ordemVolta: (data['ordem_volta'] ?? 0) is int
          ? data['ordem_volta']
          : int.tryParse(data['ordem_volta'].toString()) ?? 0,
      idTransportador: data['id_transportador'] ?? '',
    );
  }
}