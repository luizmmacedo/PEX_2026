import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_service.dart';
import 'student_model.dart';

class EditAlunoPage extends StatefulWidget {
  final Aluno aluno;
  final Map<String, dynamic> transportador;

  const EditAlunoPage({
    super.key,
    required this.aluno,
    required this.transportador,
  });

  @override
  State<EditAlunoPage> createState() => _EditAlunoPageState();
}

class _EditAlunoPageState extends State<EditAlunoPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _enderecoController;
  late final TextEditingController _responsavelController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _ordemIdaController;
  late final TextEditingController _ordemVoltaController;

  late String _periodoSelecionado;
  String? _escolaSelecionada;

  bool _loading = false;
  String? _error;

  static const primary = Color(0xFF003366);
  final DatabaseService _service = DatabaseService();

  String get _uid => widget.transportador['uid'] ?? '';

  @override
  void initState() {
    super.initState();
    final a = widget.aluno;
    _nomeController = TextEditingController(text: a.nome);
    _enderecoController = TextEditingController(text: a.enderecoCasa);
    _responsavelController = TextEditingController(text: a.responsavel);
    _whatsappController = TextEditingController(text: a.whatsappResponsavel);
    _ordemIdaController =
        TextEditingController(text: a.ordemIda.toString());
    _ordemVoltaController =
        TextEditingController(text: a.ordemVolta.toString());
    _periodoSelecionado = a.periodo;
    _escolaSelecionada = a.escola;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _enderecoController.dispose();
    _responsavelController.dispose();
    _whatsappController.dispose();
    _ordemIdaController.dispose();
    _ordemVoltaController.dispose();
    super.dispose();
  }

  Future<String?> _validarOrdem(int ordemIda, int ordemVolta) async {
    final periodo = _periodoSelecionado;

    if (ordemIda > 0) {
      final snapIda = await FirebaseFirestore.instance
          .collection('alunos')
          .where('id_transportador', isEqualTo: _uid)
          .where('periodo', isEqualTo: periodo)
          .where('ordem_ida', isEqualTo: ordemIda)
          .get();
      for (final doc in snapIda.docs) {
        if (doc.id != widget.aluno.id) {
          final nome = doc.data()['nome_aluno'] ?? 'outro aluno';
          return 'Ordem de ida $ordemIda já usada por "$nome" no período $periodo.';
        }
      }
    }

    if (ordemVolta > 0) {
      final snapVolta = await FirebaseFirestore.instance
          .collection('alunos')
          .where('id_transportador', isEqualTo: _uid)
          .where('periodo', isEqualTo: periodo)
          .where('ordem_volta', isEqualTo: ordemVolta)
          .get();
      for (final doc in snapVolta.docs) {
        if (doc.id != widget.aluno.id) {
          final nome = doc.data()['nome_aluno'] ?? 'outro aluno';
          return 'Ordem de volta $ordemVolta já usada por "$nome" no período $periodo.';
        }
      }
    }

    return null;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_escolaSelecionada == null) {
      setState(() => _error = 'Selecione uma escola.');
      return;
    }

    final ordemIda = int.tryParse(_ordemIdaController.text) ?? 0;
    final ordemVolta = int.tryParse(_ordemVoltaController.text) ?? 0;

    setState(() { _loading = true; _error = null; });

    try {
      final erroOrdem = await _validarOrdem(ordemIda, ordemVolta);
      if (erroOrdem != null) {
        setState(() { _error = erroOrdem; _loading = false; });
        return;
      }

      await FirebaseFirestore.instance
          .collection('alunos')
          .doc(widget.aluno.id)
          .update({
        'nome_aluno': _nomeController.text.trim(),
        'escola': _escolaSelecionada,
        'endereco_casa': _enderecoController.text.trim(),
        'periodo': _periodoSelecionado,
        'responsavel': _responsavelController.text.trim(),
        'whatsapp_responsavel': _whatsappController.text.trim(),
        'ordem_ida': ordemIda,
        'ordem_volta': ordemVolta,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Aluno atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = 'Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Editar — ${widget.aluno.nome.split(' ').first}'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _service.streamEscolas(_uid),
          builder: (context, snapEscolas) {
            final escolas = snapEscolas.data ?? [];

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _secao('Dados do Aluno'),
                  _campo(_nomeController, 'Nome do aluno', Icons.child_care,
                      required: true),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: DropdownButtonFormField<String>(
                      initialValue: escolas.any(
                              (e) => e['nome'] == _escolaSelecionada)
                          ? _escolaSelecionada
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Escola',
                        prefixIcon:
                            const Icon(Icons.school, color: primary),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: primary, width: 2),
                        ),
                      ),
                      hint: escolas.isEmpty
                          ? const Text('Nenhuma escola cadastrada')
                          : const Text('Selecione a escola'),
                      items: escolas
                          .map((e) => DropdownMenuItem<String>(
                                value: e['nome'] as String,
                                child: Text(e['nome'] as String),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _escolaSelecionada = val),
                      validator: (_) => _escolaSelecionada == null
                          ? 'Selecione uma escola'
                          : null,
                    ),
                  ),

                  _campo(_enderecoController, 'Local de parada',
                      Icons.location_on),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: DropdownButtonFormField<String>(
                      initialValue: _periodoSelecionado,
                      decoration: InputDecoration(
                        labelText: 'Período',
                        prefixIcon:
                            const Icon(Icons.schedule, color: primary),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: primary, width: 2),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Matutino', child: Text('Matutino')),
                        DropdownMenuItem(
                            value: 'Vespertino',
                            child: Text('Vespertino')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _periodoSelecionado = val);
                        }
                      },
                    ),
                  ),

                  _secao('Responsável'),
                  _campo(_responsavelController, 'Nome do responsável',
                      Icons.person,
                      required: true),
                  _campo(_whatsappController,
                      'WhatsApp do responsável', Icons.phone,
                      keyboardType: TextInputType.phone, required: true),

                  _secao('Ordem de Rota'),
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'A ordem deve ser única por turno ($_periodoSelecionado).',
                          style: TextStyle(
                              color: Colors.blue.shade700, fontSize: 12),
                        ),
                      ),
                    ]),
                  ),
                  Row(children: [
                    Expanded(
                      child: _campo(_ordemIdaController, 'Ordem Ida',
                          Icons.arrow_upward,
                          keyboardType: TextInputType.number,
                          required: true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _campo(_ordemVoltaController, 'Ordem Volta',
                          Icons.arrow_downward,
                          keyboardType: TextInputType.number,
                          required: true),
                    ),
                  ]),

                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style:
                                  TextStyle(color: Colors.red.shade700)),
                        ),
                      ]),
                    ),

                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _loading ? null : _salvar,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Salvar Alterações',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _secao(String titulo) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 4),
        child: Text(titulo,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: primary,
                letterSpacing: 0.5)),
      );

  Widget _campo(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: primary),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primary, width: 2),
            ),
          ),
          validator: required
              ? (v) => v == null || v.trim().isEmpty
                  ? 'Campo obrigatório'
                  : null
              : null,
        ),
      );
}