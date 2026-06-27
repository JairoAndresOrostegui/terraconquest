import 'package:flutter/material.dart';

import 'partidas/admin_partidas_screen.dart';
import 'razas/admin_razas_screen.dart';
import 'regiones/admin_regiones_screen.dart';
import 'terrenos/admin_terrenos_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const routeName = '/admin';

  void _abrir(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool disponible,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: disponible ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: disponible ? null : theme.disabledColor),
                  const Spacer(),
                  if (!disponible)
                    Chip(
                      label: const Text('Pendiente'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: theme.disabledColor.withValues(
                        alpha: 0.12,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: disponible ? null : theme.disabledColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      disponible
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.disabledColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = [
      _buildSection(
        context: context,
        icon: Icons.event_note,
        title: 'Partidas',
        subtitle: 'Crear, editar, cerrar y configurar partidas.',
        disponible: true,
        onTap: () => _abrir(context, const AdminPartidasScreen()),
      ),
      _buildSection(
        context: context,
        icon: Icons.terrain,
        title: 'Terrenos',
        subtitle: 'Administrar catalogo global de terrenos.',
        disponible: true,
        onTap: () => _abrir(context, const AdminTerrenosScreen()),
      ),
      _buildSection(
        context: context,
        icon: Icons.public,
        title: 'Regiones',
        subtitle: 'Bonos regionales y terrenos permitidos.',
        disponible: true,
        onTap: () => _abrir(context, const AdminRegionesScreen()),
      ),
      _buildSection(
        context: context,
        icon: Icons.diversity_3,
        title: 'Razas',
        subtitle: 'Bonos, costos y reglas por raza.',
        disponible: true,
        onTap: () => _abrir(context, const AdminRazasScreen()),
      ),
      _buildSection(
        context: context,
        icon: Icons.shield,
        title: 'Tropas',
        subtitle: 'Catalogo, estadisticas y costos militares.',
        disponible: false,
      ),
      _buildSection(
        context: context,
        icon: Icons.group,
        title: 'Usuarios',
        subtitle: 'Roles, estado de cuentas y soporte.',
        disponible: false,
      ),
      _buildSection(
        context: context,
        icon: Icons.auto_awesome,
        title: 'Heroes',
        subtitle: 'Mercado, clases y parametros de heroes.',
        disponible: false,
      ),
      _buildSection(
        context: context,
        icon: Icons.map,
        title: 'Mapas',
        subtitle: 'Asignacion visual y distribucion territorial.',
        disponible: false,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Administracion')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sections.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280,
              mainAxisExtent: 180,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) => sections[index],
          ),
        ),
      ),
    );
  }
}
