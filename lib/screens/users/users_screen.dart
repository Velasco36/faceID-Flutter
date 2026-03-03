// screens/users/users_screen.dart
import 'package:flutter/material.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  // Paleta de colores: azul con blanco
  static const Color _primaryBlue = Color(0xFF137FEC); // Azul principal
  static const Color _backgroundLight = Color(0xFFF8FAFC); // Blanco/gris muy claro
  static const Color _textDark = Color(0xFF1F2937); // Gris oscuro casi negro
  static const Color _textMedium = Color(0xFF4B5563); // Gris medio
  static const Color _textLight = Color(0xFF9CA3AF); // Gris claro
  static const Color _borderColor = Color(0xFFE5E7EB); // Gris para bordes
  static const Color _avatarBackground = Color(0xFFDBEAFD); // Azul muy claro para avatares

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Lista de usuarios de ejemplo
  final List<Map<String, dynamic>> _usuarios = [
    {
      'nombre': 'Juan Pérez',
      'cedula': '1.234.567-8',
      'iniciales': 'JP',
      'imagen': null,
    },
    {
      'nombre': 'María García',
      'cedula': '2.345.678-9',
      'iniciales': 'MG',
      'imagen': 'https://lh3.googleusercontent.com/aida-public/AB6AXuB7c3StKWmpOjoL09odIJvTvOssiW1jRInEtuEtuSNlZsOxZ789b1T-ZjmMXyRAa1wfE6K_mfx8MMcWrHmIElnNz-kipKF_8SVVW5a-kaMpqwoHsIzNug_LO4thU_Migr0a-M-pHqNEuP1HEzPnNlFXXMjyRTTYzff7qMKQ8OpMQ85BbPyLNwr49FlG_V8NQplaOYnQpmwqYzEHfWihATLQXTf-LIDkkAeG6-Ck0wZrr12EqHjdimtxNklSmAhH6qO4cNrb48VILLU',
    },
    {
      'nombre': 'Carlos Rodríguez',
      'cedula': '3.456.789-0',
      'iniciales': 'CR',
      'imagen': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCVB-aSfRrnxmj1rAhpjdKmk_5GUrtHpK-b8WhDEsTgFwVfuXKAVj0ggkta1GFre856d1_0O1TCQfQxKWrKGJMtIVLi3uWf7e_TJQPGl6_87a2P-jrx2LFOgr_wZg992U0rTqDuqphltMRlTWwtsSQKkPBuW596vRx9xTDq4aqs5i2JXrpClRyCoWn3V6tkqIhElMY2hYXqaoGvqvTy7OG2aBkqUy5dyOUNzqBeEyj_Oq4TvY3si3IEnLvmr82eCc2NbedXw0T4410',
    },
    {
      'nombre': 'Ana Villalba',
      'cedula': '4.567.890-1',
      'iniciales': 'AV',
      'imagen': null,
    },
    {
      'nombre': 'Diego Martínez',
      'cedula': '5.678.901-2',
      'iniciales': 'DM',
      'imagen': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDWN4ms5DzgrXJl31qX80dVeWDy4XzGhxGoqNmWm8wxqy_yMVxplN0Y31A4cXocqtamwDa0zhfD304C8SLnSH8F8MTxv78p47YEpuqhOfqZY57Zi2wD4zJoj0ziTrC-lRqtgJJeNxdum5KDlzkY7CrIdXShk10YvJW64DaDv2OqAUFUvn0tcHeNoTAUV28p-_B0O6BlyjY-Hg6t9VSoimpQ5MBbEHKM6d2P3I2AH_-wsLOTCPLRwjzaaNZ3m2aRbIG9IsEqRLTp0Kw',
    },
    {
      'nombre': 'Elena Suárez',
      'cedula': '6.789.012-3',
      'iniciales': 'ES',
      'imagen': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAPueWrJMA2t4VebvDp7-_VwYzzTV85eDBiWXznyGL_F-yvFOWxV877qNqg3kmamh7ahZfAtK-wSaPTGIOl65xBKcRDhjxpsmSCLGlcq9RvNdRUJJ0CxY-rBHYOyflqm65YkXm4faq3fodVyNXc1qbMNslDLtlVB6k4oHMms_pK2SoxqV6xGSXuYFHRKQr8mSynPS0MTQ1ggExoWt6om9HrshPHVUUTX6Q_IGvP0mnN1m5XIscUkoKOtEPbNWLtwVIXC5NAP3HYqwg',
    },
  ];

  List<Map<String, dynamic>> get _usuariosFiltrados {
    if (_searchQuery.isEmpty) return _usuarios;
    return _usuarios.where((usuario) {
      final nombre = usuario['nombre'].toLowerCase();
      final cedula = usuario['cedula'].toLowerCase();
      final query = _searchQuery.toLowerCase();
      return nombre.contains(query) || cedula.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateBack() {
    Navigator.pop(context);
  }

  void _navigateToCreateUser() {
    // TODO: Navegar a pantalla de crear usuario
    print('Navegar a crear usuario');
  }

  void _navigateToUserDetail(Map<String, dynamic> usuario) {
    // TODO: Navegar a detalle del usuario
    print('Ver detalle de: ${usuario['nombre']}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header fijo
                _buildHeader(),

                // Search Bar
                _buildSearchBar(),

                // Lista de usuarios
                Expanded(
                  child: _usuariosFiltrados.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _usuariosFiltrados.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 0,
                            color: _borderColor,
                          ),
                          itemBuilder: (context, index) {
                            final usuario = _usuariosFiltrados[index];
                            return _UserItem(
                              usuario: usuario,
                              onTap: () => _navigateToUserDetail(usuario),
                              primaryBlue: _primaryBlue,
                              avatarBackground: _avatarBackground,
                              textDark: _textDark,
                              textLight: _textLight,
                            );
                          },
                        ),
                ),

                // Espaciador inferior para el FAB
                const SizedBox(height: 80),
              ],
            ),

            // FAB - Floating Action Button
            Positioned(
              bottom: 90,
              right: 24,
              child: FloatingActionButton(
                onPressed: _navigateToCreateUser,
                backgroundColor: _primaryBlue,
                shape: const CircleBorder(),
                elevation: 8,
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
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
        border: Border(
          bottom: BorderSide(
            color: _borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Botón de retroceso
          GestureDetector(
            onTap: _navigateBack,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_back,
                color: _textDark,
                size: 24,
              ),
            ),
          ),

          // Título
          Expanded(
            child: Center(
              child: Text(
                'Usuarios',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),

          // Botón de agregar (en el header)
          GestureDetector(
            onTap: _navigateToCreateUser,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: Icon(
                Icons.person_add,
                color: _primaryBlue,
                size: 24,
              ),
            ),
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
          // Campo de búsqueda
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _borderColor,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar usuarios',
                  hintStyle: TextStyle(
                    color: _textLight,
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: _textLight,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Botón de filtros
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _borderColor,
              ),
            ),
            child: IconButton(
              onPressed: () {
                // TODO: Abrir filtros
              },
              icon: Icon(
                Icons.tune,
                color: _textLight,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: _textLight,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No hay usuarios registrados'
                : 'No se encontraron usuarios',
            style: TextStyle(
              fontSize: 16,
              color: _textMedium,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: _primaryBlue,
              ),
              child: const Text('Limpiar búsqueda'),
            ),
          ],
        ],
      ),
    );
  }
}

// Widget para cada ítem de usuario
class _UserItem extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final VoidCallback onTap;
  final Color primaryBlue;
  final Color avatarBackground;
  final Color textDark;
  final Color textLight;

  const _UserItem({
    required this.usuario,
    required this.onTap,
    required this.primaryBlue,
    required this.avatarBackground,
    required this.textDark,
    required this.textLight,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(),

              const SizedBox(width: 16),

              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario['nombre'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'C.I. ${usuario['cedula']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: textLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Icono de chevron
              Icon(
                Icons.chevron_right,
                color: textLight,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final tieneImagen = usuario['imagen'] != null;

    if (tieneImagen) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: avatarBackground,
            width: 2,
          ),
          image: DecorationImage(
            image: NetworkImage(usuario['imagen']),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: avatarBackground,
          border: Border.all(
            color: primaryBlue.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            usuario['iniciales'],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
        ),
      );
    }
  }
}
