import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/semillero_membership.dart';
import '../../providers/session_provider.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/section_label.dart';
import '../../widgets/status_badge.dart';

/// Ajustes de la membresía activa: salir del semillero o eliminarlo.
class SemilleroSettingsScreen extends StatefulWidget {
  const SemilleroSettingsScreen({super.key});

  @override
  State<SemilleroSettingsScreen> createState() =>
      _SemilleroSettingsScreenState();
}

class _SemilleroSettingsScreenState extends State<SemilleroSettingsScreen> {
  bool _busy = false;

  String _normalizar(String value) {
    const Map<String, String> acentos = <String, String>{
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    String texto = value.toLowerCase().trim();
    acentos.forEach((String con, String sin) {
      texto = texto.replaceAll(con, sin);
    });
    return texto.replaceAll(RegExp(r'\s+'), ' ');
  }

  void _error(Object error) {
    final String message = error is ApiException
        ? error.message
        : 'No se pudo completar la acción. Intenta de nuevo.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _salir(SemilleroMembership membership) async {
    final SessionProvider session = context.read<SessionProvider>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Salir del semillero'),
          content: Text(
            membership.esCreador && membership.miembros > 1
                ? 'Dejarás de ver los aportes y gastos de "${membership.nombre}". '
                      'Como lo creaste, después ya no podrás eliminarlo; si esa '
                      'es tu intención, elimínalo ahora.'
                : 'Dejarás de ver los aportes y gastos de "${membership.nombre}". '
                      'Puedes volver con el código de invitación.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await session.salirDelSemillero();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saliste del semillero.')));
      context.go('/semilleros');
    } catch (error) {
      if (mounted) _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _eliminar(SemilleroMembership membership) async {
    final SessionProvider session = context.read<SessionProvider>();
    final TextEditingController controller = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            final bool coincide =
                _normalizar(controller.text) == _normalizar(membership.nombre);
            return AlertDialog(
              title: const Text('Eliminar semillero'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'El semillero y su historial dejarán de estar disponibles '
                    'para todos. Esta acción no se puede deshacer desde la app.',
                    style: AppTextStyles.small.copyWith(color: AppColors.ink2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Escribe "${membership.nombre}" para confirmar.',
                    style: AppTextStyles.smallSemibold,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Nombre del semillero',
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.bad,
                    foregroundColor: AppColors.paper,
                  ),
                  onPressed: coincide
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  child: const Text('Eliminar'),
                ),
              ],
            );
          },
        );
      },
    );
    final String confirmacion = controller.text.trim();
    controller.dispose();
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await session.eliminarSemillero(confirmacion: confirmacion);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El semillero fue eliminado.')),
      );
      context.go('/semilleros');
    } catch (error) {
      if (mounted) _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final SessionProvider session = context.watch<SessionProvider>();
    final SemilleroMembership? membership = session.activeSemillero;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(
              title: 'Ajustes del semillero',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: membership == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No hay un semillero activo.',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.ink2,
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: <Widget>[
                        Text(membership.nombre, style: AppTextStyles.h1),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            StatusBadge.membership(membership),
                            const SizedBox(width: 10),
                            Text(
                              '${membership.miembros} '
                              '${membership.miembros == 1 ? 'integrante' : 'integrantes'}',
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.ink2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        const SectionLabel('Membresía'),
                        Text(
                          'Si sales, dejarás de ver los aportes, gastos y el '
                          'saldo de este semillero. Podrás volver con el código '
                          'que te comparta el tesorero.',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.ink2,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SecondaryButton(
                          label: 'Salir del semillero',
                          onPressed: _busy ? null : () => _salir(membership),
                        ),
                        if (membership.esCreador) ...<Widget>[
                          const SizedBox(height: 32),
                          const SectionLabel('Zona de riesgo'),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0x4DC62F2F),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Eliminar este semillero',
                                  style: AppTextStyles.bodySemibold,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Desaparece para todos los integrantes y su '
                                  'historial deja de estar disponible. Solo tú, '
                                  'como creador, puedes hacerlo.',
                                  style: AppTextStyles.small.copyWith(
                                    color: AppColors.ink2,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                DangerButton(
                                  label: 'Eliminar semillero',
                                  onPressed: _busy
                                      ? null
                                      : () => _eliminar(membership),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
