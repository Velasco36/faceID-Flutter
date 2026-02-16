// history_screen.dart
import 'package:flutter/material.dart';
import 'navigation_footer.dart';
import '../services/api_service.dart';
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _movimientos = [];
  Map<String, dynamic>? _paginacion;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _selectedFilter = 'Todos';
  final TextEditingController _searchController = TextEditingController();

  // Filtros de fecha
  String? _fechaInicio;
  String? _fechaFin;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final result = await _apiService.obtenerEstadisticas();

      if (result['exito']) {
        setState(() {
          _movimientos = result['data']['movimientos'] ?? [];
          _paginacion = result['data']['paginacion'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = result['error'] ?? 'Error al cargar datos';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }


  void _showFilterDialog() {
    String tempFilter = _selectedFilter;
    DateTime? tempFechaInicio;
    DateTime? tempFechaFin;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtrar movimientos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Filtro por tipo
                  const Text(
                    'Tipo de movimiento',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF617589),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChipModal(
                        'Todos',
                        tempFilter == 'Todos',
                        (selected) {
                          setModalState(() => tempFilter = 'Todos');
                        },
                      ),
                      _buildFilterChipModal(
                        'Entradas',
                        tempFilter == 'Entradas',
                        (selected) {
                          setModalState(() => tempFilter = 'Entradas');
                        },
                      ),
                      _buildFilterChipModal(
                        'Salidas',
                        tempFilter == 'Salidas',
                        (selected) {
                          setModalState(() => tempFilter = 'Salidas');
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Filtro por fecha
                  const Text(
                    'Rango de fechas',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF617589),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('Fecha inicio'),
                    subtitle: Text(
                      tempFechaInicio != null
                          ? '${tempFechaInicio!.day}/${tempFechaInicio!.month}/${tempFechaInicio!.year}'
                          : 'Seleccionar',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: tempFechaInicio ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setModalState(() => tempFechaInicio = date);
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('Fecha fin'),
                    subtitle: Text(
                      tempFechaFin != null
                          ? '${tempFechaFin!.day}/${tempFechaFin!.month}/${tempFechaFin!.year}'
                          : 'Seleccionar',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: tempFechaFin ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setModalState(() => tempFechaFin = date);
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempFilter = 'Todos';
                              tempFechaInicio = null;
                              tempFechaFin = null;
                            });
                          },
                          child: const Text('Limpiar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              _selectedFilter = tempFilter;
                              _fechaInicio = tempFechaInicio != null
                                  ? '${tempFechaInicio!.year}-${tempFechaInicio!.month.toString().padLeft(2, '0')}-${tempFechaInicio!.day.toString().padLeft(2, '0')}'
                                  : null;
                              _fechaFin = tempFechaFin != null
                                  ? '${tempFechaFin!.year}-${tempFechaFin!.month.toString().padLeft(2, '0')}-${tempFechaFin!.day.toString().padLeft(2, '0')}'
                                  : null;
                            });

                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF137FEC),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChipModal(
    String label,
    bool isSelected,
    Function(bool) onSelected,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF137FEC).withOpacity(0.1),
      checkmarkColor: const Color(0xFF137FEC),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF137FEC) : const Color(0xFF617589),
        fontSize: 12,
      ),
    );
  }

  String _formatFecha(String? fechaStr) {
    if (fechaStr == null) return 'Fecha no disponible';
    try {
      final fecha = DateTime.parse(fechaStr);
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    } catch (e) {
      return fechaStr;
    }
  }

  String _formatHora(String? fechaStr) {
    if (fechaStr == null) return '';
    try {
      final fecha = DateTime.parse(fechaStr);
      return '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF137FEC);
    final backgroundColor = const Color(0xFFF6F7F8);
    final secondaryTextColor = const Color(0xFF617589);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111418)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Historial de Movimientos',
          style: TextStyle(
            color: Color(0xFF111418),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF111418)),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF111418)),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Resumen
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF0F2F4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total de movimientos',
                          style: TextStyle(
                            color: Color(0xFF617589),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_paginacion?['total'] ?? 0}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.history,
                        color: primaryColor,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Filtro activo
              if (_selectedFilter != 'Todos' || _fechaInicio != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_list, size: 16, color: primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Filtro activo: $_selectedFilter',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = 'Todos';
                            _fechaInicio = null;
                            _fechaFin = null;
                          });

                        },
                        child: Icon(Icons.close, size: 16, color: primaryColor),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // Loading indicator
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_hasError)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: secondaryTextColor),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _cargarDatos,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                          ),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_movimientos.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: secondaryTextColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay movimientos registrados',
                          style: TextStyle(
                            fontSize: 16,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // History List
                Expanded(
                  child: ListView.builder(
                    itemCount: _movimientos.length,
                    itemBuilder: (context, index) {
                      final movimiento = _movimientos[index];
                      return _buildHistoryItem(
                        movimiento: movimiento,
                        primaryColor: primaryColor,
                        secondaryTextColor: secondaryTextColor,
                      );
                    },
                  ),
                ),

              const SizedBox(height: 16),

              // Paginación info
              if (_paginacion != null && _movimientos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Página ${_paginacion!['pagina_actual']} de ${_paginacion!['paginas']}',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ),

              // Navigation Footer
              NavigationFooter(
                currentIndex: 1,
                onItemTapped: (index) {
                  if (index == 0) {
                    Navigator.pop(context);
                  }
                },
                primaryColor: primaryColor,
                secondaryTextColor: secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem({
    required Map<String, dynamic> movimiento,
    required Color primaryColor,
    required Color secondaryTextColor,
  }) {
    final isEntrada = movimiento['tipo'] == 'entrada';
    final nombre = movimiento['nombre_persona'] ?? 'Desconocido';
    final cedula = movimiento['cedula'] ?? 'N/A';
    final fecha = _formatFecha(movimiento['fecha_hora']);
    final hora = _formatHora(movimiento['fecha_hora']);
    final tieneImagen = movimiento['imagen_path'] != null;
    final observacion = movimiento['observacion'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F2F4)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showDetailDialog(context, movimiento);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar/Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isEntrada
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isEntrada ? Icons.login : Icons.logout,
                    color: isEntrada ? Colors.green : Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111418),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cédula: $cedula',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: secondaryTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            fecha,
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: secondaryTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hora,
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      if (observacion != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            observacion,
                            style: TextStyle(
                              fontSize: 11,
                              color: secondaryTextColor.withOpacity(0.8),
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

                // Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
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
                          fontSize: 10,
                          color: isEntrada ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (tieneImagen)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Icon(
                          Icons.image,
                          size: 14,
                          color: primaryColor,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right,
                      color: secondaryTextColor,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(
    BuildContext context,
    Map<String, dynamic> movimiento,
  ) {
    final isEntrada = movimiento['tipo'] == 'entrada';
    final tieneImagen = movimiento['imagen_path'] != null;
    final confianza = movimiento['confianza_verificacion'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Detalle del movimiento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('ID', '${movimiento['id']}'),
                const SizedBox(height: 8),
                _buildDetailRow('Persona', movimiento['nombre_persona'] ?? 'Desconocido'),
                const SizedBox(height: 8),
                _buildDetailRow('Cédula', movimiento['cedula'] ?? 'N/A'),
                const SizedBox(height: 8),
                _buildDetailRow('Tipo', isEntrada ? 'Entrada' : 'Salida'),
                const SizedBox(height: 8),
                _buildDetailRow('Fecha', _formatFecha(movimiento['fecha_hora'])),
                const SizedBox(height: 8),
                _buildDetailRow('Hora', _formatHora(movimiento['fecha_hora'])),
                if (confianza != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow('Confianza', confianza.toString()),
                ],
                if (movimiento['observacion'] != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow('Observación', movimiento['observacion']),
                ],
                if (tieneImagen) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Imagen:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111418),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          movimiento['imagen_path'],
                          style: const TextStyle(
                            color: Color(0xFF617589),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF137FEC),
              ),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF111418),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF617589)),
          ),
        ),
      ],
    );
  }
}
