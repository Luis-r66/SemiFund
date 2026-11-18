import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/input_formatters.dart';
import '../../models/semillero_membership.dart';
import '../../providers/home_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/app_tour.dart';
import '../../widgets/buttons.dart';
import '../../widgets/form_controls.dart';
import '../../widgets/section_label.dart';
import '../../widgets/status_badge.dart';
import '../../core/navigation/volver.dart';

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

  Future<void> _editarDatos(SemilleroMembership membership) async {
    final SessionProvider session = context.read<SessionProvider>();
    final _DatosInput? input = await showDialog<_DatosInput>(
      context: context,
      builder: (BuildContext dialogContext) => _DatosSemilleroDialog(
        nombre: membership.nombre,
        ciudad: membership.ciudad,
        centroCostos: membership.centroCostos,
      ),
    );
    if (input == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await session.actualizarDatosSemillero(
        nombre: input.nombre,
        ciudad: input.ciudad,
        centroCostos: input.centroCostos,
      );
      if (!mounted) return;
      context.read<HomeProvider>().refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos del semillero actualizados.')),
      );
    } catch (error) {
      if (mounted) _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _ajustarSaldo(SemilleroMembership membership) async {
    final SessionProvider session = context.read<SessionProvider>();
    final _SaldoInput? input = await showDialog<_SaldoInput>(
      context: context,
      builder: (BuildContext dialogContext) => _SaldoInicialDialog(
        monto: membership.saldoInicial,
        nota: membership.saldoInicialNota,
      ),
    );
    if (input == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final double saldoDisponible = await session.ajustarSaldoInicial(
        monto: input.monto,
        nota: input.nota,
      );
      if (!mounted) return;
      context.read<HomeProvider>().refresh();
      if (saldoDisponible < 0) {
        await showDialog<void>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Saldo disponible negativo'),
            content: Text(
              'El ajuste deja el saldo disponible en '
              '${formatCop(saldoDisponible)}. Revisa los gastos o corrige el '
              'saldo inicial; el cambio ya quedó en auditoría.',
            ),
            actions: <Widget>[
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saldo inicial actualizado.')),
        );
      }
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
              onBack: () => volver(context),
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
                        if (session.isTesorero) ...<Widget>[
                          SectionLabel(
                            'Datos del semillero',
                            key: AppTourKeys.semillerosDatos,
                          ),
                          Text(
                            'La ciudad y el centro de costos se imprimen en los '
                            'documentos que generas para la universidad.',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.ink2,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.line),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _DatoFila(
                                  label: 'Ciudad',
                                  value: membership.ciudad,
                                ),
                                const SizedBox(height: 10),
                                const Divider(height: 1, color: AppColors.line),
                                const SizedBox(height: 10),
                                _DatoFila(
                                  label: 'Centro de costos',
                                  value: membership.centroCostos,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SecondaryButton(
                            label: 'Editar datos',
                            onPressed: _busy
                                ? null
                                : () => _editarDatos(membership),
                          ),
                          const SizedBox(height: 32),
                        ],
                        if (membership.puedeAjustarSaldoInicial) ...<Widget>[
                          const SectionLabel('Saldo inicial'),
                          Text(
                            'Dinero que el semillero ya tenía antes de usar la '
                            'app. No cuenta como aporte de ningún integrante.',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.ink2,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.line),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  formatCop(membership.saldoInicial),
                                  style: AppTextStyles.h2,
                                ),
                                if (membership.saldoInicialNota !=
                                    null) ...<Widget>[
                                  const SizedBox(height: 4),
                                  Text(
                                    membership.saldoInicialNota!,
                                    style: AppTextStyles.small.copyWith(
                                      color: AppColors.ink2,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SecondaryButton(
                            label: 'Ajustar saldo inicial',
                            onPressed: _busy
                                ? null
                                : () => _ajustarSaldo(membership),
                          ),
                          const SizedBox(height: 32),
                        ],
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

class _SaldoInput {
  const _SaldoInput({required this.monto, this.nota});

  final double monto;
  final String? nota;
}

class _SaldoInicialDialog extends StatefulWidget {
  const _SaldoInicialDialog({required this.monto, this.nota});

  final double monto;
  final String? nota;

  @override
  State<_SaldoInicialDialog> createState() => _SaldoInicialDialogState();
}

class _SaldoInicialDialogState extends State<_SaldoInicialDialog> {
  late final TextEditingController _monto = TextEditingController(
    text: widget.monto > 0 ? formatThousands(widget.monto) : '',
  );
  late final TextEditingController _nota = TextEditingController(
    text: widget.nota ?? '',
  );

  @override
  void dispose() {
    _monto.dispose();
    _nota.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajustar saldo inicial'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'El valor anterior y el nuevo quedan en auditoría. No crea ni '
              'modifica aportes de los integrantes.',
            ),
            const SizedBox(height: 16),
            MoneyField(controller: _monto),
            const SizedBox(height: 12),
            TextField(
              controller: _nota,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                hintText: 'Ej. Saldo en la cuenta de ahorros',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _confirm(),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _confirm, child: const Text('Guardar ajuste')),
      ],
    );
  }

  void _confirm() {
    final double monto = parseMoney(_monto.text);
    final String nota = _nota.text.trim();
    Navigator.of(context)
        .pop(_SaldoInput(monto: monto, nota: nota.isEmpty ? null : nota));
  }
}

class _DatoFila extends StatelessWidget {
  const _DatoFila({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final String texto = (value ?? '').trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.small.copyWith(color: AppColors.ink2),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            texto.isEmpty ? 'Sin definir' : texto,
            textAlign: TextAlign.right,
            style: texto.isEmpty
                ? AppTextStyles.small.copyWith(color: AppColors.ink3)
                : AppTextStyles.smallSemibold,
          ),
        ),
      ],
    );
  }
}

class _DatosInput {
  const _DatosInput({
    required this.nombre,
    required this.ciudad,
    required this.centroCostos,
  });

  final String nombre;
  final String ciudad;
  final String centroCostos;
}

class _DatosSemilleroDialog extends StatefulWidget {
  const _DatosSemilleroDialog({
    required this.nombre,
    this.ciudad,
    this.centroCostos,
  });

  final String nombre;
  final String? ciudad;
  final String? centroCostos;

  @override
  State<_DatosSemilleroDialog> createState() => _DatosSemilleroDialogState();
}

class _DatosSemilleroDialogState extends State<_DatosSemilleroDialog> {
  late final TextEditingController _nombre = TextEditingController(
    text: widget.nombre,
  );
  late final TextEditingController _ciudad = TextEditingController(
    text: widget.ciudad ?? '',
  );
  late final TextEditingController _centroCostos = TextEditingController(
    text: widget.centroCostos ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _ciudad.dispose();
    _centroCostos.dispose();
    super.dispose();
  }

  void _confirm() {
    final String nombre = _nombre.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'Escribe el nombre del semillero.');
      return;
    }
    Navigator.of(context).pop(
      _DatosInput(
        nombre: nombre,
        ciudad: _ciudad.text.trim(),
        centroCostos: _centroCostos.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Datos del semillero'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Estos datos se imprimen en los documentos generados. La ciudad '
              'también se usa como ciudad por defecto del periodo.',
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Nombre',
              child: AppTextField(
                controller: _nombre,
                hintText: 'Nombre del semillero',
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: semilleroNameFormatters,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() => _error = null),
              ),
            ),
            LabeledField(
              label: 'Ciudad',
              child: AppTextField(
                controller: _ciudad,
                hintText: 'Ej. Bogotá D.C.',
                textCapitalization: TextCapitalization.words,
                inputFormatters: simpleTextFormatters,
                textInputAction: TextInputAction.next,
              ),
            ),
            LabeledField(
              label: 'Centro de costos',
              child: AppTextField(
                controller: _centroCostos,
                hintText: 'Ej. Facultad de Ingeniería',
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _confirm(),
              ),
            ),
            if (_error != null)
              Text(
                _error!,
                style: AppTextStyles.small.copyWith(color: AppColors.bad),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _confirm, child: const Text('Guardar')),
      ],
    );
  }
}
