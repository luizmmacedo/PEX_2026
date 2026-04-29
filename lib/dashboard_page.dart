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
  static const accent = Color(0xFF0057B8);
  static const surface = Color(0xFFEEF2F8);

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
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primary, size: 17),
        ),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(color: Colors.black45, fontSize: 13)),
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
      height: 1, color: Colors.grey.shade100, indent: 60, endIndent: 16);

  Widget _badgePresenca(int? status) {
    late Color bg, fg;
    late IconData icon;
    late String label;
    switch (status) {
      case 1:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        icon = Icons.check_circle_rounded;
        label = 'Confirmado';
        break;
      case 2:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        icon = Icons.cancel_rounded;
        label = 'Falta';
        break;
      default:
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        icon = Icons.help_rounded;
        label = 'Não informado';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: fg, size: 13),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  void _abrirSeletorEscola(List<String> escolas) {
    final stream = _service.getAlunos(
        transportador['uid'] ?? '', _periodo, _isIndoParaEscola);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (ctx) => StreamBuilder<List<Aluno>>(
        stream: stream,
        builder: (context, snap) {
          final todos = snap.data ?? [];
          final contagemPorEscola = <String, int>{};
          for (final a in todos) {
            contagemPorEscola[a.escola] = (contagemPorEscola[a.escola] ?? 0) + 1;
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Filtrar por escola',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primary)),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$_periodo · ${_isIndoParaEscola ? 'Ida' : 'Volta'} · ${todos.length} aluno${todos.length != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ),
              const SizedBox(height: 16),
              _SeletorEscolaTile(
                label: 'Todas as escolas',
                icon: Icons.layers_rounded,
                selected: _escolaFiltro == null,
                count: todos.isNotEmpty ? todos.length : null,
                onTap: () {
                  setState(() => _escolaFiltro = null);
                  Navigator.pop(ctx);
                },
              ),
              const Divider(height: 12),
              ...escolas.map((e) => _SeletorEscolaTile(
                    label: e,
                    icon: Icons.school_rounded,
                    selected: _escolaFiltro == e,
                    count: contagemPorEscola[e],
                    onTap: () {
                      setState(() => _escolaFiltro = e);
                      Navigator.pop(ctx);
                    },
                  )),
            ]),
          );
        },
      ),
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
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2)),
          ),
          Container(
            width: 84, height: 84,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_avatarColor(nome), _avatarColor(nome).withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: _avatarColor(nome).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Center(
              child: Text(
                nome.isNotEmpty ? nome[0].toUpperCase() : 'T',
                style: const TextStyle(
                    fontSize: 36,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(nome,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: primary)),
          if (veiculo.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(veiculo,
                  style: const TextStyle(
                      color: primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
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
          _PerfilActionTile(
            icon: Icons.school_rounded,
            label: 'Gerenciar Escolas',
            onTap: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamed('/escolas', arguments: {
                ...transportador,
                'uid': transportador['uid'] ?? transportador['id'] ?? '',
              });
            },
          ),
          const SizedBox(height: 8),
          _PerfilActionTile(
            icon: Icons.logout_rounded,
            label: 'Sair',
            isDestructive: true,
            onTap: () {
              Navigator.of(ctx).pop();
              _logout();
            },
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      backgroundColor: Colors.white,
      builder: (ctx) {
        final trajeto = _isIndoParaEscola ? 'ida' : 'volta';
        return StreamBuilder<int?>(
          stream: _service.streamPresencaHoje(aluno.id, trajeto),
          builder: (context, snap) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, scrollController) => SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.only(
                  left: 24, right: 24, top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                ),
                child: Column(children: [
                  Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2)),
                  ),

                  Row(children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _avatarColor(aluno.nome),
                            _avatarColor(aluno.nome).withOpacity(0.75)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _avatarColor(aluno.nome).withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          aluno.nome.isNotEmpty
                              ? aluno.nome[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(aluno.nome,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D1B2A))),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.school_outlined,
                                  size: 13, color: Colors.black38),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(aluno.escola,
                                    style: const TextStyle(
                                        color: Colors.black45, fontSize: 12)),
                              ),
                            ]),
                            const SizedBox(height: 6),
                            snap.connectionState == ConnectionState.waiting
                                ? Container(
                                    height: 22,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                  )
                                : _badgePresenca(snap.data),
                          ]),
                    ),
                    GestureDetector(
                      onTap: () async {
                        Navigator.of(ctx).pop();
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
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit_outlined,
                            color: primary, size: 19),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: trajeto == 'ida'
                          ? const Color(0xFFE8F0FE)
                          : const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          trajeto == 'ida'
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 15,
                          color: trajeto == 'ida'
                              ? const Color(0xFF1565C0)
                              : const Color(0xFF6A1B9A),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Presença: ${trajeto == 'ida' ? 'Ida para escola' : 'Volta para casa'}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: trajeto == 'ida'
                                ? const Color(0xFF1565C0)
                                : const Color(0xFF6A1B9A),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(children: [
                      _fichaItem(Icons.person_outlined, 'Pai/Mãe',
                          aluno.responsavel),
                      _divider(),
                      _fichaItem(Icons.school_outlined, 'Escola', aluno.escola),
                      _divider(),
                      _fichaItem(Icons.location_on_outlined, 'Parada',
                          aluno.enderecoCasa.isNotEmpty
                              ? aluno.enderecoCasa
                              : '—'),
                      _divider(),
                      _fichaItem(
                          Icons.schedule_outlined, 'Período', aluno.periodo),
                      _divider(),
                      Row(children: [
                        Expanded(
                          child: _fichaItem(Icons.arrow_upward_rounded,
                              'Ordem Ida', '${aluno.ordemIda}º'),
                        ),
                        Container(
                            width: 1,
                            height: 44,
                            color: Colors.grey.shade100),
                        Expanded(
                          child: _fichaItem(Icons.arrow_downward_rounded,
                              'Ordem Volta', '${aluno.ordemVolta}º'),
                        ),
                      ]),
                    ]),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _whatsAppIcon(size: 19),
                      label: Text(
                        'Chamar no WhatsApp  ${aluno.whatsappResponsavel}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: () => _abrirWhatsApp(
                          aluno.whatsappResponsavel, aluno.nome),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(children: [
                    Expanded(
                      child: _PresencaButton(
                        label: 'Veio',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF2E7D32),
                        bgColor: const Color(0xFFE8F5E9),
                        onTap: () async {
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PresencaButton(
                        label: 'Não veio',
                        icon: Icons.cancel_rounded,
                        color: const Color(0xFFC62828),
                        bgColor: const Color(0xFFFFEBEE),
                        onTap: () async {
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _fichaItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primary, size: 15),
        ),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(color: Colors.black45, fontSize: 13)),
        const Spacer(),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontSize: 13)),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_transportadorCarregado) {
      return const Scaffold(
        backgroundColor: primary,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final nome = transportador['nome'] ?? 'Transportador';
    final primeiroNome = nome.toString().split(' ').first;

    return Scaffold(
      backgroundColor: surface,
      body: StreamBuilder<List<Aluno>>(
        stream: _service.getAlunos(
            transportador['uid'] ?? '', _periodo, _isIndoParaEscola),
        builder: (context, snapshot) {
          final todosAlunos = snapshot.data ?? [];
          final alunos = _escolaFiltro == null
              ? todosAlunos
              : todosAlunos.where((a) => a.escola == _escolaFiltro).toList();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                backgroundColor: primary,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF001F4D), Color(0xFF003F8A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              GestureDetector(
                                onTap: _abrirPerfil,
                                child: Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: _avatarColor(nome),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 2),
                                  ),
                                  child: Center(
                                    child: Text(
                                      nome.isNotEmpty
                                          ? nome[0].toUpperCase()
                                          : 'T',
                                      style: const TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Olá, $primeiroNome 👋',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold)),
                                    StreamBuilder<int>(
                                      stream: _streamTotalAlunos,
                                      builder: (_, snap) {
                                        final total = snap.data ?? 0;
                                        return Text(
                                          '$total aluno${total != 1 ? 's' : ''} cadastrado${total != 1 ? 's' : ''}',
                                          style: const TextStyle(
                                              color: Colors.white60,
                                              fontSize: 12),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context)
                                    .pushNamed('/addAluno',
                                        arguments: transportador),
                                child: Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.person_add_rounded,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            Row(children: [
                              _AppBarChip(
                                label: 'Matutino',
                                icon: Icons.wb_sunny_rounded,
                                selected: _periodo == 'Matutino',
                                onTap: () => setState(() {
                                  _periodo = 'Matutino';
                                  _escolaFiltro = null;
                                }),
                              ),
                              const SizedBox(width: 8),
                              _AppBarChip(
                                label: 'Vespertino',
                                icon: Icons.wb_twilight_rounded,
                                selected: _periodo == 'Vespertino',
                                onTap: () => setState(() {
                                  _periodo = 'Vespertino';
                                  _escolaFiltro = null;
                                }),
                              ),
                              const Spacer(),
                              _DirecaoToggle(
                                isIda: _isIndoParaEscola,
                                onToggle: (v) =>
                                    setState(() => _isIndoParaEscola = v),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Builder(builder: (context) {
                  final escolasDoPeriodo = todosAlunos
                      .map((a) => a.escola)
                      .toSet()
                      .toList()
                    ..sort();
                  if (_escolaFiltro != null &&
                      !escolasDoPeriodo.contains(_escolaFiltro)) {
                    WidgetsBinding.instance.addPostFrameCallback(
                        (_) => setState(() => _escolaFiltro = null));
                  }
                  if (escolasDoPeriodo.length < 2) return const SizedBox.shrink();

                  final ativo = _escolaFiltro != null;

                  return Container(
                    color: const Color(0xFF002A6B),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _abrirSeletorEscola(escolasDoPeriodo),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: ativo
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(24),
                              border: ativo
                                  ? null
                                  : Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  size: 14,
                                  color: ativo
                                      ? const Color(0xFF003366)
                                      : Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.5,
                                  ),
                                  child: Text(
                                    ativo ? _escolaFiltro! : 'Filtrar escola',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: ativo
                                          ? const Color(0xFF003366)
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 17,
                                  color: ativo
                                      ? const Color(0xFF003366)
                                      : Colors.white60,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (ativo) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _escolaFiltro = null),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 9),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.2)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.close_rounded,
                                      size: 13, color: Colors.white70),
                                  SizedBox(width: 4),
                                  Text('Todas',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ),

              if (snapshot.connectionState != ConnectionState.waiting)
                SliverToBoxAdapter(
                  child: _BannerTurno(
                    nome: primeiroNome,
                    totalTurno: todosAlunos.length,
                    periodo: _periodo,
                    isIda: _isIndoParaEscola,
                  ),
                ),

              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                SliverFillRemaining(
                  child: Center(
                      child: Text('Erro: ${snapshot.error}',
                          style:
                              const TextStyle(color: Colors.red))),
                )
              else if (alunos.isEmpty)
                SliverFillRemaining(
                  child: _EmptyState(
                    periodo: _periodo,
                    isIda: _isIndoParaEscola,
                    onAdd: () => Navigator.of(context)
                        .pushNamed('/addAluno', arguments: transportador),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final aluno = alunos[index];
                        return _AlunoCard(
                          aluno: aluno,
                          isIda: _isIndoParaEscola,
                          avatarColor: _avatarColor(aluno.nome),
                          service: _service,
                          badgePresenca: _badgePresenca,
                          onTap: () => _abrirFicha(aluno),
                          onWhatsApp: () => _abrirWhatsApp(
                              aluno.whatsappResponsavel, aluno.nome),
                          whatsAppIcon: _whatsAppIcon,
                        );
                      },
                      childCount: alunos.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AppBarChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AppBarChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: selected ? 1 : 0),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        builder: (context, t, _) {
          final bg = Color.lerp(
            Colors.white.withOpacity(0.12),
            Colors.white,
            t,
          )!;
          final fg = Color.lerp(Colors.white70, const Color(0xFF003366), t)!;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
            ]),
          );
        },
      ),
    );
  }
}

class _DirecaoToggle extends StatelessWidget {
  final bool isIda;
  final ValueChanged<bool> onToggle;

  const _DirecaoToggle({required this.isIda, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _tab('Ida', Icons.arrow_upward_rounded, isIda, () => onToggle(true)),
        _tab('Volta', Icons.arrow_downward_rounded, !isIda,
            () => onToggle(false)),
      ]),
    );
  }

  Widget _tab(
      String label, IconData icon, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: selected ? 1 : 0),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        builder: (context, t, _) {
          final bg = Color.lerp(Colors.transparent, Colors.white, t)!;
          final fg =
              Color.lerp(Colors.white60, const Color(0xFF003366), t)!;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
            ]),
          );
        },
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFF003366) : Colors.white,
          ),
        ),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F0FE), Color(0xFFEEF4FF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF003366).withOpacity(0.1)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF003366).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.directions_bus_rounded,
              color: Color(0xFF003366), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                  color: Color(0xFF0D1B2A), fontSize: 13),
              children: [
                TextSpan(
                    text: '$nome',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(
                    text:
                        ', você tem $totalTurno aluno${totalTurno != 1 ? 's' : ''} no '),
                TextSpan(
                    text: periodo,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(
                    text: ' — ${isIda ? 'Indo para escola' : 'Voltando para casa'}'),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _AlunoCard extends StatelessWidget {
  final Aluno aluno;
  final bool isIda;
  final Color avatarColor;
  final DatabaseService service;
  final Widget Function(int?) badgePresenca;
  final VoidCallback onTap;
  final VoidCallback onWhatsApp;
  final Widget Function({double size}) whatsAppIcon;

  const _AlunoCard({
    required this.aluno,
    required this.isIda,
    required this.avatarColor,
    required this.service,
    required this.badgePresenca,
    required this.onTap,
    required this.onWhatsApp,
    required this.whatsAppIcon,
  });

  @override
  Widget build(BuildContext context) {
    final trajeto = isIda ? 'ida' : 'volta';
    final ordem = isIda ? aluno.ordemIda : aluno.ordemVolta;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF003366).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('$ordem',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF003366))),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [avatarColor, avatarColor.withOpacity(0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  aluno.nome.isNotEmpty ? aluno.nome[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(aluno.nome,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D1B2A))),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.school_outlined,
                        size: 12, color: Colors.black38),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(aluno.escola,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black45)),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: Colors.black38),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                          aluno.enderecoCasa.isNotEmpty
                              ? aluno.enderecoCasa
                              : '—',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black45),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  StreamBuilder<int?>(
                    stream: service.streamPresencaHoje(aluno.id, trajeto),
                    builder: (_, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Container(
                          height: 20,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }
                      return badgePresenca(snap.data);
                    },
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onWhatsApp,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: whatsAppIcon(size: 20)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String periodo;
  final bool isIda;
  final VoidCallback onAdd;

  const _EmptyState(
      {required this.periodo, required this.isIda, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF003366).withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.child_care_rounded,
                size: 36, color: Color(0xFF003366)),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum aluno no período $periodo\n${isIda ? '(Ida)' : '(Volta)'}',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black54),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: const Text('Adicionar aluno'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003366),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: onAdd,
          ),
        ]),
      ),
    );
  }
}

class _PerfilActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _PerfilActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive ? Colors.red : const Color(0xFF003366);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          const Spacer(),
          Icon(isDestructive ? Icons.logout : Icons.arrow_forward_ios_rounded,
              color: color.withOpacity(0.5), size: 15),
        ]),
      ),
    );
  }
}

class _PresencaButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _PresencaButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _SeletorEscolaTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final int? count;
  final VoidCallback onTap;

  const _SeletorEscolaTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF003366);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? primary.withOpacity(0.07) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? primary.withOpacity(0.2) : Colors.transparent,
          ),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: selected
                  ? primary.withOpacity(0.12)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                size: 18,
                color: selected ? primary : Colors.grey.shade500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? primary : Colors.black87,
              ),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: selected
                    ? primary.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? primary : Colors.grey.shade600,
                ),
              ),
            ),
          ],
          if (selected) ...[
            const SizedBox(width: 8),
            const Icon(Icons.check_circle_rounded,
                size: 18, color: primary),
          ],
        ]),
      ),
    );
  }
}