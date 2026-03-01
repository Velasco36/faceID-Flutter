// screens/branch/edit_branch_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class EditBranchScreen extends StatefulWidget {
  final Map<String, dynamic> sucursal;

  const EditBranchScreen({
    super.key,
    required this.sucursal,
  });

  @override
  State<EditBranchScreen> createState() => _EditBranchScreenState();
}

class _EditBranchScreenState extends State<EditBranchScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF137FEC);

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();

  bool _isLoading = false;
  bool _isDeleting = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();

    // Inicializar controladores con datos existentes
    _nombreController.text = widget.sucursal['nombre'] ?? widget.sucursal['name'] ?? '';
    _direccionController.text = widget.sucursal['direccion'] ?? widget.sucursal['address'] ?? '';

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nombreController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  // ── API Methods ───────────────────────────────────────────────────────────

  Future<void> _actualizar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nombre = _nombreController.text.trim();
      final direccion = _direccionController.text.trim();
      final sucursalId = widget.sucursal['id'] ?? widget.sucursal['sucursal_id'];

      if (sucursalId == null) {
        throw Exception('ID de sucursal no encontrado');
      }

      // TODO: Implementar método en ApiService
      // final resultado = await _apiService.actualizarSucursal(sucursalId, nombre, direccion);

      // Simulación mientras se implementa el método
      await Future.delayed(const Duration(seconds: 1));
      final Map<String, dynamic> resultado = {'exito': true};

      if (!mounted) return;

      if (resultado['exito'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sucursal actualizada exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        final errorMsg = resultado['error']?.toString() ?? 'Error al actualizar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ── Modal de confirmación para eliminar ───────────────────────────────────

  Future<void> _mostrarModalEliminar() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.transparent,
      builder: (context) => _DeleteConfirmationModal(
        nombreSucursal: _nombreController.text,
        onConfirm: () {
          Navigator.pop(context); // Cerrar el modal
          _eliminar(); // Ejecutar la eliminación
        },
      ),
    );
  }

  Future<void> _eliminar() async {
    setState(() => _isDeleting = true);

    try {
      final sucursalId = widget.sucursal['id'] ?? widget.sucursal['sucursal_id'];

      if (sucursalId == null) {
        throw Exception('ID de sucursal no encontrado');
      }

      // TODO: Implementar método en ApiService
      // final resultado = await _apiService.eliminarSucursal(sucursalId);

      // Simulación mientras se implementa el método
      await Future.delayed(const Duration(seconds: 1));
      final Map<String, dynamic> resultado = {'exito': true};

      if (!mounted) return;

      if (resultado['exito'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sucursal eliminada exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        final errorMsg = resultado['error']?.toString() ?? 'Error al eliminar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ilustración / ícono decorativo
                              Center(
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDBEAFD),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Icon(
                                    Icons.storefront_outlined,
                                    color: _primary,
                                    size: 40,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              Center(
                                child: Column(
                                  children: const [
                                    Text(
                                      'Editar Sucursal',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Actualiza los datos de la sucursal',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF9CA3AF),
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 36),

                              // ── Campo: Nombre ──
                              _FloatingInput(
                                controller: _nombreController,
                                label: 'Nombre de la sucursal',
                                hint: 'Ej. Sucursal Norte',
                                icon: Icons.store_outlined,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'El nombre es requerido';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // ── Campo: Dirección ──
                              _FloatingInput(
                                controller: _direccionController,
                                label: 'Dirección',
                                hint: 'Ej. Av. Principal, Caracas',
                                icon: Icons.location_on_outlined,
                                maxLines: 1,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'La dirección es requerida';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 40),

                              // ── Botón Actualizar ──
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: FilledButton(
                                  onPressed: (_isLoading || _isDeleting) ? null : _actualizar,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _primary,
                                    disabledBackgroundColor: _primary.withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'Actualizar Sucursal',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // ── Botón Cancelar ──
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: TextButton(
                                  onPressed: (_isLoading || _isDeleting)
                                    ? null
                                    : () => Navigator.pop(context, false),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF6B7280),
                                    disabledBackgroundColor: Colors.white.withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ── Botón Eliminar (estilo como cancelar pero rojo) ──
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: TextButton(
                                  onPressed: (_isLoading || _isDeleting)
                                    ? null
                                    : _mostrarModalEliminar,
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF6B7280),
                                    disabledBackgroundColor: Colors.white.withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: const BorderSide(
                                         color: Color(0xFFE5E7EB),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  child: _isDeleting
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.red,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'Eliminar Sucursal',
                                          style: TextStyle(
                                            fontSize: 16,
                                             color: Colors.red,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Overlay de carga cuando se está eliminando
            if (_isDeleting)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: _primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: (_isLoading || _isDeleting)
              ? null
              : () => Navigator.pop(context, false),
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
            style: IconButton.styleFrom(shape: const CircleBorder()),
          ),
          const SizedBox(width: 4),
          const Text(
            'Editar Sucursal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Modal de Confirmación para Eliminar ───────────────────────────────────

class _DeleteConfirmationModal extends StatelessWidget {
  final String nombreSucursal;
  final VoidCallback onConfirm;

  const _DeleteConfirmationModal({
    required this.nombreSucursal,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador deslizable
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Ícono rectangular con bordes redondeados
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: Colors.red,
              size: 36,
            ),
          ),

          const SizedBox(height: 20),

          // Título
          const Text(
            'Eliminar Sucursal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),

          const SizedBox(height: 8),

          // Mensaje
          Text(
            '¿Estás seguro de eliminar "$nombreSucursal"?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Botones
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6B7280),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(
                        color: Color(0xFFE5E7EB),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Eliminar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Floating Label Input ─────────────────────────────────────────────────────

class _FloatingInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;

  const _FloatingInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
        labelStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF137FEC),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF137FEC), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
