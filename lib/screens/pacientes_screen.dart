import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/paciente.dart';
import '../widgets/nav_drawer.dart';
import '../widgets/paciente_card.dart';

class PacientesScreen extends StatefulWidget {
  const PacientesScreen({super.key});

  @override
  State<PacientesScreen> createState() => _PacientesScreenState();
}

class _PacientesScreenState extends State<PacientesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Paciente> _resultadosBusqueda = [];
  bool _buscando = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _buscar(String query, AppProvider provider) {
    if (query.trim().isEmpty) {
      setState(() {
        _buscando = false;
        _resultadosBusqueda = [];
      });
      return;
    }

    final String clave = query.trim().toLowerCase();
    final dynamic resultado = provider.hashBusqueda.obtener(clave);

    setState(() {
      _buscando = true;
      if (resultado != null) {
        _resultadosBusqueda = [resultado as Paciente];
      } else {
        // Búsqueda parcial como fallback
        _resultadosBusqueda = provider.pacientes.where((p) {
          final String nombreCompleto =
              '${p.nombre} ${p.apellido}'.toLowerCase();
          return nombreCompleto.contains(clave);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pacientes'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const NavDrawer(),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.cargando) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.pacientes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay pacientes cargados',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => provider.cargarDatos(),
                    icon: const Icon(Icons.cloud_download_outlined),
                    label: const Text('Cargar datos'),
                  ),
                ],
              ),
            );
          }

          final List<Paciente> lista =
              _buscando ? _resultadosBusqueda : provider.pacientes;

          return Column(
            children: [
              // Barra de búsqueda
              Container(
                color: Theme.of(context).colorScheme.primary,
                padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Buscar paciente por nombre...',
                  leading: const Icon(Icons.search),
                  trailing: _searchController.text.isNotEmpty
                      ? [
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _buscar('', provider);
                            },
                          )
                        ]
                      : null,
                  onChanged: (value) => _buscar(value, provider),
                  elevation: const WidgetStatePropertyAll(2),
                ),
              ),

              // Contador de resultados
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _buscando
                          ? '${lista.length} resultado(s) para "${_searchController.text}"'
                          : '${lista.length} pacientes cargados',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Lista de pacientes
              Expanded(
                child: lista.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'No se encontraron pacientes',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: lista.length,
                        padding: const EdgeInsets.only(bottom: 16),
                        itemBuilder: (context, index) {
                          final Paciente paciente = lista[index];
                          return PacienteCard(
                            paciente: paciente,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/detalle-paciente',
                                arguments: paciente,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
