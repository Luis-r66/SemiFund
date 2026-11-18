import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/layout/app_layout.dart';
import '../../core/navigation/volver.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/input_formatters.dart';
import '../../core/utils/programas.dart';
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
  final TextEditingController _document = TextEditingController();
  final TextEditingController _position = TextEditingController();

  UserType? _type;
  int? _semester;
  String? _programChoice;
  bool _saving = false;
  String? _error;
  String? _typeError;
  String? _semesterError;
  String? _programError;
  String? _documentError;

  /// El rol se define en el primer perfil y después queda bloqueado.
  bool _roleLocked = false;

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
    _type = user?.tipoUsuario;
    _semester = user?.semestre;
    _roleLocked = user?.tipoUsuario != null;
    _document.text = user?.identificacion ?? '';
    _position.text = user?.cargo ?? '';

    final String guardado = (user?.programa ?? '').trim();
    final bool esProfesor = _type == UserType.profesor;
    if (guardado.isNotEmpty) {
      final List<String> opciones = programasPara(esProfesor: esProfesor);
      String? conocida;
      for (final String opcion in opciones) {
        if (opcion.toLowerCase() == guardado.toLowerCase()) {
          conocida = opcion;
          break;
        }
      }
      if (conocida != null) {
        _programChoice = conocida;
      } else {
        _programChoice = otroPrograma;
        _program.text = guardado;
      }
    }

    for (final TextEditingController controller in <TextEditingController>[
      _names,
      _surnames,
      _program,
      _document,
      _position,
    ]) {
      controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _names.dispose();
    _surnames.dispose();
    _program.dispose();
    _document.dispose();
    _position.dispose();
    super.dispose();
  }

  bool get _isStudent => _type == UserType.estudiante;
  bool get _isProfesor => _type == UserType.profesor;

  List<String> get _programOptions => <String>[
    ...programasPara(esProfesor: _isProfesor),
    otroPrograma,
  ];

  String get _programValue {
    if (_programChoice == otroPrograma) return _program.text.trim();
    return _programChoice ?? '';
  }

  bool get _needsCustomProgram => _programChoice == otroPrograma;

  String? _validateDocument(String text) {
    final String value = text.trim();
    if (value.isEmpty) return null;
    if (!RegExp(r'^[0-9][0-9.\- ]{4,19}$').hasMatch(value)) {
      return 'Escribe entre 5 y 20 números (puedes usar puntos o guiones).';
    }
    return null;
  }

  bool get _canSave =>
      _names.text.trim().isNotEmpty &&
      _surnames.text.trim().isNotEmpty &&
      _programValue.isNotEmpty &&
      !_saving;

  void _selectType(UserType type) {
    if (_roleLocked) return;
    setState(() {
      _type = type;
      _typeError = null;
      _semesterError = null;
      _programChoice = null;
      _program.clear();
      if (type == UserType.profesor) _semester = null;
    });
  }

  Future<void> _save() async {
    final String? documentError = _validateDocument(_document.text);
    setState(() {
      _typeError = _type == null
          ? 'Selecciona si eres estudiante o profesor.'
          : null;
      _semesterError = _isStudent && _semester == null
          ? 'Selecciona tu semestre.'
          : null;
      _programError = _programValue.isEmpty
          ? 'Selecciona una opción o escribe la tuya.'
          : null;
      _documentError = documentError;
      _error = null;
    });
    if (_typeError != null ||
        _semesterError != null ||
        _programError != null ||
        _documentError != null) {
      return;
    }
    if (!_canSave) return;

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
        programa: _programValue,
        semestre: _isStudent ? _semester : null,
        identificacion: _document.text.trim().isEmpty
            ? null
            : _document.text.trim(),
        cargo: _isProfesor && _position.text.trim().isNotEmpty
            ? _position.text.trim()
            : null,
      );
      if (!mounted) return;
      if (widget.editMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos académicos actualizados')),
        );
        volver(context, fallback: '/profile');
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
        child: AppContent(
          maxWidth: AppLayout.formMaxWidth,
          child: Column(
            children: <Widget>[
              AppTopBar(
                title: widget.editMode
                    ? 'Datos académicos'
                    : 'Completa tu perfil',
                onBack: widget.editMode
                    ? () => volver(context, fallback: '/profile')
                    : null,
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
                              locked: _roleLocked,
                              onTap: () => _selectType(UserType.estudiante),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _RoleCard(
                              icon: LucideIcons.briefcaseBusiness,
                              label: 'Profesor',
                              selected: _type == UserType.profesor,
                              locked: _roleLocked,
                              onTap: () => _selectType(UserType.profesor),
                            ),
                          ),
                        ],
                      ),
                      if (_roleLocked) ...<Widget>[
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            const Icon(
                              LucideIcons.lock,
                              size: 14,
                              color: AppColors.ink3,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'El rol se define una sola vez y no se puede cambiar.',
                                style: AppTextStyles.tiny.copyWith(
                                  color: AppColors.ink3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
                          inputFormatters: lettersOnlyFormatters,
                          hintText: 'Ej. Luis Ernesto',
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      LabeledField(
                        label: 'Apellidos',
                        child: AppTextField(
                          controller: _surnames,
                          inputFormatters: lettersOnlyFormatters,
                          hintText: 'Ej. Ríos Pérez',
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      LabeledField(
                        label: programLabel,
                        error: _programError,
                        child: SelectField<String>(
                          value: _programChoice,
                          items: _programOptions,
                          labelOf: (String value) => value,
                          hintText: _isStudent
                              ? 'Selecciona tu carrera'
                              : 'Selecciona tu área',
                          onChanged: (String? value) => setState(() {
                            _programChoice = value;
                            _programError = null;
                            if (value != otroPrograma) _program.clear();
                          }),
                        ),
                      ),
                      if (_needsCustomProgram)
                        LabeledField(
                          label: _isStudent ? 'Escribe tu carrera' : 'Escribe tu área',
                          child: AppTextField(
                            controller: _program,
                            inputFormatters: simpleTextFormatters,
                            hintText: _isStudent
                                ? 'Ej. Ingeniería Ambiental'
                                : 'Ej. Departamento de Lenguas',
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
                      LabeledField(
                        label: 'Documento de identidad (opcional)',
                        error: _documentError,
                        helper: _isProfesor
                            ? 'Se imprime en los documentos que generes.'
                            : null,
                        child: AppTextField(
                          controller: _document,
                          inputFormatters: identificationFormatters,
                          hintText: 'Ej. 1.020.304.050',
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      if (_isProfesor)
                        LabeledField(
                          label: 'Cargo (opcional)',
                          child: AppTextField(
                            controller: _position,
                            inputFormatters: simpleTextFormatters,
                            hintText: 'Ej. Docente de planta',
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.done,
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
                                : () =>
                                      context.read<SessionProvider>().logout(),
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
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked && !selected ? 0.45 : 1,
      child: Material(
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
      ),
    );
  }
}
