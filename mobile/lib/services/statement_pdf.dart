import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/utils/formatters.dart';
import '../models/contribution.dart';
import '../models/member.dart';
import '../models/member_statement.dart';

/// Genera el estado de cuenta en PDF con un estilo sobrio en blanco y negro.
Future<Uint8List> buildMemberStatementPdf(
  Member member,
  MemberStatement statement,
) async {
  final pw.Font font = pw.Font.ttf(
    await rootBundle.load('assets/fonts/InstrumentSans.ttf'),
  );
  final pw.Document document = pw.Document(
    title: 'Estado de cuenta - ${member.nombre}',
    author: 'SemiFund',
    theme: pw.ThemeData.withFont(base: font, bold: font),
  );
  const pw.TextStyle small = pw.TextStyle(
    fontSize: 9,
    color: PdfColors.grey700,
  );
  const pw.TextStyle strong = pw.TextStyle(
    fontSize: 11,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 36),
      footer: (pw.Context context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 12),
        child: pw.Text(
          'SemiFund · Página ${context.pageNumber} de ${context.pagesCount}',
          style: small,
        ),
      ),
      build: (pw.Context context) => <pw.Widget>[
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: <pw.Widget>[
            pw.Text(
              'SemiFund',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
            pw.Text(_pdfDate(DateTime.now()), style: small),
          ],
        ),
        pw.Divider(color: PdfColors.grey500, height: 18),
        pw.Text(
          'Estado de cuenta',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          member.nombre,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(_academicLine(member), style: small),
        pw.SizedBox(height: 18),
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
          ),
          child: pw.Row(
            children: <pw.Widget>[
              pw.Expanded(
                child: _pdfFigure('Cuotas', formatCop(statement.esperado)),
              ),
              pw.Expanded(
                child: _pdfFigure('Pagado', formatCop(statement.cobrado)),
              ),
              pw.Expanded(
                child: _pdfFigure('Saldo', formatCop(statement.saldo)),
              ),
              pw.Expanded(
                child: _pdfFigure('Vencido', formatCop(statement.vencido)),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          statement.alDia
              ? 'Estado: al día, sin saldo pendiente.'
              : 'Estado: con saldo pendiente.',
          style: strong,
        ),
        pw.SizedBox(height: 18),
        pw.Text(
          'Cuotas',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 8),
        if (statement.cuotas.isEmpty)
          pw.Text('Este integrante no tiene cuotas registradas.', style: small)
        else
          pw.TableHelper.fromTextArray(
            headers: <String>[
              'Mes',
              'Concepto',
              'Cuota',
              'Pagado',
              'Saldo',
              'Estado',
            ],
            data: statement.cuotas
                .map(
                  (Contribution cuota) => <String>[
                    formatMonth(cuota.mes),
                    cuota.concepto,
                    formatCop(cuota.monto),
                    formatCop(cuota.cobrado),
                    formatCop(cuota.saldoPendiente),
                    _estadoCuota(cuota),
                  ],
                )
                .toList(),
            headerStyle: const pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 4,
            ),
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: const <int, pw.TableColumnWidth>{
              0: pw.FixedColumnWidth(48),
              1: pw.FixedColumnWidth(150),
              2: pw.FixedColumnWidth(66),
              3: pw.FixedColumnWidth(66),
              4: pw.FixedColumnWidth(66),
              5: pw.FixedColumnWidth(62),
            },
            cellAlignments: const <int, pw.AlignmentGeometry>{
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerLeft,
            },
          ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Documento generado por SemiFund con la información registrada en el semillero. '
          'Los valores pueden cambiar si se registran nuevos pagos o gastos.',
          style: small,
        ),
      ],
    ),
  );
  return document.save();
}

String _pdfDate(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _academicLine(Member member) {
  if (member.esProfesor) return 'Área: ${member.programa}';
  return 'Programa: ${member.programa} · Semestre: ${member.semesterLabel}';
}

String _estadoCuota(Contribution cuota) {
  if (cuota.isParcial) return 'Parcial';
  return cuota.estado.label;
}

pw.Widget _pdfFigure(String label, String value) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.Text(
        label,
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
      ),
    ],
  );
}
