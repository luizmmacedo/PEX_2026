import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'database_service.dart';
import 'student_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Map<String, dynamic> transportador;
  bool _transportadorCarregado = false;

  final DatabaseService _service = DatabaseService();
  String _periodo = 'Matutino';
  bool _isIndoParaEscola = true;

  static const primary = Color(0xFF003366);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_transportadorCarregado) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        transportador = args;
        _transportadorCarregado = true;
      }
    }
  }

  Future<void> _abrirWhatsApp(String fone, String aluno) async {
    final numero = fone.replaceAll(RegExp(r'\D'), '');
    final link = Uri.parse(
        'https://wa.me/$numero?text=Olá! Sou o transportador de $aluno.');
    if (!await launchUrl(link, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('transportador_uid');
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: primary, size: 20),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(color: Colors.black87),
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _badgePresenca(int? status) {
    late Color bg;
    late Color fg;
    late IconData icon;
    late String label;

    switch (status) {
      case 1:
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        icon = Icons.check_circle;
        label = 'Presente';
        break;
      case 2:
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        icon = Icons.cancel;
        label = 'Falta';
        break;
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        icon = Icons.help_outline;
        label = 'Não informado';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 10),
          Text('Presença hoje: ',
              style:
                  TextStyle(color: fg, fontWeight: FontWeight.w600)),
          Text(label, style: TextStyle(color: fg)),
        ],
      ),
    );
  }

  Widget _whatsAppLogo({double size = 22}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _WhatsAppLogoPainter()),
    );
  }

  void _abrirPerfilTransportador() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            CircleAvatar(
              radius: 36,
              backgroundColor: primary,
              child: Text(
                (transportador['nome'] ?? 'T')[0].toUpperCase(),
                style: const TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Text(transportador['nome'] ?? '',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primary)),
            Text(transportador['veiculo'] ?? '',
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 20),
            _infoRow(Icons.phone, 'WhatsApp', transportador['whatsapp'] ?? ''),
            _infoRow(Icons.directions_bus, 'Veículo',
                transportador['veiculo'] ?? ''),
            _infoRow(Icons.confirmation_number, 'Nº Escolar',
                transportador['numero_escolar'] ?? ''),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Sair',
                    style: TextStyle(color: Colors.red, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirFichaAluno(Aluno aluno) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => FutureBuilder<int?>(
        future: _service.getPresencaHoje(aluno.id),
        builder: (context, snap) {
          final presencaStatus = snap.data;

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),

                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        aluno.nome.isNotEmpty
                            ? aluno.nome[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(aluno.nome,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text(aluno.periodo,
                              style:
                                  const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 28),

                _infoRow(Icons.school, 'Escola', aluno.escola),
                _infoRow(Icons.person, 'Responsável', aluno.responsavel),
                _infoRow(Icons.home, 'Parada', aluno.enderecoCasa),
                _infoRow(
                    Icons.arrow_upward, 'Ordem Ida', '${aluno.ordemIda}º'),
                _infoRow(Icons.arrow_downward, 'Ordem Volta',
                    '${aluno.ordemVolta}º'),

                const SizedBox(height: 14),

                snap.connectionState == ConnectionState.waiting
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      )
                    : _badgePresenca(presencaStatus),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _whatsAppLogo(size: 22),
                    label: Text(
                        'Chamar no WhatsApp (${aluno.whatsappResponsavel})',
                        style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _abrirWhatsApp(
                        aluno.whatsappResponsavel, aluno.nome),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Veio'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          await _service.marcarPresenca(aluno.id, 1);
                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '✅ ${aluno.nome} marcado como presente'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Não veio'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          await _service.marcarPresenca(aluno.id, 2);
                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '❌ ${aluno.nome} marcado como ausente'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_transportadorCarregado) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final nomeTransportador = transportador['nome'] ?? 'Transportador';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Olá, $nomeTransportador',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('SafeRide',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Meu perfil',
            onPressed: _abrirPerfilTransportador,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Adicionar aluno',
            onPressed: () => Navigator.of(context)
                .pushNamed('/addAluno', arguments: transportador),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _FiltroChip(
                    label: 'Matutino',
                    selected: _periodo == 'Matutino',
                    onTap: () => setState(() => _periodo = 'Matutino'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FiltroChip(
                    label: 'Vespertino',
                    selected: _periodo == 'Vespertino',
                    onTap: () => setState(() => _periodo = 'Vespertino'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _FiltroChip(
                    label: 'Ida',
                    selected: _isIndoParaEscola,
                    onTap: () =>
                        setState(() => _isIndoParaEscola = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FiltroChip(
                    label: 'Volta',
                    selected: !_isIndoParaEscola,
                    onTap: () =>
                        setState(() => _isIndoParaEscola = false),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Aluno>>(
              stream: _service.getAlunos(
                transportador['uid'] ?? '',
                _periodo,
                _isIndoParaEscola,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        Text('Erro: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final alunos = snapshot.data ?? [];

                if (alunos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.child_care,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhuma criança cadastrada\npara $_periodo - ${_isIndoParaEscola ? "Ida" : "Volta"}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black45),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar aluno'),
                          onPressed: () => Navigator.of(context).pushNamed(
                              '/addAluno',
                              arguments: transportador),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        '${alunos.length} criança${alunos.length != 1 ? 's' : ''} • $_periodo • ${_isIndoParaEscola ? "Ida" : "Volta"}',
                        style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: alunos.length,
                        itemBuilder: (context, index) {
                          final aluno = alunos[index];
                          final ordem = _isIndoParaEscola
                              ? aluno.ordemIda
                              : aluno.ordemVolta;

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _abrirFichaAluno(aluno),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: primary.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$ordem',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: primary,
                                              fontSize: 16),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.blue.shade50,
                                      child: Text(
                                        aluno.nome.isNotEmpty
                                            ? aluno.nome[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: primary),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            aluno.nome,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                          Text(
                                            aluno.escola,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black54),
                                          ),
                                          if (aluno.enderecoCasa.isNotEmpty)
                                            Row(
                                              children: [
                                                const Icon(
                                                    Icons.location_on,
                                                    size: 12,
                                                    color: Colors.black38),
                                                const SizedBox(width: 2),
                                                Expanded(
                                                  child: Text(
                                                    aluno.enderecoCasa,
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors.black38),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),

                                    IconButton(
                                      icon: _whatsAppLogo(size: 26),
                                      tooltip: 'WhatsApp',
                                      onPressed: () => _abrirWhatsApp(
                                          aluno.whatsappResponsavel,
                                          aluno.nome),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected
                  ? const Color(0xFF003366)
                  : Colors.white70,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _WhatsAppLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintBg = Paint()..color = Colors.white;
    final paintIcon = Paint()
      ..color = const Color(0xFF25D366)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    canvas.drawCircle(Offset(cx, cy), r, paintBg);

    final balloonPath = Path();
    final br = r * 0.78;
    balloonPath.addOval(
        Rect.fromCircle(center: Offset(cx, cy - r * 0.05), radius: br));
    balloonPath.moveTo(cx - br * 0.15, cy + br * 0.72);
    balloonPath.lineTo(cx - br * 0.55, cy + r * 0.88);
    balloonPath.lineTo(cx + br * 0.1, cy + br * 0.6);
    balloonPath.close();
    canvas.drawPath(balloonPath, paintIcon);

    final phonePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round;

    final phoneScale = r * 0.5;
    final px = cx - phoneScale * 0.15;
    final py = cy - phoneScale * 0.22;

    final phonePath = Path();
    phonePath.moveTo(px - phoneScale * 0.55, py - phoneScale * 0.1);
    phonePath.cubicTo(
      px - phoneScale * 0.55, py - phoneScale * 0.55,
      px - phoneScale * 0.1, py - phoneScale * 0.55,
      px + phoneScale * 0.1, py - phoneScale * 0.3,
    );
    phonePath.moveTo(px + phoneScale * 0.25, py + phoneScale * 0.1);
    phonePath.cubicTo(
      px + phoneScale * 0.55, py + phoneScale * 0.3,
      px + phoneScale * 0.55, py + phoneScale * 0.6,
      px + phoneScale * 0.1, py + phoneScale * 0.6,
    );

    canvas.drawPath(phonePath, phonePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}