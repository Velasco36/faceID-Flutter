// detail_person.dart
import 'package:flutter/material.dart';

class DetailPersonScreen extends StatelessWidget {
  final Map<String, dynamic> movimiento;

  const DetailPersonScreen({super.key, required this.movimiento});

  @override
  Widget build(BuildContext context) {
    final isEntrada = movimiento['tipo'] == 'entrada';
    final tieneImagen = movimiento['imagen_path'] != null;
    final confianza = movimiento['confianza_verificacion'];
    final primaryColor = const Color(0xFF137FEC);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111418)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detalle del Movimiento',
          style: TextStyle(
            color: Color(0xFF111418),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header con tipo de movimiento
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF0F2F4)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isEntrada
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEntrada ? Icons.login : Icons.logout,
                      color: isEntrada ? Colors.green : Colors.orange,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isEntrada
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isEntrada ? 'ENTRADA' : 'SALIDA',
                      style: TextStyle(
                        color: isEntrada ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Información de la persona
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF0F2F4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INFORMACIÓN DE LA PERSONA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF617589),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.badge,
                    label: 'Cédula',
                    value: movimiento['cedula'] ?? 'N/A',
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 24),
                  _buildInfoCard(
                    icon: Icons.person,
                    label: 'Nombre completo',
                    value: movimiento['nombre_persona'] ?? 'Desconocido',
                    primaryColor: primaryColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Detalles del movimiento
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF0F2F4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DETALLES DEL MOVIMIENTO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF617589),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.confirmation_number,
                    label: 'ID Movimiento',
                    value: '#${movimiento['id']}',
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 24),
                  _buildInfoCard(
                    icon: Icons.calendar_today,
                    label: 'Fecha',
                    value: _formatFecha(movimiento['fecha_hora']),
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 24),
                  _buildInfoCard(
                    icon: Icons.access_time,
                    label: 'Hora',
                    value: _formatHora(movimiento['fecha_hora']),
                    primaryColor: primaryColor,
                  ),
                  if (confianza != null) ...[
                    const Divider(height: 24),
                    _buildInfoCard(
                      icon: Icons.verified,
                      label: 'Confianza',
                      value: '${(confianza * 100).toStringAsFixed(1)}%',
                      primaryColor: primaryColor,
                      valueColor: confianza > 0.8
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ],
                  if (movimiento['observacion'] != null) ...[
                    const Divider(height: 24),
                    _buildInfoCard(
                      icon: Icons.note,
                      label: 'Observación',
                      value: movimiento['observacion'],
                      primaryColor: primaryColor,
                      isMultiline: true,
                    ),
                  ],
                ],
              ),
            ),

            if (tieneImagen) ...[
              const SizedBox(height: 16),
              // Imagen
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF0F2F4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'IMAGEN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF617589),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F7F8),
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(movimiento['imagen_path']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        movimiento['imagen_path'].split('/').last,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF617589),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color primaryColor,
    Color? valueColor,
    bool isMultiline = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF617589)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isMultiline ? 14 : 16,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? const Color(0xFF111418),
                ),
              ),
            ],
          ),
        ),
      ],
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
}
