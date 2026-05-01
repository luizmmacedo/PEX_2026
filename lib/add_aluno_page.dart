import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_service.dart';

class AddAlunoPage extends StatefulWidget {
  final Map<String, dynamic> transportador;
  const AddAlunoPage({super.key, required this.transportador});

  @override
  State<AddAlunoPage> createState() => _AddAlunoPageState();
}

class _AddAlunoPageState extends State<AddAlunoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _responsavelController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _ordemIdaController = TextEditingController();
  final _ordemVoltaController = TextEditingController();

  String _periodoSelecionado = 'Matutino';
  String? _escolaSelecionada;
  bool _loading = false;
  String? _error;

  static const primary = Color(0xFF003366);
  final DatabaseService _service = DatabaseService();

  String get _uid => widget.transportador['uid'] ?? '';

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
      if (snapIda.docs.isNotEmpty) {
        final nome = snapIda.docs.first.data()['nome_aluno'] ?? 'outro aluno';
        return 'Ordem de ida $ordemIda já usada por "$nome" no período $periodo.';
      }
    }

    if (ordemVolta > 0) {
      final snapVolta = await FirebaseFirestore.instance
          .collection('alunos')
          .where('id_transportador', isEqualTo: _uid)
          .where('periodo', isEqualTo: periodo)
          .where('ordem_volta', isEqualTo: ordemVolta)
          .get();
      if (snapVolta.docs.isNotEmpty) {
        final nome =
            snapVolta.docs.first.data()['nome_aluno'] ?? 'outro aluno';
        return 'Ordem de volta $ordemVolta já usada por "$nome" no período $periodo.';
      }
    }

    return null;
  }

  Future<void> _salvarAluno() async {
    if (!_formKey.currentState!.validate()) return;
    if (_escolaSelecionada == null) {
      setState(() => _error = 'Selecione uma escola.');
      return;
    }

    final ordemIda = int.tryParse(_ordemIdaController.text) ?? 0;
    final ordemVolta = int.tryParse(_ordemVoltaController.text) ?? 0;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final queryNome = await FirebaseFirestore.instance
          .collection('alunos')
          .where('nome_aluno', isEqualTo: _nomeController.text.trim())
          .where('id_transportador', isEqualTo: _uid)
          .limit(1)
          .get();

      if (queryNome.docs.isNotEmpty) {
        setState(() {
          _error = 'Já existe um aluno com esse nome.';
          _loading = false;
        });
        return;
      }

      final erroOrdem = await _validarOrdem(ordemIda, ordemVolta);
      if (erroOrdem != null) {
        setState(() {
          _error = erroOrdem;
          _loading = false;
        });
        return;
      }

      await FirebaseFirestore.instance.collection('alunos').add({
        'nome_aluno': _nomeController.text.trim(),
        'escola': _escolaSelecionada,
        'endereco_casa': _enderecoController.text.trim(),
        'periodo': _periodoSelecionado,
        'responsavel': _responsavelController.text.trim(),
        'whatsapp_responsavel': _whatsappController.text.trim(),
        'ordem_ida': ordemIda,
        'ordem_volta': ordemVolta,
        'id_transportador': _uid,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ ${_nomeController.text.trim()} adicionado!'),
        backgroundColor: Colors.green.shade700,
      ));
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _service.streamEscolas(_uid),
        builder: (context, snapEscolas) {
          final escolas = snapEscolas.data ?? [];
          final semEscolas = escolas.isEmpty &&
              snapEscolas.connectionState != ConnectionState.waiting;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                expandedHeight: 100,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF001F4D), Color(0xFF003F8A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  title: const Text(
                    'Adicionar Aluno',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                  ),
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                ),
              ),

              SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      if (semEscolas)
                        _InfoBanner(
                          icon: Icons.warning_amber_rounded,
                          message:
                              'Cadastre as escolas primeiro no menu Escolas.',
                          color: Colors.orange,
                        ),

                      _Secao(titulo: 'Dados do Aluno', icon: Icons.child_care_rounded),

                      _Cartao(children: [
                        _campo(_nomeController, 'Nome do aluno',
                            Icons.badge_outlined,
                            required: true),

                        _DropdownField<String>(
                          value: _escolaSelecionada,
                          label: 'Escola',
                          icon: Icons.school_rounded,
                          hint: snapEscolas.connectionState ==
                                  ConnectionState.waiting
                              ? 'Carregando...'
                              : semEscolas
                                  ? 'Nenhuma escola cadastrada'
                                  : 'Selecione a escola',
                          items: escolas
                              .map((e) => DropdownMenuItem<String>(
                                    value: e['nome'] as String,
                                    child: Text(e['nome'] as String),
                                  ))
                              .toList(),
                          onChanged: semEscolas
                              ? null
                              : (val) =>
                                  setState(() => _escolaSelecionada = val),
                          validator: (_) => _escolaSelecionada == null
                              ? 'Selecione uma escola'
                              : null,
                        ),

                        _campo(_enderecoController, 'Local de parada',
                            Icons.location_on_outlined),

                        _DropdownField<String>(
                          value: _periodoSelecionado,
                          label: 'Período',
                          icon: Icons.schedule_rounded,
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
                          isLast: true,
                        ),
                      ]),

                      const SizedBox(height: 20),

                      _Secao(titulo: 'Responsável', icon: Icons.person_rounded),

                      _Cartao(children: [
                        _campo(_responsavelController, 'Nome do responsável',
                            Icons.person_outline,
                            required: true),
                        _campo(_whatsappController, 'WhatsApp (com DDD)',
                            Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            required: true,
                            isLast: true),
                      ]),

                      const SizedBox(height: 20),

                      _Secao(
                          titulo: 'Ordem de Rota',
                          icon: Icons.route_rounded),

                      _InfoBanner(
                        icon: Icons.info_outline_rounded,
                        message:
                            'A ordem deve ser única por turno ($_periodoSelecionado). Use 0 se o aluno não faz um dos trajetos.',
                        color: Colors.blue,
                      ),

                      const SizedBox(height: 12),

                      Row(children: [
                        Expanded(
                          child: _OrdemCard(
                            controller: _ordemIdaController,
                            label: 'Ordem Ida',
                            icon: Icons.arrow_upward_rounded,
                            color: const Color(0xFF1565C0),
                            bgColor: const Color(0xFFE8F0FE),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OrdemCard(
                            controller: _ordemVoltaController,
                            label: 'Ordem Volta',
                            icon: Icons.arrow_downward_rounded,
                            color: const Color(0xFF6A1B9A),
                            bgColor: const Color(0xFFF3E5F5),
                          ),
                        ),
                      ]),

                      const SizedBox(height: 20),

                      if (_error != null)
                        _InfoBanner(
                          icon: Icons.error_outline_rounded,
                          message: _error!,
                          color: Colors.red,
                        ),

                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _loading ? null : _salvarAluno,
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline_rounded,
                                        size: 20),
                                    SizedBox(width: 10),
                                    Text('Salvar Aluno',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _campo(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    bool isLast = false,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            labelStyle:
                const TextStyle(color: Colors.black45, fontSize: 14),
            prefixIcon: Icon(icon, color: primary, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.red.shade300, width: 1.5),
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

class _Secao extends StatelessWidget {
  final String titulo;
  final IconData icon;

  const _Secao({required this.titulo, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF003366).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF003366), size: 15),
        ),
        const SizedBox(width: 10),
        Text(titulo,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF003366),
                letterSpacing: 0.3)),
      ]),
    );
  }
}

class _Cartao extends StatelessWidget {
  final List<Widget> children;

  const _Cartao({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final T? value;
  final String label;
  final IconData icon;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final bool isLast;

  const _DropdownField({
    required this.value,
    required this.label,
    required this.icon,
    this.hint,
    required this.items,
    required this.onChanged,
    this.validator,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(color: Colors.black45, fontSize: 14),
          prefixIcon:
              Icon(icon, color: const Color(0xFF003366), size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF003366), width: 2),
          ),
        ),
        hint: hint != null ? Text(hint!) : null,
        items: items,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}

class _OrdemCard extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _OrdemCard({
    required this.controller,
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 10),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 2),
            ),
          ),
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Obrigatório'
              : null,
        ),
      ]),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final MaterialColor color;

  const _InfoBanner({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade100),
      ),
      child: Row(children: [
        Icon(icon, color: color.shade700, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: color.shade800, fontSize: 13),
          ),
        ),
      ]),
    );
  }
}