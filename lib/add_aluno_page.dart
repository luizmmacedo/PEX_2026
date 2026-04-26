import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddAlunoPage extends StatefulWidget {
  final Map<String, dynamic> transportador;
  const AddAlunoPage({super.key, required this.transportador});

  @override
  State<AddAlunoPage> createState() => _AddAlunoPageState();
}

class _AddAlunoPageState extends State<AddAlunoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _escolaController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _responsavelController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _ordemIdaController = TextEditingController();
  final _ordemVoltaController = TextEditingController();
  String _periodoSelecionado = 'Matutino';
  bool _loading = false;
  String? _error;

  static const primary = Color(0xFF003366);

  @override
  void dispose() {
    _nomeController.dispose();
    _escolaController.dispose();
    _enderecoController.dispose();
    _responsavelController.dispose();
    _whatsappController.dispose();
    _ordemIdaController.dispose();
    _ordemVoltaController.dispose();
    super.dispose();
  }

  Future<void> _salvarAluno() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final query = await FirebaseFirestore.instance
          .collection('alunos')
          .where('nome_aluno', isEqualTo: _nomeController.text.trim())
          .where('id_transportador',
              isEqualTo: widget.transportador['uid'] ?? '')
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        setState(() {
          _error = 'Já existe um aluno com esse nome para este transportador.';
          _loading = false;
        });
        return;
      }

      await FirebaseFirestore.instance.collection('alunos').add({
        'nome_aluno': _nomeController.text.trim(),
        'escola': _escolaController.text.trim(),
        'endereco_casa': _enderecoController.text.trim(),
        'periodo': _periodoSelecionado,
        'responsavel': _responsavelController.text.trim(),
        'whatsapp_responsavel': _whatsappController.text.trim(),
        'ordem_ida': int.tryParse(_ordemIdaController.text) ?? 0,
        'ordem_volta': int.tryParse(_ordemVoltaController.text) ?? 0,
        'id_transportador': widget.transportador['uid'] ?? '',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${_nomeController.text.trim()} adicionado!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Erro ao salvar aluno: $e');
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
        title: const Text('Adicionar Aluno'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _secao('Dados do Aluno'),
              _campo(_nomeController, 'Nome do aluno', Icons.child_care,
                  required: true),
              _campo(_escolaController, 'Escola', Icons.school, required: true),
              _campo(_enderecoController, 'Local de parada (endereço)',
                  Icons.location_on),

              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _periodoSelecionado,
                decoration: InputDecoration(
                  labelText: 'Período',
                  prefixIcon:
                      const Icon(Icons.schedule, color: primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primary, width: 2),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'Matutino', child: Text('Matutino')),
                  DropdownMenuItem(
                      value: 'Vespertino', child: Text('Vespertino')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _periodoSelecionado = val);
                },
              ),
              const SizedBox(height: 20),

              _secao('Responsável'),
              _campo(_responsavelController, 'Nome do responsável',
                  Icons.person,
                  required: true),
              _campo(_whatsappController, 'WhatsApp do responsável',
                  Icons.phone,
                  keyboardType: TextInputType.phone, required: true),

              const SizedBox(height: 20),
              _secao('Ordem de Rota'),
              Row(
                children: [
                  Expanded(
                    child: _campo(
                      _ordemIdaController,
                      'Ordem Ida',
                      Icons.arrow_upward,
                      keyboardType: TextInputType.number,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _campo(
                      _ordemVoltaController,
                      'Ordem Volta',
                      Icons.arrow_downward,
                      keyboardType: TextInputType.number,
                      required: true,
                    ),
                  ),
                ],
              ),

              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child:
                      Text(_error!, style: TextStyle(color: Colors.red.shade700)),
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
                  onPressed: _loading ? null : _salvarAluno,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Salvar Aluno',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secao(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _campo(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primary),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
        ),
        validator: required
            ? (v) =>
                v == null || v.trim().isEmpty ? 'Campo obrigatório' : null
            : null,
      ),
    );
  }
}