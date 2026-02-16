// filters_widget.dart
import 'package:flutter/material.dart';

class FilterChipModel {
  final String label;
  final String value;
  final bool isSelected;

  // Agregamos el constructor const
  const FilterChipModel({
    required this.label,
    required this.value,
    this.isSelected = false,
  });
}

class FiltersWidget extends StatefulWidget {
  final String selectedFilter;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final Function(String filter, DateTime? inicio, DateTime? fin) onApplyFilters;

  const FiltersWidget({
    super.key,
    required this.selectedFilter,
    required this.fechaInicio,
    required this.fechaFin,
    required this.onApplyFilters,
  });

  @override
  State<FiltersWidget> createState() => _FiltersWidgetState();
}

class _FiltersWidgetState extends State<FiltersWidget> {
  late String _tempFilter;
  DateTime? _tempFechaInicio;
  DateTime? _tempFechaFin;

  // Opción 1: Quitar el const (recomendado para este caso)
  final List<FilterChipModel> _filterOptions = [
    const FilterChipModel(label: 'Todos', value: 'Todos'), // Ahora sí puede ser const
    const FilterChipModel(label: 'Entradas', value: 'Entradas'),
    const FilterChipModel(label: 'Salidas', value: 'Salidas'),
  ];

  @override
  void initState() {
    super.initState();
    _tempFilter = widget.selectedFilter;
    _tempFechaInicio = widget.fechaInicio;
    _tempFechaFin = widget.fechaFin;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrar movimientos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            children: _filterOptions.map((option) {
              return _buildFilterChip(
                option.label,
                _tempFilter == option.value,
                (selected) {
                  setState(() {
                    _tempFilter = option.value;
                  });
                },
              );
            }).toList(),
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
          _buildDateTile('Fecha inicio', _tempFechaInicio, (date) {
            setState(() {
              _tempFechaInicio = date;
            });
          }),
          _buildDateTile('Fecha fin', _tempFechaFin, (date) {
            setState(() {
              _tempFechaFin = date;
            });
          }),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
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
  }

  Widget _buildFilterChip(
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

  Widget _buildDateTile(
    String title,
    DateTime? selectedDate,
    Function(DateTime) onDateSelected,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(
        selectedDate != null
            ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
            : 'Seleccionar',
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          onDateSelected(date);
        }
      },
    );
  }

  void _clearFilters() {
    setState(() {
      _tempFilter = 'Todos';
      _tempFechaInicio = null;
      _tempFechaFin = null;
    });
  }

  void _applyFilters() {
    Navigator.pop(context);
    widget.onApplyFilters(_tempFilter, _tempFechaInicio, _tempFechaFin);
  }
}
