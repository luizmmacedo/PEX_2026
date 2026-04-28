import 'package:flutter/material.dart';
import 'database_service.dart';

class EscolasPage extends StatefulWidget {
  final Map<String, dynamic> transportador;
  const EscolasPage({super.key, required this.transportador});

  @override
  State<EscolasPage> createState() => _EscolasPageState();
}

class _EscolasPageState extends State<EscolasPage> {
  final DatabaseService _service = DatabaseService();
  final TextEditingController _nomeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _adicionando = false;

  static const primary = Color(0xFF003366);

  String get _uid => widget.transportador['uid'] ?? '';

  Future<void> _adicionar() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o nome da escola')),
      );
      return;
    }
    setState(() => _adicionando = true);
    try {
      await _service.adicionarEscola(_uid, nome);
      _nomeController.clear();
      _focusNode.unfocus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ "$nome" adicionada!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _adicionando = false);
    }
  }

  Future<void> _confirmarRemocao(String escolaId, String nome) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remover escola'),
        content: Text(
            'Deseja remover "$nome"?\nOs alunos vinculados não serão afetados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) await _service.removerEscola(escolaId);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Escolas'),
      ),
      body: Column(children: [
        Container(
          color: primary,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _nomeController,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _adicionar(),
                decoration: InputDecoration(
                  hintText: 'Nome da escola...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.15),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.school_outlined,
                      color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 48,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primary,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _adicionando ? null : _adicionar,
                child: _adicionando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF003366)),
                      )
                    : const Icon(Icons.add, size: 24),
              ),
            ),
          ]),
        ),

        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _service.streamEscolas(_uid),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final escolas = snap.data ?? [];

              if (escolas.isEmpty) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.school_outlined,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text(
                      'Nenhuma escola cadastrada.\nAdicione a primeira acima!',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: Colors.black38, fontSize: 15),
                    ),
                  ]),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: escolas.length,
                itemBuilder: (context, i) {
                  final escola = escolas[i];
                  final nome = escola['nome'] as String? ?? '';
                  final id = escola['id'] as String;

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.school,
                            color: primary, size: 22),
                      ),
                      title: Text(nome,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () => _confirmarRemocao(id, nome),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}