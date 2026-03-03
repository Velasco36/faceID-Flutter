// screens/users/users_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import './../widgets/skeleton_loader.dart';
import './create_user_modal.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  static const Color _primaryBlue     = Color(0xFF137FEC);
  static const Color _backgroundLight = Color(0xFFF8FAFC);
  static const Color _textDark        = Color(0xFF1F2937);
  static const Color _textMedium      = Color(0xFF4B5563);
  static const Color _textLight       = Color(0xFF9CA3AF);
  static const Color _borderColor     = Color(0xFFE5E7EB);

  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  String  _searchQuery  = '';
  bool    _isLoading    = false;
  String? _errorMessage;
  String? _filtroRol;

  List<Map<String, dynamic>> _usuarios = [];

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() { _isLoading = true; _errorMessage = null; });

    final resultado = await _apiService.getAllUsers();
    if (!mounted) return;

    if (resultado['exito'] == true) {
      final data = resultado['data'];
      List<dynamic> lista = [];
      if (data is Map && data.containsKey('usuarios')) {
        lista = data['usuarios'] as List<dynamic>;
      }

      final usuariosMapeados = lista.map((user) {
        final userMap = Map<String, dynamic>.from(user as Map);
        String username  = (userMap['username'] ?? 'Usuario').toString();
        String iniciales = username.length >= 2
            ? username.substring(0, 2).toUpperCase()
            : username.substring(0, 1).toUpperCase();
        String rol        = (userMap['rol'] ?? 'user').toString();
        String rolMostrar = rol == 'admin_empresa' ? 'Admin' : 'Usuario';
        String fechaFormateada = '';
        if (userMap['fecha_creacion'] != null) {
          try { fechaFormateada = userMap['fecha_creacion'].toString().split('T')[0]; } catch (_) {}
        }
        return {
          'id'             : userMap['id'],
          'username'       : username,
          'iniciales'      : iniciales,
          'rol'            : rol,
          'rol_mostrar'    : rolMostrar,
          'activo'         : userMap['activo'] ?? true,
          'empresa_id'     : userMap['empresa_id'],
          'empresa_nombre' : (userMap['empresa_nombre'] ?? '').toString(),
          'sucursal_id'    : userMap['sucursal_id'],
          'sucursal_nombre': (userMap['sucursal_nombre'] ?? '').toString(),
          'fecha_creacion' : userMap['fecha_creacion'],
          'fecha_formateada': fechaFormateada,
        };
      }).toList();

      setState(() { _usuarios = usuariosMapeados; _isLoading = false; });
    } else {
      setState(() {
        _errorMessage = resultado['error']?.toString() ?? 'Error desconocido';
        _isLoading    = false;
      });
      if (resultado['error'] == 'Sesión expirada.') _mostrarDialogoSesionExpirada();
    }
  }

  void _mostrarDialogoSesionExpirada() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Sesión expirada'),
        content: const Text('Tu sesión ha expirado. Por favor, inicia sesión nuevamente.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            style: TextButton.styleFrom(foregroundColor: _primaryBlue),
            child: const Text('Ir a login'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _usuariosFiltrados {
    List<Map<String, dynamic>> lista = _usuarios;
    if (_filtroRol != null) lista = lista.where((u) => u['rol'] == _filtroRol).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      lista = lista.where((u) {
        final username = (u['username'] ?? '').toString().toLowerCase();
        final rol      = (u['rol_mostrar'] ?? '').toString().toLowerCase();
        final sucursal = (u['sucursal_nombre'] ?? '').toString().toLowerCase();
        return username.contains(q) || rol.contains(q) || sucursal.contains(q);
      }).toList();
    }
    return lista;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateBack() => Navigator.pop(context);

void _navigateToCreateUser() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateUserScreen()),
    ).then((creado) {
      if (creado == true) _cargarUsuarios();
    });
  }

  void _navigateToUserDetail(Map<String, dynamic> usuario) {
    Navigator.pushNamed(context, '/users/detail', arguments: usuario).then((actualizado) {
      if (actualizado == true) _cargarUsuarios();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuariosFiltrados = _usuariosFiltrados;

    return Scaffold(
      backgroundColor: _backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                Expanded(
                  child: _isLoading
                      // ✅ Skeleton con shimmer mientras carga
                      ? const SkeletonLoader(itemCount: 6)
                      : _errorMessage != null
                          ? _buildErrorState()
                          : usuariosFiltrados.isEmpty
                              ? _buildEmptyState()
                              : RefreshIndicator(
                                  onRefresh: _cargarUsuarios,
                                  color: _primaryBlue,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                                    itemCount: usuariosFiltrados.length,
                                    itemBuilder: (context, index) {
                                      final usuario = usuariosFiltrados[index];
                                      // ✅ UserCard en lugar de _UserItem
                                      return UserCard(
                                        usuario: usuario,
                                        primaryBlue: _primaryBlue,
                                        onTap: () => _navigateToUserDetail(usuario),
                                      );
                                    },
                                  ),
                                ),
                ),
              ],
            ),
            Positioned(
              bottom: 90,
              right: 24,
              child: FloatingActionButton(
                onPressed: _navigateToCreateUser,
                backgroundColor: _primaryBlue,
                shape: const CircleBorder(),
                elevation: 8,
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: _textMedium)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarUsuarios,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty && _filtroRol == null ? Icons.people_outline : Icons.search_off,
              size: 64, color: _textLight,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty && _filtroRol == null
                  ? 'No hay usuarios registrados'
                  : 'No se encontraron usuarios',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: _textMedium),
            ),
            const SizedBox(height: 16),
            if (_searchQuery.isEmpty && _filtroRol == null)
              ElevatedButton.icon(
                onPressed: _navigateToCreateUser,
                icon: const Icon(Icons.add),
                label: const Text('Agregar usuario'),
                style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, foregroundColor: Colors.white),
              )
            else
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() { _searchQuery = ''; _filtroRol = null; });
                },
                style: TextButton.styleFrom(foregroundColor: _primaryBlue),
                child: const Text('Limpiar filtros'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _navigateBack,
            child: Container(width: 40, height: 40, alignment: Alignment.center,
                child: Icon(Icons.arrow_back, color: _textDark, size: 24)),
          ),
          Expanded(
            child: Center(
              child: Text('Usuarios',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
            ),
          ),
          GestureDetector(
            onTap: _navigateToCreateUser,
            child: Container(width: 40, height: 40, alignment: Alignment.center,
                child: Icon(Icons.person_add, color: _primaryBlue, size: 24)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Buscar por usuario, rol o sucursal',
                  hintStyle: TextStyle(color: _textLight, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: _textLight, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _filtroRol != null ? _primaryBlue.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _filtroRol != null ? _primaryBlue : _borderColor),
            ),
            child: IconButton(
              onPressed: _mostrarOpcionesFiltro,
              icon: Icon(Icons.tune,
                  color: _filtroRol != null ? _primaryBlue : _textLight, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarOpcionesFiltro() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filtrar por rol',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _filtroTile(icon: Icons.people,              label: 'Todos',            activeColor: _primaryBlue,    isActive: _filtroRol == null,           onTap: () { setState(() => _filtroRol = null);            Navigator.pop(context); }),
              _filtroTile(icon: Icons.admin_panel_settings, label: 'Administradores',  activeColor: Colors.purple,   isActive: _filtroRol == 'admin_empresa', onTap: () { setState(() => _filtroRol = 'admin_empresa'); Navigator.pop(context); }),
              _filtroTile(icon: Icons.person_outline,      label: 'Usuarios',         activeColor: Colors.green,    isActive: _filtroRol == 'user',          onTap: () { setState(() => _filtroRol = 'user');          Navigator.pop(context); }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filtroTile({
    required IconData icon,
    required String label,
    required Color activeColor,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isActive ? activeColor : _textLight),
      title: Text(label),
      trailing: isActive ? Icon(Icons.check, color: activeColor) : null,
      onTap: onTap,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  UserCard  —  componente reutilizable
//  Importar en otras pantallas:
//    import '../../screens/users/users_screen.dart';
//  O mover a widgets/user_card.dart y actualizar el import.
// ═══════════════════════════════════════════════════════════════

class UserCard extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final VoidCallback onTap;
  final Color primaryBlue;

  static const Color _border     = Color(0xFFE5E7EB);
  static const Color _adminColor = Color(0xFF7C3AED);
  static const Color _textDark   = Color(0xFF0F172A);
  static const Color _textLight  = Color(0xFF94A3B8);
  static const Color _textMedium = Color(0xFF64748B);

  const UserCard({
    super.key,
    required this.usuario,
    required this.onTap,
    required this.primaryBlue,
  });

  Color get _rolColor =>
      (usuario['rol'] ?? '') == 'admin_empresa' ? _adminColor : primaryBlue;

  @override
  Widget build(BuildContext context) {
    final String username        = (usuario['username']         ?? 'Usuario').toString();
    final String iniciales       = (usuario['iniciales']        ?? 'U').toString();
    final String rolMostrar      = (usuario['rol_mostrar']      ?? 'Usuario').toString();
    final String sucursalNombre  = (usuario['sucursal_nombre']  ?? 'Sin sucursal').toString();
    final String fechaFormateada = (usuario['fecha_formateada'] ?? '').toString();
    final bool   activo          = (usuario['activo'] ?? true) as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [

                // ── Avatar con iniciales + dot activo ────────
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _rolColor.withOpacity(0.10),
                        border: Border.all(color: _rolColor.withOpacity(0.30), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          iniciales,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _rolColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: activo ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // ── Nombre + rol badge + sucursal + fecha ────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              username,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _textDark,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _rolColor.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              rolMostrar,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _rolColor,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.store_rounded, size: 11, color: _textLight),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              sucursalNombre,
                              style: const TextStyle(fontSize: 12, color: _textMedium),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (fechaFormateada.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 11, color: _textLight),
                            const SizedBox(width: 4),
                            Text(
                              fechaFormateada,
                              style: const TextStyle(fontSize: 11, color: _textLight),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const Icon(Icons.chevron_right, color: _textLight, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
