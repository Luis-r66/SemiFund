import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'guided_intro.dart';

/// Puntos de referencia del recorrido. Cada pantalla marca con una de estas
/// claves el widget que la guía debe señalar; si la clave no existe en la
/// pantalla (por ejemplo, el + de un integrante que no es tesorero), la nube
/// se muestra centrada y el paso sigue explicando la pantalla.
class AppTourKeys {
  const AppTourKeys._();

  // Inicio
  static final GlobalKey inicioSaldo = GlobalKey(
    debugLabel: 'tour-inicio-saldo',
  );
  static final GlobalKey inicioModulos = GlobalKey(
    debugLabel: 'tour-inicio-modulos',
  );

  // Aportes
  static final GlobalKey aportesAgregar = GlobalKey(
    debugLabel: 'tour-aportes-agregar',
  );
  static final GlobalKey aportesFiltros = GlobalKey(
    debugLabel: 'tour-aportes-filtros',
  );

  // Gastos
  static final GlobalKey gastosAgregar = GlobalKey(
    debugLabel: 'tour-gastos-agregar',
  );
  static final GlobalKey gastosResumen = GlobalKey(
    debugLabel: 'tour-gastos-resumen',
  );

  // Integrantes
  static final GlobalKey integrantesAgregar = GlobalKey(
    debugLabel: 'tour-integrantes-agregar',
  );
  static final GlobalKey integrantesBuscar = GlobalKey(
    debugLabel: 'tour-integrantes-buscar',
  );

  // Documentos
  static final GlobalKey documentosSubir = GlobalKey(
    debugLabel: 'tour-documentos-subir',
  );

  // Administración
  static final GlobalKey cuentasTitulo = GlobalKey(
    debugLabel: 'tour-cuentas-titulo',
  );
  static final GlobalKey invitarTitulo = GlobalKey(
    debugLabel: 'tour-invitar-titulo',
  );
  static final GlobalKey actividadTitulo = GlobalKey(
    debugLabel: 'tour-actividad-titulo',
  );

  // Perfil y semilleros
  static final GlobalKey perfilTitulo = GlobalKey(
    debugLabel: 'tour-perfil-titulo',
  );
  static final GlobalKey semillerosTitulo = GlobalKey(
    debugLabel: 'tour-semilleros-titulo',
  );
  static final GlobalKey semillerosDatos = GlobalKey(
    debugLabel: 'tour-semilleros-datos',
  );
}

/// Recorrido completo por la app. Se arma según el rol: el tesorero ve las
/// pantallas de administración y el profesor la de documentos; el integrante
/// solo las que puede usar.
class AppTour {
  const AppTour._();

  static List<GuidedStep> pasosPara({
    required bool tesorero,
    required bool profesor,
  }) {
    return <GuidedStep>[
      GuidedStep(
        route: '/home',
        icon: LucideIcons.cloud,
        title: 'Conoce SemiFund',
        body:
            'Te acompaño por las pantallas de la app para mostrarte qué hace '
            'cada una. Puedes saltar el recorrido y repetirlo cuando quieras '
            'desde tu perfil.',
      ),
      GuidedStep(
        route: '/home',
        icon: LucideIcons.wallet,
        target: AppTourKeys.inicioSaldo,
        title: 'El saldo del semillero',
        body:
            'Aquí ves el dinero disponible: lo recaudado menos lo gastado. Se '
            'actualiza con cada cuota, aporte o gasto que se registra.',
      ),
      GuidedStep(
        route: '/home',
        icon: LucideIcons.house,
        target: AppTourKeys.inicioModulos,
        title: tesorero ? 'Tu tablero de trabajo' : 'Tus accesos',
        body: tesorero
            ? 'Desde estas tarjetas entras a integrantes, aportes, gastos y, si '
                  'eres profesor, a documentos. Más abajo están las '
                  'herramientas de administración.'
            : 'Desde aquí entras a los integrantes, tus aportes y los gastos del '
                  'semillero. Si eres profesor también verás Documentos.',
      ),
      GuidedStep(
        route: '/contributions',
        icon: tesorero ? LucideIcons.circlePlus : LucideIcons.wallet,
        target: tesorero
            ? AppTourKeys.aportesAgregar
            : AppTourKeys.aportesFiltros,
        title: tesorero ? 'Todo se crea desde el +' : 'Tus cuotas y aportes',
        body: tesorero
            ? 'El + reúne las tres formas de cobrar: una cuota individual, las '
                  'cuotas del mes para varios integrantes y un aporte para un '
                  'destino concreto. El menú de Excel queda aparte, para '
                  'importar o exportar el libro.'
            : 'Cuando la tesorería te asigne una cuota aparecerá aquí. Abre el '
                  'detalle para reportar el pago con el comprobante; la '
                  'tesorería lo revisa y lo aprueba.',
      ),
      if (tesorero)
        GuidedStep(
          route: '/contributions',
          icon: LucideIcons.listChecks,
          target: AppTourKeys.aportesFiltros,
          title: 'Sigue cada pago',
          body:
              'Los filtros separan lo pendiente, lo vencido y lo reportado. '
              'Toca un registro para registrar abonos, aprobar comprobantes o '
              'eliminar una cuota.',
        ),
      GuidedStep(
        route: '/expenses',
        icon: LucideIcons.receipt,
        target: tesorero
            ? AppTourKeys.gastosAgregar
            : AppTourKeys.gastosResumen,
        title: tesorero ? 'Registrar un gasto' : 'En qué se gastó',
        body: tesorero
            ? 'El + abre el formulario del gasto: descripción, categoría, monto '
                  'y, si lo tienes, proveedor, NIT y número de factura. Esos '
                  'datos alimentan los documentos del profesor.'
            : 'Aquí ves el total gastado y el detalle de cada gasto, con su '
                  'categoría y su fecha.',
      ),
      if (tesorero)
        GuidedStep(
          route: '/members',
          icon: LucideIcons.userPlus,
          target: AppTourKeys.integrantesAgregar,
          title: 'Sumar integrantes',
          body:
              'El + crea un integrante con su carrera, semestre y documento. '
              'Desde su detalle puedes editar los datos o desactivarlo cuando '
              'deje el semillero.',
        ),
      GuidedStep(
        route: '/members',
        icon: LucideIcons.users,
        target: AppTourKeys.integrantesBuscar,
        title: 'Buscar y consultar',
        body:
            'Busca por nombre y abre el detalle de cada integrante para ver su '
            'historial de cuotas y aportes.',
      ),
      if (profesor)
        GuidedStep(
          route: '/documents',
          icon: LucideIcons.fileText,
          target: AppTourKeys.documentosSubir,
          title: 'Tus documentos, llenos solos',
          body:
              'Sube tu formato Word o Excel con las etiquetas de SemiFund una '
              'sola vez. La app lo llena con los datos del semillero y te lo '
              'entrega listo para descargar.',
        ),
      if (tesorero) ...<GuidedStep>[
        GuidedStep(
          route: '/accounts',
          icon: LucideIcons.shieldCheck,
          target: AppTourKeys.cuentasTitulo,
          title: 'Cuentas y roles',
          body:
              'Aprueba o rechaza solicitudes para entrar al semillero y decide '
              'quién es tesorero. Cada cambio queda registrado en la '
              'actividad.',
        ),
        GuidedStep(
          route: '/invite',
          icon: LucideIcons.userPlus,
          target: AppTourKeys.invitarTitulo,
          title: 'Invitar con el código',
          body:
              'Comparte el código del semillero. Quien lo reciba envía su '
              'solicitud y tú la apruebas desde Cuentas.',
        ),
        GuidedStep(
          route: '/activity',
          icon: LucideIcons.history,
          target: AppTourKeys.actividadTitulo,
          title: 'Actividad y auditoría',
          body:
              'Aquí queda quién creó, editó o eliminó cada registro, con la '
              'fecha. Sirve para rendir cuentas ante el semillero.',
        ),
      ],
      GuidedStep(
        route: '/profile',
        icon: LucideIcons.userRound,
        target: AppTourKeys.perfilTitulo,
        title: 'Tu perfil',
        body:
            'Edita tus datos académicos, cambia la contraseña y repite esta '
            'introducción cuando quieras. El tipo de usuario (estudiante o '
            'profesor) queda fijo al completar el perfil.',
      ),
      GuidedStep(
        route: '/semilleros',
        icon: LucideIcons.building2,
        target: AppTourKeys.semillerosTitulo,
        title: 'Tus semilleros',
        body:
            'Cambia de semillero, crea uno nuevo o únete con un código. Cada '
            'semillero tiene su propio saldo, integrantes y movimientos.',
      ),
      if (tesorero)
        GuidedStep(
          route: '/semilleros/settings',
          icon: LucideIcons.settings,
          target: AppTourKeys.semillerosDatos,
          title: 'Datos que van en los documentos',
          body:
              'Aquí guardas la ciudad y el centro de costos, y ajustas el saldo '
              'inicial del semillero. Son los datos que aparecen en los '
              'documentos que genera el profesor.',
        ),
      GuidedStep(
        route: '/home',
        icon: LucideIcons.check,
        title: 'Listo',
        body:
            'Eso es todo. Si olvidas algo, entra a tu perfil y elige '
            '"Ver introducción" para repetir el recorrido.',
      ),
    ];
  }
}
