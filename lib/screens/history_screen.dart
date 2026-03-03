import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import './widgets/skeleton_loader.dart'; // ajusta la ruta

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _movimientos = [];
  List<Map<String, dynamic>> _sucursales = [];

  int _paginaActual = 1;
  bool _cargando = false;
  bool _cargandoMas = false;
  bool _tieneSiguiente = true;
  String? _error;

  // Filtros
  String? _sucursalId;
  String? _tipo;
  String _busqueda = '';
  Timer? _debounce;

  // ── Colores ──
  static const Color _primary = Color(0xFF137FEC);
  static const Color _green = Color(0xFF10B981);
  static const Color _rose = Color(0xFFF43F5E);
  static const Color _bgPage = Color(0xFFF6F7F8);
  static const Color _border = Color(0xFFE8ECF0);

  @override
  void initState() {
    super.initState();
    _cargarSucursales();
    _cargarMovimientos(reiniciar: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _cargarMas();
      }
    });

    _searchController.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () {
        if (_busqueda != _searchController.text) {
          _busqueda = _searchController.text;
          _cargarMovimientos(reiniciar: true);
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _cargarSucursales() async {
    final r = await _api.listarSucursales();
    if (r['exito'] == true && mounted) {
      setState(() {
        _sucursales = List<Map<String, dynamic>>.from(
          r['data']['sucursales'] ?? [],
        );
      });
    }
  }

  Future<void> _cargarMovimientos({bool reiniciar = false}) async {
    if (_cargando || _cargandoMas) return;

    if (reiniciar) {
      setState(() {
        _cargando = true;
        _error = null;
        _paginaActual = 1;
        _tieneSiguiente = true;
      });
    } else {
      setState(() {
        _cargandoMas = true;
      });
    }

    final r = await _api.listarMovimientos(
      page: reiniciar ? 1 : _paginaActual,
      perPage: 10,
      sucursalId: _sucursalId,
      tipo: _tipo,
      cedula: _busqueda.isNotEmpty ? _busqueda : null,
    );

    if (!mounted) return;

    if (r['exito'] == true) {
      final data = r['data'];
      final nuevos = List<Map<String, dynamic>>.from(data['movimientos'] ?? []);
      final pag = data['paginacion'];
      setState(() {
        if (reiniciar) {
          _movimientos = nuevos;
        } else {
          _movimientos.addAll(nuevos);
        }
        _paginaActual = (pag['pagina_actual'] as int) + 1;
        _tieneSiguiente = pag['tiene_siguiente'] ?? false;
        _cargando = false;
        _cargandoMas = false;
      });
    } else {
      setState(() {
        _error = r['error'];
        _cargando = false;
        _cargandoMas = false;
      });
    }
  }

  Future<void> _cargarMas() async {
    if (!_tieneSiguiente || _cargandoMas || _cargando) return;
    await _cargarMovimientos(reiniciar: false);
  }

  void _seleccionarSucursal(String? id) {
    setState(() => _sucursalId = id);
    _cargarMovimientos(reiniciar: true);
  }

  void _seleccionarTipo(String? t) {
    setState(() => _tipo = t);
    _cargarMovimientos(reiniciar: true);
  }

  // ── Agrupa movimientos por fecha ──
  Map<String, List<Map<String, dynamic>>> _agruparPorFecha() {
    final grupos = <String, List<Map<String, dynamic>>>{};
    for (final m in _movimientos) {
      final key = _labelFecha(m['fecha_hora'] ?? '');
      grupos.putIfAbsent(key, () => []).add(m);
    }
    return grupos;
  }

  String _labelFecha(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final hoy = DateTime.now();
      final ayer = DateTime(hoy.year, hoy.month, hoy.day - 1);
      final d = DateTime(dt.year, dt.month, dt.day);
      if (d == DateTime(hoy.year, hoy.month, hoy.day)) {
        return 'Hoy, ${_diaConMes(dt)}';
      }
      if (d == ayer) return 'Ayer, ${_diaConMes(dt)}';
      return _diaConMes(dt);
    } catch (_) {
      return raw;
    }
  }

  String _diaConMes(DateTime dt) {
    const meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${dt.day} de ${meses[dt.month - 1]}';
  }

  String _hora(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h = dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = h >= 12 ? 'PM' : 'AM';
      final h12 = h % 12 == 0 ? 12 : h % 12;
      return '$h12:$m $ampm';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearch(),
            _buildSucursalesChips(),
            Expanded(child: _buildLista()),
          ],
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.face_6_rounded, color: _primary, size: 22),
          ),
          const SizedBox(width: 10),
          const Text(
            'Historial',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showTipoSheet(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _tipo != null ? _primary.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _tipo != null ? _primary.withOpacity(0.3) : _border,
                ),
              ),
              child: Icon(
                Icons.filter_list_rounded,
                color: _tipo != null ? _primary : const Color(0xFF64748B),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Buscador ──
  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(
              Icons.search_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre o cédula',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _busqueda = '';
                  _cargarMovimientos(reiniciar: true);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.close_rounded,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Chips de sucursales ──
  Widget _buildSucursalesChips() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildChip(
            label: 'Todas',
            seleccionado: _sucursalId == null,
            onTap: () => _seleccionarSucursal(null),
          ),
          ..._sucursales.map(
            (s) => _buildChip(
              label: s['nombre'] ?? '',
              seleccionado: _sucursalId == s['id'].toString(),
              onTap: () => _seleccionarSucursal(s['id'].toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool seleccionado,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: seleccionado ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: seleccionado ? _primary : _border),
          boxShadow: seleccionado
              ? [
                  BoxShadow(
                    color: _primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: seleccionado ? Colors.white : const Color(0xFF64748B),
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }

  // ── Lista agrupada por fecha ──
  Widget _buildLista() {
    // ✅ DESPUÉS
    if (_cargando) {
      return const SkeletonLoader(itemCount: 6);
    }

    if (_error != null && _movimientos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: Color(0xFFCBD5E1),
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _cargarMovimientos(reiniciar: true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Reintentar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_movimientos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, color: Color(0xFFCBD5E1), size: 44),
            SizedBox(height: 12),
            Text(
              'Sin movimientos',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'No hay registros con los filtros aplicados',
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
            ),
          ],
        ),
      );
    }

    final grupos = _agruparPorFecha();
    final fechas = grupos.keys.toList();

    final items = <_ListItem>[];
    for (final fecha in fechas) {
      items.add(_ListItem(isHeader: true, fecha: fecha));
      for (final m in grupos[fecha]!) {
        items.add(_ListItem(isHeader: false, movimiento: m));
      }
    }
    if (_tieneSiguiente) items.add(_ListItem(isHeader: false, isLoader: true));

    return RefreshIndicator(
      color: _primary,
      onRefresh: () => _cargarMovimientos(reiniciar: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final item = items[i];
          if (item.isLoader) return _buildLoaderItem();
          if (item.isHeader) return _buildDateHeader(item.fecha!);
          return _buildCard(item.movimiento!);
        },
      ),
    );
  }

  Widget _buildDateHeader(String fecha) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        children: [
          Text(
            fecha.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: _border)),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> m) {
    final esEntrada = m['tipo'] == 'entrada';
    final badgeColor = esEntrada ? _green : _rose;

    // ✅ CORREGIDO: campo correcto de la API
    final nombre = m['nombre_persona'] ?? '—';
    final cedula = m['cedula'] ?? '';
    final hora = _hora(m['fecha_hora'] ?? '');
    final sucursal = m['sucursal_nombre'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar con badge SVG
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,

                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: SvgPicture.asset(
                      'assets/icons/operator.svg',

                    ),
                  ),
                ),
                // ✅ CORREGIDO: ícono SVG desde assets
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: SvgPicture.asset(
                        'assets/icons/operator.svg',
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Nombre + cédula + sede
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'C.I. $cedula',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (sucursal.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.store_rounded,
                          size: 10,
                          color: Color(0xFFCBD5E1),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          sucursal,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFCBD5E1),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Hora + tipo
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hora,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  esEntrada ? 'Entrada' : 'Salida',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoaderItem() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(color: _primary, strokeWidth: 2),
        ),
      ),
    );
  }

  // ── Bottom sheet filtro tipo ──
  void _showTipoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Filtrar por tipo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            _buildTipoOption(
              null,
              'Todos los movimientos',
              Icons.swap_vert_rounded,
              const Color(0xFF64748B),
            ),
            const SizedBox(height: 8),
            _buildTipoOption(
              'entrada',
              'Solo entradas',
              Icons.login_rounded,
              _green,
            ),
            const SizedBox(height: 8),
            _buildTipoOption(
              'salida',
              'Solo salidas',
              Icons.logout_rounded,
              _rose,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoOption(
    String? valor,
    String label,
    IconData icon,
    Color color,
  ) {
    final seleccionado = _tipo == valor;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _seleccionarTipo(valor);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: seleccionado
              ? color.withOpacity(0.08)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado ? color.withOpacity(0.3) : _border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: seleccionado ? color : const Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            if (seleccionado)
              Icon(Icons.check_circle_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

// Helper para aplanar grupos en ListView
class _ListItem {
  final bool isHeader;
  final bool isLoader;
  final String? fecha;
  final Map<String, dynamic>? movimiento;

  const _ListItem({
    required this.isHeader,
    this.fecha,
    this.movimiento,
    this.isLoader = false,
  });
}
