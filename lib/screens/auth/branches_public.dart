import 'package:flutter/material.dart';
import 'dart:convert';

class Branch {
  final String name;
  final String address;
  final IconData icon;
  final Map<String, dynamic> rawData;

  const Branch({
    required this.name,
    required this.address,
    required this.icon,
    required this.rawData,
  });
}

class SucursalesPublicScreen extends StatefulWidget {
  const SucursalesPublicScreen({super.key});

  @override
  State<SucursalesPublicScreen> createState() => _SucursalesPublicScreenState();
}

class _SucursalesPublicScreenState extends State<SucursalesPublicScreen> {
  static const Color _primary = Color(0xFF137FEC);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Datos recibidos de la pantalla anterior
  String? _rif;
  dynamic _empresa;
  int? _empresaId;
  List<dynamic>? _sucursalesData;

  // Lista de sucursales procesada
  List<Branch> _branches = [];

  // Índice de la sucursal seleccionada
  int? _selectedIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Recibir argumentos
    final args = ModalRoute.of(context)?.settings.arguments as Map?;

    if (args != null) {
      _rif = args['rif'] as String?;
      _empresa = args['empresa'];
      _sucursalesData = args['sucursales'] as List<dynamic>?;
      _empresaId = args['empresaId'] as int?;

      print('📥 SucursalesPublicScreen - Datos recibidos:');
      print('RIF: $_rif');
      print('Empresa: $_empresa');
      print('Tipo de empresa: ${_empresa.runtimeType}');
      print('Sucursales: $_sucursalesData');

      // Procesar las sucursales
      _procesarSucursales();
    }
  }

  String _getNombreEmpresa() {
    if (_empresa == null) return 'Corporación Global';

    if (_empresa is Map) {
      return _empresa['nombre'] ??
          _empresa['name'] ??
          _empresa['razon_social'] ??
          'Corporación Global';
    }

    if (_empresa is String) {
      return _empresa;
    }

    return 'Corporación Global';
  }

  void _procesarSucursales() {
    if (_sucursalesData == null) return;

    setState(() {
      _branches = _sucursalesData!.map((sucursal) {
        final nombre =
            sucursal['nombre'] ??
            sucursal['name'] ??
            sucursal['descripcion'] ??
            'Sucursal sin nombre';

        final direccion =
            sucursal['direccion'] ??
            sucursal['address'] ??
            sucursal['ubicacion'] ??
            'Dirección no disponible';

        IconData icono;
        if (nombre.toLowerCase().contains('principal') ||
            nombre.toLowerCase().contains('central')) {
          icono = Icons.location_on_outlined;
        } else if (nombre.toLowerCase().contains('norte')) {
          icono = Icons.north_outlined;
        } else if (nombre.toLowerCase().contains('sur')) {
          icono = Icons.south_outlined;
        } else if (nombre.toLowerCase().contains('este')) {
          icono = Icons.east_outlined;
        } else if (nombre.toLowerCase().contains('oeste')) {
          icono = Icons.west_outlined;
        } else {
          icono = Icons.storefront_outlined;
        }

        return Branch(
          name: nombre,
          address: direccion,
          icon: icono,
          rawData: sucursal as Map<String, dynamic>,
        );
      }).toList();

      print('✅ Sucursales procesadas: ${_branches.length}');
      for (var i = 0; i < _branches.length; i++) {
        print(
          'Sucursal ${i + 1}: ${_branches[i].name} - ${_branches[i].address}',
        );
      }
    });
  }

  void _seleccionarSucursal(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Pequeña pausa para que se vea la selección (opcional)
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _navegarALogin(_branches[index]);
      }
    });
  }

  void _navegarALogin(Branch sucursalSeleccionada) {
    print('📦 Datos completos: ${sucursalSeleccionada.rawData}');

    // Crear una lista con la sucursal seleccionada
    List<Map<String, dynamic>> sucursalesList = [sucursalSeleccionada.rawData];

    Navigator.pushNamed(
      context,
      '/login',
      arguments: {
        'rif': _rif,
        'empresa': _empresa,
        'empresaId': _empresaId,
        'sucursales': sucursalesList, // 👈 Enviamos como lista
        'sucursalSeleccionada':
            sucursalSeleccionada.rawData, // 👈 Y también la seleccionada
      },
    );
  }

  List<Branch> get _filteredBranches {
    if (_searchQuery.isEmpty) return _branches;
    return _branches
        .where(
          (b) =>
              b.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              b.address.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBranches;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 448),
          margin: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width > 448
                ? (MediaQuery.of(context).size.width - 448) / 2
                : 0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Header ──
              _buildHeader(),

              // ── Content ──
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Title row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sucursales disponibles',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${filtered.length} ${filtered.length == 1 ? 'sucursal' : 'sucursales'}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Branch cards
                    if (_branches.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.storefront_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay sucursales disponibles',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filtered.asMap().entries.map((entry) {
                        final originalIndex = _branches.indexOf(entry.value);
                        final isSelected = _selectedIndex == originalIndex;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _BranchCard(
                            branch: entry.value,
                            isSelected: isSelected,
                            onTap: () => _seleccionarSucursal(originalIndex),
                          ),
                        );
                      }),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back),
                  color: const Color(0xFF0F172A),
                  style: IconButton.styleFrom(shape: const CircleBorder()),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _getNombreEmpresa(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (_rif != null)
                        Text(
                          'RIF: $_rif',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar sucursal por nombre o dirección...',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF137FEC),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  static const Color _primary = Color(0xFF137FEC);

  final Branch branch;
  final bool isSelected;
  final VoidCallback onTap;

  const _BranchCard({
    required this.branch,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? _primary.withOpacity(0.12)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                branch.icon,
                color: isSelected ? _primary : const Color(0xFF64748B),
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branch.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    branch.address,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Check indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _primary : Colors.grey.shade300,
              ),
              child: Icon(
                Icons.check,
                size: 16,
                color: isSelected ? Colors.white : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
