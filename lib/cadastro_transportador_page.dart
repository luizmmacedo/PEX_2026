import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CadastroTransportadorPage extends StatefulWidget {
  const CadastroTransportadorPage({super.key});

  @override
  State<CadastroTransportadorPage> createState() =>
      _CadastroTransportadorPageState();
}

class _CadastroTransportadorPageState
    extends State<CadastroTransportadorPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _veiculoController = TextEditingController();
  final TextEditingController _numeroEscolarController =
      TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nomeController.dispose();
    _usuarioController.dispose();
    _senhaController.dispose();
    _whatsappController.dispose();
    _veiculoController.dispose();
    _numeroEscolarController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final query = await FirebaseFirestore.instance
          .collection('transportadores')
          .where('usuario', isEqualTo: _usuarioController.text.trim())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        setState(() {
          _error = 'Usuário já existe';
          _loading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('transportadores')
          .add({
        'nome': _nomeController.text.trim(),
        'usuario': _usuarioController.text.trim(),
        'senha': _senhaController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'veiculo': _veiculoController.text.trim(),
        'numero_escolar': _numeroEscolarController.text.trim(),
      });

      await doc.update({'uid': doc.id});

      if (!mounted) return;
      Navigator.of(context).pop({
        'usuario': _usuarioController.text.trim(),
        'senha': _senhaController.text.trim(),
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao cadastrar: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF003366);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text('Criar Conta'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 8),
                _buildField(_nomeController, 'Nome completo', Icons.person,
                    required: true),
                _buildField(_usuarioController, 'Usuário de acesso',
                    Icons.alternate_email,
                    required: true),
                _buildField(_senhaController, 'Senha', Icons.lock,
                    required: true, obscure: true),
                _buildField(
                    _whatsappController, 'WhatsApp (com DDD)', Icons.phone,
                    keyboardType: TextInputType.phone),
                _buildField(_veiculoController, 'Tipo de veículo',
                    Icons.directions_bus),
                _buildField(_numeroEscolarController, 'Número da Van',
                    Icons.confirmation_number,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 24),
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(_error!,
                        style: TextStyle(color: Colors.red.shade700)),
                  ),
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
                    onPressed: _loading ? null : _cadastrar,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Cadastrar',
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF003366)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF003366), width: 2),
          ),
        ),
        validator: required
            ? (v) => v == null || v.trim().isEmpty ? 'Campo obrigatório' : null
            : null,
      ),
    );
  }
}