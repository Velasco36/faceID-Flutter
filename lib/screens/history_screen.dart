// history_screen.dart
import 'package:flutter/material.dart';
import 'navigation_footer.dart';
import '../services/api_service.dart';
import 'filters_widget.dart';
import 'detail_person.dart';
import 'search_filter.dart';

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
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return FiltersWidget(
          selectedFilter: _selectedFilter,
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
          onApplyFilters: (filter, inicio, fin) {
            setState(() {
              _selectedFilter = filter;
              _fechaInicio = inicio;
              _fechaFin = fin;
            });
            _aplicarFiltros();
          },
        );
      },
    );
  }

  void _aplicarFiltros() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filtro aplicado: $_selectedFilter'),
        duration: const Duration(seconds: 1),
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
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF111418),
          ), // Cambiado a arrow_back para mejor UX
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
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: SingleChildScrollView(
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

                    // 🔍 INPUT DE BÚSQUEDA INTEGRADO
                    const SearchFilter(),

                    const SizedBox(height: 16),

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
                            Icon(
                              Icons.filter_list,
                              size: 16,
                              color: primaryColor,
                            ),
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
                                _aplicarFiltros();
                              },
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: primaryColor,
                              ),
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
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.history,
                                size: 64,
                                color: Color(0xFF617589),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No hay movimientos registrados',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF617589),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      // History List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
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
                  ],
                ),
              ),
            ),
          ),

          // Navigation Footer - AHORA FUERA DEL PADDING Y EXPANDED
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

          const SizedBox(height: 8), // Pequeño espacio al final
        ],
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DetailPersonScreen(movimiento: movimiento),
              ),
            );
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
                        child: Icon(Icons.image, size: 14, color: primaryColor),
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
}

