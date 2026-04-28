import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'database_service.dart';
import 'student_model.dart';
import 'edit_aluno_page.dart';

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
  String? _escolaFiltro;

  Stream<List<String>>? _streamNomesEscolas;

  Stream<int>? _streamTotalAlunos;

  static const primary = Color(0xFF003366);

  static const _avatarColors = [
    Color(0xFF1565C0), Color(0xFF6A1B9A), Color(0xFF00695C),
    Color(0xFFAD1457), Color(0xFF4527A0), Color(0xFF00838F),
    Color(0xFF2E7D32), Color(0xFFE65100), Color(0xFF4E342E),
  ];

  Color _avatarColor(String nome) {
    if (nome.isEmpty) return primary;
    return _avatarColors[nome.codeUnitAt(0) % _avatarColors.length];
  }

  static const _waIconUrl =
      'https://upload.wikimedia.org/wikipedia/commons/6/6b/WhatsApp.svg';

  Widget _whatsAppIcon({double size = 26}) {
    return Image.network(
      _waIconUrl,
      width: size,
      height: size,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.message, color: const Color(0xFF25D366), size: size),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_transportadorCarregado) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        transportador = args;
        _transportadorCarregado = true;
        final uid = transportador['uid'] ?? '';
        _streamNomesEscolas = _service
            .streamEscolas(uid)
            .map((lista) => lista.map((e) => e['nome'] as String).toList());
        _streamTotalAlunos = _service.streamTotalAlunos(uid);
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


  Widget _perfilItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, color: primary, size: 20),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(color: Colors.black54, fontSize: 14)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 14)),
      ]),
    );
  }

  Widget _divider() => Divider(
      height: 1, color: Colors.grey.shade200, indent: 16, endIndent: 16);

  Widget _badgePresenca(int? status) {
    late Color bg, fg;
    late IconData icon;
    late String label;
    switch (status) {
      case 1:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        icon = Icons.check_circle;
        label = 'Confirmado';
        break;
      case 2:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        icon = Icons.cancel;
        label = 'Falta';
        break;
      default:
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFE65100);
        icon = Icons.help_outline;
        label = 'Não informado';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: fg, size: 14),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }


  void _abrirPerfil() {
    final nome = transportador['nome'] ?? '';
    final veiculo = transportador['veiculo'] ?? '';
    final whatsapp = transportador['whatsapp'] ?? '';
    final numEscolar = transportador['numero_escolar'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              color: _avatarColor(nome),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: _avatarColor(nome).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6))
              ],
            ),
            child: Center(
              child: Text(
                nome.isNotEmpty ? nome[0].toUpperCase() : 'T',
                style: const TextStyle(
                    fontSize: 38,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(nome,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: primary)),
          if (veiculo.isNotEmpty)
            Text(veiculo,
                style:
                    const TextStyle(color: Colors.black45, fontSize: 14)),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(children: [
              _perfilItem(Icons.person_outline, 'Nome', nome),
              _divider(),
              _perfilItem(Icons.phone_outlined, 'WhatsApp',
                  whatsapp.isNotEmpty ? whatsapp : '—'),
              _divider(),
              _perfilItem(Icons.directions_bus_outlined, 'Veículo',
                  veiculo.isNotEmpty ? veiculo : '—'),
              if (numEscolar.isNotEmpty) ...[
                _divider(),
                _perfilItem(Icons.confirmation_number_outlined,
                    'Nº Escolar', numEscolar),
              ],
              _divider(),
              StreamBuilder<int>(
                stream: _streamTotalAlunos,
                builder: (context, snap) {
                  final total = snap.data ?? 0;
                  return _perfilItem(
                    Icons.child_care,
                    'Total de crianças',
                    '$total criança${total != 1 ? 's' : ''}',
                  );
                },
              ),
            ]),
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200)),
            leading: const Icon(Icons.school, color: primary),
            title: const Text('Gerenciar Escolas'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(ctx).pop();
              Navigator.of(context)
                  .pushNamed('/escolas', arguments: {
                    ...transportador,
                    'uid': transportador['uid'] ?? transportador['id'] ?? '',
                  });
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red, size: 18),
              label: const Text('Sair',
                  style: TextStyle(color: Colors.red, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _logout();
              },
            ),
          ),
        ]),
      ),
    );
  }


  void _abrirFicha(Aluno aluno) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (ctx) {
        final trajeto = _isIndoParaEscola ? 'ida' : 'volta';
        return StreamBuilder<int?>(
        stream: _service.streamPresencaHoje(aluno.id, trajeto),
        builder: (context, snap) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: trajeto == 'ida'
                      ? const Color(0xFFE3F2FD)
                      : const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    trajeto == 'ida' ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: trajeto == 'ida'
                        ? const Color(0xFF1565C0)
                        : const Color(0xFF6A1B9A),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Presença: ${trajeto == 'ida' ? 'Ida' : 'Volta'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: trajeto == 'ida'
                          ? const Color(0xFF1565C0)
                          : const Color(0xFF6A1B9A),
                    ),
                  ),
                ]),
              ),

              Row(children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: _avatarColor(aluno.nome),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      aluno.nome.isNotEmpty
                          ? aluno.nome[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
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
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.school_outlined,
                              size: 13, color: Colors.black45),
                          const SizedBox(width: 4),
                          Text(aluno.escola,
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 13)),
                        ]),
                        const SizedBox(height: 6),
                        snap.connectionState == ConnectionState.waiting
                            ? const SizedBox(
                                height: 14,
                                width: 80,
                                child: LinearProgressIndicator())
                            : _badgePresenca(snap.data),
                      ]),
                ),
                IconButton(
                  tooltip: 'Editar aluno',
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        color: primary, size: 20),
                  ),
                  onPressed: () async {
                    Navigator.of(ctx).pop(); // fecha o modal
                    final editado = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => EditAlunoPage(
                          aluno: aluno,
                          transportador: transportador,
                        ),
                      ),
                    );
                    if (editado == true && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Dados atualizados!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
              ]),

              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(children: [
                  _perfilItem(Icons.person_outlined, 'Pai/Mãe',
                      aluno.responsavel),
                  _divider(),
                  _perfilItem(
                      Icons.school_outlined, 'Escola', aluno.escola),
                  _divider(),
                  _perfilItem(Icons.location_on_outlined, 'Parada',
                      aluno.enderecoCasa.isNotEmpty
                          ? aluno.enderecoCasa
                          : '—'),
                  _divider(),
                  _perfilItem(
                      Icons.schedule_outlined, 'Período', aluno.periodo),
                  _divider(),
                  _perfilItem(Icons.arrow_upward, 'Ordem Ida',
                      '${aluno.ordemIda}º'),
                  _divider(),
                  _perfilItem(Icons.arrow_downward, 'Ordem Volta',
                      '${aluno.ordemVolta}º'),
                ]),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _whatsAppIcon(size: 20),
                  label: Text(
                      'Chamar no WhatsApp  ${aluno.whatsappResponsavel}',
                      style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () =>
                      _abrirWhatsApp(aluno.whatsappResponsavel, aluno.nome),
                ),
              ),
              const SizedBox(height: 10),

              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Veio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      await _service.marcarPresenca(aluno.id, 1, trajeto);
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            "✅ ${aluno.nome} — ${trajeto == 'ida' ? 'Ida' : 'Volta'} confirmada"),
                        backgroundColor: Colors.green.shade700,
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Não veio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      await _service.marcarPresenca(aluno.id, 2, trajeto);
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            "❌ ${aluno.nome} — ${trajeto == 'ida' ? 'Ida' : 'Volta'} ausente"),
                        backgroundColor: Colors.red.shade700,
                      ));
                    },
                  ),
                ),
              ]),
            ]),
          );
        },
      );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_transportadorCarregado) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final nome = transportador['nome'] ?? 'Transportador';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Olá, $nome',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('SafeRide',
              style: TextStyle(fontSize: 11, color: Colors.white60)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Perfil',
            onPressed: _abrirPerfil,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Adicionar aluno',
            onPressed: () => Navigator.of(context)
                .pushNamed('/addAluno', arguments: transportador),
          ),
        ],
      ),
      body: StreamBuilder<List<String>>(
        stream: _streamNomesEscolas,
        builder: (context, snapEscolas) {
          final nomesEscolas = snapEscolas.data ?? [];

          return StreamBuilder<List<Aluno>>(
            stream: _service.getAlunos(
                transportador['uid'] ?? '', _periodo, _isIndoParaEscola),
            builder: (context, snapshot) {
              final todosAlunos = snapshot.data ?? [];

              if (_escolaFiltro != null &&
                  !nomesEscolas.contains(_escolaFiltro)) {
                WidgetsBinding.instance.addPostFrameCallback(
                    (_) => setState(() => _escolaFiltro = null));
              }

              final alunos = _escolaFiltro == null
                  ? todosAlunos
                  : todosAlunos
                      .where((a) => a.escola == _escolaFiltro)
                      .toList();

              return Column(children: [
                Container(
                  color: primary,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Row(children: [
                    Expanded(
                        child: _FiltroChip(
                            label: 'Matutino',
                            selected: _periodo == 'Matutino',
                            onTap: () => setState(() {
                                  _periodo = 'Matutino';
                                  _escolaFiltro = null;
                                }))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _FiltroChip(
                            label: 'Vespertino',
                            selected: _periodo == 'Vespertino',
                            onTap: () => setState(() {
                                  _periodo = 'Vespertino';
                                  _escolaFiltro = null;
                                }))),
                    const SizedBox(width: 14),
                    Expanded(
                        child: _FiltroChip(
                            label: 'Ida',
                            selected: _isIndoParaEscola,
                            onTap: () =>
                                setState(() => _isIndoParaEscola = true))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _FiltroChip(
                            label: 'Volta',
                            selected: !_isIndoParaEscola,
                            onTap: () =>
                                setState(() => _isIndoParaEscola = false))),
                  ]),
                ),

                if (nomesEscolas.isNotEmpty)
                  Container(
                    color: primary.withOpacity(0.88),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [
                        _EscolaChip(
                          label: 'Todas',
                          selected: _escolaFiltro == null,
                          onTap: () =>
                              setState(() => _escolaFiltro = null),
                        ),
                        ...nomesEscolas.map((e) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _EscolaChip(
                                label: e,
                                selected: _escolaFiltro == e,
                                onTap: () =>
                                    setState(() => _escolaFiltro = e),
                              ),
                            )),
                      ]),
                    ),
                  ),

                if (snapshot.connectionState != ConnectionState.waiting)
                  _BannerTurno(
                    nome: transportador['nome'] ?? '',
                    totalTurno: todosAlunos.length,
                    periodo: _periodo,
                    isIda: _isIndoParaEscola,
                  ),

                Expanded(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const Center(child: CircularProgressIndicator())
                      : snapshot.hasError
                          ? Center(child: Text('Erro: ${snapshot.error}'))
                          : alunos.isEmpty
                              ? _emptyState()
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 8, 16, 24),
                                  itemCount: alunos.length,
                                  itemBuilder: (context, i) => _AlunoCard(
                                    aluno: alunos[i],
                                    isIda: _isIndoParaEscola,
                                    avatarColor:
                                        _avatarColor(alunos[i].nome),
                                    service: _service,
                                    onWhatsApp: _abrirWhatsApp,
                                    onTap: () => _abrirFicha(alunos[i]),
                                    whatsAppIcon: _whatsAppIcon,
                                    badgePresenca: _badgePresenca,
                                  ),
                                ),
                ),
              ]);
            },
          );
        },
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.child_care, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Nenhuma criança cadastrada\npara $_periodo · ${_isIndoParaEscola ? "Ida" : "Volta"}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Colors.black38),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Adicionar aluno'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context)
                .pushNamed('/addAluno', arguments: transportador),
          ),
        ]),
      );
}

class _AlunoCard extends StatelessWidget {
  final Aluno aluno;
  final bool isIda;
  final Color avatarColor;
  final DatabaseService service;
  final Future<void> Function(String, String) onWhatsApp;
  final VoidCallback onTap;
  final Widget Function({double size}) whatsAppIcon;
  final Widget Function(int?) badgePresenca;

  const _AlunoCard({
    required this.aluno,
    required this.isIda,
    required this.avatarColor,
    required this.service,
    required this.onWhatsApp,
    required this.onTap,
    required this.whatsAppIcon,
    required this.badgePresenca,
  });

  static const primary = Color(0xFF003366);

  @override
  Widget build(BuildContext context) {
    final ordem = isIda ? aluno.ordemIda : aluno.ordemVolta;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: avatarColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    aluno.nome.isNotEmpty
                        ? aluno.nome[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                bottom: -6, right: -6,
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text('$ordem',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ]),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(aluno.nome,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.school_outlined,
                          size: 13, color: Colors.black38),
                      const SizedBox(width: 4),
                      Text(aluno.escola,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black54)),
                    ]),
                    if (aluno.enderecoCasa.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: Colors.black38),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(aluno.enderecoCasa,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black45),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                    ],
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.schedule_outlined,
                          size: 13, color: Colors.black38),
                      const SizedBox(width: 4),
                      Text(aluno.periodo,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black45)),
                    ]),
                    const SizedBox(height: 8),
                    StreamBuilder<int?>(
                      stream: service.streamPresencaHoje(aluno.id, isIda ? 'ida' : 'volta'),
                      builder: (context, snap) {
                        if (snap.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                              height: 22,
                              width: 100,
                              child:
                                  LinearProgressIndicator(minHeight: 2));
                        }
                        return badgePresenca(snap.data);
                      },
                    ),
                  ]),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 4, top: 2),
              child: GestureDetector(
                onTap: () =>
                    onWhatsApp(aluno.whatsappResponsavel, aluno.nome),
                child: whatsAppIcon(size: 28),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FiltroChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: selected
                      ? const Color(0xFF003366)
                      : Colors.white70)),
        ),
      ),
    );
  }
}

class _EscolaChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _EscolaChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? Colors.white : Colors.white38,
              width: 1),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? const Color(0xFF003366)
                    : Colors.white)),
      ),
    );
  }
}

class _BannerTurno extends StatelessWidget {
  final String nome;
  final int totalTurno;
  final String periodo;
  final bool isIda;

  const _BannerTurno({
    required this.nome,
    required this.totalTurno,
    required this.periodo,
    required this.isIda,
  });

  @override
  Widget build(BuildContext context) {
    if (totalTurno == 0) return const SizedBox.shrink();

    final primeiroNome = nome.split(' ').first;
    final trajetoLabel = isIda ? 'levar' : 'buscar';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB3D9F5)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.info_outline,
              color: Color(0xFF1565C0), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                  color: Color(0xFF1A3A5C), fontSize: 13.5, height: 1.4),
              children: [
                TextSpan(
                  text: 'Olá, $primeiroNome! ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      'Você tem $totalTurno criança${totalTurno != 1 ? 's' : ''} para $trajetoLabel no período ',
                ),
                TextSpan(
                  text: periodo,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}