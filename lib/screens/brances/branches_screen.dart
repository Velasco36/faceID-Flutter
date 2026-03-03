import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import './create_branch_screen.dart';
import './edit_branch_screen.dart';
import '../widgets/skeleton_loader.dart';

class SucursalesScreen extends StatefulWidget {
  const SucursalesScreen({super.key});

  @override
  State<SucursalesScreen> createState() => _SucursalesScreenState();
}

class _SucursalesScreenState extends State<SucursalesScreen> {
  static const Color _primary = Color(0xFF137FEC);

  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _sucursales = [];

  String? _rif;
  dynamic _empresa;
  int? _empresaId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && _sucursales.isEmpty) {
      _rif = args['rif'] as String?;
      _empresa = args['empresa'];
      _empresaId = args['empresaId'] as int?;
    }
    _cargarSucursales();
  }

  Future<void> _cargarSucursales() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final resultado = await _apiService.listarSucursales();
    if (!mounted) return;

    if (resultado['exito'] == true) {
      final data = resultado['data'];
      List<dynamic> lista = [];
      if (data is List) {
        lista = data;
      } else if (data is Map && data.containsKey('sucursales')) {
        lista = data['sucursales'] as List<dynamic>;
      }
      setState(() {
        _sucursales = lista.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = resultado['error'];
        _isLoading = false;
      });
    }
  }

  String _getNombreEmpresa() {
    if (_empresa == null) return 'Empresa';
    if (_empresa is Map) {
      return _empresa['nombre'] ??
          _empresa['name'] ??
          _empresa['razon_social'] ??
          'Empresa';
    }
    if (_empresa is String) return _empresa as String;
    return 'Empresa';
  }

  void _navegarAEditar(Map<String, dynamic> sucursal) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditBranchScreen(sucursal: sucursal)),
    ).then((actualizado) {
      if (actualizado == true) _cargarSucursales();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Header siempre visible ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.store,
                          color: _primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _sucursales.isNotEmpty
                                ? (_sucursales.first['empresa_nombre'] ??
                                      'Empresa')
                                : _getNombreEmpresa(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const Text(
                            'Sucursales',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Contenido ──
                Expanded(
                  child: _isLoading
                      // ✅ Skeleton sin padding lateral
                      ? const SkeletonLoader(itemCount: 6)
                      : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.wifi_off_rounded,
                                  size: 48,
                                  color: Color(0xFF9CA3AF),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: _cargarSucursales,
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: _primary,
                                  ),
                                  label: const Text(
                                    'Reintentar',
                                    style: TextStyle(color: _primary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _sucursales.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.storefront_outlined,
                                size: 56,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No hay sucursales disponibles',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                          itemCount: _sucursales.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final s = _sucursales[index];
                            final nombre =
                                s['nombre'] ?? s['name'] ?? 'Sin nombre';
                            final direccion =
                                s['direccion'] ??
                                s['address'] ??
                                'Sin dirección';
                            return _SucursalCard(
                              nombre: nombre,
                              direccion: direccion,
                              onTap: () => _navegarAEditar(s),
                            );
                          },
                        ),
                ),
              ],
            ),

            // ── FAB ──
            Positioned(
              bottom: 90,
              right: 24,
              child: FloatingActionButton(
                onPressed: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateBranchScreen(),
                      ),
                    ).then((creado) {
                      if (creado == true) _cargarSucursales();
                    }),
                backgroundColor: _primary,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card ────────────────────────────────────────────────────────────────────

class _SucursalCard extends StatelessWidget {
  final String nombre;
  final String direccion;
  final VoidCallback onTap;

  const _SucursalCard({
    required this.nombre,
    required this.direccion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF9FAFB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.storefront_outlined,
                color: Color(0xFF9CA3AF),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.store_outlined,
                        size: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          direccion,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF9CA3AF),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
