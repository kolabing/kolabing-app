// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Kolabing';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonNext => 'Siguiente';

  @override
  String get commonBack => 'Atrás';

  @override
  String get commonDone => 'Hecho';

  @override
  String get commonErrorGeneric => 'Algo ha salido mal. Inténtalo de nuevo.';

  @override
  String get welcomeLogIn => 'Iniciar sesión';

  @override
  String get welcomeHeadlineLine1 => 'Donde las marcas locales';

  @override
  String get welcomeHeadlineLine2 => 'se unen a comunidades reales.';

  @override
  String get welcomeSubtitle =>
      'Colaboraciones lideradas por comunidades para eventos, contenido (UGC), reseñas y crecimiento real.';

  @override
  String get welcomeGetStarted => 'Empezar';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get languageScreenTitle => 'Idioma';

  @override
  String get languageSystemDefault => 'Predeterminado del sistema';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageCatalan => 'Català';

  @override
  String get applicationReviewTitle => 'SOLICITUD';

  @override
  String get applicationReviewLoadError => 'No se pudo cargar la solicitud';

  @override
  String get applicationReviewNotFound => 'Solicitud no encontrada';

  @override
  String get applicationReviewMessageLabel => 'Mensaje';

  @override
  String get applicationReviewNoMessage => 'No se proporcionó ningún mensaje';

  @override
  String get applicationReviewAvailabilityLabel => 'Disponibilidad';

  @override
  String get applicationReviewNotSpecified => 'No especificada';

  @override
  String get applicationReviewAppliedLabel => 'Aplicó';

  @override
  String get applicationReviewUnknownOpportunity => 'Oportunidad desconocida';

  @override
  String get applicationReviewViewFullProfile => 'Ver perfil completo';

  @override
  String get applicationReviewStatusAccepted => 'Aceptada';

  @override
  String get applicationReviewStatusAcceptedDesc =>
      'Esta solicitud ha sido aceptada. Puedes chatear con quien la envió.';

  @override
  String get applicationReviewStatusDeclined => 'Rechazada';

  @override
  String applicationReviewStatusDeclinedReason(String reason) {
    return 'Rechazada: $reason';
  }

  @override
  String get applicationReviewStatusDeclinedDesc =>
      'Esta solicitud ha sido rechazada.';

  @override
  String get applicationReviewStatusWithdrawn => 'Retirada';

  @override
  String get applicationReviewStatusWithdrawnDesc =>
      'Quien la envió ha retirado su solicitud.';

  @override
  String get applicationReviewStatusPending => 'Pendiente';

  @override
  String get applicationReviewOpenChat => 'ABRIR CHAT';

  @override
  String get applicationReviewDecline => 'RECHAZAR';

  @override
  String get applicationReviewAccept => 'ACEPTAR';

  @override
  String get applicationReviewDeclineDialogTitle => 'Rechazar solicitud';

  @override
  String applicationReviewDeclineDialogBody(String name) {
    return '¿Seguro que quieres rechazar esta solicitud de $name?';
  }

  @override
  String get applicationReviewDeclineReasonHint => 'Motivo (opcional)';

  @override
  String get applicationReviewDeclineDialogConfirm => 'Rechazar';

  @override
  String get applicationReviewDeclinedSnack => 'Solicitud rechazada';

  @override
  String get acceptFormTitle => 'Aceptar solicitud';

  @override
  String get acceptFormSubtitle =>
      'Elige una fecha para el kolab; seguirás la conversación en el chat después de aceptar.';

  @override
  String get acceptFormScheduledDate => 'FECHA PROGRAMADA';

  @override
  String get acceptFormNoDates =>
      'No hay fechas futuras disponibles dentro del rango de la oportunidad.';

  @override
  String get acceptFormConfirm => 'CONFIRMAR ACEPTACIÓN';

  @override
  String get acceptFormAcceptedSnack => '¡Solicitud aceptada! Kolab creado.';

  @override
  String get acceptFormError =>
      'No se pudo aceptar la solicitud. Inténtalo de nuevo.';

  @override
  String get applicationsTitle => 'SOLICITUDES';

  @override
  String get applicationsTabSent => 'ENVIADAS';

  @override
  String get applicationsTabReceived => 'RECIBIDAS';

  @override
  String get applicationsSentEmptyTitle => 'Aún no hay solicitudes';

  @override
  String get applicationsSentEmptyBody =>
      'Empieza a explorar oportunidades y solicita kolabs con negocios y comunidades.';

  @override
  String get applicationsReceivedEmptyTitle => 'No hay solicitudes recibidas';

  @override
  String get applicationsReceivedEmptyBody =>
      'Cuando alguien solicite tus oportunidades, aparecerán aquí.';

  @override
  String get applicationsErrorTitle => 'Algo salió mal';

  @override
  String applicationCardFrom(String name) {
    return 'De: $name';
  }

  @override
  String applicationCardTo(String name) {
    return 'Para: $name';
  }

  @override
  String get applicationStatusPending => 'Pendiente';

  @override
  String get applicationStatusAccepted => 'Aceptada';

  @override
  String get applicationStatusDeclined => 'Rechazada';

  @override
  String get applicationStatusWithdrawn => 'Retirada';

  @override
  String get chatApplicationNotFound => 'Solicitud no encontrada';

  @override
  String get chatResubscribeBanner =>
      'Tu suscripción ha caducado. Vuelve a suscribirte para continuar este chat.';

  @override
  String get chatResubscribeAction => 'RESUSCRIBIRSE';

  @override
  String get chatLoading => 'Cargando...';

  @override
  String get chatDateToday => 'Hoy';

  @override
  String get chatDateYesterday => 'Ayer';

  @override
  String get chatMessageHint => 'Escribe un mensaje...';

  @override
  String get chatSessionExpiredTitle => 'Sesión caducada';

  @override
  String get chatSessionExpiredBody => 'Inicia sesión de nuevo para continuar.';

  @override
  String get chatSignIn => 'Iniciar sesión';

  @override
  String get chatEmptyTitle => 'Inicia la conversación';

  @override
  String get chatEmptyBody =>
      'Envía un mensaje para empezar a hablar de este kolab';

  @override
  String get chatViewOpportunity => 'Ver oportunidad';

  @override
  String get chatCancelApplication => 'Cancelar solicitud';

  @override
  String get chatCancelDialogTitle => '¿Cancelar solicitud?';

  @override
  String get chatCancelDialogBody =>
      '¿Seguro que quieres cancelar esta solicitud? Esta acción no se puede deshacer.';

  @override
  String get chatCancelDialogKeep => 'No, mantenerla';

  @override
  String get chatCancelDialogWithdraw => 'Sí, retirar';

  @override
  String get chatApplicationWithdrawn => 'Solicitud retirada';

  @override
  String get applyModalHeader => 'NUEVA SOLICITUD';

  @override
  String get applyModalMessageTitle => 'Tu mensaje';

  @override
  String get applyModalMessageHelp =>
      'Una breve presentación te ayuda a destacar; menciona qué aportas y por qué encajas.';

  @override
  String get applyModalMessageHint =>
      'Cuéntales por qué eres perfecto para este kolab y qué valor puedes aportar...';

  @override
  String get applyModalSelectDatesTitle => 'Selecciona fecha(s)';

  @override
  String get applyModalSelectDatesHelp =>
      'Elige entre las fechas disponibles para este kolab';

  @override
  String get applyModalSelectDateError => 'Selecciona al menos una fecha';

  @override
  String get applyModalNoDates => 'No hay fechas disponibles para este kolab';

  @override
  String get applyModalNotesLabel => 'Notas adicionales (opcional)';

  @override
  String get applyModalNotesHint =>
      'p. ej., Flexible con el horario, prefiero las mañanas...';

  @override
  String get applyModalTimeFrom => 'Desde';

  @override
  String get applyModalTimeTo => 'Hasta';

  @override
  String get applyModalOptionalBadge => 'Opcional';

  @override
  String get applyModalUnknownHost => 'Anfitrión desconocido';

  @override
  String get applyModalHostFallback => 'Anfitrión';

  @override
  String get applyModalApplyingTo => 'Estás solicitando a';

  @override
  String get applyModalWhatsOffered => 'Qué se ofrece';

  @override
  String get applyModalTip =>
      'Elige las fechas que te vengan bien y añade un mensaje breve; las solicitudes con detalles se aceptan más rápido.';

  @override
  String get applyModalSending => 'ENVIANDO…';

  @override
  String get applyModalSend => 'ENVIAR SOLICITUD';

  @override
  String get applyModalAlreadyApplied => 'Ya has solicitado esta oportunidad';

  @override
  String get applyModalSubmitError =>
      'No se pudo enviar la solicitud. Inténtalo de nuevo.';

  @override
  String get commonDismiss => 'Descartar';

  @override
  String get commonGotIt => 'Entendido';

  @override
  String get authEmailLabel => 'Correo electrónico';

  @override
  String get authEmailHint => 'tu@correo.com';

  @override
  String get authPasswordLabel => 'Contraseña';

  @override
  String get authConfirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get authEmailRequired => 'El correo electrónico es obligatorio';

  @override
  String get authEmailInvalid => 'Introduce un correo electrónico válido';

  @override
  String get authPasswordRequired => 'La contraseña es obligatoria';

  @override
  String get authPasswordTooShort =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get authConfirmPasswordRequired => 'Confirma tu contraseña';

  @override
  String get authPasswordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get authNoInternet => 'Sin conexión a internet. Comprueba tu red.';

  @override
  String get authUnexpectedError => 'Se ha producido un error inesperado';

  @override
  String get attendeeRegisterTitle => 'ÚNETE COMO ASISTENTE';

  @override
  String get attendeeRegisterSubtitle =>
      'Crea tu cuenta para unirte a eventos y completar retos';

  @override
  String get attendeeRegisterPasswordHint => 'Mín. 8 caracteres';

  @override
  String get attendeeRegisterConfirmPasswordHint =>
      'Vuelve a introducir tu contraseña';

  @override
  String get attendeeRegisterCreateAccount => 'CREAR CUENTA';

  @override
  String get attendeeRegisterTerms =>
      'Al crear una cuenta, aceptas nuestras Condiciones del servicio y Política de privacidad';

  @override
  String get loginPanelTitle => 'Inicia sesión en tu cuenta';

  @override
  String get loginPanelSubtitle => 'Retoma donde lo dejaste.';

  @override
  String get loginSignInButton => 'Iniciar sesión';

  @override
  String get loginForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get loginHeroWelcome => 'Bienvenido de nuevo.';

  @override
  String get loginSignUpLink => 'Registrarse';

  @override
  String get loginUserNotFoundTitle => 'Cuenta no encontrada';

  @override
  String get loginUserNotFoundMessage =>
      'No existe ninguna cuenta con este correo de Google. Crea una cuenta primero.';

  @override
  String get loginCreateAccountButton => 'Crear cuenta';

  @override
  String get forgotPasswordFormTitle => 'Restablece tu contraseña';

  @override
  String get forgotPasswordFormSubtitle =>
      'Introduce el correo de tu cuenta y te enviaremos un enlace seguro para restablecerla.';

  @override
  String get forgotPasswordHelperText =>
      'Si el correo coincide con una cuenta, el enlace de restablecimiento llegará en breve.';

  @override
  String get forgotPasswordSendButton => 'ENVIAR ENLACE DE RESTABLECIMIENTO';

  @override
  String get forgotPasswordSuccessTitle => 'Revisa tu bandeja de entrada';

  @override
  String get forgotPasswordSuccessSubtitle =>
      'Si existe una cuenta para este correo, el enlace de restablecimiento está en camino.';

  @override
  String get forgotPasswordBackToSignIn => 'VOLVER A INICIAR SESIÓN';

  @override
  String get forgotPasswordUseAnotherEmail => 'Usar otro correo';

  @override
  String get forgotPasswordHeroLine1 => 'RECUPERA EL ACCESO.';

  @override
  String get forgotPasswordHeroLine2 => 'VUELVE A ENTRAR.';

  @override
  String get forgotPasswordHeroLine3 => '¿CONTRASEÑA OLVIDADA?';

  @override
  String get forgotPasswordHeroSentLine1 => 'REVISA TU CORREO.';

  @override
  String get forgotPasswordHeroSentLine2 => 'ABRE EL ENLACE.';

  @override
  String get forgotPasswordHeroSentLine3 => 'YA CASI ESTÁS DENTRO.';

  @override
  String get resetPasswordTitle => 'RESTABLECER CONTRASEÑA';

  @override
  String get resetPasswordSubtitle =>
      'Introduce tu nueva contraseña a continuación.';

  @override
  String get resetPasswordNewLabel => 'Nueva contraseña';

  @override
  String get resetPasswordNewHint => 'Introduce la nueva contraseña';

  @override
  String get resetPasswordConfirmHint => 'Confirma la nueva contraseña';

  @override
  String get resetPasswordButton => 'RESTABLECER CONTRASEÑA';

  @override
  String get resetPasswordInvalidLink =>
      'Enlace de restablecimiento no válido. Solicita uno nuevo.';

  @override
  String get resetPasswordSuccessTitle => 'CONTRASEÑA RESTABLECIDA';

  @override
  String get resetPasswordSuccessMessage =>
      'Tu contraseña se ha restablecido correctamente. Te redirigimos al inicio de sesión...';

  @override
  String get resetPasswordGoToSignIn => 'IR A INICIAR SESIÓN';

  @override
  String get signInTitle => 'BIENVENIDO DE NUEVO';

  @override
  String get signInSubtitle => 'Inicia sesión para continuar';

  @override
  String get signInWithGoogle => 'Iniciar sesión con Google';

  @override
  String get signInWithApple => 'Iniciar sesión con Apple';

  @override
  String get authOrContinueWith => 'o continúa con';

  @override
  String get signInNoAccount => '¿No tienes una cuenta?';

  @override
  String get signInSignUp => 'Registrarse';

  @override
  String get signInTypeMismatchTitle => 'Tipo de cuenta incorrecto';

  @override
  String signInTypeMismatchMessage(String type) {
    return 'Esta cuenta de Google está registrada como usuario $type. Inicia sesión desde la pantalla correcta.';
  }

  @override
  String get signInTypeMismatchDifferent => 'diferente';

  @override
  String get splashSemanticLabel => 'Kolabing - Cargando la aplicación';

  @override
  String authLinkSemanticLabel(String leading, String action) {
    return '$leading Toca $action para navegar';
  }

  @override
  String get kolabingLogoSemanticLabel => 'Logotipo de Kolabing';

  @override
  String get selectionCardBusinessTitle => 'SOY UN NEGOCIO';

  @override
  String get selectionCardCommunityTitle => 'SOY UNA COMUNIDAD';

  @override
  String get selectionCardAttendeeTitle => 'SOY UN ASISTENTE';

  @override
  String get selectionCardBusinessDescription =>
      'Busco comunidades con las que colaborar';

  @override
  String get selectionCardCommunityDescription =>
      'Busco patrocinadores y socios para kolabs';

  @override
  String get selectionCardAttendeeDescription =>
      'Unirme a eventos y completar retos';

  @override
  String selectionCardSemanticLabel(String title, String description) {
    return '$title. $description';
  }

  @override
  String get businessNavHome => 'Inicio';

  @override
  String get businessNavExplore => 'Explorar';

  @override
  String get businessNavMyKolabs => 'Mis Kolabs';

  @override
  String get businessNavProfile => 'Perfil';

  @override
  String get businessMainCreateKolabTooltip => 'Crear solicitud de Kolab';

  @override
  String get businessProfileSignOutTitle => 'Cerrar sesión';

  @override
  String get businessProfileSignOutMessage =>
      '¿Seguro que quieres cerrar sesión?';

  @override
  String get businessProfileSignOut => 'Cerrar sesión';

  @override
  String get businessProfileDeleteAccountTitle => 'Eliminar cuenta';

  @override
  String get businessProfileDeleteAccountMessage =>
      '¿Seguro que quieres eliminar tu cuenta? Esta acción no se puede deshacer.';

  @override
  String get businessProfileDelete => 'Eliminar';

  @override
  String get businessProfileDeleteAccount => 'Eliminar cuenta';

  @override
  String get businessProfileChangePhotoTitle => 'Cambiar foto de perfil';

  @override
  String get businessProfileTakePhoto => 'Hacer foto';

  @override
  String get businessProfileTakePhotoSubtitle => 'Usa la cámara';

  @override
  String get businessProfileChooseFromGallery => 'Elegir de la galería';

  @override
  String get businessProfileChooseFromGallerySubtitle =>
      'Selecciona una foto existente';

  @override
  String get businessProfileUploadingPhoto => 'Subiendo foto...';

  @override
  String get businessProfilePhotoUpdated => 'Foto de perfil actualizada';

  @override
  String get businessProfilePhotoUpdateFailed =>
      'No se pudo actualizar la foto';

  @override
  String get businessProfileDismiss => 'Descartar';

  @override
  String get businessProfileLoadFailed => 'No se pudo cargar el perfil';

  @override
  String get businessProfileSomethingWrong => 'Algo salió mal';

  @override
  String get businessProfileTryAgain => 'REINTENTAR';

  @override
  String get businessProfileBusinessFallback => 'Empresa';

  @override
  String get businessProfileAbout => 'Acerca de';

  @override
  String get businessProfileSubscription => 'Suscripción';

  @override
  String get businessProfilePremiumPlan => 'Plan Premium';

  @override
  String get businessProfileNoActivePlan => 'Sin plan activo';

  @override
  String get businessProfileRenews => 'Se renueva';

  @override
  String get businessProfileRemaining => 'Restante';

  @override
  String businessProfileDaysRemaining(num count) {
    return '$count días';
  }

  @override
  String get businessProfileSubscriptionEnding =>
      'La suscripción finaliza al acabar el periodo de facturación actual';

  @override
  String get businessProfileManageSubscription => 'GESTIONAR SUSCRIPCIÓN';

  @override
  String get businessProfileUpgradePremium => 'PASAR A PREMIUM';

  @override
  String get businessProfileStatusActive => 'Activa';

  @override
  String get businessProfileStatusCancelled => 'Cancelada';

  @override
  String get businessProfileStatusPastDue => 'Vencida';

  @override
  String get businessProfileStatusInactive => 'Inactiva';

  @override
  String get businessProfileContactInfo => 'Información de contacto';

  @override
  String get businessProfileNotifications => 'Notificaciones';

  @override
  String get businessProfileNotifMessages => 'Mensajes';

  @override
  String get businessProfileNotifApplications => 'Avisos de solicitudes';

  @override
  String get businessProfileNotifKolabUpdates => 'Actualizaciones de Kolab';

  @override
  String get businessProfileNotifRewards => 'Recompensas y monedero';

  @override
  String get businessProfileNotifMarketing => 'Marketing y consejos';

  @override
  String get businessProfileAccount => 'Cuenta';

  @override
  String get communityOfferDetailUnknown => 'Desconocido';

  @override
  String get communityOfferDetailSubscribeToReveal => 'Suscríbete para revelar';

  @override
  String communityOfferDetailApplicationsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count solicitudes',
      one: '$count solicitud',
      zero: 'Sin solicitudes',
    );
    return '$_temp0';
  }

  @override
  String get communityOfferDetailCategories => 'CATEGORÍAS';

  @override
  String get communityOfferDetailBusinessOffer => 'OFERTA DE LA EMPRESA';

  @override
  String get communityOfferDetailVenueProvided => 'Local incluido';

  @override
  String get communityOfferDetailFoodDrink => 'Comida y bebida incluidas';

  @override
  String communityOfferDetailDiscountPct(num percent) {
    return '$percent% de descuento';
  }

  @override
  String get communityOfferDetailDiscountOffered => 'Descuento ofrecido';

  @override
  String get communityOfferDetailExpectedDeliverables =>
      'ENTREGABLES ESPERADOS';

  @override
  String get communityOfferDetailSocialMedia => 'Contenido en redes sociales';

  @override
  String get communityOfferDetailEventActivation => 'Activación de evento';

  @override
  String get communityOfferDetailProductPlacement =>
      'Emplazamiento de producto';

  @override
  String get communityOfferDetailCommunityReach => 'Alcance de la comunidad';

  @override
  String get communityOfferDetailReviewFeedback => 'Reseña y valoración';

  @override
  String get communityOfferDetailLocationTitle => 'UBICACIÓN Y DISPONIBILIDAD';

  @override
  String get communityOfferDetailCity => 'Ciudad';

  @override
  String get communityOfferDetailNotSpecified => 'Sin especificar';

  @override
  String get communityOfferDetailVenue => 'Local';

  @override
  String get communityOfferDetailAddress => 'Dirección';

  @override
  String get communityOfferDetailDates => 'Fechas';

  @override
  String get communityOfferDetailMode => 'Modo';

  @override
  String get communityOfferDetailPreviewMode => 'MODO VISTA PREVIA';

  @override
  String get communityOfferDetailAlreadyApplied => 'YA TE HAS POSTULADO';

  @override
  String get communityOfferDetailApplyNow => 'POSTULARSE AHORA';

  @override
  String get communityOfferDetailTitle => 'Detalles de la oportunidad';

  @override
  String get communityOfferDetailNotFound => 'Oportunidad no encontrada';

  @override
  String get communityOfferDetailPreviewBanner =>
      'Estás viendo la vista previa de este kolab como lo ven las empresas';

  @override
  String get communityOfferDetailPastEvents =>
      'Eventos anteriores de esta comunidad';

  @override
  String get communityOfferDetailPastEventsSubtitle =>
      'Consulta el historial reciente de esta comunidad antes de postularte.';

  @override
  String get communityOfferDetailTheOffer => 'LA OFERTA';

  @override
  String get communityOfferDetailExtraTerms =>
      'CONDICIONES EXTRA DESBLOQUEADAS';

  @override
  String get communityOfferDetailExtraTermsSubtitle =>
      'Esto solo se muestra porque ya te has postulado.';

  @override
  String communityOfferDetailTriggerCondition(String condition) {
    return 'SI $condition';
  }

  @override
  String get exploreRecommendedMatches => 'Coincidencias recomendadas para ti';

  @override
  String get exploreBrowseAll => 'Explora todos los kolabs abiertos';

  @override
  String exploreFilterNeeds(num count) {
    return 'Ofertas $count';
  }

  @override
  String exploreFilterTypes(num count) {
    return 'Tipos $count';
  }

  @override
  String exploreFilterOffers(num count) {
    return 'Ofertas $count';
  }

  @override
  String exploreFilterKolab(num count) {
    return 'Kolab $count';
  }

  @override
  String exploreResultCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '$count resultado',
      zero: 'Sin resultados',
    );
    return '$_temp0';
  }

  @override
  String get exploreEmptyNoResults => 'No se encontraron resultados';

  @override
  String get exploreEmptyNoRecommended =>
      'Aún no hay coincidencias recomendadas';

  @override
  String get exploreEmptyNoOpportunities => 'Aún no hay oportunidades';

  @override
  String get exploreEmptyNoResultsHint =>
      'Prueba a ampliar los filtros o a cambiar de pestaña.';

  @override
  String get exploreEmptyNoRecommendedHint =>
      'Cambia a Todos o vuelve más tarde para ver nuevos kolabs.';

  @override
  String get exploreEmptyNoOpportunitiesHint =>
      'Vuelve más tarde para ver nuevas oportunidades.';

  @override
  String get exploreClearFilters => 'Borrar todos los filtros';

  @override
  String get exploreSomethingWrong => 'Algo salió mal';

  @override
  String get exploreTryAgain => 'Reintentar';

  @override
  String get exploreFeedRecommended => 'Recomendados';

  @override
  String get exploreFeedAll => 'Todos';

  @override
  String get myKolabsTabPublished => 'Publicados';

  @override
  String get myKolabsTabDraft => 'Borradores';

  @override
  String get myKolabsPublished => '¡Kolab publicado!';

  @override
  String get myKolabsPublishFailed => 'No se pudo publicar';

  @override
  String get myKolabsClosed => 'Kolab cerrado';

  @override
  String get myKolabsCloseFailed => 'No se pudo cerrar';

  @override
  String get myKolabsDeleteTitle => 'Eliminar Kolab';

  @override
  String get myKolabsDeleteMessage =>
      '¿Seguro que quieres eliminar este kolab? Esta acción no se puede deshacer.';

  @override
  String get myKolabsDelete => 'Eliminar';

  @override
  String get myKolabsDeleted => 'Kolab eliminado';

  @override
  String get myKolabsDeleteFailed => 'No se pudo eliminar';

  @override
  String get myKolabsTitle => 'MIS KOLABS';

  @override
  String get myKolabsSubtitle => 'Gestiona tus kolabs';

  @override
  String myKolabsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kolabs',
      one: '$count kolab',
      zero: '0 kolabs',
    );
    return '$_temp0';
  }

  @override
  String get myKolabsEmptyTitle => 'Aún no tienes kolabs';

  @override
  String get myKolabsEmptyMessage =>
      'Crea tu primer kolab para empezar a conectar con comunidades';

  @override
  String get myKolabsCreate => 'Crear Kolab';

  @override
  String get myKolabsSomethingWrong => 'Algo salió mal';

  @override
  String get myKolabsTryAgain => 'Reintentar';

  @override
  String get kolabReviewSheetTitle => '¿Qué tal fue el Kolab? ⭐';

  @override
  String kolabReviewSheetSubtitle(String partnerName) {
    return 'Tu reseña ayuda a $partnerName a generar confianza en Kolabing.';
  }

  @override
  String get kolabReviewSheetCommentHint => '¿Algo que añadir? (opcional)';

  @override
  String get kolabReviewSheetWouldAgain => '¿Harías otro Kolab?';

  @override
  String get kolabReviewSheetYes => 'Sí';

  @override
  String get kolabReviewSheetNo => 'No';

  @override
  String get kolabReviewSheetSubmitXp => 'Enviar +10 XP ✨';

  @override
  String get kolabReviewSheetSkip => 'Omitir por ahora';

  @override
  String get kolabCompletionConfirmTitle => '¿Se hizo el Kolab? 🎯';

  @override
  String kolabCompletionConfirmSubtitle(String partnerName) {
    return 'Marca tu Kolab con $partnerName como completado.';
  }

  @override
  String get kolabCompletionConfirmLoading => 'Completando…';

  @override
  String get kolabCompletionConfirmCta => 'Sí, completar Kolab ✨';

  @override
  String get kolabCompletionConfirmDismiss => 'Todavía no';

  @override
  String get kolabCompletionFeedbackTitle => '¿Qué tal fue el Kolab? ⭐';

  @override
  String kolabCompletionFeedbackSubtitle(String partnerName) {
    return 'Los comentarios son obligatorios para terminar. Tu reseña ayuda a $partnerName a generar confianza en Kolabing.';
  }

  @override
  String get kolabCompletionFeedbackCommentHint =>
      '¿Algo que añadir? (opcional)';

  @override
  String get kolabCompletionFeedbackWouldAgain => '¿Harías otro Kolab?';

  @override
  String get kolabCompletionFeedbackYes => 'Sí';

  @override
  String get kolabCompletionFeedbackNo => 'No';

  @override
  String get kolabCompletionFeedbackSubmitting => 'Enviando…';

  @override
  String get kolabCompletionFeedbackSubmit => 'Enviar y terminar';

  @override
  String get kolabCompletionFeedbackTapStar => 'Toca una estrella para puntuar';

  @override
  String get kolabCompletionFeedbackFinishLater => 'Terminar más tarde';

  @override
  String get kolabCompletionSheetFeedbackError =>
      'No se pudieron enviar los comentarios. Inténtalo de nuevo.';

  @override
  String get kolabCompletionCelebrationTitle => '¡Kolab completado! 🎉';

  @override
  String get kolabCompletionCelebrationBody =>
      'Has ganado XP y tu perfil ahora refleja este Kolab completado.';

  @override
  String kolabCompletionXpEarned(num xp) {
    return '+$xp XP ganados ⚡';
  }

  @override
  String get kolabCompletionCelebrationCta => 'Ver mi XP →';

  @override
  String get kolabCompletionDoneTitle => '¡Todo listo! 🏆';

  @override
  String get kolabCompletionDoneBody =>
      'Este Kolab está completado. Revisa tu perfil para ver tu historial creciente de colaboraciones.';

  @override
  String kolabCompletionDoneXp(num xp) {
    return '+$xp XP';
  }

  @override
  String get kolabCompletionDoneXpLabel => 'XP ganados';

  @override
  String get kolabCompletionDoneClose => 'Cerrar';

  @override
  String get collaborationDetailNotFound => 'Kolab no encontrado';

  @override
  String get collaborationDetailRescheduleHelp => 'Reprogramar Kolab';

  @override
  String get collaborationDetailStartTimeHelp => 'Hora de inicio (opcional)';

  @override
  String get collaborationDetailScheduleUpdated => 'Horario actualizado.';

  @override
  String collaborationDetailScheduleUpdateError(String error) {
    return 'No se pudo actualizar el horario: $error';
  }

  @override
  String get collaborationDetailEventDetails => 'DETALLES DEL EVENTO';

  @override
  String get collaborationDetailEdit => 'EDITAR';

  @override
  String get collaborationDetailDateLabel => 'Fecha';

  @override
  String get collaborationDetailTimeLabel => 'Hora';

  @override
  String get collaborationDetailVenueLabel => 'Lugar';

  @override
  String collaborationDetailVenueValue(String businessName) {
    return '$businessName (Local del negocio)';
  }

  @override
  String get collaborationDetailCommunityReachLabel =>
      'Alcance de la comunidad';

  @override
  String get collaborationDetailReachIncluded => 'Incluido';

  @override
  String get collaborationDetailReachNotSpecified => 'No especificado';

  @override
  String get collaborationDetailBusinessPartner => 'SOCIO COMERCIAL';

  @override
  String get collaborationDetailCommunityPartner => 'SOCIO DE LA COMUNIDAD';

  @override
  String get collaborationDetailOffersTitleBusiness => 'LO QUE OFRECES';

  @override
  String get collaborationDetailOffersTitleCommunity => 'LO QUE SE OFRECE';

  @override
  String get collaborationDetailOfferVenue => 'Local incluido';

  @override
  String get collaborationDetailOfferFoodDrink => 'Comida y bebida incluidas';

  @override
  String get collaborationDetailOfferSocialMedia =>
      'Visibilidad en redes sociales';

  @override
  String get collaborationDetailOfferContentCreation =>
      'Apoyo en creación de contenido';

  @override
  String collaborationDetailOfferDiscount(num percentage) {
    return 'Descuento: $percentage%';
  }

  @override
  String get collaborationDetailDeliverablesTitleBusiness =>
      'ENTREGABLES ESPERADOS';

  @override
  String get collaborationDetailDeliverablesTitleCommunity =>
      'LO QUE ENTREGARÁS';

  @override
  String get collaborationDetailDeliverableSocialContent =>
      'Contenido en redes sociales';

  @override
  String get collaborationDetailDeliverableEventActivation =>
      'Activación del evento';

  @override
  String get collaborationDetailDeliverableProductPlacement =>
      'Emplazamiento de producto';

  @override
  String get collaborationDetailDeliverableCommunityReach =>
      'Alcance de la comunidad';

  @override
  String get collaborationDetailDeliverableReviewFeedback =>
      'Reseña y comentarios';

  @override
  String get collaborationDetailContactTitle => 'CONTACTO';

  @override
  String get collaborationDetailContactEmail => 'Correo electrónico';

  @override
  String get collaborationDetailProcessTitle => 'PROCESO';

  @override
  String get collaborationDetailGamificationTitle =>
      'CONFIGURACIÓN DE GAMIFICACIÓN';

  @override
  String collaborationDetailSelectedCount(num count) {
    return '$count seleccionados';
  }

  @override
  String get collaborationDetailGamificationDescription =>
      'Selecciona retos para que los asistentes completen durante el evento. Estarán disponibles en la app de asistentes.';

  @override
  String get collaborationDetailNoChallengesTitle => 'Aún no hay retos';

  @override
  String get collaborationDetailNoChallengesBody =>
      'Añade retos para que el evento sea más atractivo para los asistentes';

  @override
  String get collaborationDetailPoints => 'pts';

  @override
  String get collaborationDetailCustomChallengeSoon =>
      'La creación de retos personalizados estará disponible pronto';

  @override
  String get collaborationDetailAddCustomChallenge =>
      'AÑADIR RETO PERSONALIZADO';

  @override
  String get collaborationDetailQrTitle => 'REGISTRO CON CÓDIGO QR';

  @override
  String get collaborationDetailQrPlaceholder => 'Código QR';

  @override
  String get collaborationDetailQrGeneratedOnDay =>
      'Se genera el día del evento';

  @override
  String get collaborationDetailQrDescription =>
      'Los asistentes escanean este código QR en tu evento para registrarse y empezar a completar retos.';

  @override
  String get collaborationDetailQrUnavailable =>
      'El código QR estará disponible cuando se cree el evento';

  @override
  String get collaborationDetailViewQr => 'VER CÓDIGO QR';

  @override
  String get collaborationDetailResubscribeTitle =>
      'Vuelve a suscribirte para continuar';

  @override
  String get collaborationDetailResubscribeBody =>
      'Tu suscripción ha caducado, así que este Kolab en curso y su chat están en pausa por tu parte. La comunidad mantiene el acceso completo. Vuelve a suscribirte para retomarlo donde lo dejaste.';

  @override
  String get collaborationDetailResubscribeCta => 'VOLVER A SUSCRIBIRSE';

  @override
  String get collaborationDetailLoadError => 'No se pudo cargar el Kolab';

  @override
  String get collaborationDetailTodayBannerTitle => '¡El Kolab de hoy!';

  @override
  String collaborationDetailTodayBannerBody(String partnerName) {
    return 'Tu Kolab con $partnerName es hoy. Cuando esté activo podrás marcarlo como completado.';
  }

  @override
  String get collaborationDetailCompleteTitleToday =>
      '¡Completa el Kolab de hoy!';

  @override
  String get collaborationDetailCompleteTitle => '¿Kolab completado?';

  @override
  String collaborationDetailCompleteBodyToday(String partnerName) {
    return '¿Se hizo tu Kolab con $partnerName? Márcalo como completado.';
  }

  @override
  String collaborationDetailCompleteBody(String partnerName) {
    return '¿Se hizo el Kolab con $partnerName? Márcalo como completado.';
  }

  @override
  String get collaborationDetailMarkDone => 'Marcar como completado ✨';

  @override
  String get collaborationDetailItHappened => 'Sí, se hizo ✨';

  @override
  String get collaborationDetailReviewSubmitted => 'Reseña enviada ✓';

  @override
  String get collaborationDetailLeaveReview => 'Deja una reseña';

  @override
  String get collaborationDetailXpBadge => '+10 XP';

  @override
  String collaborationDetailReviewHelp(String partnerName) {
    return 'Ayuda a $partnerName a generar confianza en Kolabing.';
  }

  @override
  String get collaborationDetailLeaveReviewCta => 'Dejar reseña +10 XP ✨';

  @override
  String get communityMainNavHome => 'Inicio';

  @override
  String get communityMainNavExplore => 'Explorar';

  @override
  String get communityMainNavMyKolabs => 'Mis Kolabs';

  @override
  String get communityMainNavCommunity => 'Comunidad';

  @override
  String get communityMainNavProfile => 'Perfil';

  @override
  String get communityMainCreateOpportunityTooltip => 'Crear oportunidad';

  @override
  String get communityProfileSignOutTitle => 'Cerrar sesión';

  @override
  String get communityProfileSignOutBody =>
      '¿Seguro que quieres cerrar sesión?';

  @override
  String get communityProfileSignOutConfirm => 'Cerrar sesión';

  @override
  String get communityProfileSignOutButton => 'CERRAR SESIÓN';

  @override
  String get communityProfileDeleteAccountTitle => 'Eliminar cuenta';

  @override
  String get communityProfileDeleteAccountBody =>
      '¿Seguro que quieres eliminar tu cuenta? Esta acción no se puede deshacer.';

  @override
  String get communityProfileDeleteAccountConfirm => 'Eliminar';

  @override
  String get communityProfileDeleteAccountLink => 'Eliminar cuenta';

  @override
  String get communityProfileChangePhotoTitle => 'Cambiar foto de perfil';

  @override
  String get communityProfileTakePhoto => 'Hacer foto';

  @override
  String get communityProfileTakePhotoSubtitle => 'Usa tu cámara';

  @override
  String get communityProfileChooseFromGallery => 'Elegir de la galería';

  @override
  String get communityProfileChooseFromGallerySubtitle =>
      'Selecciona una foto existente';

  @override
  String get communityProfileUploadingPhoto => 'Subiendo foto...';

  @override
  String get communityProfilePhotoUpdated => 'Foto de perfil actualizada';

  @override
  String communityProfilePhotoUpdateFailed(String error) {
    return 'No se pudo actualizar la foto: $error';
  }

  @override
  String get communityProfileDismiss => 'Descartar';

  @override
  String get communityProfileLoadFailed => 'No se pudo cargar el perfil';

  @override
  String get communityProfileErrorTitle => 'Algo salió mal';

  @override
  String get communityProfileTryAgain => 'REINTENTAR';

  @override
  String get communityProfileCommunityFallback => 'Comunidad';

  @override
  String communityProfileLevelChip(int level, String title, int xp) {
    return 'NIV. $level · $title · $xp XP';
  }

  @override
  String get communityProfileAboutSection => 'Acerca de';

  @override
  String get communityProfileContactInfoSection => 'Información de contacto';

  @override
  String get communityProfileNotificationsSection => 'Notificaciones';

  @override
  String get communityProfileNotifMessages => 'Mensajes';

  @override
  String get communityProfileNotifApplications => 'Avisos de solicitudes';

  @override
  String get communityProfileNotifKolabUpdates => 'Novedades de Kolabs';

  @override
  String get communityProfileNotifRewards => 'Recompensas y monedero';

  @override
  String get communityProfileNotifMarketing => 'Marketing y consejos';

  @override
  String get communityProfileAccountSection => 'Cuenta';

  @override
  String get createOpportunityEditTitle => 'Editar Kolab';

  @override
  String get createOpportunityCreateTitle => 'Crear un Kolab';

  @override
  String get createOpportunityStep0Title => 'INFORMACIÓN BÁSICA';

  @override
  String get createOpportunityStep0Subtitle => 'Describe tu idea de kolab';

  @override
  String get createOpportunityTitleLabel => 'Título';

  @override
  String get createOpportunityTitleHint =>
      'p. ej., Promoción de la Semana del Restaurante';

  @override
  String get createOpportunityDescriptionLabel => 'Descripción';

  @override
  String get createOpportunityDescriptionHint =>
      'Describe tu oportunidad de kolab en detalle. ¿Qué estás buscando?';

  @override
  String get createOpportunityCategoriesLabel => 'Categorías';

  @override
  String get createOpportunityCategoriesHint => 'Selecciona hasta 5 categorías';

  @override
  String get createOpportunityPhotoLabel => 'Foto del Kolab';

  @override
  String get createOpportunityPhotoHint =>
      'Opcional, pero recomendada para Explorar.';

  @override
  String get createOpportunityStep1Title => '¿QUÉ NECESITAS DE LA EMPRESA?';

  @override
  String get createOpportunityStep1Subtitle =>
      'Selecciona lo que tu comunidad espera en este kolab';

  @override
  String get createOpportunityOfferVenueTitle => 'Local';

  @override
  String get createOpportunityOfferVenueSubtitle =>
      'Necesitas un local para el evento';

  @override
  String get createOpportunityOfferFoodTitle => 'Comida y bebida';

  @override
  String get createOpportunityOfferFoodSubtitle =>
      'Te gustaría que se ofrezca comida o bebida';

  @override
  String get createOpportunityOfferDiscountTitle => 'Descuento';

  @override
  String get createOpportunityOfferDiscountSubtitle =>
      'Descuento especial para tu comunidad';

  @override
  String get createOpportunityDiscountPercentageLabel =>
      'Porcentaje de descuento';

  @override
  String get createOpportunityDiscountPercentageHint => 'p. ej., 20';

  @override
  String get createOpportunityOfferProductsTitle => 'Productos';

  @override
  String get createOpportunityOfferProductsSubtitle =>
      'Te gustaría recibir productos o muestras';

  @override
  String get createOpportunityProductNameHint => 'Nombre del producto';

  @override
  String get createOpportunityAddProduct => 'AÑADIR PRODUCTO';

  @override
  String get createOpportunityOfferOtherTitle => 'Otro';

  @override
  String get createOpportunityOfferOtherSubtitle => 'Otro apoyo de la empresa';

  @override
  String get createOpportunityOfferOtherDetailsLabel =>
      'Detalles de la otra oferta';

  @override
  String get createOpportunityOfferOtherDetailsHint =>
      'Describe lo que ofrece la empresa';

  @override
  String get createOpportunityStep2Title => 'ENTREGABLES DE LA COMUNIDAD';

  @override
  String get createOpportunityStep2Subtitle =>
      '¿Qué aportará la comunidad a cambio?';

  @override
  String get createOpportunityDelivSocialTitle => 'Contenido en redes sociales';

  @override
  String get createOpportunityDelivSocialSubtitle =>
      'Publicación de Instagram, Historia de Instagram, Reel / vídeo corto, vídeo de TikTok, contenido fotográfico (UGC para uso de marca)';

  @override
  String get createOpportunityDelivEventTitle => 'Activación en el evento';

  @override
  String get createOpportunityDelivEventSubtitle =>
      'Integración o mención de la marca durante nuestro evento';

  @override
  String get createOpportunityDelivProductTitle => 'Emplazamiento de producto';

  @override
  String get createOpportunityDelivProductSubtitle =>
      'Exhibición o visibilidad del producto durante nuestro evento';

  @override
  String get createOpportunityDelivReachTitle => 'Alcance de la comunidad';

  @override
  String get createOpportunityDelivReachSubtitle =>
      'Garantía de asistentes mínimos, acceso a nuestros miembros, difusión, código de descuento de la comunidad';

  @override
  String get createOpportunityDelivReviewTitle => 'Reseñas y comentarios';

  @override
  String get createOpportunityDelivReviewSubtitle =>
      'Reseñas en Google/redes, testimonios o comentarios de los miembros';

  @override
  String get createOpportunityDelivOtherTitle => 'Otro';

  @override
  String get createOpportunityDelivOtherSubtitle =>
      'Escribe tu propio entregable';

  @override
  String get createOpportunityDelivOtherDetailsLabel =>
      'Detalles del otro entregable';

  @override
  String get createOpportunityDelivOtherDetailsHint =>
      'Describe lo que aportará la comunidad';

  @override
  String get createOpportunityStep3Title => 'UBICACIÓN Y DISPONIBILIDAD';

  @override
  String get createOpportunityStep3Subtitle =>
      '¿Cuándo está disponible tu comunidad para este kolab?';

  @override
  String get createOpportunityAvailabilityLabel => 'Disponibilidad';

  @override
  String get createOpportunityVenueLabel => 'Local';

  @override
  String get createOpportunityAddressLabel => 'Dirección';

  @override
  String get createOpportunityAddressHint => 'Introduce la dirección del local';

  @override
  String get createOpportunityPreferredCityLabel => 'Ciudad preferida';

  @override
  String createOpportunityCitiesLoadError(String error) {
    return 'Error al cargar las ciudades: $error';
  }

  @override
  String get createOpportunitySelectCityHint => 'Selecciona una ciudad';

  @override
  String get createOpportunityAvailableFromLabel => 'Disponible desde';

  @override
  String get createOpportunityAvailableUntilLabel => 'Disponible hasta';

  @override
  String get createOpportunityTimeLabel => 'Hora';

  @override
  String get createOpportunityDayOfWeekLabel => 'Día de la semana';

  @override
  String get createOpportunitySelectTime => 'Selecciona una hora';

  @override
  String get createOpportunityStep4Title => 'REVISA TU OPORTUNIDAD';

  @override
  String get createOpportunityStep4Subtitle =>
      'Asegúrate de que todo esté correcto antes de publicar';

  @override
  String get createOpportunityReviewUntitled => 'Oportunidad sin título';

  @override
  String get createOpportunityReviewNoDescription => 'Sin descripción';

  @override
  String get createOpportunityReviewBusinessOffer => 'Oferta de la empresa';

  @override
  String get createOpportunityReviewDeliverables =>
      'Entregables de la comunidad';

  @override
  String get createOpportunityReviewNoCity => 'Ninguna ciudad seleccionada';

  @override
  String get createOpportunityReviewEditHint =>
      'Toca cualquier sección de arriba para editar';

  @override
  String get createOpportunityBackButton => 'ATRÁS';

  @override
  String get createOpportunityContinueButton => 'CONTINUAR';

  @override
  String get createOpportunityPublishButton => 'PUBLICAR';

  @override
  String get createOpportunitySaveDraftButton => 'GUARDAR BORRADOR';

  @override
  String get myOpportunitiesTabPublished => 'Publicadas';

  @override
  String get myOpportunitiesTabDraft => 'Borrador';

  @override
  String get myOpportunitiesPublishError =>
      'No se pudo publicar la oportunidad';

  @override
  String get myOpportunitiesPublishSuccess => '¡Oportunidad publicada!';

  @override
  String get myOpportunitiesShareUnavailable =>
      'No se puede compartir. Se ha copiado el enlace en su lugar.';

  @override
  String get myOpportunitiesShareFailed =>
      'No se pudo abrir el menú para compartir.';

  @override
  String get myOpportunitiesCloseError => 'No se pudo cerrar la oportunidad';

  @override
  String get myOpportunitiesCloseSuccess => 'Oportunidad cerrada';

  @override
  String get myOpportunitiesDeleteTitle => 'Eliminar oportunidad';

  @override
  String get myOpportunitiesDeleteBody =>
      '¿Seguro que quieres eliminar esta oportunidad? Esta acción no se puede deshacer.';

  @override
  String get myOpportunitiesDeleteConfirm => 'Eliminar';

  @override
  String get myOpportunitiesDeleteError => 'No se pudo eliminar la oportunidad';

  @override
  String get myOpportunitiesDeleteSuccess => 'Oportunidad eliminada';

  @override
  String get myOpportunitiesCreateNewTooltip => 'Crear nueva oportunidad';

  @override
  String get myOpportunitiesHeaderTitle => 'MIS OPORTUNIDADES';

  @override
  String get myOpportunitiesHeaderSubtitle =>
      'Crea y gestiona tus oportunidades';

  @override
  String myOpportunitiesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oportunidades',
      one: '1 oportunidad',
    );
    return '$_temp0';
  }

  @override
  String get myOpportunitiesEmptyTitle => 'Aún no hay oportunidades';

  @override
  String get myOpportunitiesEmptyBody =>
      'Crea tu primera oportunidad y empieza a conectar.';

  @override
  String get myOpportunitiesEmptyCreateButton => 'Crear oportunidad';

  @override
  String get myOpportunitiesErrorTitle => 'Algo salió mal';

  @override
  String myOpportunityCardApplicationsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count solicitudes',
      one: '1 solicitud',
    );
    return '$_temp0';
  }

  @override
  String get myOpportunityCardUntitled => 'Oportunidad sin título';

  @override
  String get myOpportunityCardActionView => 'Ver';

  @override
  String get myOpportunityCardActionEdit => 'Editar';

  @override
  String get myOpportunityCardActionPublish => 'Publicar';

  @override
  String get myOpportunityCardActionShare => 'Compartir';

  @override
  String get myOpportunityCardActionClose => 'Cerrar';

  @override
  String get myOpportunityCardActionDelete => 'Eliminar';

  @override
  String get opportunityPublishSuccessDraftTitle => '¡Borrador guardado!';

  @override
  String get opportunityPublishSuccessPublishedTitle =>
      '¡Oportunidad publicada!';

  @override
  String get opportunityPublishSuccessDraftBody =>
      'Tu oportunidad se ha guardado como borrador. Puedes editarla y publicarla más tarde.';

  @override
  String get opportunityPublishSuccessPublishedBody =>
      'Tu oportunidad ya está publicada. ¡Las empresas pueden empezar a postularse!';

  @override
  String get opportunityPublishSuccessShare => 'COMPARTIR';

  @override
  String get opportunityPublishSuccessViewOpportunities =>
      'VER MIS OPORTUNIDADES';

  @override
  String get eventDetailDeleteTitle => 'Eliminar evento';

  @override
  String eventDetailDeleteConfirm(String name) {
    return '¿Seguro que quieres eliminar \"$name\"? Esta acción no se puede deshacer.';
  }

  @override
  String get eventDetailDeleteAction => 'Eliminar';

  @override
  String get eventDetailDeletedSnack => 'Evento eliminado';

  @override
  String get eventDetailNotFound => 'Evento no encontrado';

  @override
  String get eventDetailPhotosTitle => 'Fotos';

  @override
  String get eventDetailVideosTitle => 'Vídeos';

  @override
  String get eventDetailDeleteButton => 'ELIMINAR EVENTO';

  @override
  String get eventDetailKolabWithLabel => 'Kolab con';

  @override
  String get eventDetailDateLabel => 'Fecha del evento';

  @override
  String get eventDetailAttendeesLabel => 'Asistentes';

  @override
  String eventDetailAttendeesCount(num count) {
    return '$count personas';
  }

  @override
  String eventDetailRecapVideoTitle(num number) {
    return 'Vídeo resumen $number';
  }

  @override
  String get eventDetailRecapVideoSubtitle => 'Toca para abrir el vídeo subido';

  @override
  String get eventDetailVideoOpenError =>
      'No se pudo abrir el enlace del vídeo';

  @override
  String get addEventTitle => 'Añadir evento pasado';

  @override
  String get addEventMaxPhotos => 'Máximo 5 fotos permitidas';

  @override
  String get addEventMaxVideos => 'Máximo 1 vídeo permitido';

  @override
  String get addEventAtLeastOnePhoto => 'Añade al menos una foto';

  @override
  String get addEventSuccess => 'Evento añadido correctamente';

  @override
  String get addEventFailure => 'No se pudo añadir el evento';

  @override
  String get addEventNameLabel => 'Nombre del evento';

  @override
  String get addEventNameHint => 'p. ej., Festival de Música de Verano';

  @override
  String get addEventNameError => 'Introduce el nombre del evento';

  @override
  String get addEventPartnerLabel => 'Kolab con';

  @override
  String get addEventPartnerHint => 'p. ej., Rock Community Istanbul';

  @override
  String get addEventPartnerError => 'Introduce el nombre del colaborador';

  @override
  String get addEventDateLabel => 'Fecha del evento';

  @override
  String get addEventAttendeeCountLabel => 'Número de asistentes';

  @override
  String get addEventAttendeeCountHint => 'p. ej., 250';

  @override
  String get addEventAttendeeCountError => 'Introduce el número de asistentes';

  @override
  String get addEventAttendeeCountInvalid => 'Introduce un número válido';

  @override
  String get addEventPhotosLabel => 'Fotos del evento';

  @override
  String addEventPhotosCounter(num count) {
    return '($count/5)';
  }

  @override
  String get addEventAddPhotoButton => 'Añadir foto';

  @override
  String get addEventVideoLabel => 'Vídeo resumen (opcional)';

  @override
  String get addEventVideoDescription =>
      'Añade un vídeo corto para mostrar cómo se vivió el evento.';

  @override
  String get addEventAddVideoButton => 'AÑADIR VÍDEO';

  @override
  String get addEventSubmitButton => 'AÑADIR EVENTO';

  @override
  String get pastEventsTitle => 'Eventos pasados';

  @override
  String get pastEventsAddButton => 'AÑADIR';

  @override
  String get pastEventsLoadError => 'No se pudieron cargar los eventos';

  @override
  String get pastEventsEmptyTitle => 'Aún no hay eventos';

  @override
  String get pastEventsEmptySubtitle =>
      'Comparte tus kolabs pasados con la comunidad';

  @override
  String get pastEventsEmptyAddButton => '+ Añadir un evento pasado';

  @override
  String get attendeeRoleLabel => 'Asistente';

  @override
  String get attendeeNavHome => 'Inicio';

  @override
  String get attendeeNavCommunities => 'Comunidades';

  @override
  String get attendeeNavScan => 'Escanear';

  @override
  String get attendeeNavProfile => 'Perfil';

  @override
  String get attendeeMyQrTitle => 'Mi QR de perfil';

  @override
  String get attendeeMyQrSubtitle =>
      'Muéstralo a un organizador para registrarte o conectar.';

  @override
  String get attendeeMyQrTooltip => 'Mi código QR';

  @override
  String get attendeeMyQrUnavailable => 'Tu QR de perfil aún no está listo.';

  @override
  String get attendeeHomeWelcomeBack => 'Bienvenido de nuevo';

  @override
  String get attendeeHomeNearbyEvents => 'EVENTOS CERCANOS';

  @override
  String attendeeHomeRadiusKm(String radius) {
    return '$radius km';
  }

  @override
  String get attendeeHomeGettingLocation => 'Obteniendo tu ubicación...';

  @override
  String get attendeeHomeSearchingEvents => 'Buscando eventos...';

  @override
  String attendeeHomeShowingWithinRadius(String radius) {
    return 'Mostrando eventos en un radio de $radius km';
  }

  @override
  String attendeeHomeEventsFound(num count) {
    return '$count encontrados';
  }

  @override
  String get attendeeHomeLoadMore => 'Cargar más';

  @override
  String get attendeeHomeStatPoints => 'Puntos';

  @override
  String get attendeeHomeStatChallenges => 'Retos';

  @override
  String get attendeeHomeStatEvents => 'Eventos';

  @override
  String get attendeeHomeLocationRequired => 'Ubicación necesaria';

  @override
  String get attendeeHomeTryAgain => 'Reintentar';

  @override
  String get attendeeHomeOpenSettings => 'Abrir ajustes';

  @override
  String get attendeeHomeNoEventsNearby => 'No hay eventos cerca';

  @override
  String get attendeeHomeNoEventsNearbyHint =>
      'Prueba a ampliar el radio de búsqueda\no vuelve más tarde para ver nuevos eventos.';

  @override
  String get attendeeHomeAdjustRadius => 'Ajustar radio';

  @override
  String get attendeeHomeFailedToLoadEvents =>
      'No se pudieron cargar los eventos';

  @override
  String get attendeeHomeSearchRadius => 'Radio de búsqueda';

  @override
  String get attendeeHomeApply => 'Aplicar';

  @override
  String get attendeeHomeLocationDenied => 'Permiso de ubicación denegado';

  @override
  String get attendeeHomeLocationDeniedForever =>
      'Los permisos de ubicación están denegados permanentemente. Actívalos en los ajustes.';

  @override
  String get attendeeHomeLocationServicesDisabled =>
      'Los servicios de ubicación están desactivados';

  @override
  String attendeeHomeLocationError(String error) {
    return 'No se pudo obtener la ubicación: $error';
  }

  @override
  String get attendeeProfileYourStats => 'TUS ESTADÍSTICAS';

  @override
  String get attendeeProfileTotalPoints => 'Puntos totales';

  @override
  String get attendeeProfileChallenges => 'Retos';

  @override
  String get attendeeProfileEventsAttended => 'Eventos asistidos';

  @override
  String get attendeeProfileEditProfile => 'Editar perfil';

  @override
  String get attendeeProfileNotifications => 'Notificaciones';

  @override
  String get attendeeProfileHelpSupport => 'Ayuda y soporte';

  @override
  String get attendeeProfileSignOut => 'Cerrar sesión';

  @override
  String get attendeeProfileSignOutConfirm =>
      '¿Seguro que quieres cerrar sesión?';

  @override
  String get attendeeProfileStatFriends => 'Amigos';

  @override
  String get attendeeProfileStatEvents => 'Eventos';

  @override
  String get attendeeProfileStatChats => 'Chats';

  @override
  String get attendeeProfileStatPoints => 'Puntos';

  @override
  String get attendeeProfileMyCommunities => 'MIS COMUNIDADES';

  @override
  String get attendeeProfileNoCommunities =>
      'Todavía no te has unido a ninguna comunidad.';

  @override
  String get attendeeProfileFindFriends => 'Buscar amigos';

  @override
  String get attendeeProfileFriends => 'AMIGOS';

  @override
  String get attendeeProfileSeeAll => 'Ver todos';

  @override
  String get editProfileTitle => 'Editar perfil';

  @override
  String get editProfileChangePhoto => 'Cambiar foto';

  @override
  String get editProfileNameLabel => 'Nombre';

  @override
  String get editProfileNameHint => 'Tu nombre';

  @override
  String get editProfileNameRequired => 'Introduce tu nombre.';

  @override
  String get editProfileCityLabel => 'Ciudad';

  @override
  String get editProfileCityHint => 'Selecciona tu ciudad';

  @override
  String get editProfileCitySearchHint => 'Buscar ciudades';

  @override
  String get editProfileNoCitiesFound => 'No se han encontrado ciudades';

  @override
  String get editProfileCityLoadError => 'No se han podido cargar las ciudades';

  @override
  String get editProfileSave => 'Guardar';

  @override
  String get editProfileSaved => 'Perfil actualizado';

  @override
  String get editProfileSaveError =>
      'No se ha podido guardar tu perfil. Inténtalo de nuevo.';

  @override
  String get memberProfileFriends => 'Amigos';

  @override
  String get badgesScreenTitle => 'Insignias';

  @override
  String get badgesScreenEarnedBadges => 'INSIGNIAS CONSEGUIDAS';

  @override
  String get badgesScreenAllBadges => 'TODAS LAS INSIGNIAS';

  @override
  String get badgesScreenBadgesEarned => 'Insignias conseguidas';

  @override
  String get badgesScreenFailedToLoad => 'No se pudieron cargar las insignias';

  @override
  String get gamificationTryAgain => 'Reintentar';

  @override
  String get leaderboardScreenGlobalTitle => 'Clasificación global';

  @override
  String get leaderboardScreenTitle => 'Clasificación';

  @override
  String get leaderboardScreenRankings => 'CLASIFICACIÓN';

  @override
  String get leaderboardScreenYourRanking => 'Tu posición';

  @override
  String get leaderboardScreenPoints => 'puntos';

  @override
  String get leaderboardScreenNoRankings => 'Aún no hay clasificación';

  @override
  String get leaderboardScreenNoRankingsHint =>
      '¡Sé el primero en ganar puntos\ny hacerte con el primer puesto!';

  @override
  String get leaderboardScreenFailedToLoad =>
      'No se pudo cargar la clasificación';

  @override
  String get statsScreenTitle => 'Mis estadísticas';

  @override
  String get statsScreenTotalPoints => 'Puntos totales';

  @override
  String get statsScreenEvents => 'Eventos';

  @override
  String get statsScreenChallenges => 'Retos';

  @override
  String get statsScreenBadges => 'Insignias';

  @override
  String get statsScreenDetailedStats => 'ESTADÍSTICAS DETALLADAS';

  @override
  String get statsScreenRewardsWon => 'Recompensas ganadas';

  @override
  String get statsScreenRewardsRedeemed => 'Recompensas canjeadas';

  @override
  String get statsScreenEventsDiscovered => 'Eventos descubiertos';

  @override
  String get statsScreenSpinsUsed => 'Tiradas usadas';

  @override
  String get statsScreenQuickActions => 'ACCIONES RÁPIDAS';

  @override
  String get statsScreenRewards => 'Recompensas';

  @override
  String get statsScreenShareComingSoon =>
      '¡Compartir tu tarjeta de juego estará disponible pronto!';

  @override
  String get statsScreenFailedToLoad =>
      'No se pudieron cargar las estadísticas';

  @override
  String get commonTryAgain => 'Reintentar';

  @override
  String get createChallengeTitle => 'Crear reto';

  @override
  String get createChallengeSuccess => '¡Reto creado correctamente!';

  @override
  String get createChallengeNameLabel => 'Nombre del reto';

  @override
  String get createChallengeNameHint => 'Introduce el nombre del reto';

  @override
  String get createChallengeNameRequired => 'Introduce el nombre del reto';

  @override
  String get createChallengeNameTooShort =>
      'El nombre debe tener al menos 3 caracteres';

  @override
  String get createChallengeDescriptionLabel => 'Descripción';

  @override
  String get createChallengeDescriptionHint =>
      'Describe lo que deben hacer los asistentes';

  @override
  String get createChallengeDifficultyLabel => 'Dificultad';

  @override
  String get createChallengePointsLabel => 'Puntos';

  @override
  String get createChallengePointsHint => 'Puntos otorgados';

  @override
  String get createChallengePointsInvalid => 'Introduce un número válido';

  @override
  String get createChallengePointsMax => 'Máximo 100 puntos';

  @override
  String get createChallengeResetDefault => 'Restablecer valor predeterminado';

  @override
  String get createChallengePointsDefaultHint =>
      'Predeterminado: Fácil=5, Media=15, Difícil=30 puntos';

  @override
  String get createChallengeSubmit => 'CREAR RETO';

  @override
  String createChallengePointsValue(int points) {
    return '$points pts';
  }

  @override
  String get eventChallengesTitle => 'Retos';

  @override
  String get eventChallengesTabAll => 'Todos los retos';

  @override
  String get eventChallengesTabCustom => 'Personalizados';

  @override
  String get eventChallengesEmptyAll =>
      'No hay retos disponibles para este evento';

  @override
  String get eventChallengesEmptyCustomOrganizer =>
      'Crea retos personalizados para tu evento';

  @override
  String get eventChallengesEmptyCustom =>
      'Todavía no hay retos personalizados';

  @override
  String get eventChallengesNewChallenge => 'Nuevo reto';

  @override
  String eventChallengesPointsAwarded(int points) {
    return '+$points pts';
  }

  @override
  String get eventChallengesSystemBadge => 'Sistema';

  @override
  String get eventChallengesStartChallenge => 'INICIAR RETO';

  @override
  String get eventDiscoveryTitle => 'Descubrir eventos';

  @override
  String get eventDiscoveryPermissionDenied => 'Permiso de ubicación denegado';

  @override
  String get eventDiscoveryPermissionDeniedForever =>
      'Los permisos de ubicación están denegados permanentemente. Actívalos en los ajustes.';

  @override
  String get eventDiscoveryServicesDisabled =>
      'Los servicios de ubicación están desactivados';

  @override
  String eventDiscoveryLocationFailed(String error) {
    return 'No se pudo obtener la ubicación: $error';
  }

  @override
  String get eventDiscoveryGettingLocation => 'Obteniendo tu ubicación...';

  @override
  String get eventDiscoverySearching => 'Buscando eventos...';

  @override
  String eventDiscoveryRadiusInfo(String radius) {
    return 'Mostrando eventos en un radio de $radius km';
  }

  @override
  String eventDiscoveryFoundCount(int count) {
    return '$count encontrados';
  }

  @override
  String get eventDiscoveryLoadMore => 'Cargar más';

  @override
  String get eventDiscoveryLocationRequired => 'Ubicación necesaria';

  @override
  String get eventDiscoveryOpenSettings => 'Abrir ajustes';

  @override
  String get eventDiscoveryEmptyTitle => 'No hay eventos cerca';

  @override
  String get eventDiscoveryEmptyBody =>
      'Prueba a aumentar el radio de búsqueda\no vuelve más tarde para ver nuevos eventos.';

  @override
  String get eventDiscoveryAdjustRadius => 'Ajustar radio';

  @override
  String get eventDiscoveryErrorTitle => 'No se pudieron descubrir eventos';

  @override
  String get eventDiscoverySearchRadius => 'Radio de búsqueda';

  @override
  String eventDiscoveryRadiusKm(String radius) {
    return '$radius km';
  }

  @override
  String get eventDiscoveryApply => 'Aplicar';

  @override
  String get eventQrTitle => 'Registro del evento';

  @override
  String get eventQrInstructions =>
      'Los asistentes pueden escanear este código QR para registrarse en tu evento';

  @override
  String get eventQrViewCheckins => 'Ver registros';

  @override
  String get eventQrGenerating => 'Generando código QR...';

  @override
  String get eventQrErrorTitle => 'No se pudo generar el código QR';

  @override
  String get eventQrCopyToken => 'Copiar token';

  @override
  String get eventQrTokenCopied => 'Token copiado al portapapeles';

  @override
  String get initiateChallengeTitle => 'Iniciar reto';

  @override
  String get initiateChallengeFailed => 'No se pudo iniciar el reto';

  @override
  String get initiateChallengeSuccessTitle => '¡Reto iniciado!';

  @override
  String get initiateChallengeSuccessBody =>
      'Se avisará al verificador para que confirme que completaste el reto.';

  @override
  String initiateChallengePointsAwarded(int points) {
    return '+$points pts';
  }

  @override
  String get initiateChallengeHowItWorks => 'Cómo funciona';

  @override
  String get initiateChallengeStep1 =>
      'Introduce el ID de perfil del verificador';

  @override
  String get initiateChallengeStep2 =>
      'Completa el reto con el verificador presente';

  @override
  String get initiateChallengeStep3 =>
      'El verificador confirma que lo completaste';

  @override
  String get initiateChallengeStep4 => '¡Gana tus puntos!';

  @override
  String get initiateChallengeVerifierLabel => 'ID de perfil del verificador';

  @override
  String get initiateChallengeVerifierHint =>
      'Introduce el ID de perfil del verificador';

  @override
  String get initiateChallengeVerifierRequired =>
      'Introduce el ID de perfil del verificador';

  @override
  String get initiateChallengeVerifierHelper =>
      'Pide a otro asistente su ID de perfil para verificar tu reto';

  @override
  String get initiateChallengeSubmit => 'INICIAR RETO';

  @override
  String get qrScannerEventFallback => 'Evento';

  @override
  String get qrScannerCheckinFailed => 'No se pudo registrar la entrada';

  @override
  String get qrScannerSuccessTitle => '¡Registro completado!';

  @override
  String get qrScannerSuccessSubtitle => 'Te has registrado en';

  @override
  String get qrScannerErrorTitle => 'Registro fallido';

  @override
  String get qrScannerClose => 'Cerrar';

  @override
  String get qrScannerTitle => 'Escanear código QR';

  @override
  String get qrScannerCheckingIn => 'Registrando...';

  @override
  String get qrScannerInstructionTitle =>
      'Apunta la cámara al código QR del evento';

  @override
  String get qrScannerInstructionSubtitle =>
      'El organizador del evento mostrará el código QR';

  @override
  String get rewardWalletTitle => 'Mis recompensas';

  @override
  String get rewardWalletEmptyTitle => 'Todavía no hay recompensas';

  @override
  String get rewardWalletEmptyBody =>
      '¡Completa retos y gira la ruleta\npara ganar recompensas increíbles!';

  @override
  String get rewardWalletErrorTitle => 'No se pudieron cargar las recompensas';

  @override
  String get challengeCompletionDefaultName => 'Reto';

  @override
  String get challengeCompletionDefaultChallenger => 'Retador';

  @override
  String get challengeCompletionReject => 'Rechazar';

  @override
  String get challengeCompletionVerify => 'Verificar';

  @override
  String get challengeCompletionStatusVerified => 'Verificado';

  @override
  String get challengeCompletionStatusRejected => 'Rechazado';

  @override
  String get challengeCompletionStatusPending => 'Pendiente';

  @override
  String get mediaTitleVenue => 'MUESTRA TU LOCAL';

  @override
  String get mediaTitleProduct => 'MUESTRA TU PRODUCTO';

  @override
  String get mediaSubtitle =>
      'Añade fotos para que las comunidades vean lo que ofreces. (Mín. 1, máx. 5)';

  @override
  String get mediaSelectFromLibrary => 'SELECCIONAR DE LA BIBLIOTECA';

  @override
  String get mediaSelectExistingTitle => 'Selecciona fotos existentes';

  @override
  String get mediaUsePhoto => 'Usar foto';

  @override
  String get mediaUsePhotos => 'Usar fotos';

  @override
  String get mediaPhotosAlreadyAdded => 'Esas fotos ya están en este Kolab.';

  @override
  String mediaPhotosAdded(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se añadieron $count fotos existentes.',
      one: 'Se añadió $count foto existente.',
    );
    return '$_temp0';
  }

  @override
  String mediaUploadFailed(String error) {
    return 'Error al subir: $error';
  }

  @override
  String get mediaAddPhoto => 'Añadir foto';

  @override
  String mediaPhotoSlot(int number) {
    return 'Foto $number';
  }

  @override
  String get offeringTitle => 'QUÉ OFRECES';

  @override
  String get offeringSelectAllThatApply => 'Selecciona todo lo que corresponda';

  @override
  String get offeringVenueTitle => 'Local';

  @override
  String get offeringVenueSubtitle => 'Ofrece tu espacio para el kolab';

  @override
  String get offeringFoodDrinkTitle => 'Comida y bebida incluidas';

  @override
  String get offeringFoodDrinkSubtitle =>
      'Comidas o bebidas para los miembros de la comunidad';

  @override
  String get offeringDiscountTitle => 'Descuento para miembros de la comunidad';

  @override
  String get offeringDiscountSubtitle =>
      'Precios exclusivos para los participantes';

  @override
  String get offeringProductsTitle => 'Productos / Muestras';

  @override
  String get offeringProductsSubtitle =>
      'Muestras de producto gratuitas o regalos';

  @override
  String get offeringSocialMediaTitle => 'Visibilidad en redes sociales';

  @override
  String get offeringSocialMediaSubtitle => 'Aparece en tus canales';

  @override
  String get offeringContentCreationTitle => 'Creación de contenido';

  @override
  String get offeringContentCreationSubtitle => 'Fotos y vídeo profesionales';

  @override
  String get offeringSponsorshipTitle => 'Presupuesto de patrocinio';

  @override
  String get offeringSponsorshipSubtitle => 'Apoyo económico para el kolab';

  @override
  String get offeringOtherTitle => 'Otro';

  @override
  String get offeringOtherSubtitle => 'Algo más que ofrecer';

  @override
  String get offeringBaseOfferLabel => 'OFERTA BÁSICA';

  @override
  String get offeringBaseOfferHelper =>
      'Lo que cada comunidad verá en tu tarjeta. Sé específico para que los responsables puedan evaluarlo de un vistazo.';

  @override
  String get offeringBaseOfferHint =>
      'p. ej. 20% de descuento los martes, sala de reuniones gratis para grupos de 10 o más';

  @override
  String get offeringExtraTermsLabel => 'CONDICIONES ADICIONALES (OPCIONAL)';

  @override
  String get offeringExtraTermsHelper =>
      'Mejores condiciones que solo se desbloquean cuando una comunidad propone un kolab. Las ven después de enviarte un Kolab.';

  @override
  String get offeringAddExtraTerm => 'AÑADIR CONDICIÓN';

  @override
  String offeringTriggerIfPrefix(String condition) {
    return 'SI $condition';
  }

  @override
  String get offeringTriggerSheetTitle => 'Añadir una condición';

  @override
  String get offeringTriggerSheetSubtitle =>
      'Solo aparece después de que una comunidad envíe una propuesta de Kolab.';

  @override
  String get offeringTriggerWhenLabel => 'Cuándo';

  @override
  String get offeringTriggerWhenHint => 'p. ej. eventos mensuales recurrentes';

  @override
  String get offeringTriggerThenLabel => 'Entonces ofrece';

  @override
  String get offeringTriggerThenHint =>
      'p. ej. alquiler del local gratis a partir del tercer evento';

  @override
  String get offeringAddTerm => 'AÑADIR CONDICIÓN';

  @override
  String get pastEventsSubtitle =>
      'Muestra a las comunidades qué eventos se han celebrado antes en tu local.';

  @override
  String get pastEventsLoadingProfileEvents => 'Cargando eventos del perfil...';

  @override
  String get pastEventsSelectFromProfile => 'Seleccionar del perfil';

  @override
  String get pastEventsAddPastEvent => 'Añadir un evento anterior';

  @override
  String get pastEventsAllAlreadyAdded =>
      'Ya se han añadido todos los eventos del perfil.';

  @override
  String pastEventsImported(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se importaron $count eventos del perfil.',
      one: 'Se importó $count evento del perfil.',
    );
    return '$_temp0';
  }

  @override
  String pastEventsEventNumber(int number) {
    return 'Evento $number';
  }

  @override
  String get pastEventsEventNameLabel => 'Nombre del evento';

  @override
  String get pastEventsEventNameHint =>
      'p. ej. Encuentro de bienestar de verano';

  @override
  String get pastEventsDateLabel => 'Fecha';

  @override
  String get pastEventsPartnerNameLabel => 'Nombre del colaborador';

  @override
  String get pastEventsPartnerNameHint =>
      'p. ej. Club de Corredores de la Ciudad';

  @override
  String get pastEventsPhotosLabel => 'Fotos (máx. 3)';

  @override
  String get pastEventsRecapVideoLabel => 'Vídeo resumen (máx. 1)';

  @override
  String get pastEventsRecapVideoChip => 'Vídeo resumen';

  @override
  String pastEventsUploadFailed(String error) {
    return 'Error al subir: $error';
  }

  @override
  String get productDetailsSectionHeader => 'TU PRODUCTO O SERVICIO';

  @override
  String get productDetailsListingTitleLabel => 'Título del anuncio';

  @override
  String get productDetailsListingTitleHint =>
      'p. ej. Cold brew orgánico, perfecto para eventos comunitarios';

  @override
  String get productDetailsProductNameLabel => 'Nombre del producto';

  @override
  String get productDetailsProductNameHint => 'p. ej. Café cold brew orgánico';

  @override
  String get productDetailsProductTypeLabel => 'Tipo de producto';

  @override
  String get productDetailsDescriptionLabel => 'Descripción';

  @override
  String get productDetailsDescriptionHint =>
      'Describe tu producto o servicio...';

  @override
  String get productDetailsOfferHeadlineLabel => 'Titular de la oferta';

  @override
  String get productDetailsOfferHeadlineHelper =>
      'Una línea breve que las comunidades verán en tu tarjeta.';

  @override
  String get productDetailsOfferHeadlineHint =>
      'p. ej. Gratis con cualquier pedido de 5 o más';

  @override
  String get productDetailsCityLabel => 'Ciudad';

  @override
  String get productDetailsSelectCityHint => 'Selecciona una ciudad';

  @override
  String get productDetailsFailedToLoadCities =>
      'No se pudieron cargar las ciudades';

  @override
  String get venueDetailsSectionHeader => 'DETALLES DE LA PROMOCIÓN';

  @override
  String get venueDetailsListingTitleLabel => 'Título del anuncio';

  @override
  String get venueDetailsListingTitleHint =>
      'p. ej. Encuentro en la azotea al atardecer para creadores locales';

  @override
  String get venueDetailsCampaignDescriptionLabel =>
      'Descripción de la campaña';

  @override
  String get venueDetailsCampaignDescriptionHint =>
      'Cuéntales a las comunidades qué tipo de experiencia quieres ofrecer y por qué tu local encaja a la perfección.';

  @override
  String get venueDetailsOfferHeadlineLabel => 'Titular de la oferta';

  @override
  String get venueDetailsOfferHeadlineHelper =>
      'Una línea breve que las comunidades verán en tu tarjeta.';

  @override
  String get venueDetailsOfferHeadlineHint =>
      'p. ej. 20% de descuento los martes para grupos de 10 o más';

  @override
  String get venueDetailsPrimaryVenue => 'LOCAL PRINCIPAL';

  @override
  String get venueDetailsVenueFallback => 'Local';

  @override
  String venueDetailsTypeCapacity(String type, String capacity) {
    return '$type • Aforo $capacity';
  }

  @override
  String get communityInfoTypeHeader => 'TIPO DE TU COMUNIDAD';

  @override
  String get communityInfoTypeSubtitle =>
      'Ayuda a las empresas a entender tu audiencia. Selecciona hasta 3.';

  @override
  String get communityInfoCommunitySizeLabel => 'TAMAÑO DE LA COMUNIDAD';

  @override
  String get communityInfoCommunitySizeHint => 'p. ej., 500';

  @override
  String get communityInfoExpectedAttendeesLabel => 'ASISTENTES PREVISTOS';

  @override
  String get communityInfoExpectedAttendeesHint => 'p. ej., 50';

  @override
  String get eventDetailsHeader => 'DETALLES DEL KOLAB';

  @override
  String get eventDetailsSubtitle => 'Describe tu kolab y lo que ofreces';

  @override
  String get eventDetailsTitleLabel => 'Título';

  @override
  String get eventDetailsTitleHint =>
      'p. ej., Comunidad fitness x Cafetería local';

  @override
  String get eventDetailsDescriptionLabel => 'Descripción';

  @override
  String get eventDetailsDescriptionHint =>
      'Describe lo que buscas y cómo funcionaría este kolab...';

  @override
  String get eventDetailsOffersHeader => 'LO QUE OFRECES A CAMBIO';

  @override
  String get logisticsAvailabilityHeader => 'DISPONIBILIDAD';

  @override
  String get logisticsAvailabilitySubtitle =>
      '¿Cuándo está disponible tu comunidad para este kolab?';

  @override
  String get logisticsLocationHeader => 'UBICACIÓN';

  @override
  String get logisticsPreferredCityLabel => 'Ciudad preferida';

  @override
  String logisticsCitiesLoadError(String error) {
    return 'Error al cargar las ciudades: $error';
  }

  @override
  String get logisticsSelectCityHint => 'Selecciona una ciudad';

  @override
  String get logisticsPreferredAreaLabel =>
      'Barrio / zona preferida (opcional)';

  @override
  String get logisticsPreferredAreaHint => 'p. ej., Shoreditch, Kreuzberg';

  @override
  String get logisticsAvailableFromLabel => 'Disponible desde';

  @override
  String get logisticsAvailableUntilLabel => 'Disponible hasta';

  @override
  String get logisticsTimeLabel => 'Hora';

  @override
  String get logisticsDayOfWeekLabel => 'Día de la semana';

  @override
  String get logisticsSelectDate => 'Selecciona una fecha';

  @override
  String get logisticsSelectTime => 'Selecciona una hora';

  @override
  String get photoAddHeader => 'AÑADE UNA FOTO';

  @override
  String get photoAddSubtitle =>
      'Aparecerá en la tarjeta de tu kolab en Explorar.';

  @override
  String get photoUseProfilePhoto => 'Usa la foto de perfil de tu comunidad';

  @override
  String get photoDividerOr => 'O';

  @override
  String get photoChooseFromGallery => 'Elige de la galería o eventos pasados';

  @override
  String get photoUploadTitle => 'Sube una foto';

  @override
  String get photoUploadMaxSize => 'Máx. 5 MB';

  @override
  String photoUploadFailed(String error) {
    return 'Error al subir: $error';
  }

  @override
  String get photoPickerSheetTitle =>
      'Usa una foto de la galería o de un evento pasado';

  @override
  String get photoPickerConfirmLabel => 'Usar foto';

  @override
  String get photoUploadedSelectedTitle => 'Foto subida seleccionada';

  @override
  String get photoUploadedSelectedSubtitle =>
      'Esta imagen aparecerá en la tarjeta de tu kolab en Explorar.';

  @override
  String get photoUseProfilePhotoButton => 'Usar foto de perfil';

  @override
  String get photoReplacePhotoButton => 'Reemplazar foto';

  @override
  String get intentSelectionAppBarTitle => 'NUEVO KOLAB';

  @override
  String get intentSelectionCommunityTitle => '¿Qué te gustaría hacer?';

  @override
  String get intentSelectionBusinessTitle => '¿Qué te gustaría promocionar?';

  @override
  String get intentSelectionCommunitySubtitle =>
      'Elige cómo quieres hacer kolab con negocios.';

  @override
  String get intentSelectionBusinessSubtitle =>
      'Elige qué quieres promocionar a las comunidades.';

  @override
  String get intentSelectionFindVenueTitle =>
      'Encuentra un local o patrocinador';

  @override
  String get intentSelectionFindVenueSubtitle =>
      'para el evento de mi comunidad';

  @override
  String get intentSelectionBadgeFree => 'GRATIS';

  @override
  String get intentSelectionPromoteVenueTitle => 'Promociona mi local';

  @override
  String get intentSelectionPromoteVenueSubtitle =>
      'Consigue que las comunidades organicen eventos en tu local';

  @override
  String get intentSelectionPromoteProductTitle =>
      'Promociona un producto o servicio';

  @override
  String get intentSelectionPromoteProductSubtitle =>
      'Consigue que las comunidades muestren tus productos en sus eventos';

  @override
  String get intentSelectionProfileLoadError => 'No se pudo cargar tu perfil';

  @override
  String get intentSelectionProfileLoadErrorHint =>
      'Inténtalo de nuevo para seguir creando un kolab.';

  @override
  String get intentSelectionLockedTitle =>
      'Se necesita una suscripción activa para crear Kolabs.';

  @override
  String get intentSelectionLockedSubtitle =>
      'Mejora tu plan de negocio para publicar oportunidades de local o producto para las comunidades.';

  @override
  String get intentSelectionUpgradeButton => 'Mejora para crear';

  @override
  String get kolabFlowNoIntentSelected =>
      'No se ha seleccionado ninguna intención';

  @override
  String get kolabFlowTitleFindPartner => 'ENCUENTRA UN SOCIO';

  @override
  String get kolabFlowTitlePromoteVenue => 'PROMOCIONA LOCAL';

  @override
  String get kolabFlowTitlePromoteProduct => 'PROMOCIONA PRODUCTO';

  @override
  String get kolabFlowPublishedTitle => '¡Kolab publicado!';

  @override
  String get kolabFlowDraftSavedTitle => '¡Borrador guardado!';

  @override
  String get kolabFlowPublishedMessage => 'Tu kolab ya es visible en Explorar.';

  @override
  String get kolabFlowDraftSavedMessage => 'Puedes seguir editando más tarde.';

  @override
  String get myKolabsHubTitle => 'MIS KOLABS';

  @override
  String get myKolabsHubTabOffers => 'OFERTAS';

  @override
  String get myKolabsHubTabRequests => 'SOLICITUDES';

  @override
  String get myKolabsHubTabActive => 'ACTIVOS';

  @override
  String get myKolabsHubTabFinished => 'FINALIZADOS';

  @override
  String get myKolabsHubActiveEmptyTitle => 'No hay kolabs activos';

  @override
  String get myKolabsHubActiveEmptyMessage =>
      'Cuando ambas partes aceptan una solicitud, el kolab aparece aquí mientras está en curso.';

  @override
  String get myKolabsHubFinishedEmptyTitle => 'Nada finalizado todavía';

  @override
  String get myKolabsHubFinishedEmptyMessage =>
      'Los kolabs completados y cancelados se recogerán aquí.';

  @override
  String get myKolabsHubCreateTooltip => 'Crear Kolab';

  @override
  String existingPhotoPickerSubtitle(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotos subidas anteriormente',
      one: '1 foto subida anteriormente',
    );
    return 'Selecciona hasta $_temp0.';
  }

  @override
  String get existingPhotoPickerEmpty => 'Aún no hay fotos reutilizables.';

  @override
  String get kolabActionBarSaveDraft => 'GUARDAR BORRADOR';

  @override
  String get kolabActionBarPublish => 'PUBLICAR';

  @override
  String get kolabReviewSectionTitleDescription => 'Título y descripción';

  @override
  String get kolabReviewSectionWhatYouNeed => 'Lo que necesitas';

  @override
  String get kolabReviewSectionCommunityInfo => 'Información de la comunidad';

  @override
  String get kolabReviewSectionOffersInReturn => 'Ofertas a cambio';

  @override
  String get kolabReviewSectionLocation => 'Ubicación';

  @override
  String get kolabReviewSectionCampaignVenue => 'Campaña y local';

  @override
  String get kolabReviewSectionMedia => 'Multimedia';

  @override
  String get kolabReviewSectionWhatYouOffer => 'Lo que ofreces';

  @override
  String get kolabReviewSectionSeekingCommunities => 'Comunidades que buscas';

  @override
  String get kolabReviewSectionPastEvents => 'Eventos anteriores';

  @override
  String get kolabReviewSectionProductInfo => 'Información del producto';

  @override
  String get kolabReviewSectionAvailability => 'Disponibilidad';

  @override
  String get kolabReviewFieldTitle => 'Título';

  @override
  String get kolabReviewFieldDescription => 'Descripción';

  @override
  String get kolabReviewFieldTypes => 'Tipos';

  @override
  String get kolabReviewFieldCommunitySize => 'Tamaño de la comunidad';

  @override
  String get kolabReviewFieldTypicalAttendance => 'Asistencia habitual';

  @override
  String get kolabReviewFieldCity => 'Ciudad';

  @override
  String get kolabReviewFieldArea => 'Zona';

  @override
  String get kolabReviewFieldVenue => 'Local';

  @override
  String get kolabReviewFieldType => 'Tipo';

  @override
  String get kolabReviewFieldCapacity => 'Aforo';

  @override
  String get kolabReviewFieldAddress => 'Dirección';

  @override
  String get kolabReviewFieldPhotosVideos => 'Fotos / Vídeos';

  @override
  String get kolabReviewFieldEvents => 'Eventos';

  @override
  String get kolabReviewFieldName => 'Nombre';

  @override
  String get kolabReviewFieldSchedule => 'Horario';

  @override
  String get kolabReviewEmptyNeeds => 'No se han seleccionado necesidades';

  @override
  String get kolabReviewEmptyCommunityInfo =>
      'No se ha proporcionado información de la comunidad';

  @override
  String get kolabReviewEmptyOffers => 'No se han seleccionado ofertas';

  @override
  String get kolabReviewEmptyOfferings => 'No hay ofrecimientos indicados';

  @override
  String get kolabReviewEmptyCommunities =>
      'No se han seleccionado comunidades';

  @override
  String get kolabReviewNoMedia => 'No se ha añadido multimedia';

  @override
  String get kolabReviewNoPastEvents => 'No se han añadido eventos anteriores';

  @override
  String kolabReviewMediaCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos',
      one: '1 elemento',
    );
    return '$_temp0';
  }

  @override
  String kolabReviewEventsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos',
      one: '1 evento',
    );
    return '$_temp0';
  }

  @override
  String kolabReviewAvailabilityFrom(String date) {
    return 'Desde: $date';
  }

  @override
  String kolabReviewAvailabilityTo(String date) {
    return 'Hasta: $date';
  }

  @override
  String get myKolabCardUntitled => 'Kolab sin título';

  @override
  String get myKolabCardActionView => 'Ver';

  @override
  String get myKolabCardActionEdit => 'Editar';

  @override
  String get myKolabCardActionPublish => 'Publicar';

  @override
  String get myKolabCardActionClose => 'Cerrar';

  @override
  String get myKolabCardActionDelete => 'Eliminar';

  @override
  String get myKolabCardStatusPublished => 'PUBLICADO';

  @override
  String get myKolabCardStatusClosed => 'CERRADO';

  @override
  String get myKolabCardStatusCompleted => 'COMPLETADO';

  @override
  String get myKolabCardStatusDraft => 'BORRADOR';

  @override
  String get profileEventPickerTitle => 'Elige entre los eventos de tu perfil';

  @override
  String profileEventPickerSubtitle(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos',
      one: '1 evento',
    );
    return 'Selecciona hasta $_temp0 para importar.';
  }

  @override
  String get profileEventPickerImport => 'Importar eventos';

  @override
  String get notificationsScreenTitle => 'Notificaciones';

  @override
  String get notificationsScreenMarkAllRead => 'Marcar todo como leído';

  @override
  String get notificationsScreenEmptyTitle => 'Aún no tienes notificaciones';

  @override
  String get notificationsScreenEmptyBody =>
      'Cuando recibas mensajes o actualizaciones de tus solicitudes, aparecerán aquí.';

  @override
  String get notificationBellTooltip => 'Notificaciones';

  @override
  String get businessFinalEmailRequired =>
      'El correo electrónico es obligatorio';

  @override
  String get businessFinalEmailInvalid =>
      'Introduce un correo electrónico válido';

  @override
  String get businessFinalPasswordRequired => 'La contraseña es obligatoria';

  @override
  String get businessFinalPasswordTooShort =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get businessFinalConfirmPasswordRequired => 'Confirma tu contraseña';

  @override
  String get businessFinalPasswordsMismatch => 'Las contraseñas no coinciden';

  @override
  String get businessFinalSignupFailed => 'No se pudo completar el registro';

  @override
  String get businessFinalNoInternet =>
      'Sin conexión a internet. Comprueba tu red.';

  @override
  String get businessFinalErrorCopied =>
      'Detalles del error copiados al portapapeles';

  @override
  String get businessFinalCopyDetails => 'Copiar detalles';

  @override
  String get businessFinalTitleAuthenticated =>
      'FINALIZA EL ALTA DE TU NEGOCIO';

  @override
  String get businessFinalTitleNewAccount => 'CREA TU CUENTA';

  @override
  String get businessFinalSubtitleAuthenticated =>
      'Revisa tus datos importados una última vez y guarda el perfil de tu negocio.';

  @override
  String get businessFinalSubtitleNewAccount =>
      'Introduce tu correo electrónico y contraseña para completar el registro';

  @override
  String get businessFinalEdit => 'Editar';

  @override
  String get businessFinalEmailLabel => 'Correo electrónico';

  @override
  String get businessFinalEmailHint => 'tu@correo.com';

  @override
  String get businessFinalPasswordLabel => 'Contraseña';

  @override
  String get businessFinalPasswordHint => 'Mín. 8 caracteres';

  @override
  String get businessFinalConfirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get businessFinalConfirmPasswordHint =>
      'Vuelve a escribir tu contraseña';

  @override
  String get businessFinalAuthenticatedInfo =>
      'Tu cuenta ya está creada. Al pulsar el botón de abajo se guardarán estos datos de alta en el perfil de tu negocio.';

  @override
  String get businessFinalCompleteButton => 'COMPLETAR ALTA';

  @override
  String get businessFinalCreateAccountButton => 'CREAR CUENTA';

  @override
  String get businessFinalTermsAuthenticated =>
      'Solo guardamos las fotos de Google seleccionadas cuando la solicitud de alta se completa correctamente.';

  @override
  String get businessFinalTermsNewAccount =>
      'Al crear una cuenta, aceptas nuestras Condiciones del servicio y la Política de privacidad';

  @override
  String get businessStep2PhotoAccessDenied =>
      'Permite el acceso a Fotos en Ajustes para añadir imágenes del local.';

  @override
  String get businessStep2PhotoLibraryError =>
      'No pudimos abrir tu galería de fotos. Inténtalo de nuevo.';

  @override
  String get businessStep2IncompleteError =>
      'Completa los datos obligatorios del negocio, añade al menos una foto del local e introduce el aforo antes de continuar.';

  @override
  String get businessStep2PhoneMustStartPlus =>
      'Debe empezar por + (p. ej. +34612345678)';

  @override
  String get businessStep2PhoneDigitsOnly =>
      'Usa el formato E.164 solo con dígitos';

  @override
  String get businessStep2PhoneTooShort =>
      'Introduce al menos 9 dígitos después del +';

  @override
  String get businessStep2PhoneTooLong =>
      'El número de teléfono es demasiado largo';

  @override
  String get businessStep2Title => 'REVISA LOS DATOS DE TU NEGOCIO';

  @override
  String get businessStep2Subtitle =>
      'Importamos lo que pudimos de Google. Revísalo, indica el aforo y selecciona la galería final del local antes de terminar.';

  @override
  String get businessStep2ImportedBanner =>
      'Importado de Google. Puedes editar todos los campos antes de guardar.';

  @override
  String get businessStep2AddLogo => 'Añadir logo (opcional)';

  @override
  String get businessStep2VenueAddressLabel => 'Dirección del local';

  @override
  String get businessStep2BusinessNameLabel => 'Nombre del negocio';

  @override
  String get businessStep2BusinessNameHint =>
      'Introduce el nombre de tu negocio';

  @override
  String get businessStep2BusinessTypeLabel => 'Tipo de negocio';

  @override
  String get businessStep2BusinessTypeHint =>
      'Selecciona hasta 3 categorías que describan tu negocio.';

  @override
  String get businessStep2BusinessTypesLoadError =>
      'No se pudieron cargar los tipos de negocio';

  @override
  String get businessStep2VenueTypeLabel => 'Tipo de local';

  @override
  String get businessStep2CapacityLabel => 'Aforo';

  @override
  String get businessStep2CapacityHelper =>
      'Google no proporciona el aforo del local, así que tienes que introducirlo manualmente.';

  @override
  String get businessStep2CapacityHint => '¿A cuántas personas puedes acoger?';

  @override
  String get businessStep2VenuePhotosLabel => 'Fotos del local';

  @override
  String get businessStep2AboutLabel => 'Sobre tu negocio';

  @override
  String get businessStep2AboutHint => 'Cuenta qué hace especial a tu negocio';

  @override
  String get businessStep2PhoneLabel => 'Número de teléfono';

  @override
  String get businessStep2InstagramLabel => 'Instagram';

  @override
  String get businessStep2WebsiteLabel => 'Sitio web';

  @override
  String get businessStep2ChangeVenue => 'Cambiar local';

  @override
  String get businessStep3PhotoAccessDenied =>
      'Permite el acceso a Fotos en Ajustes para añadir imágenes del local.';

  @override
  String get businessStep3PhotoLibraryError =>
      'No pudimos abrir tu galería de fotos. Inténtalo de nuevo.';

  @override
  String get businessStep3NoPhotosError =>
      'Añade al menos una foto del local para continuar';

  @override
  String get businessStep3Title => 'AÑADE FOTOS DEL LOCAL';

  @override
  String get businessStep3Subtitle =>
      'Estas formarán tu galería reutilizable del local, así no tendrás que subirlas cada vez que crees un Kolab de local.';

  @override
  String get businessStep3AddPhoto => 'Añadir foto';

  @override
  String get businessStep5PickAddressError =>
      'Elige la dirección de tu local entre las sugerencias';

  @override
  String get businessStep5ImportFallback =>
      'No pudimos importar desde Google, rellénalo manualmente.';

  @override
  String get businessStep5Title => 'ELIGE TU LOCAL';

  @override
  String get businessStep5Subtitle =>
      'Busca el local de tu negocio e importaremos los datos que podamos de Google antes de que los revises.';

  @override
  String get businessStep5SearchHint => 'Buscar dirección del local';

  @override
  String get businessStep5HintStartTyping =>
      'Empieza a escribir la dirección de tu local para ver sugerencias.';

  @override
  String get businessStep5HintNoMatches =>
      'Aún no hay coincidencias. Prueba a añadir la ciudad a la dirección.';

  @override
  String get businessStep5SuggestionsError =>
      'No pudimos cargar las sugerencias de locales ahora mismo.';

  @override
  String get businessStep5Importing =>
      'Importando la información de tu negocio desde Google';

  @override
  String get businessStep5PreviewTitle => 'FOTOS DE GOOGLE';

  @override
  String get businessStep5PreviewSubtitle =>
      'Importamos estas fotos para tu local. Pulsa la X para quitar las que no quieras antes de continuar. Puedes añadir las tuyas más tarde.';

  @override
  String get businessStep5NoPhotosLeft =>
      'No quedan fotos. Continúa para añadir las tuyas o vuelve atrás para elegir otro local.';

  @override
  String get businessStep5SelectedAddress => 'Dirección seleccionada';

  @override
  String get communityFinalTitle => 'CREA TU CUENTA';

  @override
  String get communityFinalSubtitle =>
      'Introduce tu correo electrónico y contraseña para completar el registro';

  @override
  String get communityFinalEdit => 'Editar';

  @override
  String get communityFinalEmailLabel => 'Correo electrónico';

  @override
  String get communityFinalEmailHint => 'tu@email.com';

  @override
  String get communityFinalPasswordLabel => 'Contraseña';

  @override
  String get communityFinalPasswordHint => 'Mín. 8 caracteres';

  @override
  String get communityFinalConfirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get communityFinalConfirmPasswordHint =>
      'Vuelve a introducir tu contraseña';

  @override
  String get communityFinalEmailRequired =>
      'El correo electrónico es obligatorio';

  @override
  String get communityFinalEmailInvalid =>
      'Introduce un correo electrónico válido';

  @override
  String get communityFinalPasswordRequired => 'La contraseña es obligatoria';

  @override
  String get communityFinalPasswordMinLength =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get communityFinalConfirmPasswordRequired => 'Confirma tu contraseña';

  @override
  String get communityFinalPasswordsMismatch => 'Las contraseñas no coinciden';

  @override
  String get communityFinalNoInternet =>
      'Sin conexión a internet. Comprueba tu red.';

  @override
  String get communityFinalCreateAccountButton => 'CREAR CUENTA';

  @override
  String get communityFinalTermsNotice =>
      'Al crear una cuenta, aceptas nuestros Términos de servicio y Política de privacidad';

  @override
  String get communityStep1Title => 'CUÉNTANOS SOBRE TI';

  @override
  String get communityStep1Subtitle => 'Vamos a crear tu perfil';

  @override
  String get communityStep1DisplayNameLabel => 'Nombre visible';

  @override
  String get communityStep1NameHint => 'Tu nombre o usuario';

  @override
  String get communityStep1NameRequired => 'Introduce tu nombre visible';

  @override
  String get communityStep2Title => '¿Qué tipo de comunidad eres?';

  @override
  String get communityStep2Subtitle =>
      'Ayuda a los negocios a entender tu comunidad';

  @override
  String get communityStep2TypeRequired => 'Selecciona un tipo de comunidad';

  @override
  String get communityStep2LoadError =>
      'No se pudieron cargar los tipos de comunidad';

  @override
  String get communityStep3Title => '¿DÓNDE TE ENCUENTRAS?';

  @override
  String get communityStep3Subtitle => 'Encuentra oportunidades en tu zona';

  @override
  String get communityStep3SearchHint => 'Buscar ciudades...';

  @override
  String get communityStep3PopularCities => 'Ciudades populares:';

  @override
  String get communityStep3NoCitiesFound => 'No se encontraron ciudades';

  @override
  String get communityStep3LoadError => 'No se pudieron cargar las ciudades';

  @override
  String get communityStep3CityRequired => 'Selecciona una ciudad';

  @override
  String get communityStep4Title => 'COMPLETA TU PERFIL';

  @override
  String get communityStep4Subtitle =>
      'Añade tus redes sociales (todo opcional)';

  @override
  String get communityStep4AboutLabel => 'Acerca de / Biografía';

  @override
  String get communityStep4AboutHint => 'Cuéntanos sobre ti...';

  @override
  String get communityStep4UsernameHint => 'usuario';

  @override
  String get communityStep4WebsiteLabel => 'Sitio web';

  @override
  String get communityStep4WebsiteHint => 'www.ejemplo.com';

  @override
  String get photoUploadFileTooLarge => 'La imagen debe pesar menos de 5MB';

  @override
  String get photoUploadSelectFailed => 'No se pudo seleccionar la imagen';

  @override
  String get photoUploadSelectFailedRetry =>
      'No se pudo seleccionar la imagen. Inténtalo de nuevo.';

  @override
  String get photoUploadPhotosAccessDenied =>
      'Permite el acceso a Fotos en Ajustes para subir una imagen.';

  @override
  String get photoUploadCameraAccessDenied =>
      'Permite el acceso a la Cámara en Ajustes para hacer una foto.';

  @override
  String get photoUploadChooseLibrary => 'Elegir de la galería';

  @override
  String get photoUploadTakePhoto => 'Hacer foto';

  @override
  String get photoUploadChangePhoto => 'Cambiar foto';

  @override
  String get photoUploadRemovePhoto => 'Eliminar foto';

  @override
  String get photoUploadTapToChange => 'Toca para cambiar';

  @override
  String get venuePhotoAddPhoto => 'Añadir foto';

  @override
  String get venuePhotoPoweredByGoogle => 'Con tecnología de Google';

  @override
  String get venuePhotoEmptyTitle => 'Añade fotos del local';

  @override
  String get venuePhotoEmptyDescription =>
      'Conserva las fotos importadas de Google, sube las tuyas, elimina las que no quieras y define aquí el orden final.';

  @override
  String get venuePhotoSourceGoogle => 'Importada de Google';

  @override
  String get venuePhotoSourceSaved => 'Foto guardada';

  @override
  String get venuePhotoSourceUpload => 'Subida';

  @override
  String venuePhotoPositionLabel(num position, num total) {
    return 'Foto $position de $total';
  }

  @override
  String get venuePhotoMoveEarlier => 'Mover antes';

  @override
  String get venuePhotoMoveLater => 'Mover después';

  @override
  String get venuePhotoRemovePhoto => 'Eliminar foto';

  @override
  String get venuePhotoCredits => 'Créditos de la foto';

  @override
  String get venuePhotoCreditsSheetTitle => 'Créditos de la foto de Google';

  @override
  String get profileReviewsTitle => 'Reseñas';

  @override
  String profileReviewsTitleNamed(String name) {
    return 'Reseñas de $name';
  }

  @override
  String get profileReviewsLoadError => 'No se han podido cargar las reseñas.';

  @override
  String get profileReviewsEmpty => 'Aún no hay reseñas.';

  @override
  String get profileReviewsLoadMore => 'Cargar más';

  @override
  String get publicProfileAbout => 'Acerca de';

  @override
  String get publicProfileLoadError => 'No se ha podido cargar el perfil';

  @override
  String get publicProfilePastKolabs => 'Kolabs anteriores';

  @override
  String get publicProfileNoPastKolabs => 'Aún no hay kolabs anteriores';

  @override
  String get publicProfileSocialLinks => 'Redes sociales';

  @override
  String get publicProfileSaveForLater => 'Guardar para más tarde';

  @override
  String get publicProfileSendKolabProposal => 'ENVIAR UNA PROPUESTA DE KOLAB';

  @override
  String get publicProfileRecentReviews => 'Reseñas recientes';

  @override
  String get publicProfileViewMore => 'Ver más';

  @override
  String get memberProfilePoints => 'Puntos';

  @override
  String get memberProfileEventsAttended => 'Eventos asistidos';

  @override
  String get memberProfileBadges => 'Insignias';

  @override
  String get memberProfileNoBadges => 'Aún no hay insignias';

  @override
  String get referralCodeCopied => 'Código de invitación copiado';

  @override
  String get referralScreenTitle => 'PROGRAMA DE INVITACIONES';

  @override
  String get referralScreenYourCode => 'TU CÓDIGO DE INVITACIÓN';

  @override
  String get referralScreenCopyCode => 'COPIAR CÓDIGO';

  @override
  String get referralScreenShareCode => 'COMPARTIR CÓDIGO';

  @override
  String get referralScreenHowItWorks => 'CÓMO FUNCIONA';

  @override
  String get referralScreenStep1Title => 'Comparte tu código único';

  @override
  String get referralScreenStep1Desc =>
      'Envía tu código de invitación a amigos y colegas.';

  @override
  String get referralScreenStep2Title =>
      'Un negocio se suscribe usando tu código';

  @override
  String get referralScreenStep2Desc =>
      'Cuando se registran y eligen un plan, introducen tu código.';

  @override
  String get referralScreenStep3TitleBusiness =>
      'Ganas 1 mes gratis de suscripción';

  @override
  String get referralScreenStep3TitleCommunity =>
      'Ganas 50-100 puntos (EUR 10-EUR 20)';

  @override
  String get referralScreenStep3DescBusiness =>
      'Tu próximo ciclo de facturación se amplía automáticamente.';

  @override
  String get referralScreenStep3DescCommunity =>
      'Los puntos se añaden a tu monedero y se pueden retirar.';

  @override
  String get referralScreenRewardTiers => 'NIVELES DE RECOMPENSA';

  @override
  String get referralScreenTierBusinessCondition => 'Cada invitación con éxito';

  @override
  String get referralScreenTierBusinessReward => '1 mes gratis';

  @override
  String get referralScreenTier1MonthCondition =>
      'El usuario invitado se queda 1 mes';

  @override
  String get referralScreenTier1MonthReward => '50 ptos (EUR 10)';

  @override
  String get referralScreenTier4MonthCondition =>
      'El usuario invitado se queda 4 meses';

  @override
  String get referralScreenTier4MonthReward => '100 ptos (EUR 20)';

  @override
  String get walletScreenTitle => 'XP Y REPUTACIÓN';

  @override
  String get walletScreenWaysToEarn => 'FORMAS DE GANAR XP';

  @override
  String get walletScreenBadges => 'INSIGNIAS';

  @override
  String get walletScreenCashReferral => 'INVITACIÓN EN EFECTIVO';

  @override
  String get walletScreenXpHistory => 'HISTORIAL DE XP';

  @override
  String get walletScreenXpPoints => 'PUNTOS XP';

  @override
  String walletScreenTotalXp(num count) {
    return 'XP total: $count';
  }

  @override
  String walletScreenXpToNext(num count, String tier) {
    return '$count XP para $tier';
  }

  @override
  String walletScreenXpGain(num count) {
    return '+$count XP';
  }

  @override
  String walletScreenXpAmount(num count) {
    return '$count XP';
  }

  @override
  String get walletScreenMissionCompleteKolab => 'Completa un kolab';

  @override
  String get walletScreenMissionPostReview => 'Publica una reseña';

  @override
  String get walletScreenMissionShareContent => 'Comparte contenido (UGC)';

  @override
  String get walletScreenMissionReferBusiness => 'Invita a un negocio';

  @override
  String get walletScreenNoBadges => 'No hay insignias disponibles';

  @override
  String get walletScreenEarnCashTitle => 'Gana 75 € en efectivo';

  @override
  String get walletScreenEarnCashSubtitle =>
      'Invita a 3 negocios con un plan de 4 meses';

  @override
  String get walletScreenMilestoneReached =>
      '¡Objetivo alcanzado! Solicita tu recompensa en efectivo.';

  @override
  String walletScreenMilestoneProgress(
    num conversions,
    num goal,
    num remaining,
  ) {
    return '$conversions / $goal negocios invitados · faltan $remaining';
  }

  @override
  String walletScreenShareMessage(String code) {
    return 'Únete a Kolabing con mi código: $code';
  }

  @override
  String get walletScreenShareLink => 'COMPARTIR ENLACE';

  @override
  String get walletScreenRequestCash => 'SOLICITAR 75 €';

  @override
  String get walletScreenNoXpActivity =>
      'Aún no hay actividad de XP. ¡Completa un kolab!';

  @override
  String get walletScreenLoadMore => 'CARGAR MÁS';

  @override
  String get withdrawalScreenTitle => 'RETIRAR';

  @override
  String get withdrawalRequestFailed => 'La solicitud de retiro ha fallado';

  @override
  String get withdrawalIbanRequired => 'El IBAN es obligatorio';

  @override
  String get withdrawalIbanInvalid =>
      'Introduce un IBAN válido (15-34 caracteres)';

  @override
  String get withdrawalAccountHolderRequired =>
      'El nombre del titular es obligatorio';

  @override
  String get withdrawalSuccessTitle => 'Solicitud enviada';

  @override
  String get withdrawalSuccessMessage =>
      'Tu solicitud de retiro se ha enviado correctamente. Se procesará en 5-7 días laborables.';

  @override
  String get withdrawalBackToWallet => 'VOLVER AL MONEDERO';

  @override
  String get withdrawalAvailableLabel => 'Disponible para retirar';

  @override
  String get withdrawalIbanLabel => 'IBAN';

  @override
  String get withdrawalIbanHint => 'p. ej. DE89 3704 0044 0532 0130 00';

  @override
  String get withdrawalAccountHolderLabel => 'NOMBRE DEL TITULAR';

  @override
  String get withdrawalAccountHolderHint =>
      'Nombre completo de la cuenta bancaria';

  @override
  String withdrawalSubmitButton(String amount) {
    return 'RETIRAR EUR $amount';
  }

  @override
  String get referralBannerEarnBySharing => 'GANA COMPARTIENDO';

  @override
  String get referralBannerTagline =>
      'Invita a 3 negocios → gana 75 € en efectivo';

  @override
  String get referralBannerShareButton => 'COMPARTIR CÓDIGO';

  @override
  String get referralSheetYourCode => 'TU CÓDIGO DE INVITACIÓN';

  @override
  String get referralSheetInstructions =>
      'Pide a los negocios que usen este código al registrarse.';

  @override
  String get referralSheetCopyCode => 'COPIAR CÓDIGO';

  @override
  String get referralSheetShareCode => 'COMPARTIR CÓDIGO';

  @override
  String get referralSheetShareUnavailable =>
      'No se puede compartir. Código de invitación copiado.';

  @override
  String get referralSheetShareFailed =>
      'No se pudo abrir el menú de compartir. Código de invitación copiado.';

  @override
  String get themeSelectorTitle => 'Apariencia';

  @override
  String get themeSelectorSystemLabel => 'Sistema';

  @override
  String get themeSelectorSystemDescription =>
      'Seguir los ajustes del dispositivo';

  @override
  String get themeSelectorLightLabel => 'Claro';

  @override
  String get themeSelectorLightDescription => 'Usar siempre el tema claro';

  @override
  String get themeSelectorDarkLabel => 'Oscuro';

  @override
  String get themeSelectorDarkDescription => 'Usar siempre el tema oscuro';

  @override
  String get referralCodeFieldLabel => 'Código de invitación (opcional)';

  @override
  String get referralCodeFieldHint => 'Pega el código de invitación';

  @override
  String get discoveryQuickFilterCity => 'Ciudad';

  @override
  String get discoveryQuickFilterKolabType => 'Tipo de Kolab';

  @override
  String get discoveryQuickFilterWhatTheyOffer => 'Qué ofrecen';

  @override
  String get discoveryQuickFilterAvailability => 'Disponibilidad';

  @override
  String get discoveryQuickFilterNeed => 'Oferta';

  @override
  String get discoveryQuickFilterCommunityType => 'Tipo de comunidad';

  @override
  String get discoveryQuickFilterAudienceSize => 'Tamaño de la audiencia';

  @override
  String get profileGallerySectionTitle => 'Galería';

  @override
  String get profileGallerySectionAdd => 'Añadir';

  @override
  String get profileGallerySectionUploading => 'Subiendo foto...';

  @override
  String get profileGallerySheetTitle => 'Añadir foto a la galería';

  @override
  String get profileGallerySheetTakePhoto => 'Hacer foto';

  @override
  String get profileGallerySheetTakePhotoSubtitle => 'Usa tu cámara';

  @override
  String get profileGallerySheetChooseGallery => 'Elegir de la galería';

  @override
  String get profileGallerySheetChooseGallerySubtitle =>
      'Selecciona una foto existente';

  @override
  String get profileGalleryEmptyTitleBusiness => 'Muestra tu local';

  @override
  String get profileGalleryEmptyTitleCommunity => 'Muestra tu comunidad';

  @override
  String get profileGalleryEmptyBodyBusiness =>
      'Añade fotos de tu local para que los socios de kolab vean tu espacio antes de postularse.';

  @override
  String get profileGalleryEmptyBodyCommunity =>
      'Añade fotos de tus eventos para que los nuevos socios de kolab entiendan tu comunidad.';

  @override
  String get profileGalleryDeleteTitle => 'Eliminar foto';

  @override
  String get profileGalleryDeleteBody =>
      '¿Seguro que quieres eliminar esta foto?';

  @override
  String get profileGalleryDeleteConfirm => 'Eliminar';

  @override
  String get exploreFilterSearchHint =>
      'Busca por título, descripción o creador...';

  @override
  String get exploreFilterCity => 'Ciudad';

  @override
  String get exploreFilterCityHint => 'Escribe una ciudad';

  @override
  String get exploreFilterAvailability => 'Disponibilidad';

  @override
  String get exploreFilterKolabType => 'Tipo de Kolab';

  @override
  String get exploreFilterWhatTheyOffer => 'Qué ofrecen';

  @override
  String get exploreFilterVenueType => 'Tipo de local';

  @override
  String get exploreFilterProductType => 'Tipo de producto';

  @override
  String get exploreFilterExpectedDeliverables => 'Entregables esperados';

  @override
  String get exploreFilterMinCommunitySize =>
      'Tamaño mínimo de comunidad requerido';

  @override
  String get exploreFilterNeed => 'Oferta';

  @override
  String get exploreFilterCommunityType => 'Tipo de comunidad';

  @override
  String get exploreFilterAudienceSize => 'Tamaño de la audiencia';

  @override
  String get exploreFilterOffersInReturn => 'Ofrece a cambio';

  @override
  String get exploreFilterVenuePreference => 'Preferencia de local';

  @override
  String get exploreFilterTitle => 'Buscar y filtrar';

  @override
  String get exploreFilterClearAll => 'Borrar todo';

  @override
  String get exploreFilterNoMatchingCities => 'No se encontraron ciudades';

  @override
  String get exploreFilterCitySuggestionsError =>
      'No se pudieron cargar las sugerencias de ciudades';

  @override
  String exploreFilterResultsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados encontrados',
      one: '1 resultado encontrado',
      zero: 'Mostrando todas las oportunidades',
    );
    return '$_temp0';
  }

  @override
  String exploreSwipeCardMatch(num score) {
    return '$score% de coincidencia';
  }

  @override
  String get exploreSwipeCardBusinessOffer => 'Oferta de empresa';

  @override
  String get exploreSwipeCardCommunityRequest => 'Solicitud de comunidad';

  @override
  String exploreSwipeCardKolabsCount(num count) {
    return '$count Kolabs';
  }

  @override
  String exploreSwipeCardPreviousKolabs(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kolabs anteriores',
      one: '1 Kolab anterior',
    );
    return '$_temp0';
  }

  @override
  String get exploreSwipeCardViewDetails => 'Ver detalles';

  @override
  String get exploreDetailUnknownCreator => 'Desconocido';

  @override
  String get exploreDetailSubscribeToReveal =>
      'Suscríbete para ver esta comunidad';

  @override
  String get exploreDetailCreatorBadge => 'Creador';

  @override
  String get exploreDetailLookingFor => 'Qué están buscando';

  @override
  String get exploreDetailWhatTheyOffer => 'Qué ofrecen';

  @override
  String get exploreDetailCommunitySize => 'Tamaño de la comunidad';

  @override
  String exploreDetailScaleCommunity(num count) {
    return '$count en la comunidad';
  }

  @override
  String exploreDetailScaleExpected(num count) {
    return '$count esperados';
  }

  @override
  String get exploreDetailWhatsOffered => 'Qué se ofrece';

  @override
  String get exploreDetailAvailableDays => 'Días disponibles';

  @override
  String get exploreDetailUnlockToApply => 'DESBLOQUEAR PARA POSTULARTE';

  @override
  String get exploreDetailApplyNow => 'POSTULARTE AHORA';

  @override
  String get exploreDetailViewCreatorProfile => 'Ver perfil del creador';

  @override
  String get exploreDetailPastEventPhotos => 'Fotos de eventos pasados';

  @override
  String get exploreDetailRecentMoments =>
      'Momentos recientes de esta comunidad';

  @override
  String get subscriptionScreenTitle => 'Suscripción';

  @override
  String get subscriptionScreenAppleError =>
      'No se pudo iniciar la compra en la App Store';

  @override
  String get subscriptionScreenCheckoutError =>
      'No se pudo crear la sesión de pago';

  @override
  String get subscriptionReferralCodeApplied => 'Código de referido aplicado.';

  @override
  String get subscriptionReactivateSuccess =>
      'Suscripción reactivada correctamente';

  @override
  String get subscriptionCancelScheduledToast =>
      'La suscripción se cancelará al final del periodo de facturación';

  @override
  String get subscriptionCancelDialogTitle => 'Cancelar suscripción';

  @override
  String get subscriptionCancelDialogBody =>
      'Tu suscripción seguirá activa hasta el final del periodo de facturación actual. Puedes volver a suscribirte en cualquier momento.\n\n¿Seguro que quieres cancelar?';

  @override
  String get subscriptionKeepButton => 'Mantener suscripción';

  @override
  String get subscriptionCancelButton => 'Cancelar suscripción';

  @override
  String get subscriptionStatusPremiumTitle => 'Negocio Premium';

  @override
  String get subscriptionStatusActiveSubtitle => 'Tu suscripción está activa';

  @override
  String get subscriptionStatusEndingTitle => 'Suscripción finalizando';

  @override
  String get subscriptionStatusEndingSubtitle =>
      'Activa hasta el final del periodo de facturación';

  @override
  String get subscriptionStatusPastDueTitle => 'Pago fallido';

  @override
  String get subscriptionStatusPastDueSubtitle => 'Actualiza tu método de pago';

  @override
  String get subscriptionStatusNoPlanTitle => 'Sin plan activo';

  @override
  String get subscriptionStatusNoPlanSubtitle =>
      'Suscríbete para publicar oportunidades';

  @override
  String get subscriptionBenefitsTitle => 'Beneficios Premium';

  @override
  String get subscriptionBenefitPublishTitle => 'Publica oportunidades';

  @override
  String get subscriptionBenefitPublishDesc =>
      'Crea y publica ofertas de kolab';

  @override
  String get subscriptionBenefitConnectTitle => 'Conecta con comunidades';

  @override
  String get subscriptionBenefitConnectDesc =>
      'Llega a comunidades y creadores locales';

  @override
  String get subscriptionBenefitApplicationsTitle => 'Recibe solicitudes';

  @override
  String get subscriptionBenefitApplicationsDesc =>
      'Recibe solicitudes de comunidades interesadas';

  @override
  String get subscriptionBenefitTrackTitle => 'Mide el rendimiento';

  @override
  String get subscriptionBenefitTrackDesc =>
      'Monitoriza las métricas de tus kolabs';

  @override
  String get subscriptionPerMonthUnit => 'EUR/mes';

  @override
  String get subscriptionPlanDetailsTitle => 'Detalles del plan';

  @override
  String get subscriptionDetailPlanLabel => 'Plan';

  @override
  String get subscriptionDetailPriceLabel => 'Precio';

  @override
  String get subscriptionPriceMonthly => '29 EUR/mes';

  @override
  String get subscriptionDetailCurrentPeriodLabel => 'Periodo actual';

  @override
  String get subscriptionDetailRenewsOnLabel => 'Se renueva el';

  @override
  String get subscriptionDetailDaysRemainingLabel => 'Días restantes';

  @override
  String subscriptionDaysValue(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get subscriptionPastDueWarningBody =>
      'Tu último pago falló. Actualiza tu método de pago para seguir publicando oportunidades.';

  @override
  String get subscriptionCancelPendingTitle => 'Cancelación programada';

  @override
  String subscriptionCancelPendingBody(String endDate) {
    return 'Tu suscripción está activa hasta el $endDate. Después de esa fecha, no podrás publicar nuevas oportunidades.';
  }

  @override
  String get subscriptionEndOfBillingPeriod =>
      'el final del periodo de facturación';

  @override
  String get subscriptionReactivateButton => 'REACTIVAR SUSCRIPCIÓN';

  @override
  String get subscriptionSubscribeButton => 'SUSCRIBIRSE';

  @override
  String get subscriptionSubscribePricedButton => 'SUSCRIBIRSE POR 29 EUR/MES';

  @override
  String get subscriptionUpdatePaymentButton => 'ACTUALIZAR MÉTODO DE PAGO';

  @override
  String get subscriptionManageBillingButton => 'GESTIONAR FACTURACIÓN';

  @override
  String get subscriptionLoadingApplePrice =>
      'Cargando precio de la App Store...';

  @override
  String get subscriptionUnavailable => 'Suscripción no disponible';

  @override
  String subscriptionPricePerMonth(String price) {
    return '$price/mes';
  }

  @override
  String get subscriptionPaywallAppleError =>
      'No se pudo iniciar la compra en la App Store';

  @override
  String get subscriptionPaywallCheckoutError =>
      'No se pudo crear la sesión de pago';

  @override
  String get subscriptionPaywallTitle => 'Mejora a Premium';

  @override
  String get subscriptionPaywallDescription =>
      'Has usado tu solicitud de kolab gratuita. Suscríbete para crear solicitudes ilimitadas y conectar con más comunidades.';

  @override
  String get subscriptionPaywallBenefitUnlimited =>
      'Publica solicitudes de kolab ilimitadas';

  @override
  String get subscriptionPaywallBenefitConnect =>
      'Conecta con comunidades locales';

  @override
  String get subscriptionPaywallBenefitApplications =>
      'Recibe y gestiona solicitudes';

  @override
  String get subscriptionPaywallPerMonth => '/ mes';

  @override
  String get subscriptionPaywallSubscribeButton => 'SUSCRIBIRSE AHORA';

  @override
  String get subscriptionPaywallNotNowButton => 'Ahora no';

  @override
  String get subscriptionRestorePurchasesButton => 'Restaurar compras';

  @override
  String get pastEventsStepHeader => 'KOLABS ANTERIORES (OPCIONAL)';

  @override
  String referralShareMessage(String code) {
    return 'Comparte Kolabing y Gana: usa mi código de invitación $code al registrar tu negocio.';
  }

  @override
  String get dashboardBusinessTitle => 'PANEL DE NEGOCIO';

  @override
  String get dashboardCommunityTitle => 'PANEL DE COMUNIDAD';

  @override
  String dashboardWelcomeBack(String name) {
    return 'Hola de nuevo, $name';
  }

  @override
  String get dashboardErrorLoad =>
      'No se han podido cargar los datos del panel';

  @override
  String get dashboardStatPublished => 'Publicadas';

  @override
  String get dashboardStatPendingApplications => 'Solicitudes pendientes';

  @override
  String get dashboardStatActiveKolabs => 'Kolabs activos';

  @override
  String get dashboardStatCompleted => 'Completados';

  @override
  String get dashboardStatPending => 'Pendientes';

  @override
  String get dashboardStatAccepted => 'Aceptadas';

  @override
  String get dashboardCreateKolabRequest => 'CREAR SOLICITUD DE KOLAB';

  @override
  String get dashboardFindAKolab => 'BUSCAR UN KOLAB';

  @override
  String get dashboardMyApplications => 'MIS SOLICITUDES';

  @override
  String get dashboardUpcomingKolabs => 'PRÓXIMOS KOLABS';

  @override
  String get dashboardNoUpcomingKolabs => 'Aún no hay kolabs próximos';

  @override
  String get dashboardDefaultBusinessName => 'Negocio';

  @override
  String get dashboardDefaultCommunityName => 'Comunidad';

  @override
  String get eventHubOpenChat => 'Abrir chat del evento';

  @override
  String get eventHubAttendeesTitle => 'Asistentes';

  @override
  String get eventHubWaitlistTitle => 'Lista de espera';

  @override
  String get eventHubNoAttendees => 'Aún no se ha apuntado nadie.';

  @override
  String eventHubGoingCount(num count) {
    return '$count asistirán';
  }

  @override
  String eventHubWaitlistCount(num count) {
    return '$count en lista de espera';
  }

  @override
  String eventHubCapacity(num count) {
    return 'aforo $count';
  }

  @override
  String eventHubSpotsLeft(num count) {
    return 'quedan $count plaza(s)';
  }

  @override
  String get eventHubUnlimited => 'Ilimitado';

  @override
  String get eventHubImGoing => 'Voy a ir';

  @override
  String get eventHubGoingTapToLeave => 'Asistirás ✓  ·  toca para salir';

  @override
  String get eventHubJoinWaitlist => 'Unirse a la lista de espera';

  @override
  String get eventHubOnWaitlistTapToLeave =>
      'En lista de espera  ·  toca para salir';

  @override
  String eventHubWaitlistPosition(num position) {
    return 'Eres el número $position en la lista de espera';
  }

  @override
  String get eventDetailViewCommunity => 'Ver comunidad';

  @override
  String get eventHubEdit => 'Editar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get eventHubDelete => 'Eliminar evento';

  @override
  String get eventHubScanCheckIns => 'Escanear registros';

  @override
  String get eventHubDeleteConfirmTitle => '¿Eliminar este evento?';

  @override
  String eventHubDeleteConfirmBody(String name) {
    return '\"$name\": se avisará a quien vaya a asistir o esté en lista de espera de que se ha cancelado.';
  }

  @override
  String get eventHubDeleteScopeThis => 'Solo este evento';

  @override
  String get eventHubDeleteScopeFollowing => 'Este y los siguientes eventos';

  @override
  String get eventHubDeleteScopeSeries => 'Toda la serie';

  @override
  String get eventHubDeleted => 'Evento eliminado';

  @override
  String get eventHubExtendSeries => 'Ampliar serie (+3 meses)';

  @override
  String eventHubExtended(int count) {
    return 'Serie ampliada: $count fechas nuevas';
  }

  @override
  String get eventHubExtendedNone => 'No hay fechas nuevas que añadir';

  @override
  String get eventHubAddPhotos => 'Añadir fotos';

  @override
  String get eventFormNewTitle => 'Nuevo evento';

  @override
  String get eventFormEditTitle => 'Editar evento';

  @override
  String get eventFormSave => 'Guardar';

  @override
  String get eventFormPublish => 'Publicar evento';

  @override
  String get eventFormRepeatLabel => 'Repetir';

  @override
  String get eventFormRepeatNone => 'No se repite';

  @override
  String get eventFormRepeatWeekly => 'Semanal';

  @override
  String get eventFormRepeatBiweekly => 'Cada 2 semanas';

  @override
  String get eventFormRepeatMonthly => 'Mensual';

  @override
  String get eventFormRepeatEnds => 'Termina';

  @override
  String get eventFormRepeatNever => 'Nunca';

  @override
  String get eventFormRepeatAfter => 'Después de';

  @override
  String get eventFormRepeatEvents => 'eventos';

  @override
  String get eventFormRepeatOnDate => 'En una fecha';

  @override
  String get eventFormRepeatChatLabel => 'Chat de la serie';

  @override
  String get eventFormRepeatChatPerEvent => 'Un chat por evento';

  @override
  String get eventFormRepeatChatShared => 'Un chat compartido para la serie';

  @override
  String get eventFormPublishSeries => 'Publicar serie';

  @override
  String get eventFormApplyTo => 'Aplicar los cambios a';

  @override
  String get eventFormErrWeekday => 'Elige al menos un día';

  @override
  String get eventFormErrEndsCount => 'Indica cuántos eventos';

  @override
  String get eventFormErrEndsOn => 'Elige una fecha posterior al inicio';

  @override
  String get eventFormNameLabel => 'Nombre';

  @override
  String get eventFormNameHint => 'Carrera 10K del sábado';

  @override
  String get eventFormStartsLabel => 'Empieza';

  @override
  String get eventFormEndsLabel => 'Termina (opcional)';

  @override
  String get eventFormPickStart => 'Elige fecha y hora de inicio';

  @override
  String get eventFormPickEnd => 'Elige fecha y hora de fin';

  @override
  String get eventFormLocationLabel => 'Ubicación (opcional)';

  @override
  String get eventFormLocationHint => 'Parque de la Ciudadela';

  @override
  String get eventFormCityLabel => 'Ciudad (opcional)';

  @override
  String get eventFormCityHint => 'Selecciona una ciudad';

  @override
  String get eventFormLocationSearchHint => 'Busca el local o la dirección';

  @override
  String get eventFormLocationStartTyping =>
      'Empieza a escribir el local o la dirección para ver sugerencias.';

  @override
  String get eventFormLocationNoMatches =>
      'Aún no hay coincidencias. Prueba a añadir la ciudad a la dirección.';

  @override
  String get eventFormLocationError =>
      'No pudimos cargar las sugerencias de ubicación ahora mismo.';

  @override
  String eventFormCityDetected(String city) {
    return 'Ciudad: $city';
  }

  @override
  String get eventFormCityNotDetected =>
      'No se detectó ninguna ciudad para este lugar. El evento no aparecerá en el descubrimiento por ciudad.';

  @override
  String get eventFormCapacityLabel => 'Aforo (opcional)';

  @override
  String get eventFormLimit => 'Límite';

  @override
  String get eventFormWhoCanJoin => 'Quién puede unirse';

  @override
  String get eventFormAllMembers => 'Todos los miembros';

  @override
  String get eventFormSelectedTiers => 'Niveles seleccionados';

  @override
  String get eventFormVisibilityLabel => 'Visibilidad';

  @override
  String get eventFormVisibilityPublic => 'Pública';

  @override
  String get eventFormVisibilityPublicHint =>
      'Aparece en el descubrimiento de la ciudad: cualquiera puede encontrarla.';

  @override
  String get eventFormVisibilityMembers => 'Miembros';

  @override
  String get eventFormVisibilityMembersHint =>
      'Solo los miembros de tu comunidad pueden verla.';

  @override
  String get eventFormVisibilityTier => 'Nivel específico';

  @override
  String get eventFormVisibilityTierHint =>
      'Solo los miembros de los niveles seleccionados pueden verla.';

  @override
  String get eventFormPhotos => 'Fotos';

  @override
  String get eventFormAddFromGallery => 'Añadir desde la galería';

  @override
  String get eventFormPhotosAfterCreate =>
      'Las fotos se pueden añadir una vez creado el evento.';

  @override
  String get eventFormErrName =>
      'El nombre del evento necesita al menos 3 caracteres.';

  @override
  String get eventFormErrStart => 'Elige una fecha y hora de inicio.';

  @override
  String get eventFormErrStartFuture => 'El inicio debe ser en el futuro.';

  @override
  String get eventFormErrEndAfterStart =>
      'El fin debe ser posterior al inicio.';

  @override
  String get eventFormErrCapacity =>
      'Introduce un aforo válido o desactiva el límite.';

  @override
  String get eventFormErrTier =>
      'Selecciona al menos un nivel para este evento.';

  @override
  String get eventFormPhotosUploaded => 'Fotos subidas.';

  @override
  String eventPhotosMaxPerAdd(int max) {
    return 'Puedes añadir hasta $max fotos a la vez.';
  }

  @override
  String eventPhotosTotalCapReached(int count, int max) {
    return 'Esta galería ya tiene $count de $max fotos.';
  }

  @override
  String eventPhotosTotalCapPartial(int allowed, int max) {
    return 'Solo se pueden añadir $allowed fotos más (máximo $max en total).';
  }

  @override
  String get eventFormAddFromCommunity =>
      'Elegir de la galería de la comunidad';

  @override
  String get eventFormCommunityGalleryTitle => 'Galería de la comunidad';

  @override
  String get eventFormCommunityGalleryEmpty =>
      'Aún no hay fotos en la galería de la comunidad.';

  @override
  String eventFormCommunityGalleryAdd(int count) {
    return 'Añadir $count fotos';
  }

  @override
  String get communityShareInvite => 'Compartir invitación';

  @override
  String communityShareInviteMessage(String name, String url) {
    return 'Únete a $name en Kolabing: $url';
  }

  @override
  String get communityShareInviteCopied => 'Enlace de invitación copiado.';

  @override
  String get notifSettingsTitle => 'Notificaciones';

  @override
  String get notifSettingsMessages => 'Mensajes';

  @override
  String get notifSettingsMessagesSubtitle =>
      'Nuevos mensajes de chat en tus comunidades y eventos';

  @override
  String get notifSettingsApplications => 'Nuevas solicitudes';

  @override
  String get notifSettingsApplicationsSubtitle =>
      'Cuando alguien se postula a tu Kolab';

  @override
  String get notifSettingsCollaborations => 'Actualizaciones de colaboraciones';

  @override
  String get notifSettingsCollaborationsSubtitle =>
      'Cambios de estado en tus Kolabs';

  @override
  String get notifSettingsMarketing => 'Consejos y novedades';

  @override
  String get notifSettingsMarketingSubtitle =>
      'Consejos de producto y noticias ocasionales';

  @override
  String get notifSettingsSaveError =>
      'No se pudo guardar tu preferencia. Inténtalo de nuevo.';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get chatInboxTooltip => 'Chats';

  @override
  String get chatThreadFallbackTitle => 'Chat';

  @override
  String get chatSenderFallback => 'Miembro';

  @override
  String get chatThreadTapToOpen => 'Toca para abrir';

  @override
  String get chatThreadNoMessagesYet => 'Aún no hay mensajes';

  @override
  String get chatInboxEmptyTitle => 'Aún no hay chats';

  @override
  String get chatInboxEmptyBody =>
      'Las conversaciones aparecerán aquí cuando se inicie un chat de un Kolab, una comunidad o un evento.';

  @override
  String get chatSectionMain => 'Principal';

  @override
  String get chatSectionCommunityChats => 'Chats de la comunidad';

  @override
  String get chatSectionEvents => 'Eventos';

  @override
  String get chatSectionKolabs => 'Kolabs';

  @override
  String get chatComposerHint => 'Mensaje';

  @override
  String get chatThreadEmptyMessage => 'Aún no hay mensajes. Saluda 👋';

  @override
  String get chatManageNewChatTitle => 'Nuevo chat';

  @override
  String get chatManageRenameTitle => 'Renombrar chat';

  @override
  String get chatManageNameLabel => 'Nombre del chat';

  @override
  String get chatManageNameHint => 'p. ej. Directivos, Sociales, Filantropía';

  @override
  String get chatManageCreate => 'Crear';

  @override
  String get chatManageRename => 'Renombrar';

  @override
  String get chatManageDelete => 'Eliminar';

  @override
  String get chatManageCreateChat => 'Crear chat';

  @override
  String chatManageChatCreated(String name) {
    return 'Se creó \"$name\"';
  }

  @override
  String get chatManageChatRenamed => 'Chat renombrado';

  @override
  String get chatManageChatDeleted => 'Chat eliminado';

  @override
  String chatManageChatLimit(int count) {
    return 'Llegaste al límite de $count chats personalizados.';
  }

  @override
  String get chatManageDeleteTitle => '¿Eliminar este chat?';

  @override
  String chatManageDeleteBody(String name) {
    return 'Los miembros perderán acceso a \"$name\". Puedes recuperarlo después si cambias de opinión.';
  }

  @override
  String get chatManageWhichCommunity => '¿Cuál comunidad?';

  @override
  String get chatJoinSectionTitle => 'Chats a los que te puedes unir';

  @override
  String get chatJoinAction => 'Unirme';

  @override
  String chatJoinedSnack(String name) {
    return 'Te uniste a \"$name\"';
  }

  @override
  String get chatThreadOpenEvent => 'Abrir evento';

  @override
  String get chatMembersTitle => 'Miembros';

  @override
  String get chatMembersEmpty => 'Aún no hay miembros para administrar.';

  @override
  String get chatMemberRemove => 'Quitar';

  @override
  String chatMemberRemoveTitle(String name) {
    return '¿Quitar a $name?';
  }

  @override
  String get chatMemberRemoveBody =>
      'Perderá acceso a este chat y no podrá volver a unirse.';

  @override
  String chatMemberRemoved(String name) {
    return 'Se quitó a $name';
  }

  @override
  String get chatThreadManageMembers => 'Administrar miembros';

  @override
  String get communityDetailTabChats => 'Chats';

  @override
  String get communityDetailTabEvents => 'Eventos';

  @override
  String get communityDetailTabMembers => 'Miembros';

  @override
  String get communityDetailTabDetails => 'Detalles';

  @override
  String communityDetailTypeAndMembers(String type, int count) {
    return '$type · $count miembros';
  }

  @override
  String communityDetailMembersCount(int count) {
    return '$count miembros';
  }

  @override
  String get communityDetailChatsLoadError => 'No se pudieron cargar los chats';

  @override
  String get communityDetailNoChatsTitle => 'Aún no hay chats';

  @override
  String get communityDetailNoChatsBody =>
      'Las conversaciones de esta comunidad aparecerán aquí.';

  @override
  String get communityDetailNoEventsTitle => 'No hay próximos eventos';

  @override
  String get communityDetailNoEventsBody =>
      'Los eventos creados para esta comunidad aparecerán aquí.';

  @override
  String get communityDetailEventLockedSubtitle =>
      'Bloqueado — para otro nivel de membresía';

  @override
  String get communityDetailEventLockedSnack =>
      'Este evento es para otro nivel de membresía.';

  @override
  String get communityDetailLeaderboardButton => 'Clasificación del capítulo';

  @override
  String get communityDetailAboutLabel => 'Acerca de';

  @override
  String get communityDetailMembershipLabel => 'Tu membresía';

  @override
  String get communityDetailRowTier => 'Nivel';

  @override
  String get communityDetailRowType => 'Tipo';

  @override
  String get communityDetailRowMembers => 'Miembros';

  @override
  String get communityDetailRowRole => 'Rol';

  @override
  String get communityDetailRoleCanManage => 'Puede gestionar';

  @override
  String get communityDetailTierFallback => 'Miembro';

  @override
  String get communityDetailGalleryLabel => 'Galería y eventos pasados';

  @override
  String get communityDetailGalleryBody =>
      'Las fotos y los eventos pasados estarán aquí cuando se lance el ciclo de vida de eventos (Fase 3).';

  @override
  String get communityDetailGalleryEmpty =>
      'Aún no hay eventos pasados que mostrar.';

  @override
  String get myCommunitiesNoTier => 'Sin nivel todavía';

  @override
  String get myCommunitiesAdminBadge => 'ADMIN';

  @override
  String get myCommunitiesEmptyTitle => 'Aún no perteneces a ninguna comunidad';

  @override
  String get myCommunitiesEmptyBody =>
      'Únete a una comunidad para ganarte tu lugar en sus niveles y ver eventos y ventajas exclusivos para miembros.';

  @override
  String get communityHubEmptyTitle => 'Crea tu comunidad';

  @override
  String get communityHubEmptyBody =>
      'Crea una comunidad para formar una lista de miembros y configurar tus propios niveles. Tu primera comunidad es gratis.';

  @override
  String get communityHubCreateCommunity => 'CREAR COMUNIDAD';

  @override
  String get communityHubSectionTiers => 'Niveles';

  @override
  String get communityHubSectionMembers => 'Miembros';

  @override
  String get communityHubSectionEvents => 'Eventos';

  @override
  String get communityHubSectionChats => 'Chats';

  @override
  String communityHubTypeAndMembers(String type, int count) {
    return '$type  ·  $count miembros';
  }

  @override
  String get communityHubNoEvents => 'Aún no hay próximos eventos.';

  @override
  String get communityHubCreateEvent => 'Crear evento';

  @override
  String get communityHubNewChatTitle => 'Nuevo chat';

  @override
  String get communityHubChatNameLabel => 'Nombre del chat';

  @override
  String get communityHubChatNameHint => 'p. ej. Junta, Social, Filantropía';

  @override
  String get communityHubCreate => 'Crear';

  @override
  String communityHubChatCreated(String name) {
    return '\"$name\" creado';
  }

  @override
  String communityHubChatLimit(int count) {
    return 'Puedes tener hasta $count chats';
  }

  @override
  String get communityHubAccess => 'Acceso';

  @override
  String get chatManageAccess => 'Quién puede acceder';

  @override
  String get chatManageMembers => 'Miembros';

  @override
  String get chatBlock => 'Bloquear';

  @override
  String get chatUnblock => 'Desbloquear';

  @override
  String get chatBlockedTag => 'Bloqueado';

  @override
  String get chatRenameHint => 'Nombre del chat';

  @override
  String get chatRenamed => 'Chat renombrado';

  @override
  String get chatDeleteTitle => '¿Eliminar este chat?';

  @override
  String chatDeleteBody(String name) {
    return 'Se eliminarán todos los mensajes de \"$name\".';
  }

  @override
  String get chatDeleted => 'Chat eliminado';

  @override
  String get communityHubAccessNoTiers => 'Ningún nivel';

  @override
  String get communityHubAccessAllTiers => 'Todos los niveles';

  @override
  String get communityHubAccessOneTier => '1 nivel';

  @override
  String communityHubAccessTierCount(int count) {
    return '$count niveles';
  }

  @override
  String get communityHubCreateTiersFirst =>
      'Crea primero niveles de membresía para restringir los chats.';

  @override
  String communityHubAccessDialogTitle(String name) {
    return '¿Quién puede acceder a \"$name\"?';
  }

  @override
  String get communityHubAccessDialogChat => 'chat';

  @override
  String get communityHubAccessDialogBody =>
      'Tú y tus gestores siempre tenéis acceso. Elige qué niveles de miembros pueden abrir este chat.';

  @override
  String get communityHubChatAccessUpdated => 'Acceso al chat actualizado';

  @override
  String communityHubNoChatsHint(int count) {
    return 'Aún no hay chats. Tu chat principal y hasta $count chats personalizados aparecerán aquí.';
  }

  @override
  String get communityHubCreateChat => 'Crear chat';

  @override
  String communityHubChatLimitReached(int count) {
    return 'Límite de chats alcanzado ($count chats personalizados).';
  }

  @override
  String get communityHubChatMain => 'Principal';

  @override
  String get communityHubChatFallback => 'Chat';

  @override
  String get communityHubChipMain => 'PRINCIPAL';

  @override
  String communityHubTierDetail(String rule, int threshold, String unit) {
    return '$rule · $threshold $unit';
  }

  @override
  String get communityHubChipDefault => 'PREDETERMINADO';

  @override
  String communityHubTierRank(int rank) {
    return '#$rank';
  }

  @override
  String get communityHubNoTiersHint =>
      'Aún no hay niveles. Añade niveles para dar a los miembros una escala de estatus.';

  @override
  String get communityHubAddTier => 'Añadir nivel';

  @override
  String get communityHubNoMembersHint =>
      'Aún no hay miembros. Invita a personas o comparte tu enlace de invitación.';

  @override
  String get communityHubManageMembers => 'Gestionar miembros';

  @override
  String communityHubManageAllMembers(int count) {
    return 'Gestionar los $count miembros';
  }

  @override
  String get communityHubMemberFallback => 'Miembro';

  @override
  String get communityHubChipAdmin => 'ADMIN';

  @override
  String get communityHubLoadError => 'No se pudo cargar tu comunidad';

  @override
  String get createCommunityPremiumTitle => 'Community Premium';

  @override
  String get createCommunityPremiumBody =>
      'Tu plan gratuito incluye una comunidad. Gestionar más de una forma parte de Community Premium — próximamente.';

  @override
  String get createCommunityTitle => 'Nueva comunidad';

  @override
  String get createCommunityNameLabel => 'Nombre';

  @override
  String get createCommunityNameHint =>
      'p. ej. Kappa Delta — Beta Chi, o Club de Running de la Ciudad';

  @override
  String get createCommunityNameRequired => 'El nombre es obligatorio';

  @override
  String get createCommunityTypeLabel => 'Tipo';

  @override
  String get createCommunityWhoCanJoin => 'Quién puede unirse';

  @override
  String get createCommunityJoinAnyone => 'Cualquiera';

  @override
  String get createCommunityJoinInviteOnly => 'Solo con invitación';

  @override
  String get createCommunitySubmit => 'CREAR COMUNIDAD';

  @override
  String get tierEditorEditTitle => 'Editar nivel';

  @override
  String get tierEditorNewTitle => 'Nuevo nivel';

  @override
  String get tierEditorDeleteTooltip => 'Eliminar nivel';

  @override
  String get tierEditorDeleteTitle => '¿Eliminar nivel?';

  @override
  String tierEditorDeleteBody(String name) {
    return '¿Eliminar \"$name\"? Habrá que reasignar a los miembros que lo tengan.';
  }

  @override
  String get tierEditorDelete => 'Eliminar';

  @override
  String get tierEditorNameLabel => 'Nombre';

  @override
  String get tierEditorNameHint => 'p. ej. Junta, Activo, Capitán, Entrenador';

  @override
  String get tierEditorNameRequired => 'El nombre es obligatorio';

  @override
  String get tierEditorRankLabel => 'Rango (mayor = más senior)';

  @override
  String get tierEditorRankRequired => 'Introduce un número (1 o superior)';

  @override
  String get tierEditorColourLabel => 'Color';

  @override
  String get tierEditorRuleLabel => 'Cómo obtienen los miembros este nivel';

  @override
  String tierEditorThresholdLabel(String unit) {
    return 'Umbral ($unit)';
  }

  @override
  String tierEditorThresholdRequired(String unit) {
    return 'Introduce un umbral de $unit';
  }

  @override
  String get tierEditorSave => 'GUARDAR';

  @override
  String get tierEditorCreate => 'CREAR NIVEL';

  @override
  String get rosterTitle => 'Miembros';

  @override
  String get rosterInviteTooltip => 'Invitar miembro';

  @override
  String get rosterInviteTitle => 'Invitar miembro';

  @override
  String get rosterInviteBody =>
      'Añade un miembro con el correo de su cuenta de Kolabing.';

  @override
  String get rosterInviteEmailLabel => 'Correo electrónico';

  @override
  String get rosterInviteEmailHint => 'nombre@ejemplo.com';

  @override
  String get rosterInvite => 'Invitar';

  @override
  String get rosterInviteInvalidEmail =>
      'Introduce un correo electrónico válido';

  @override
  String get rosterMemberAdded => 'Miembro añadido';

  @override
  String get rosterNoAccountForEmail =>
      'No se encontró ninguna cuenta de Kolabing con ese correo';

  @override
  String get rosterMemberFallback => 'Miembro';

  @override
  String get rosterViewProfile => 'Ver perfil';

  @override
  String get rosterEmptyTitle => 'Aún no hay miembros';

  @override
  String get rosterInviteMember => 'Invitar a un miembro';

  @override
  String get rosterRemoveTitle => '¿Eliminar miembro?';

  @override
  String rosterRemoveBody(String name) {
    return '¿Eliminar a $name de la comunidad?';
  }

  @override
  String get rosterRemoveBodyFallback => 'este miembro';

  @override
  String get rosterRemove => 'Eliminar';

  @override
  String get rosterTierLabel => 'Nivel';

  @override
  String get rosterNoTier => 'Sin nivel';

  @override
  String get rosterCanManageTitle => 'Puede gestionar esta comunidad';

  @override
  String get rosterCanManageSubtitle =>
      'Capacidad de administración — independiente del nivel';

  @override
  String get rosterStatusLabel => 'Estado';

  @override
  String get rosterSave => 'GUARDAR';

  @override
  String get friendsTitle => 'Amigos';

  @override
  String get friendRequestsTitle => 'Solicitudes';

  @override
  String get friendAdd => 'Agregar amigo';

  @override
  String get friendPending => 'Pendiente';

  @override
  String get friendAccept => 'Aceptar';

  @override
  String get friendDecline => 'Rechazar';

  @override
  String get friendFriends => 'Amigos';

  @override
  String get friendRemoveTitle => '¿Eliminar a este amigo?';

  @override
  String get friendRemoveConfirm => 'Eliminar amigo';

  @override
  String get friendActionFailed => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get friendsEmpty => 'Aún no tienes amigos';

  @override
  String get friendsLoadError => 'No se pudieron cargar los amigos';

  @override
  String get friendUnknownName => 'Miembro';

  @override
  String get friendCountOne => '1 amigo';

  @override
  String friendCountOther(int count) {
    return '$count amigos';
  }

  @override
  String get discoverCommunitiesTitle => 'Descubre comunidades';

  @override
  String get discoverCommunitiesCta => 'Descubre comunidades';

  @override
  String get discoverCommunitiesJoin => 'Unirse';

  @override
  String get discoverCommunitiesJoined => 'Te has unido';

  @override
  String discoverCommunitiesJoinedToast(String name) {
    return 'Te has unido a $name';
  }

  @override
  String get discoverCommunitiesInviteOnly => 'Solo con invitación';

  @override
  String discoverCommunitiesInviteOnlyMessage(String name) {
    return '$name es solo con invitación. Pide a un miembro que te añada.';
  }

  @override
  String get discoverCommunitiesJoinError =>
      'No se pudo unir ahora mismo. Inténtalo de nuevo.';

  @override
  String discoverCommunitiesMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miembros',
      one: '1 miembro',
    );
    return '$_temp0';
  }

  @override
  String get discoverCommunitiesEmptyTitle => 'Aún no hay nada que descubrir';

  @override
  String get discoverCommunitiesEmptyBody =>
      'El descubrimiento de comunidades llegará pronto. Vuelve para encontrar y unirte a comunidades cerca de ti.';

  @override
  String get discoverCommunitiesError =>
      'No se pudieron cargar las comunidades. Inténtalo de nuevo.';

  @override
  String get commonSkip => 'Omitir';

  @override
  String get handleFieldPlaceholder => 'tunombre';

  @override
  String get handleFieldHint =>
      '3-20 caracteres: minúsculas, números y guiones bajos.';

  @override
  String get handleFieldFormatError =>
      'Usa 3-20 minúsculas, números o guiones bajos.';

  @override
  String get handleFieldChecking => 'Comprobando disponibilidad…';

  @override
  String get handleFieldAvailable => 'Disponible';

  @override
  String get handleFieldTaken => 'Ese nombre de usuario no está disponible.';

  @override
  String handleFieldTakenWithSuggestion(String suggestion) {
    return 'No disponible. Prueba @$suggestion';
  }

  @override
  String get handleFieldYours => 'Este es tu nombre de usuario actual.';

  @override
  String attendeeOnboardingStepCounter(int step, int total) {
    return 'Paso $step de $total';
  }

  @override
  String get attendeeOnboardingStep1Title => 'Vamos a configurarte';

  @override
  String get attendeeOnboardingStep1Subtitle =>
      'Añade tu nombre, elige un nombre de usuario y una foto si quieres.';

  @override
  String get attendeeOnboardingAddPhoto => 'Añadir una foto';

  @override
  String get attendeeOnboardingNameLabel => 'Tu nombre';

  @override
  String get attendeeOnboardingNameHint => '¿Cómo quieres que te llamemos?';

  @override
  String get attendeeOnboardingHandleLabel => 'Tu nombre de usuario';

  @override
  String get attendeeOnboardingStep2Title => '¿Dónde estás?';

  @override
  String get attendeeOnboardingStep2Subtitle =>
      'Elige tu ciudad para descubrir comunidades cerca de ti.';

  @override
  String get attendeeOnboardingStep3Title => '¿Qué te interesa?';

  @override
  String get attendeeOnboardingStep3Subtitle =>
      'Elige algunos intereses para sugerirte las comunidades adecuadas.';

  @override
  String get attendeeOnboardingStep4Title => 'Únete a tus primeras comunidades';

  @override
  String get attendeeOnboardingStep4Subtitle =>
      'Toca para unirte a las que te gusten. Siempre puedes unirte a más después.';

  @override
  String get attendeeOnboardingFinish => 'Finalizar';

  @override
  String get attendeeOnboardingForYou => 'Para ti';

  @override
  String get editProfileHandleLabel => 'Nombre de usuario';

  @override
  String get addFriendTitle => 'Añadir un amigo';

  @override
  String get addFriendSubtitle =>
      'Encuentra a alguien por su correo o su @nombre.';

  @override
  String get addFriendInputHint => 'Correo o @nombre';

  @override
  String get addFriendSearch => 'Buscar';

  @override
  String get addFriendNoMatch =>
      'Nadie coincide con ese correo o nombre de usuario.';

  @override
  String get addFriendUnavailable =>
      'Añadir amigos no está disponible ahora mismo.';

  @override
  String get addFriendError => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get addFriendSelf => 'Eres tú';

  @override
  String get rosterInviteIdentifierLabel => 'Correo o @nombre';

  @override
  String get rosterInviteIdentifierHint => 'nombre@ejemplo.com o @nombre';

  @override
  String get rosterInviteInvalidIdentifier =>
      'Introduce un correo o @nombre válido.';

  @override
  String get rosterNoAccountForIdentifier =>
      'Ninguna cuenta de Kolabing coincide con ese correo o nombre de usuario.';

  @override
  String get attendeeHomeEventsTitle => 'EVENTOS';

  @override
  String get attendeeHomeChooseCity => 'Elegir ciudad';

  @override
  String get attendeeHomeFilterToday => 'Hoy';

  @override
  String get attendeeHomeFilterDate => 'Cuándo';

  @override
  String get attendeeHomeFilterUpcoming => 'Próximos';

  @override
  String get attendeeHomeFilterThisWeek => 'Esta semana';

  @override
  String get attendeeHomeFilterThisWeekend => 'Este fin de semana';

  @override
  String get attendeeHomeFilterThisMonth => 'Este mes';

  @override
  String get attendeeHomeFilterType => 'Tipo';

  @override
  String get attendeeHomeFilterTypeAll => 'Todos los tipos';

  @override
  String get attendeeHomeExploreCommunities => 'Explorar comunidades';

  @override
  String get attendeeHomePickCityTitle => 'Elige una ciudad';

  @override
  String get attendeeHomePickCityHint =>
      'Elige una ciudad para descubrir eventos cerca de ti.';

  @override
  String get attendeeHomeNoEventsCity => 'No hay eventos en esta ciudad';

  @override
  String get attendeeHomeNoEventsCityHint =>
      'Prueba otra ciudad o borra los filtros.';

  @override
  String get eventPartnerBusiness => 'Negocio';

  @override
  String get eventPartnerCommunity => 'Comunidad';

  @override
  String get eventDateToday => 'Hoy';

  @override
  String get eventDateTomorrow => 'Mañana';

  @override
  String eventDateInDays(int days) {
    return 'En $days días';
  }

  @override
  String get attendeeCommunityProfileErrorTitle =>
      'No se pudo cargar la comunidad';

  @override
  String get attendeeCommunityProfileTypeFallback => 'Comunidad';

  @override
  String attendeeCommunityProfileMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miembros',
      one: '$count miembro',
      zero: 'Aún sin miembros',
    );
    return '$_temp0';
  }

  @override
  String get attendeeCommunityProfileAboutTitle => 'Acerca de';

  @override
  String get attendeeCommunityProfileUpcomingEventsTitle => 'Próximos eventos';

  @override
  String get attendeeCommunityProfileSeeAll => 'Ver todo →';

  @override
  String get attendeeCommunityProfileNoUpcomingEvents =>
      'Aún no hay próximos eventos.';

  @override
  String get attendeeCommunityProfileJoin => 'Unirse a la comunidad';

  @override
  String get attendeeCommunityProfileJoinedSnack => 'Te has unido ✓';

  @override
  String get attendeeCommunityProfileRequestToJoin => 'Solicitar unirse';

  @override
  String get attendeeCommunityProfileRequested => 'Solicitado';

  @override
  String get attendeeCommunityProfileRequestedSnack => 'Solicitud enviada';

  @override
  String get attendeeCommunityProfileRequestUnavailable =>
      'Las solicitudes aún no están disponibles. Inténtalo más tarde.';

  @override
  String get attendeeCommunityProfileOpenCommunity => 'Abrir comunidad';
}
