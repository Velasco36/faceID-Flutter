// search_filter.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SearchFilter extends StatefulWidget {
  const SearchFilter({super.key});

  @override
  State<SearchFilter> createState() => _SearchFilterState();
}

class _SearchFilterState extends State<SearchFilter> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _buscando = false;
  String? _error;
  Map<String, dynamic>? _resultado;
  List<dynamic>? _personasMultiples;

  // Detecta si el texto es solo números → cédula, si tiene letras → nombre
  bool get _esCedula => RegExp(r'^\d+$').hasMatch(_searchCtrl.text.trim());
  String get _tipoBusquedaLabel => _searchCtrl.text.trim().isEmpty
      ? ''
      : _esCedula
      ? 'Buscando por cédula'
      : 'Buscando por nombre';

  static const _primaryColor = Color(0xFF137FEC);
  static const _secondaryTextColor = Color(0xFF617589);

  Future<void> _buscar({String? cedulaDirecta}) async {
    final texto = cedulaDirecta ?? _searchCtrl.text.trim();

    if (texto.isEmpty) {
      setState(() => _error = 'Ingresa una cédula o un nombre para buscar.');
      return;
    }

    // Detectar si es cédula (solo dígitos) o nombre (tiene letras)
    final esCedula = cedulaDirecta != null || RegExp(r'^\d+$').hasMatch(texto);

    setState(() {
      _buscando = true;
      _error = null;
      _resultado = null;
      _personasMultiples = null;
    });

    final respuesta = await _apiService.movimientosPorPersona(
      cedula: esCedula ? texto : null,
      nombre: esCedula ? null : texto,
    );

    setState(() {
      _buscando = false;
      if (respuesta['exito'] == true) {
        _resultado = respuesta['data'] as Map<String, dynamic>;
      } else if (respuesta['multiples'] == true) {
        _personasMultiples =
            (respuesta['data'] as Map<String, dynamic>)['personas']
                as List<dynamic>;
      } else {
        _error = respuesta['error'] as String?;
      }
    });
  }

  void _limpiar() {
    setState(() {
      _searchCtrl.clear();
      _resultado = null;
      _personasMultiples = null;
      _error = null;
    });
  }

  String _formatFecha(String? fechaStr) {
    if (fechaStr == null) return 'Fecha no disponible';
    try {
      final fecha = DateTime.parse(fechaStr);
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    } catch (_) {
      return fechaStr;
    }
  }

  String _formatHora(String? fechaStr) {
    if (fechaStr == null) return '';
    try {
      final fecha = DateTime.parse(fechaStr);
      return '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Campo de búsqueda único ─────────────────────────────
        TextField(
          controller: _searchCtrl,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}), // refresca el label indicador
          onSubmitted: (_) => _buscar(), // Busca al presionar Enter
          decoration: InputDecoration(
            hintText: 'Buscar por nombre o cédula',
            hintStyle: const TextStyle(color: _secondaryTextColor),
            prefixIcon: const Icon(Icons.search, color: _secondaryTextColor),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: _secondaryTextColor),
                    onPressed: _limpiar,
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF0F2F4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: _primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
          ),
        ),

        // ── Indicador de tipo de búsqueda ───────────────────────
        if (_searchCtrl.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Row(
              children: [
                Icon(
                  _esCedula ? Icons.badge_outlined : Icons.person_outlined,
                  size: 14,
                  color: _primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _tipoBusquedaLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // ── Error ───────────────────────────────────────────────
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),

        // ── Múltiples coincidencias ─────────────────────────────
        if (_personasMultiples != null) ...[
          const SizedBox(height: 4),
          Text(
            'Varias coincidencias. Selecciona una:',
            style: const TextStyle(
              color: _secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ..._personasMultiples!.map((p) {
            final persona = p as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF0F2F4)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _primaryColor.withOpacity(0.1),
                  child: const Icon(Icons.person, color: _primaryColor),
                ),
                title: Text(
                  persona['nombre'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Cédula: ${persona['cedula'] ?? ''}'),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: _secondaryTextColor,
                ),
                onTap: () =>
                    _buscar(cedulaDirecta: persona['cedula'].toString()),
              ),
            );
          }),
        ],

        // ── Resultado ───────────────────────────────────────────
        if (_resultado != null) _buildResultado(),
      ],
    );
  }

  Widget _buildResultado() {
    final persona = _resultado!['persona'] as Map<String, dynamic>? ?? {};
    final movimientos = _resultado!['movimientos'] as List<dynamic>? ?? [];
    final resumen = _resultado!['resumen'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarjeta persona
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF0F2F4)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: _primaryColor.withOpacity(0.1),
                child: const Icon(Icons.person, color: _primaryColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      persona['nombre'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cédula: ${persona['cedula'] ?? ''}',
                      style: const TextStyle(color: _secondaryTextColor),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  persona['activo'] == true ? 'Activo' : 'Inactivo',
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor: persona['activo'] == true
                    ? Colors.green.shade100
                    : Colors.red.shade100,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Resumen entradas/salidas
        Row(
          children: [
            Expanded(
              child: _buildResumenChip(
                label: 'Entradas',
                count: resumen['entradas'] ?? 0,
                color: Colors.green,
                icon: Icons.login,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildResumenChip(
                label: 'Salidas',
                count: resumen['salidas'] ?? 0,
                color: Colors.orange,
                icon: Icons.logout,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Text(
          'Movimientos (${_resultado!['total_movimientos'] ?? 0})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111418),
          ),
        ),

        const SizedBox(height: 8),

        if (movimientos.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Sin movimientos registrados.',
                style: TextStyle(color: _secondaryTextColor),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: movimientos.length,
            itemBuilder: (context, index) {
              final m = movimientos[index] as Map<String, dynamic>;
              final isEntrada =
                  (m['tipo'] as String? ?? '').toLowerCase() == 'entrada';
              final fecha = _formatFecha(m['fecha_hora']);
              final hora = _formatHora(m['fecha_hora']);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF0F2F4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isEntrada
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isEntrada ? Icons.login : Icons.logout,
                          color: isEntrada ? Colors.green : Colors.orange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isEntrada
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isEntrada ? 'Entrada' : 'Salida',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isEntrada
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: _secondaryTextColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  fecha,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _secondaryTextColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: _secondaryTextColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  hora,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                            if (m['observacion'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  m['observacion'].toString(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _secondaryTextColor.withOpacity(0.8),
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildResumenChip({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: color, fontSize: 12)),
              Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}
