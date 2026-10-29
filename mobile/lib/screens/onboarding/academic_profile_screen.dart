import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/user.dart';
import '../../providers/session_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/form_controls.dart';

class AcademicProfileScreen extends StatefulWidget {
  const AcademicProfileScreen({super.key, this.editMode = false});

  final bool editMode;

  @override
  State<AcademicProfileScreen> createState() => _AcademicProfileScreenState();
}

class _AcademicProfileScreenState extends State<AcademicProfileScreen> {
  final TextEditingController _names = TextEditingController();
  final TextEditingController _surnames = TextEditingController();
  final TextEditingController _program = TextEditingController();

  UserType? _type;
  int? _semester;
  bool _saving = false;
  String? _error;
  String? _typeError;
  String? _semesterError;

  @override
  void initState() {
    super.initState();
    final UserModel? user = context.read<SessionProvider>().user;
    final List<String> parts = (user?.nombre ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();
    _names.text = (user?.nombres ?? '').isNotEmpty
        ? user!.nombres
        : (parts.isNotEmpty ? parts.first : '');
    _surnames.text = (user?.apellidos ?? '').isNotEmpty
        ? user!.apellidos
        : (parts.length > 1 ? parts.skip(1).join(' ') : '');
    _program.text = user?.programa ?? '';
    _type = user?.tipoUsuario;
    _semester = user?.semestre;

    for (final TextEditingController controller in <TextEditingController>[
      _names,
      _surnames,
      _program,
    ]) {
      controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _names.dispose();
    _surnames.dispose();
    _program.dispose();
    super.dispose();
  }

  bool get _isStudent => _type == UserType.estudiante;

  bool get _canSave =>
      _names.text.trim().isNotEmpty &&
      _surnames.text.trim().isNotEmpty &&
      _program.text.trim().isNotEmpty &&
      !_saving;

  void _selectType(UserType type) {
    setState(() {
      _type = type;
      _typeError = null;
      _semesterError = null;
      if (type == UserType.profesor) _semester = null;
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _typeError = _type == null
          ? 'Selecciona si eres estudiante o profesor.'
          : null;
      _semesterError = _isStudent && _semester == null
          ? 'Selecciona tu semestre.'
          : null;
      _error = null;
    });
    if (_typeError != null || _semesterError != null) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await context.read<SessionProvider>().completeProfile(
        nombres: _names.text.trim(),
        apellidos: _surnames.text.trim(),
        tipoUsuario: _type!,
        programa: _program.text.trim(),
        semestre: _isStudent ? _semester : null,
      );
      if (!mounted) return;
      if (widget.editMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos académicos actualizados')),
        );
        context.pop();
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudieron guardar los datos. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String programLabel = _type == null
        ? 'Carrera, programa o área'
        : (_isStudent ? 'Carrera o programa' : 'Área o departamento');

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(
              title: widget.editMode
                  ? 'Datos académicos'
                  : 'Completa tu perfil',
              onBack: widget.editMode ? () => context.pop() : null,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.editMode
                          ? 'Actualiza tu información académica.'
                          : 'Cuéntanos quién eres para personalizar tu cuenta.',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.ink2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '¿Cómo participas?',
                      style: AppTextStyles.smallMedium.copyWith(
                        color: AppColors.ink2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _RoleCard(
                            icon: LucideIcons.graduationCap,
                            label: 'Estudiante',
                            selected: _type == UserType.estudiante,
                            onTap: () => _selectType(UserType.estudiante),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _RoleCard(
                            icon: LucideIcons.briefcaseBusiness,
                            label: 'Profesor',
                            selected: _type == UserType.profesor,
                            onTap: () => _selectType(UserType.profesor),
                          ),
                        ),
                      ],
                    ),
                    if (_typeError != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        _typeError!,
                        style: AppTextStyles.smallMedium.copyWith(
                          color: AppColors.bad,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    LabeledField(
                      label: 'Nombres',
                      child: AppTextField(
                        controller: _names,
                        hintText: 'Ej. Luis Ernesto',
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    LabeledField(
                      label: 'Apellidos',
                      child: AppTextField(
                        controller: _surnames,
                        hintText: 'Ej. Ríos Pérez',
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    LabeledField(
                      label: programLabel,
                      child: AppTextField(
                        controller: _program,
                        hintText: _isStudent
                            ? 'Ej. Ingeniería de Sistemas'
                            : 'Ej. Departamento de Sistemas',
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    if (_isStudent)
                      LabeledField(
                        label: 'Semestre',
                        child: SelectField<int>(
                          value: _semester,
                          error: _semesterError,
                          items: List<int>.generate(
                            10,
                            (int index) => index + 1,
                          ),
                          labelOf: (int value) => '$value° semestre',
                          hintText: 'Selecciona tu semestre',
                          onChanged: (int? value) =>
                              setState(() => _semester = value),
                        ),
                      ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 8),
                      ErrorBanner(message: _error!),
                    ],
                    if (!widget.editMode) ...<Widget>[
                      const SizedBox(height: 18),
                      Center(
                        child: TextButton(
                          onPressed: _saving
                              ? null
                              : () => context.read<SessionProvider>().logout(),
                          child: const Text('Cerrar sesión'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: PrimaryButton(
                label: widget.editMode ? 'Guardar cambios' : 'Continuar',
                loading: _saving,
                onPressed: _canSave ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.mist : AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.ink : AppColors.line,
          width: selected ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                icon,
                size: 22,
                color: selected ? AppColors.ink : AppColors.ink3,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: AppTextStyles.bodySemibold.copyWith(
                  color: selected ? AppColors.ink : AppColors.ink2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
