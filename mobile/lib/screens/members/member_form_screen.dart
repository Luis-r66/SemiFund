import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../models/member.dart';
import '../../providers/members_provider.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_view.dart';

class MemberFormScreen extends StatefulWidget {
  const MemberFormScreen({super.key, this.memberId});

  final String? memberId;

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final TextEditingController _names = TextEditingController();
  final TextEditingController _surnames = TextEditingController();
  final TextEditingController _program = TextEditingController();
  final TextEditingController _semester = TextEditingController();

  bool _loading = false;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.memberId != null;

  @override
  void initState() {
    super.initState();
    for (final TextEditingController c in <TextEditingController>[
      _names,
      _surnames,
      _program,
      _semester,
    ]) {
      c.addListener(() => setState(() {}));
    }
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadMember());
    }
  }

  @override
  void dispose() {
    _names.dispose();
    _surnames.dispose();
    _program.dispose();
    _semester.dispose();
    super.dispose();
  }

  Future<void> _loadMember() async {
    setState(() => _loading = true);
    try {
      final Member member = await context.read<DashboardService>().member(
        widget.memberId!,
      );
      if (!mounted) return;
      final List<String> parts = member.nombre
          .trim()
          .split(RegExp(r'\s+'))
          .where((String part) => part.isNotEmpty)
          .toList();
      _names.text = member.nombres.isNotEmpty
          ? member.nombres
          : (parts.isNotEmpty ? parts.first : '');
      _surnames.text = member.apellidos.isNotEmpty
          ? member.apellidos
          : (parts.length > 1 ? parts.skip(1).join(' ') : '');
      _program.text = member.programa;
      _semester.text = member.semestre?.toString() ?? '';
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int? get _semesterValue {
    final int? value = int.tryParse(_semester.text.trim());
    if (value == null || value < 1 || value > 10) return null;
    return value;
  }

  bool get _canSave =>
      _names.text.trim().isNotEmpty &&
      _surnames.text.trim().isNotEmpty &&
      _program.text.trim().isNotEmpty &&
      _semesterValue != null &&
      !_saving;

  Future<void> _save() async {
    if (!_canSave) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    final MembersProvider members = context.read<MembersProvider>();
    try {
      if (_isEdit) {
        await members.update(widget.memberId!, <String, dynamic>{
          'nombres': _names.text.trim(),
          'apellidos': _surnames.text.trim(),
          'programa': _program.text.trim(),
          'semestre': _semesterValue,
        });
      } else {
        await members.create(
          nombres: _names.text.trim(),
          apellidos: _surnames.text.trim(),
          programa: _program.text.trim(),
          semestre: _semesterValue!,
        );
      }
      if (!mounted) return;
      context.pop();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String semesterText = _semester.text.trim();
    final bool semesterInvalid =
        semesterText.isNotEmpty && _semesterValue == null;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(
              title: _isEdit ? 'Editar integrante' : 'Nuevo integrante',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: _loading
                  ? const LoadingView()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          LabeledField(
                            label: 'Nombres',
                            child: AppTextField(
                              controller: _names,
                              hintText: 'Ej. Juliana',
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          LabeledField(
                            label: 'Apellidos',
                            child: AppTextField(
                              controller: _surnames,
                              hintText: 'Ej. Herrera Pérez',
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          LabeledField(
                            label: 'Programa académico',
                            child: AppTextField(
                              controller: _program,
                              hintText: 'Ej. Ingeniería de Sistemas',
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          LabeledField(
                            label: 'Semestre',
                            error: semesterInvalid
                                ? 'Ingresa un semestre entre 1 y 10.'
                                : null,
                            child: AppTextField(
                              controller: _semester,
                              hintText: '1 - 10',
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _save(),
                            ),
                          ),
                          if (_error != null) ...<Widget>[
                            const SizedBox(height: 8),
                            ErrorBanner(message: _error!),
                          ],
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: PrimaryButton(
                label: 'Guardar',
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
