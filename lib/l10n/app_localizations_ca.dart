// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get appName => 'Kolabing';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonCancel => 'Cancel·lar';

  @override
  String get commonSave => 'Desar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonNext => 'Següent';

  @override
  String get commonBack => 'Enrere';

  @override
  String get commonDone => 'Fet';

  @override
  String get commonErrorGeneric =>
      'Alguna cosa ha anat malament. Torna-ho a provar.';

  @override
  String onboardingCompleteMissingFields(String fields) {
    return 'Completa: $fields';
  }

  @override
  String get onboardingFieldName => 'Nom';

  @override
  String get onboardingFieldBusinessCategory => 'Categoria del negoci';

  @override
  String get onboardingFieldVenueType => 'Tipus de local';

  @override
  String get onboardingFieldVenueCapacity => 'Aforament';

  @override
  String get onboardingFieldVenuePhotos => 'Fotos del local';

  @override
  String get onboardingFieldBusinessAddress => 'Adreça';

  @override
  String get onboardingFieldTargetCities => 'Ciutats';

  @override
  String get onboardingFieldCommunityType => 'Tipus de comunitat';

  @override
  String get onboardingFieldCommunityCity => 'Ciutat';

  @override
  String get welcomeLogIn => 'Inicia la sessió';

  @override
  String get welcomeHeadlineLine1 => 'On les marques locals';

  @override
  String get welcomeHeadlineLine2 => 'es troben amb comunitats reals.';

  @override
  String get welcomeSubtitle =>
      'Col·laboracions liderades per comunitats per a esdeveniments, contingut (UGC), ressenyes i creixement real.';

  @override
  String get welcomeGetStarted => 'Comença';

  @override
  String get welcomeStartKolabing => 'Comença a kolabing';

  @override
  String get welcomeHeroWhere => 'On';

  @override
  String get welcomeHeroBusinesses => 'empreses';

  @override
  String get welcomeHeroAnd => 'i';

  @override
  String get welcomeHeroCommunities => 'comunitats';

  @override
  String get welcomeHeroGrow => 'creixen';

  @override
  String get welcomeHeroTogether => 'juntes';

  @override
  String get welcomeTaglineMatch => 'CONNECTA';

  @override
  String get welcomeTaglineDot => '·';

  @override
  String get welcomeTaglineKolab => 'KOLAB';

  @override
  String get welcomeTaglineGrow => 'CREIX';

  @override
  String get welcomeFloatingEvents => 'esdeveniments';

  @override
  String get welcomeFloatingUgc => 'UGC';

  @override
  String get welcomeFloatingReviews => 'ressenyes';

  @override
  String get welcomeFloatingGrowth => 'creixement';

  @override
  String get welcomeFloatingCommunity => 'comunitat';

  @override
  String get welcomeFloatingBrands => 'marques';

  @override
  String get welcomeFloatingPeople => 'persones';

  @override
  String get welcomeFloatingConnection => 'connexió';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get languageScreenTitle => 'Idioma';

  @override
  String get languageSystemDefault => 'Predeterminat del sistema';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageCatalan => 'Català';

  @override
  String get applicationReviewTitle => 'SOL·LICITUD';

  @override
  String get applicationReviewLoadError =>
      'No s\'ha pogut carregar la sol·licitud';

  @override
  String get applicationReviewNotFound => 'Sol·licitud no trobada';

  @override
  String get applicationReviewMessageLabel => 'Missatge';

  @override
  String get applicationReviewNoMessage => 'No s\'ha proporcionat cap missatge';

  @override
  String get applicationReviewAvailabilityLabel => 'Disponibilitat';

  @override
  String get applicationReviewNotSpecified => 'No especificada';

  @override
  String get applicationReviewAppliedLabel => 'Aplicat';

  @override
  String get applicationReviewUnknownOpportunity => 'Oportunitat desconeguda';

  @override
  String get applicationReviewViewFullProfile => 'Veure el perfil complet';

  @override
  String get applicationReviewStatusAccepted => 'Acceptada';

  @override
  String get applicationReviewStatusAcceptedDesc =>
      'Aquesta sol·licitud s\'ha acceptat. Pots xatejar amb qui l\'ha enviada.';

  @override
  String get applicationReviewStatusDeclined => 'Rebutjada';

  @override
  String applicationReviewStatusDeclinedReason(String reason) {
    return 'Rebutjada: $reason';
  }

  @override
  String get applicationReviewStatusDeclinedDesc =>
      'Aquesta sol·licitud s\'ha rebutjat.';

  @override
  String get applicationReviewStatusWithdrawn => 'Retirada';

  @override
  String get applicationReviewStatusWithdrawnDesc =>
      'Qui l\'ha enviada ha retirat la seva sol·licitud.';

  @override
  String get applicationReviewStatusPending => 'Pendent';

  @override
  String get applicationReviewOpenChat => 'OBRIR EL XAT';

  @override
  String get applicationReviewDecline => 'REBUTJAR';

  @override
  String get applicationReviewAccept => 'ACCEPTAR';

  @override
  String get applicationReviewDeclineDialogTitle => 'Rebutjar la sol·licitud';

  @override
  String applicationReviewDeclineDialogBody(String name) {
    return 'Segur que vols rebutjar aquesta sol·licitud de $name?';
  }

  @override
  String get applicationReviewDeclineReasonHint => 'Motiu (opcional)';

  @override
  String get applicationReviewDeclineDialogConfirm => 'Rebutjar';

  @override
  String get applicationReviewDeclinedSnack => 'Sol·licitud rebutjada';

  @override
  String get acceptFormTitle => 'Acceptar la sol·licitud';

  @override
  String get acceptFormSubtitle =>
      'Tria una data per al kolab; continuaràs la conversa al xat després d\'acceptar.';

  @override
  String get acceptFormScheduledDate => 'DATA PROGRAMADA';

  @override
  String get acceptFormNoDates =>
      'No hi ha dates futures disponibles dins del rang de l\'oportunitat.';

  @override
  String get acceptFormConfirm => 'CONFIRMAR L\'ACCEPTACIÓ';

  @override
  String get acceptFormAcceptedSnack => 'Sol·licitud acceptada! Kolab creat.';

  @override
  String get acceptFormError =>
      'No s\'ha pogut acceptar la sol·licitud. Torna-ho a provar.';

  @override
  String get applicationsTitle => 'SOL·LICITUDS';

  @override
  String get applicationsTabSent => 'ENVIADES';

  @override
  String get applicationsTabReceived => 'REBUDES';

  @override
  String get applicationsSentEmptyTitle => 'Encara no hi ha sol·licituds';

  @override
  String get applicationsSentEmptyBody =>
      'Comença a explorar oportunitats i sol·licita kolabs amb negocis i comunitats.';

  @override
  String get applicationsReceivedEmptyTitle => 'No hi ha sol·licituds rebudes';

  @override
  String get applicationsReceivedEmptyBody =>
      'Quan algú sol·liciti les teves oportunitats, apareixeran aquí.';

  @override
  String get applicationsErrorTitle => 'Alguna cosa ha anat malament';

  @override
  String applicationCardFrom(String name) {
    return 'De: $name';
  }

  @override
  String applicationCardTo(String name) {
    return 'Per a: $name';
  }

  @override
  String get applicationStatusPending => 'Pendent';

  @override
  String get applicationStatusAccepted => 'Acceptada';

  @override
  String get applicationStatusDeclined => 'Rebutjada';

  @override
  String get applicationStatusWithdrawn => 'Retirada';

  @override
  String get chatApplicationNotFound => 'Sol·licitud no trobada';

  @override
  String get chatResubscribeBanner =>
      'La teva subscripció ha caducat. Torna a subscriure\'t per continuar aquest xat.';

  @override
  String get chatResubscribeAction => 'TORNA A SUBSCRIURE\'T';

  @override
  String get chatLoading => 'Carregant...';

  @override
  String get chatDateToday => 'Avui';

  @override
  String get chatDateYesterday => 'Ahir';

  @override
  String get chatMessageHint => 'Escriu un missatge...';

  @override
  String get chatSessionExpiredTitle => 'Sessió caducada';

  @override
  String get chatSessionExpiredBody => 'Torna a iniciar sessió per continuar.';

  @override
  String get chatSignIn => 'Inicia sessió';

  @override
  String get chatEmptyTitle => 'Inicia la conversa';

  @override
  String get chatEmptyBody =>
      'Envia un missatge per començar a parlar d\'aquest kolab';

  @override
  String get chatViewOpportunity => 'Veure l\'oportunitat';

  @override
  String get chatCancelApplication => 'Cancel·lar la sol·licitud';

  @override
  String get chatCancelDialogTitle => 'Vols cancel·lar la sol·licitud?';

  @override
  String get chatCancelDialogBody =>
      'Segur que vols cancel·lar aquesta sol·licitud? Aquesta acció no es pot desfer.';

  @override
  String get chatCancelDialogKeep => 'No, mantén-la';

  @override
  String get chatCancelDialogWithdraw => 'Sí, retira-la';

  @override
  String get chatApplicationWithdrawn => 'Sol·licitud retirada';

  @override
  String get applyModalHeader => 'NOVA SOL·LICITUD';

  @override
  String get applyModalMessageTitle => 'El teu missatge';

  @override
  String get applyModalMessageHelp =>
      'Una breu presentació t\'ajuda a destacar; esmenta què aportes i per què hi encaixes.';

  @override
  String get applyModalMessageHint =>
      'Explica\'ls per què ets perfecte per a aquest kolab i quin valor pots aportar...';

  @override
  String get applyModalSelectDatesTitle => 'Selecciona data/dates';

  @override
  String get applyModalSelectDatesHelp =>
      'Tria entre les dates disponibles per a aquest kolab';

  @override
  String get applyModalSelectDateError => 'Selecciona almenys una data';

  @override
  String get applyModalNoDates =>
      'No hi ha dates disponibles per a aquest kolab';

  @override
  String get applyModalClosedSnack =>
      'Les inscripcions per a aquest kolab estan tancades';

  @override
  String get exploreApplicationsClosed => 'Inscripcions tancades';

  @override
  String get applyModalNotesLabel => 'Notes addicionals (opcional)';

  @override
  String get applyModalNotesHint =>
      'p. ex., Flexible amb l\'horari, prefereixo els matins...';

  @override
  String get applyModalTimeFrom => 'Des de';

  @override
  String get applyModalTimeTo => 'Fins a';

  @override
  String get applyModalOptionalBadge => 'Opcional';

  @override
  String get applyModalUnknownHost => 'Amfitrió desconegut';

  @override
  String get applyModalHostFallback => 'Amfitrió';

  @override
  String get applyModalApplyingTo => 'Estàs sol·licitant a';

  @override
  String get applyModalWhatsOffered => 'Què s\'ofereix';

  @override
  String get applyModalTip =>
      'Tria les dates que et vagin bé i afegeix un missatge breu; les sol·licituds amb detalls s\'accepten més de pressa.';

  @override
  String get applyModalSending => 'ENVIANT…';

  @override
  String get applyModalSend => 'ENVIAR SOL·LICITUD';

  @override
  String get applyModalAlreadyApplied =>
      'Ja has sol·licitat aquesta oportunitat';

  @override
  String get applyModalSubmitError =>
      'No s\'ha pogut enviar la sol·licitud. Torna-ho a provar.';

  @override
  String get commonDismiss => 'Descartar';

  @override
  String get routeNotFoundTitle => 'Pàgina no trobada';

  @override
  String get routeNotFoundBody => 'No hem pogut trobar aquesta pàgina';

  @override
  String get routeNotFoundGoToDashboard => 'Anar al tauler';

  @override
  String get routeNotFoundSignOut => 'Tancar sessió';

  @override
  String get routeNotFoundBackToLogin => 'Tornar a l\'inici de sessió';

  @override
  String opportunityLoadError(Object error) {
    return 'No s\'ha pogut carregar l\'oportunitat: $error';
  }

  @override
  String get profileMenuTitle => 'Perfil';

  @override
  String get networkOfflineBannerMessage =>
      'Sense connexió a internet. Desactiva el mode avió o torna a connectar-te, i torna-ho a provar.';

  @override
  String get commonGotIt => 'Entesos';

  @override
  String get authEmailLabel => 'Correu electrònic';

  @override
  String get authEmailHint => 'el-teu@correu.com';

  @override
  String get authPasswordLabel => 'Contrasenya';

  @override
  String get authConfirmPasswordLabel => 'Confirmar contrasenya';

  @override
  String get authEmailRequired => 'El correu electrònic és obligatori';

  @override
  String get authEmailInvalid => 'Introdueix un correu electrònic vàlid';

  @override
  String get authPasswordRequired => 'La contrasenya és obligatòria';

  @override
  String get authPasswordTooShort =>
      'La contrasenya ha de tenir com a mínim 8 caràcters';

  @override
  String get authConfirmPasswordRequired => 'Confirma la teva contrasenya';

  @override
  String get authPasswordsDoNotMatch => 'Les contrasenyes no coincideixen';

  @override
  String get authNoInternet =>
      'Sense connexió a internet. Comprova la teva xarxa.';

  @override
  String get authUnexpectedError => 'S\'ha produït un error inesperat';

  @override
  String get attendeeRegisterTitle => 'UNEIX-T\'HI COM A ASSISTENT';

  @override
  String get attendeeRegisterSubtitle =>
      'Crea el teu compte per unir-te a esdeveniments i completar reptes';

  @override
  String get attendeeRegisterPasswordHint => 'Mín. 8 caràcters';

  @override
  String get attendeeRegisterConfirmPasswordHint =>
      'Torna a introduir la teva contrasenya';

  @override
  String get attendeeRegisterCreateAccount => 'CREAR COMPTE';

  @override
  String get attendeeRegisterTerms =>
      'En crear un compte, acceptes les nostres Condicions del servei i Política de privadesa';

  @override
  String get loginPanelTitle => 'Inicia la sessió al teu compte';

  @override
  String get loginPanelSubtitle => 'Reprèn on ho vas deixar.';

  @override
  String get loginSignInButton => 'Iniciar sessió';

  @override
  String get loginForgotPassword => 'Has oblidat la contrasenya?';

  @override
  String get loginHeroWelcome => 'Benvingut de nou.';

  @override
  String get loginSignUpLink => 'Registrar-se';

  @override
  String get loginUserNotFoundTitle => 'Compte no trobat';

  @override
  String get loginUserNotFoundMessage =>
      'Encara no existeix cap compte per a aquest inici de sessió. Crea un compte primer.';

  @override
  String get loginCreateAccountButton => 'Crear compte';

  @override
  String get forgotPasswordFormTitle => 'Restableix la teva contrasenya';

  @override
  String get forgotPasswordFormSubtitle =>
      'Introdueix el correu del teu compte i t\'enviarem un enllaç segur per restablir-la.';

  @override
  String get forgotPasswordHelperText =>
      'Si el correu coincideix amb un compte, l\'enllaç de restabliment arribarà aviat.';

  @override
  String get forgotPasswordSendButton => 'ENVIAR ENLLAÇ DE RESTABLIMENT';

  @override
  String get forgotPasswordSuccessTitle => 'Revisa la teva safata d\'entrada';

  @override
  String get forgotPasswordSuccessSubtitle =>
      'Si existeix un compte per a aquest correu, l\'enllaç de restabliment està en camí.';

  @override
  String get forgotPasswordBackToSignIn => 'TORNAR A INICIAR SESSIÓ';

  @override
  String get forgotPasswordUseAnotherEmail => 'Utilitzar un altre correu';

  @override
  String get forgotPasswordHeroLine1 => 'Recupera l\'accés.';

  @override
  String get forgotPasswordHeroLine2 => 'TORNA A ENTRAR.';

  @override
  String get forgotPasswordHeroLine3 => 'CONTRASENYA OBLIDADA?';

  @override
  String get forgotPasswordHeroSentLine1 => 'REVISA EL TEU CORREU.';

  @override
  String get forgotPasswordHeroSentLine2 => 'OBRE L\'ENLLAÇ.';

  @override
  String get forgotPasswordHeroSentLine3 => 'JA HI ETS GAIREBÉ.';

  @override
  String get resetPasswordTitle => 'RESTABLIR CONTRASENYA';

  @override
  String get resetPasswordSubtitle =>
      'Introdueix la teva nova contrasenya a continuació.';

  @override
  String get resetPasswordNewLabel => 'Nova contrasenya';

  @override
  String get resetPasswordNewHint => 'Introdueix la nova contrasenya';

  @override
  String get resetPasswordConfirmHint => 'Confirma la nova contrasenya';

  @override
  String get resetPasswordButton => 'RESTABLIR CONTRASENYA';

  @override
  String get resetPasswordInvalidLink =>
      'Enllaç de restabliment no vàlid. Sol·licita\'n un de nou.';

  @override
  String get resetPasswordSuccessTitle => 'CONTRASENYA RESTABLERTA';

  @override
  String get resetPasswordSuccessMessage =>
      'La teva contrasenya s\'ha restablert correctament. Et redirigim a l\'inici de sessió...';

  @override
  String get resetPasswordGoToSignIn => 'ANAR A INICIAR SESSIÓ';

  @override
  String get signInTitle => 'Benvingut de nou.';

  @override
  String get signInSubtitle => 'Inicia la sessió per continuar';

  @override
  String get signInWithGoogle => 'Iniciar sessió amb Google';

  @override
  String get signInWithApple => 'Iniciar sessió amb Apple';

  @override
  String get authOrContinueWith => 'o continua amb';

  @override
  String get signInNoAccount => 'No tens un compte?';

  @override
  String get signInSignUp => 'Registrar-se';

  @override
  String get signInTypeMismatchTitle => 'Tipus de compte incorrecte';

  @override
  String signInTypeMismatchMessage(String type) {
    return 'Aquest compte de Google està registrat com a usuari $type. Inicia la sessió des de la pantalla correcta.';
  }

  @override
  String get signInTypeMismatchDifferent => 'diferent';

  @override
  String get splashSemanticLabel => 'Kolabing - Carregant l\'aplicació';

  @override
  String authLinkSemanticLabel(String leading, String action) {
    return '$leading Toca $action per navegar';
  }

  @override
  String get kolabingLogoSemanticLabel => 'Logotip de Kolabing';

  @override
  String get selectionCardBusinessTitle => 'Sóc un negoci';

  @override
  String get selectionCardCommunityTitle => 'Sóc una comunitat';

  @override
  String get selectionCardAttendeeTitle => 'Sóc un membre';

  @override
  String get selectionCardBusinessDescription =>
      'Cerco comunitats amb qui col·laborar';

  @override
  String get selectionCardCommunityDescription =>
      'Cerco marques per fer Kolabs';

  @override
  String get selectionCardAttendeeDescription =>
      'Unir-me a esdeveniments i completar reptes';

  @override
  String get selectionCardComingSoonBadge => 'Ben aviat';

  @override
  String selectionCardSemanticLabel(String title, String description) {
    return '$title. $description';
  }

  @override
  String get businessNavHome => 'Inici';

  @override
  String get businessNavExplore => 'Explora';

  @override
  String get businessNavMyKolabs => 'Els meus Kolabs';

  @override
  String get businessNavProfile => 'Perfil';

  @override
  String get businessMainCreateKolabTooltip => 'Crear sol·licitud de Kolab';

  @override
  String get businessProfileSignOutTitle => 'Tancar la sessió';

  @override
  String get businessProfileSignOutMessage =>
      'Segur que vols tancar la sessió?';

  @override
  String get businessProfileSignOut => 'Tancar la sessió';

  @override
  String get businessProfileDeleteAccountTitle => 'Eliminar el compte';

  @override
  String get businessProfileDeleteAccountMessage =>
      'Segur que vols eliminar el teu compte? Aquesta acció no es pot desfer.';

  @override
  String get businessProfileDelete => 'Eliminar';

  @override
  String get businessProfileDeleteAccount => 'Eliminar el compte';

  @override
  String get businessProfileChangePhotoTitle => 'Canviar la foto de perfil';

  @override
  String get businessProfileTakePhoto => 'Fer una foto';

  @override
  String get businessProfileTakePhotoSubtitle => 'Fes servir la càmera';

  @override
  String get businessProfileChooseFromGallery => 'Triar de la galeria';

  @override
  String get businessProfileChooseFromGallerySubtitle =>
      'Selecciona una foto existent';

  @override
  String get businessProfileUploadingPhoto => 'Pujant la foto...';

  @override
  String get businessProfilePhotoUpdated => 'Foto de perfil actualitzada';

  @override
  String get businessProfilePhotoUpdateFailed =>
      'No s\'ha pogut actualitzar la foto';

  @override
  String get businessProfileDismiss => 'Descartar';

  @override
  String get businessProfileLoadFailed => 'No s\'ha pogut carregar el perfil';

  @override
  String get businessProfileSomethingWrong => 'Alguna cosa ha anat malament';

  @override
  String get businessProfileTryAgain => 'TORNAR-HO A PROVAR';

  @override
  String get businessProfileBusinessFallback => 'Empresa';

  @override
  String get businessProfileAbout => 'Sobre';

  @override
  String get businessProfileSubscription => 'Subscripció';

  @override
  String get businessProfilePremiumPlan => 'Pla Premium';

  @override
  String get businessProfileNoActivePlan => 'Sense pla actiu';

  @override
  String get businessProfileRenews => 'Es renova';

  @override
  String get businessProfileRemaining => 'Restant';

  @override
  String businessProfileDaysRemaining(num count) {
    return '$count dies';
  }

  @override
  String get businessProfileSubscriptionEnding =>
      'La subscripció acaba al final del període de facturació actual';

  @override
  String get businessProfileManageSubscription => 'GESTIONAR LA SUBSCRIPCIÓ';

  @override
  String get businessProfileUpgradePremium => 'PASSAR A PREMIUM';

  @override
  String get businessProfileStatusActive => 'Activa';

  @override
  String get businessProfileStatusCancelled => 'Cancel·lada';

  @override
  String get businessProfileStatusPastDue => 'Vençuda';

  @override
  String get businessProfileStatusInactive => 'Inactiva';

  @override
  String get businessProfileContactInfo => 'Informació de contacte';

  @override
  String get businessProfileNotifications => 'Notificacions';

  @override
  String get businessProfileNotifMessages => 'Missatges';

  @override
  String get businessProfileNotifApplications => 'Avisos de sol·licituds';

  @override
  String get businessProfileNotifKolabUpdates => 'Actualitzacions de Kolab';

  @override
  String get businessProfileNotifRewards => 'Recompenses i moneder';

  @override
  String get businessProfileNotifMarketing => 'Màrqueting i consells';

  @override
  String get businessProfileAccount => 'Compte';

  @override
  String get communityOfferDetailUnknown => 'Desconegut';

  @override
  String get communityOfferDetailSubscribeToReveal => 'Subscriu-te per revelar';

  @override
  String communityOfferDetailApplicationsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sol·licituds',
      one: '$count sol·licitud',
      zero: 'Cap sol·licitud',
    );
    return '$_temp0';
  }

  @override
  String get communityOfferDetailCategories => 'CATEGORIES';

  @override
  String get communityOfferDetailBusinessOffer => 'OFERTA DE L\'EMPRESA';

  @override
  String get communityOfferDetailVenueProvided => 'Local inclòs';

  @override
  String get communityOfferDetailFoodDrink => 'Menjar i beguda inclosos';

  @override
  String communityOfferDetailDiscountPct(num percent) {
    return '$percent% de descompte';
  }

  @override
  String get communityOfferDetailDiscountOffered => 'Descompte ofert';

  @override
  String get communityOfferDetailExpectedDeliverables => 'LLIURABLES ESPERATS';

  @override
  String get communityOfferDetailSocialMedia =>
      'Contingut a les xarxes socials';

  @override
  String get communityOfferDetailEventActivation => 'Activació d\'esdeveniment';

  @override
  String get communityOfferDetailProductPlacement => 'Emplaçament de producte';

  @override
  String get communityOfferDetailCommunityReach => 'Abast de la comunitat';

  @override
  String get communityOfferDetailReviewFeedback => 'Ressenya i valoració';

  @override
  String get communityOfferDetailLocationTitle => 'UBICACIÓ I DISPONIBILITAT';

  @override
  String get communityOfferDetailCity => 'Ciutat';

  @override
  String get communityOfferDetailNotSpecified => 'Sense especificar';

  @override
  String get communityOfferDetailVenue => 'Local';

  @override
  String get communityOfferDetailAddress => 'Adreça';

  @override
  String get communityOfferDetailDates => 'Dates';

  @override
  String get communityOfferDetailMode => 'Mode';

  @override
  String get communityOfferDetailPreviewMode => 'Mode vista prèvia';

  @override
  String get communityOfferDetailAlreadyApplied => 'Ja t\'hi has postulat';

  @override
  String get communityOfferDetailApplyNow => 'Postula\'t ara';

  @override
  String get communityOfferDetailTitle => 'Detalls de l\'oportunitat';

  @override
  String get communityOfferDetailNotFound => 'Oportunitat no trobada';

  @override
  String get communityOfferDetailPreviewBanner =>
      'Estàs veient la vista prèvia d\'aquest kolab tal com el veuen les empreses';

  @override
  String get communityOfferDetailPastEvents =>
      'Esdeveniments anteriors d\'aquesta comunitat';

  @override
  String get communityOfferDetailPastEventsSubtitle =>
      'Consulta l\'historial recent d\'aquesta comunitat abans de postular-t\'hi.';

  @override
  String get communityOfferDetailTheOffer => 'L\'OFERTA';

  @override
  String get communityOfferDetailExtraTerms =>
      'CONDICIONS EXTRA DESBLOQUEJADES';

  @override
  String get communityOfferDetailExtraTermsSubtitle =>
      'Això només es mostra perquè ja t\'hi has postulat.';

  @override
  String communityOfferDetailTriggerCondition(String condition) {
    return 'SI $condition';
  }

  @override
  String get exploreRecommendedMatches => 'Coincidències recomanades per a tu';

  @override
  String get exploreBrowseAll => 'Explora tots els kolabs oberts';

  @override
  String exploreFilterNeeds(num count) {
    return 'Ofertes $count';
  }

  @override
  String exploreFilterTypes(num count) {
    return 'Tipus $count';
  }

  @override
  String exploreFilterOffers(num count) {
    return 'Ofertes $count';
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
      other: '$count resultats',
      one: '$count resultat',
      zero: 'Cap resultat',
    );
    return '$_temp0';
  }

  @override
  String get exploreEmptyNoResults => 'No s\'han trobat resultats';

  @override
  String get exploreEmptyNoRecommended =>
      'Encara no hi ha coincidències recomanades';

  @override
  String get exploreEmptyNoOpportunities => 'Encara no hi ha oportunitats';

  @override
  String get exploreEmptyNoResultsHint =>
      'Prova d\'ampliar els filtres o de canviar de pestanya.';

  @override
  String get exploreEmptyNoRecommendedHint =>
      'Canvia a Tots o torna més tard per veure nous kolabs.';

  @override
  String get exploreEmptyNoOpportunitiesHint =>
      'Torna més tard per veure noves oportunitats.';

  @override
  String get exploreClearFilters => 'Esborrar tots els filtres';

  @override
  String get exploreSomethingWrong => 'Alguna cosa ha anat malament';

  @override
  String get exploreTryAgain => 'Tornar-ho a provar';

  @override
  String get exploreFeedRecommended => 'Recomanats';

  @override
  String get exploreFeedAll => 'Tots';

  @override
  String get exploreFeedSaved => 'Desats';

  @override
  String get savedKolabsEmptyTitle => 'Encara no tens Kolabs desats';

  @override
  String get savedKolabsEmptyBody =>
      'Toca el marcador d\'un Kolab per desar-lo per a més tard.';

  @override
  String get savedKolabsErrorTitle => 'No s\'han pogut carregar els desats';

  @override
  String get savedKolabsErrorBody =>
      'Alguna cosa ha anat malament. Torna-ho a provar.';

  @override
  String get savedKolabsSaveError =>
      'No s\'ha pogut desar aquest Kolab. Torna-ho a provar.';

  @override
  String get savedKolabsUnsaveError =>
      'No s\'ha pogut treure aquest Kolab. Torna-ho a provar.';

  @override
  String get myKolabsTabPublished => 'Publicats';

  @override
  String get myKolabsTabDraft => 'Esborranys';

  @override
  String get myKolabsPublished => 'Kolab publicat!';

  @override
  String get myKolabsPublishFailed => 'No s\'ha pogut publicar';

  @override
  String get myKolabsClosed => 'Kolab tancat';

  @override
  String get myKolabsCloseFailed => 'No s\'ha pogut tancar';

  @override
  String get myKolabsDeleteTitle => 'Eliminar Kolab';

  @override
  String get myKolabsDeleteMessage =>
      'Segur que vols eliminar aquest kolab? Aquesta acció no es pot desfer.';

  @override
  String get myKolabsDelete => 'Eliminar';

  @override
  String get myKolabsDeleted => 'Kolab eliminat';

  @override
  String get myKolabsDeleteFailed => 'No s\'ha pogut eliminar';

  @override
  String get myKolabsTitle => 'ELS MEUS KOLABS';

  @override
  String get myKolabsSubtitle => 'Gestiona els teus kolabs';

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
  String get myKolabsEmptyTitle => 'Encara no tens kolabs';

  @override
  String get myKolabsEmptyMessage =>
      'Crea el teu primer kolab per començar a connectar amb comunitats';

  @override
  String get myKolabsCreateNewButton => 'Crear un Kolab';

  @override
  String get myKolabsCreate => 'Crear Kolab';

  @override
  String get myKolabsSomethingWrong => 'Alguna cosa ha anat malament';

  @override
  String get myKolabsTryAgain => 'Tornar-ho a provar';

  @override
  String get kolabReviewSheetTitle => 'Com ha anat el Kolab? ⭐';

  @override
  String kolabReviewSheetSubtitle(String partnerName) {
    return 'La teva ressenya ajuda $partnerName a generar confiança a Kolabing.';
  }

  @override
  String get kolabReviewSheetCommentHint => 'Vols afegir res? (opcional)';

  @override
  String get kolabReviewSheetWouldAgain => 'Tornaries a fer un Kolab?';

  @override
  String get kolabReviewSheetYes => 'Sí';

  @override
  String get kolabReviewSheetNo => 'No';

  @override
  String get kolabReviewSheetSubmitXp => 'Enviar +10 XP ✨';

  @override
  String get kolabReviewSheetSkip => 'Omet per ara';

  @override
  String get kolabCompletionConfirmTitle => 'S\'ha fet el Kolab? 🎯';

  @override
  String kolabCompletionConfirmSubtitle(String partnerName) {
    return 'Marca el teu Kolab amb $partnerName com a completat.';
  }

  @override
  String get kolabCompletionConfirmLoading => 'Completant…';

  @override
  String get kolabCompletionConfirmCta => 'Sí, completa el Kolab ✨';

  @override
  String get kolabCompletionConfirmDismiss => 'Encara no';

  @override
  String get kolabCompletionConfirmNo => 'No, no s\'ha fet';

  @override
  String get kolabCompletionConfirmedNotYetTitle => 'Entès, gràcies 👍';

  @override
  String get kolabCompletionConfirmedNotYetBody =>
      'Ho revisarem més tard — torna aquí quan el Kolab es faci per confirmar-ho.';

  @override
  String get kolabCompletionConfirmedNoTitle => 'Gràcies per avisar-nos';

  @override
  String get kolabCompletionConfirmedNoBody =>
      'Hem registrat que aquest Kolab no s\'ha fet. Contacta amb suport si necessites ajuda per resoldre-ho.';

  @override
  String get kolabCompletionConfirmError =>
      'No s\'ha pogut enviar la teva confirmació. Torna-ho a provar.';

  @override
  String get kolabCompletionFeedbackTitle => 'Com ha anat el Kolab? ⭐';

  @override
  String get kolabCompletionFeedbackOptionalTitle =>
      'Vols afegir més detalls? ⭐';

  @override
  String kolabCompletionFeedbackOptionalSubtitle(String partnerName) {
    return 'Entès — la teva resposta s\'ha registrat. Compartir una valoració ràpida i alguns detalls ajuda $partnerName a generar confiança a Kolabing — i guanyes XP extra. Totalment opcional.';
  }

  @override
  String get kolabCompletionFeedbackSkip => 'Omet per ara';

  @override
  String kolabCompletionFeedbackSubtitle(String partnerName) {
    return 'Els comentaris són obligatoris per acabar. La teva ressenya ajuda $partnerName a generar confiança a Kolabing.';
  }

  @override
  String get kolabCompletionFeedbackCommentHint =>
      'Vols afegir res? (opcional)';

  @override
  String get kolabCompletionFeedbackWouldAgain => 'Tornaries a fer un Kolab?';

  @override
  String get kolabCompletionFeedbackYes => 'Sí';

  @override
  String get kolabCompletionFeedbackNo => 'No';

  @override
  String get kolabCompletionFeedbackSubmitting => 'Enviant…';

  @override
  String get kolabCompletionFeedbackSubmit => 'Envia i acaba';

  @override
  String get kolabCompletionFeedbackTapStar => 'Toca una estrella per puntuar';

  @override
  String get kolabCompletionFeedbackFinishLater => 'Acaba més tard';

  @override
  String get kolabCompletionSheetFeedbackError =>
      'No s\'han pogut enviar els comentaris. Torna-ho a provar.';

  @override
  String get kolabStarReviewTitle => 'Valora aquest Kolab ⭐';

  @override
  String kolabStarReviewSubtitle(String partnerName) {
    return 'Fet — la teva resposta queda registrada. Una valoració ràpida de 5 estrelles ajuda $partnerName a generar confiança a Kolabing. Totalment opcional.';
  }

  @override
  String get kolabStarReviewBizCommunicationLabel => 'Comunicació';

  @override
  String get kolabStarReviewBizCommunicationHelper =>
      'Va ser fàcil coordinar-se?';

  @override
  String get kolabStarReviewBizReliabilityLabel => 'Fiabilitat';

  @override
  String get kolabStarReviewBizReliabilityHelper =>
      'La comunitat es va presentar i va complir?';

  @override
  String get kolabStarReviewBizFitLabel => 'Afinitat amb la comunitat';

  @override
  String get kolabStarReviewBizFitHelper =>
      'La seva audiència era un bon match?';

  @override
  String get kolabStarReviewBizValueLabel => 'Valor per al negoci';

  @override
  String get kolabStarReviewBizValueHelper =>
      'El Kolab va aportar valor al teu negoci?';

  @override
  String get kolabStarReviewBizRepeatLabel => 'Repetiries amb ells';

  @override
  String get kolabStarReviewBizRepeatHelper => 'Repetiries un Kolab amb ells?';

  @override
  String get kolabStarReviewComCommunicationLabel => 'Comunicació';

  @override
  String get kolabStarReviewComCommunicationHelper =>
      'Va ser fàcil coordinar-se?';

  @override
  String get kolabStarReviewComReliabilityLabel => 'Fiabilitat';

  @override
  String get kolabStarReviewComReliabilityHelper =>
      'El negoci va complir el que s\'havia acordat?';

  @override
  String get kolabStarReviewComFitLabel => 'Afinitat de l\'experiència';

  @override
  String get kolabStarReviewComFitHelper =>
      'L\'experiència era adequada per a la teva comunitat?';

  @override
  String get kolabStarReviewComValueLabel => 'Valor per als membres';

  @override
  String get kolabStarReviewComValueHelper =>
      'Els teus membres van obtenir alguna cosa valuosa?';

  @override
  String get kolabStarReviewComRepeatLabel => 'Repetiries el Kolab';

  @override
  String get kolabStarReviewComRepeatHelper => 'Repetiries un Kolab amb ells?';

  @override
  String get kolabStarReviewCommentLabel => 'Vols afegir alguna cosa més?';

  @override
  String get kolabStarReviewSubmit => 'Enviar valoració';

  @override
  String get kolabStarReviewSubmitting => 'Enviant…';

  @override
  String get kolabStarReviewSkip => 'Ometre per ara';

  @override
  String get kolabStarReviewSuccess =>
      'Gràcies — la teva valoració ajuda a millorar futurs Kolabs.';

  @override
  String get kolabStarReviewAlreadyDone =>
      'Ja has compartit la teva valoració ✓';

  @override
  String get kolabStarReviewError =>
      'No s\'ha pogut enviar la teva valoració. Torna-ho a provar.';

  @override
  String get kolabCompletionCelebrationTitle => 'Kolab completat! 🎉';

  @override
  String get kolabCompletionCelebrationBody =>
      'Has guanyat XP i el teu perfil ara reflecteix aquest Kolab completat.';

  @override
  String kolabCompletionXpEarned(num xp) {
    return '+$xp XP guanyats ⚡';
  }

  @override
  String get kolabCompletionCelebrationCta => 'Veure el meu XP →';

  @override
  String get kolabCompletionDoneTitle => 'Tot fet! 🏆';

  @override
  String get kolabCompletionDoneBody =>
      'Aquest Kolab està completat. Consulta el teu perfil per veure el teu historial creixent de col·laboracions.';

  @override
  String kolabCompletionDoneXp(num xp) {
    return '+$xp XP';
  }

  @override
  String get kolabCompletionDoneXpLabel => 'XP guanyats';

  @override
  String get kolabCompletionDoneClose => 'Tanca';

  @override
  String kolabCompletionConfirmMutualNote(String partnerName) {
    return 'Primer, confirma si el Kolab s\'ha fet. Les ressenyes són opcionals després d\'això.';
  }

  @override
  String get kolabCompletionFeedbackExpectationMatch =>
      'Va complir les teves expectatives?';

  @override
  String get kolabCompletionFeedbackWouldRecommend =>
      'Recomanaries aquest partner?';

  @override
  String get kolabCompletionFeedbackWouldCollaborateAgain =>
      'Tornaries a kolaborar?';

  @override
  String get kolabCompletionFeedbackMetricsOptional => 'Resultats (opcional)';

  @override
  String get kolabCompletionFeedbackPostsReels => 'Posts / reels publicats';

  @override
  String get kolabCompletionFeedbackStoriesPosted => 'Stories publicades';

  @override
  String get kolabCompletionFeedbackRevenue => 'Ingressos generats';

  @override
  String get kolabCompletionFeedbackBenefits => 'Beneficis rebuts';

  @override
  String get kolabCompletionAwaitingPartnerTitle =>
      'Gràcies! La teva valoració està enviada ✅';

  @override
  String kolabCompletionAwaitingPartnerBody(String partnerName) {
    return 'Aquest Kolab es completarà quan $partnerName també ho confirmi. T\'avisarem.';
  }

  @override
  String get kolabCompletionAwaitingPartnerClose => 'Entesos';

  @override
  String get kolabCompletionAlreadyCompleted =>
      'Aquest Kolab ja està completat.';

  @override
  String get collaborationDetailNotFound => 'Kolab no trobat';

  @override
  String get collaborationDetailRescheduleHelp => 'Reprograma el Kolab';

  @override
  String get collaborationDetailStartTimeHelp => 'Hora d\'inici (opcional)';

  @override
  String get collaborationDetailScheduleUpdated => 'Horari actualitzat.';

  @override
  String collaborationDetailScheduleUpdateError(String error) {
    return 'No s\'ha pogut actualitzar l\'horari: $error';
  }

  @override
  String get collaborationDetailEventDetails => 'DETALLS DE L\'ESDEVENIMENT';

  @override
  String get collaborationDetailEdit => 'EDITA';

  @override
  String get collaborationDetailDateLabel => 'Data';

  @override
  String get collaborationDetailTimeLabel => 'Hora';

  @override
  String get collaborationDetailVenueLabel => 'Lloc';

  @override
  String collaborationDetailVenueValue(String businessName) {
    return '$businessName (Local del negoci)';
  }

  @override
  String get collaborationDetailCommunityReachLabel => 'Abast de la comunitat';

  @override
  String get collaborationDetailReachIncluded => 'Inclòs';

  @override
  String get collaborationDetailReachNotSpecified => 'No especificat';

  @override
  String get collaborationDetailBusinessPartner => 'SOCI COMERCIAL';

  @override
  String get collaborationDetailCommunityPartner => 'SOCI DE LA COMUNITAT';

  @override
  String get collaborationDetailOffersTitleBusiness => 'EL QUE OFEREIXES';

  @override
  String get collaborationDetailOffersTitleCommunity => 'EL QUE S\'OFEREIX';

  @override
  String get collaborationDetailOfferVenue => 'Local inclòs';

  @override
  String get collaborationDetailOfferFoodDrink => 'Menjar i beguda inclosos';

  @override
  String get collaborationDetailOfferSocialMedia =>
      'Visibilitat a les xarxes socials';

  @override
  String get collaborationDetailOfferContentCreation =>
      'Suport en creació de contingut';

  @override
  String collaborationDetailOfferDiscount(num percentage) {
    return 'Descompte: $percentage%';
  }

  @override
  String get collaborationDetailDeliverablesTitleBusiness =>
      'LLIURABLES ESPERATS';

  @override
  String get collaborationDetailDeliverablesTitleCommunity =>
      'EL QUE LLIURARÀS';

  @override
  String get collaborationDetailDeliverableSocialContent =>
      'Contingut a les xarxes socials';

  @override
  String get collaborationDetailDeliverableEventActivation =>
      'Activació de l\'esdeveniment';

  @override
  String get collaborationDetailDeliverableProductPlacement =>
      'Emplaçament de producte';

  @override
  String get collaborationDetailDeliverableCommunityReach =>
      'Abast de la comunitat';

  @override
  String get collaborationDetailDeliverableReviewFeedback =>
      'Ressenya i comentaris';

  @override
  String get collaborationDetailContactTitle => 'CONTACTE';

  @override
  String get collaborationDetailContactEmail => 'Correu electrònic';

  @override
  String get collaborationDetailProcessTitle => 'PROCÉS';

  @override
  String get collaborationDetailGamificationTitle =>
      'CONFIGURACIÓ DE GAMIFICACIÓ';

  @override
  String collaborationDetailSelectedCount(num count) {
    return '$count seleccionats';
  }

  @override
  String get collaborationDetailGamificationDescription =>
      'Selecciona reptes perquè els assistents els completin durant l\'esdeveniment. Estaran disponibles a l\'app d\'assistents.';

  @override
  String get collaborationDetailNoChallengesTitle => 'Encara no hi ha reptes';

  @override
  String get collaborationDetailNoChallengesBody =>
      'Afegeix reptes perquè l\'esdeveniment sigui més atractiu per als assistents';

  @override
  String get collaborationDetailPoints => 'pts';

  @override
  String get collaborationDetailCustomChallengeSoon =>
      'La creació de reptes personalitzats arribarà aviat';

  @override
  String get collaborationDetailAddCustomChallenge =>
      'AFEGEIX UN REPTE PERSONALITZAT';

  @override
  String get collaborationDetailQrTitle => 'REGISTRE AMB CODI QR';

  @override
  String get collaborationDetailQrPlaceholder => 'Codi QR';

  @override
  String get collaborationDetailQrGeneratedOnDemand => 'Es genera a l\'instant';

  @override
  String get collaborationDetailQrDescription =>
      'Toca a sota per generar el teu codi QR de registre. Els assistents l\'escanegen al teu esdeveniment per registrar-se i començar a completar reptes.';

  @override
  String get collaborationDetailQrGenerating => 'GENERANT…';

  @override
  String collaborationDetailQrGenerateError(String error) {
    return 'No s\'ha pogut generar el codi QR: $error';
  }

  @override
  String get collaborationDetailViewQr => 'VEURE EL CODI QR';

  @override
  String get collaborationDetailResubscribeTitle =>
      'Torna a subscriure\'t per continuar';

  @override
  String get collaborationDetailResubscribeBody =>
      'La teva subscripció ha caducat, així que aquest Kolab en curs i el seu xat estan en pausa per la teva banda. La comunitat manté l\'accés complet. Torna a subscriure\'t per reprendre-ho on ho vas deixar.';

  @override
  String get collaborationDetailResubscribeCta => 'TORNA A SUBSCRIURE\'T';

  @override
  String get collaborationDetailLoadError => 'No s\'ha pogut carregar el Kolab';

  @override
  String get collaborationDetailTodayBannerTitle => 'El Kolab d\'avui!';

  @override
  String collaborationDetailTodayBannerBody(String partnerName) {
    return 'El teu Kolab amb $partnerName és avui. Quan estigui actiu podràs marcar-lo com a completat.';
  }

  @override
  String get collaborationDetailCompleteTitleToday =>
      'Completa el Kolab d\'avui!';

  @override
  String get collaborationDetailCompleteTitle => 'Kolab completat?';

  @override
  String collaborationDetailCompleteBodyToday(String partnerName) {
    return 'S\'ha fet el teu Kolab amb $partnerName? Marca\'l com a fet.';
  }

  @override
  String collaborationDetailCompleteBody(String partnerName) {
    return 'S\'ha fet el Kolab amb $partnerName? Marca\'l com a fet.';
  }

  @override
  String get collaborationDetailMarkDone => 'Marca\'l com a fet ✨';

  @override
  String get collaborationDetailItHappened => 'Sí, s\'ha fet ✨';

  @override
  String get collaborationDetailUpdateStatus => 'Actualitza l\'estat';

  @override
  String get collaborationDetailCheckAgain => 'Comprova de nou';

  @override
  String get collaborationDetailReviewStatus => 'Revisa l\'estat';

  @override
  String get collaborationDetailLeaveFeedbackLater =>
      'Deixa comentaris opcionals';

  @override
  String get collaborationDetailFeedbackCtaTitle => 'Valora aquest Kolab';

  @override
  String collaborationDetailFeedbackCtaBody(String partnerName) {
    return 'La teva ressenya ajuda $partnerName a generar confiança a Kolabing.';
  }

  @override
  String get collaborationDetailFeedbackCtaButton => 'Deixa una ressenya';

  @override
  String get collaborationDetailFeedbackAlreadyLeft =>
      'Has compartit els teus comentaris ✓';

  @override
  String get collaborationDetailFeedbackConfirmedTitle => 'Ho has confirmat ✓';

  @override
  String collaborationDetailFeedbackConfirmedBody(String partnerName) {
    return 'Esperant que $partnerName també ho confirmi. El Kolab es completa quan ho feu tots dos.';
  }

  @override
  String collaborationDetailPartnerSaidNotYetTitle(String partnerName) {
    return 'Esperant $partnerName';
  }

  @override
  String collaborationDetailPartnerSaidNotYetBody(String partnerName) {
    return '$partnerName ha dit que el Kolab encara no s\'ha fet. El Kolab es completa quan els dos confirmeu \'sí\'.';
  }

  @override
  String collaborationDetailPartnerSaidNoTitle(String partnerName) {
    return '$partnerName ha dit que no s\'ha fet';
  }

  @override
  String collaborationDetailPartnerSaidNoBody(String partnerName) {
    return '$partnerName ha dit que aquest Kolab no s\'ha fet. Contacta amb suport si necessites ajuda per resoldre-ho.';
  }

  @override
  String get collaborationCardWaitingForPartner =>
      'Has confirmat — esperant el soci';

  @override
  String get collaborationDetailReviewSubmitted => 'Ressenya enviada ✓';

  @override
  String get collaborationDetailLeaveReview => 'Deixa una ressenya';

  @override
  String get collaborationDetailXpBadge => '+10 XP';

  @override
  String collaborationDetailReviewHelp(String partnerName) {
    return 'Ajuda $partnerName a generar confiança a Kolabing.';
  }

  @override
  String get collaborationDetailLeaveReviewCta => 'Deixa una ressenya +10 XP ✨';

  @override
  String get communityMainNavHome => 'Inici';

  @override
  String get communityMainNavExplore => 'Explora';

  @override
  String get communityMainNavMyKolabs => 'Els meus Kolabs';

  @override
  String get communityMainNavCommunity => 'Comunitat';

  @override
  String get communityMainNavProfile => 'Perfil';

  @override
  String get communityMainCreateOpportunityTooltip => 'Crea una oportunitat';

  @override
  String get communityProfileSignOutTitle => 'Tanca la sessió';

  @override
  String get communityProfileSignOutBody => 'Segur que vols tancar la sessió?';

  @override
  String get communityProfileSignOutConfirm => 'Tanca la sessió';

  @override
  String get communityProfileSignOutButton => 'TANCA LA SESSIÓ';

  @override
  String get communityProfileDeleteAccountTitle => 'Elimina el compte';

  @override
  String get communityProfileDeleteAccountBody =>
      'Segur que vols eliminar el teu compte? Aquesta acció no es pot desfer.';

  @override
  String get communityProfileDeleteAccountConfirm => 'Elimina';

  @override
  String get communityProfileDeleteAccountLink => 'Elimina el compte';

  @override
  String get communityProfileChangePhotoTitle => 'Canvia la foto de perfil';

  @override
  String get communityProfileTakePhoto => 'Fes una foto';

  @override
  String get communityProfileTakePhotoSubtitle => 'Fes servir la càmera';

  @override
  String get communityProfileChooseFromGallery => 'Tria de la galeria';

  @override
  String get communityProfileChooseFromGallerySubtitle =>
      'Selecciona una foto existent';

  @override
  String get communityProfileUploadingPhoto => 'Pujant la foto...';

  @override
  String get communityProfilePhotoUpdated => 'Foto de perfil actualitzada';

  @override
  String communityProfilePhotoUpdateFailed(String error) {
    return 'No s\'ha pogut actualitzar la foto: $error';
  }

  @override
  String get communityProfileDismiss => 'Descarta';

  @override
  String get communityProfileLoadFailed => 'No s\'ha pogut carregar el perfil';

  @override
  String get communityProfileErrorTitle => 'Alguna cosa ha anat malament';

  @override
  String get communityProfileTryAgain => 'TORNA-HO A PROVAR';

  @override
  String get communityProfileCommunityFallback => 'Comunitat';

  @override
  String communityProfileLevelChip(int level, String title, int xp) {
    return 'NIV. $level · $title · $xp XP';
  }

  @override
  String get communityProfileAboutSection => 'Sobre';

  @override
  String get communityProfileContactInfoSection => 'Informació de contacte';

  @override
  String get communityProfileDetailsSection => 'Detalls de la comunitat';

  @override
  String get communityProfileSizeNotSet => 'Sense definir';

  @override
  String get communityProfileNotificationsSection => 'Notificacions';

  @override
  String get communityProfileNotifMessages => 'Missatges';

  @override
  String get communityProfileNotifApplications => 'Avisos de sol·licituds';

  @override
  String get communityProfileNotifKolabUpdates => 'Novetats de Kolabs';

  @override
  String get communityProfileNotifRewards => 'Recompenses i moneder';

  @override
  String get communityProfileNotifMarketing => 'Màrqueting i consells';

  @override
  String get communityProfileAccountSection => 'Compte';

  @override
  String get createOpportunityEditTitle => 'Edita el Kolab';

  @override
  String get createOpportunityCreateTitle => 'Crea un Kolab';

  @override
  String get createOpportunityStep0Title => 'INFORMACIÓ BÀSICA';

  @override
  String get createOpportunityStep0Subtitle => 'Descriu la teva idea de kolab';

  @override
  String get createOpportunityTitleLabel => 'Títol';

  @override
  String get createOpportunityTitleHint =>
      'p. ex., Promoció de la Setmana del Restaurant';

  @override
  String get createOpportunityDescriptionLabel => 'Descripció';

  @override
  String get createOpportunityDescriptionHint =>
      'Descriu la teva oportunitat de kolab en detall. Què estàs buscant?';

  @override
  String get createOpportunityCategoriesLabel => 'Categories';

  @override
  String get createOpportunityCategoriesHint =>
      'Selecciona fins a 5 categories';

  @override
  String get createOpportunityPhotoLabel => 'Foto del Kolab';

  @override
  String get createOpportunityPhotoHint =>
      'Opcional, però recomanada per a Explora.';

  @override
  String get createOpportunityStep1Title => 'QUÈ NECESSITES DE L\'EMPRESA?';

  @override
  String get createOpportunityStep1Subtitle =>
      'Selecciona el que la teva comunitat espera en aquest kolab';

  @override
  String get createOpportunityOfferVenueTitle => 'Local';

  @override
  String get createOpportunityOfferVenueSubtitle =>
      'Necessites un local per a l\'esdeveniment';

  @override
  String get createOpportunityOfferFoodTitle => 'Menjar i beguda';

  @override
  String get createOpportunityOfferFoodSubtitle =>
      'T\'agradaria que oferissin menjar o beguda';

  @override
  String get createOpportunityOfferDiscountTitle => 'Descompte';

  @override
  String get createOpportunityOfferDiscountSubtitle =>
      'Descompte especial per a la teva comunitat';

  @override
  String get createOpportunityDiscountPercentageLabel =>
      'Percentatge de descompte';

  @override
  String get createOpportunityDiscountPercentageHint => 'p. ex., 20';

  @override
  String get createOpportunityOfferProductsTitle => 'Productes';

  @override
  String get createOpportunityOfferProductsSubtitle =>
      'T\'agradaria rebre productes o mostres';

  @override
  String get createOpportunityProductNameHint => 'Nom del producte';

  @override
  String get createOpportunityAddProduct => 'AFEGEIX UN PRODUCTE';

  @override
  String get createOpportunityOfferOtherTitle => 'Altres';

  @override
  String get createOpportunityOfferOtherSubtitle =>
      'Un altre suport de l\'empresa';

  @override
  String get createOpportunityOfferOtherDetailsLabel =>
      'Detalls de l\'altra oferta';

  @override
  String get createOpportunityOfferOtherDetailsHint =>
      'Descriu el que ofereix l\'empresa';

  @override
  String get createOpportunityStep2Title => 'LLIURAMENTS DE LA COMUNITAT';

  @override
  String get createOpportunityStep2Subtitle =>
      'Què aportarà la comunitat a canvi?';

  @override
  String get createOpportunityDelivSocialTitle =>
      'Contingut a les xarxes socials';

  @override
  String get createOpportunityDelivSocialSubtitle =>
      'Publicació d\'Instagram, Història d\'Instagram, Reel / vídeo curt, vídeo de TikTok, contingut fotogràfic (UGC per a ús de marca)';

  @override
  String get createOpportunityDelivEventTitle => 'Activació a l\'esdeveniment';

  @override
  String get createOpportunityDelivEventSubtitle =>
      'Integració o menció de la marca durant el nostre esdeveniment';

  @override
  String get createOpportunityDelivProductTitle => 'Emplaçament de producte';

  @override
  String get createOpportunityDelivProductSubtitle =>
      'Exhibició o visibilitat del producte durant el nostre esdeveniment';

  @override
  String get createOpportunityDelivReachTitle => 'Abast de la comunitat';

  @override
  String get createOpportunityDelivReachSubtitle =>
      'Garantia d\'assistents mínims, accés als nostres membres, difusió, codi de descompte de la comunitat';

  @override
  String get createOpportunityDelivReviewTitle => 'Ressenyes i comentaris';

  @override
  String get createOpportunityDelivReviewSubtitle =>
      'Ressenyes a Google/xarxes, testimonis o comentaris dels membres';

  @override
  String get createOpportunityDelivOtherTitle => 'Altres';

  @override
  String get createOpportunityDelivOtherSubtitle =>
      'Escriu el teu propi lliurament';

  @override
  String get createOpportunityDelivOtherDetailsLabel =>
      'Detalls de l\'altre lliurament';

  @override
  String get createOpportunityDelivOtherDetailsHint =>
      'Descriu el que aportarà la comunitat';

  @override
  String get createOpportunityStep3Title => 'UBICACIÓ I DISPONIBILITAT';

  @override
  String get createOpportunityStep3Subtitle =>
      'Quan està disponible la teva comunitat per a aquest kolab?';

  @override
  String get createOpportunityAvailabilityLabel => 'Disponibilitat';

  @override
  String get createOpportunityVenueLabel => 'Local';

  @override
  String get createOpportunityAddressLabel => 'Adreça';

  @override
  String get createOpportunityAddressHint => 'Introdueix l\'adreça del local';

  @override
  String get createOpportunityPreferredCityLabel => 'Ciutat preferida';

  @override
  String createOpportunityCitiesLoadError(String error) {
    return 'Error en carregar les ciutats: $error';
  }

  @override
  String get createOpportunitySelectCityHint => 'Selecciona una ciutat';

  @override
  String get createOpportunityAvailableFromLabel => 'Disponible des de';

  @override
  String get createOpportunityAvailableUntilLabel => 'Disponible fins a';

  @override
  String get createOpportunityTimeLabel => 'Hora';

  @override
  String get createOpportunityDayOfWeekLabel => 'Dia de la setmana';

  @override
  String get createOpportunitySelectTime => 'Selecciona una hora';

  @override
  String get createOpportunityStep4Title => 'REVISA LA TEVA OPORTUNITAT';

  @override
  String get createOpportunityStep4Subtitle =>
      'Assegura\'t que tot és correcte abans de publicar';

  @override
  String get createOpportunityReviewUntitled => 'Oportunitat sense títol';

  @override
  String get createOpportunityReviewNoDescription => 'Sense descripció';

  @override
  String get createOpportunityReviewBusinessOffer => 'Oferta de l\'empresa';

  @override
  String get createOpportunityReviewDeliverables =>
      'Lliuraments de la comunitat';

  @override
  String get createOpportunityReviewNoCity => 'Cap ciutat seleccionada';

  @override
  String get createOpportunityReviewEditHint =>
      'Toca qualsevol secció de dalt per editar';

  @override
  String get createOpportunityBackButton => 'ENRERE';

  @override
  String get createOpportunityContinueButton => 'CONTINUA';

  @override
  String get createOpportunityPublishButton => 'PUBLICA';

  @override
  String get createOpportunitySaveDraftButton => 'DESA L\'ESBORRANY';

  @override
  String get myOpportunitiesTabPublished => 'Publicades';

  @override
  String get myOpportunitiesTabDraft => 'Esborrany';

  @override
  String get myOpportunitiesPublishError =>
      'No s\'ha pogut publicar l\'oportunitat';

  @override
  String get myOpportunitiesPublishSuccess => 'Oportunitat publicada!';

  @override
  String get myOpportunitiesShareUnavailable =>
      'No es pot compartir. S\'ha copiat l\'enllaç al seu lloc.';

  @override
  String get myOpportunitiesShareFailed =>
      'No s\'ha pogut obrir el menú per compartir.';

  @override
  String get myOpportunitiesCloseError =>
      'No s\'ha pogut tancar l\'oportunitat';

  @override
  String get myOpportunitiesCloseSuccess => 'Oportunitat tancada';

  @override
  String get myOpportunitiesDeleteTitle => 'Elimina l\'oportunitat';

  @override
  String get myOpportunitiesDeleteBody =>
      'Segur que vols eliminar aquesta oportunitat? Aquesta acció no es pot desfer.';

  @override
  String get myOpportunitiesDeleteConfirm => 'Elimina';

  @override
  String get myOpportunitiesDeleteError =>
      'No s\'ha pogut eliminar l\'oportunitat';

  @override
  String get myOpportunitiesDeleteSuccess => 'Oportunitat eliminada';

  @override
  String get myOpportunitiesCreateNewTooltip => 'Crea una nova oportunitat';

  @override
  String get myOpportunitiesHeaderTitle => 'Les meves oportunitats';

  @override
  String get myOpportunitiesHeaderSubtitle =>
      'Crea i gestiona les teves oportunitats';

  @override
  String myOpportunitiesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oportunitats',
      one: '1 oportunitat',
    );
    return '$_temp0';
  }

  @override
  String get myOpportunitiesEmptyTitle => 'Encara no hi ha oportunitats';

  @override
  String get myOpportunitiesEmptyBody =>
      'Crea la teva primera oportunitat i comença a connectar.';

  @override
  String get myOpportunitiesEmptyCreateButton => 'Crea una oportunitat';

  @override
  String get myOpportunitiesErrorTitle => 'Alguna cosa ha anat malament';

  @override
  String myOpportunityCardApplicationsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sol·licituds',
      one: '1 sol·licitud',
    );
    return '$_temp0';
  }

  @override
  String get myOpportunityCardUntitled => 'Oportunitat sense títol';

  @override
  String get myOpportunityCardActionView => 'Veure';

  @override
  String get myOpportunityCardActionEdit => 'Edita';

  @override
  String get myOpportunityCardActionPublish => 'Publica';

  @override
  String get myOpportunityCardActionShare => 'Comparteix';

  @override
  String get myOpportunityCardActionClose => 'Tanca';

  @override
  String get myOpportunityCardActionDelete => 'Elimina';

  @override
  String get opportunityPublishSuccessDraftTitle => 'Esborrany desat!';

  @override
  String get opportunityPublishSuccessPublishedTitle =>
      'Oportunitat publicada!';

  @override
  String get opportunityPublishSuccessDraftBody =>
      'La teva oportunitat s\'ha desat com a esborrany. La pots editar i publicar més tard.';

  @override
  String get opportunityPublishSuccessPublishedBody =>
      'La teva oportunitat ja és activa. Les empreses ja poden començar a presentar-s\'hi!';

  @override
  String get opportunityPublishSuccessShare => 'COMPARTEIX';

  @override
  String get opportunityPublishSuccessViewOpportunities =>
      'Veure les meves oportunitats';

  @override
  String get eventDetailDeleteTitle => 'Elimina l\'esdeveniment';

  @override
  String eventDetailDeleteConfirm(String name) {
    return 'Segur que vols eliminar \"$name\"? Aquesta acció no es pot desfer.';
  }

  @override
  String get eventDetailDeleteAction => 'Elimina';

  @override
  String get eventDetailDeletedSnack => 'Esdeveniment eliminat';

  @override
  String get eventDetailNotFound => 'No s\'ha trobat l\'esdeveniment';

  @override
  String get eventDetailPhotosTitle => 'Fotos';

  @override
  String get eventDetailVideosTitle => 'Vídeos';

  @override
  String get eventDetailDeleteButton => 'ELIMINA L\'ESDEVENIMENT';

  @override
  String get eventDetailKolabWithLabel => 'Kolab amb';

  @override
  String get eventDetailDateLabel => 'Data de l\'esdeveniment';

  @override
  String get eventDetailAttendeesLabel => 'Assistents';

  @override
  String eventDetailAttendeesCount(num count) {
    return '$count persones';
  }

  @override
  String eventDetailRecapVideoTitle(num number) {
    return 'Vídeo resum $number';
  }

  @override
  String get eventDetailRecapVideoSubtitle => 'Toca per obrir el vídeo penjat';

  @override
  String get eventDetailVideoOpenError =>
      'No s\'ha pogut obrir l\'enllaç del vídeo';

  @override
  String get addEventTitle => 'Afegeix un esdeveniment passat';

  @override
  String get addEventMaxPhotos => 'Màxim 5 fotos permeses';

  @override
  String get addEventMaxVideos => 'Màxim 1 vídeo permès';

  @override
  String get addEventAtLeastOnePhoto => 'Afegeix almenys una foto';

  @override
  String get addEventSuccess => 'Esdeveniment afegit correctament';

  @override
  String get addEventFailure => 'No s\'ha pogut afegir l\'esdeveniment';

  @override
  String get addEventNameLabel => 'Nom de l\'esdeveniment';

  @override
  String get addEventNameHint => 'p. ex., Festival de Música d\'Estiu';

  @override
  String get addEventNameError => 'Introdueix el nom de l\'esdeveniment';

  @override
  String get addEventPartnerLabel => 'Kolab amb';

  @override
  String get addEventPartnerHint => 'p. ex., Rock Community Istanbul';

  @override
  String get addEventPartnerError => 'Introdueix el nom del col·laborador';

  @override
  String get addEventDateLabel => 'Data de l\'esdeveniment';

  @override
  String get addEventAttendeeCountLabel => 'Nombre d\'assistents';

  @override
  String get addEventAttendeeCountHint => 'p. ex., 250';

  @override
  String get addEventAttendeeCountError => 'Introdueix el nombre d\'assistents';

  @override
  String get addEventAttendeeCountInvalid => 'Introdueix un nombre vàlid';

  @override
  String get addEventPhotosLabel => 'Fotos de l\'esdeveniment';

  @override
  String addEventPhotosCounter(num count) {
    return '($count/5)';
  }

  @override
  String get addEventAddPhotoButton => 'Afegeix una foto';

  @override
  String get addEventVideoLabel => 'Vídeo resum (opcional)';

  @override
  String get addEventVideoDescription =>
      'Afegeix un vídeo curt per mostrar com es va viure l\'esdeveniment.';

  @override
  String get addEventAddVideoButton => 'AFEGEIX VÍDEO';

  @override
  String get addEventSubmitButton => 'AFEGEIX ESDEVENIMENT';

  @override
  String get pastEventsTitle => 'Esdeveniments passats';

  @override
  String get pastEventsAddButton => 'AFEGEIX';

  @override
  String get pastEventsLoadError =>
      'No s\'han pogut carregar els esdeveniments';

  @override
  String get pastEventsEmptyTitle => 'Encara no hi ha esdeveniments';

  @override
  String get pastEventsEmptySubtitle =>
      'Comparteix els teus kolabs passats amb la comunitat';

  @override
  String get pastEventsEmptyAddButton => '+ Afegeix un esdeveniment passat';

  @override
  String get attendeeRoleLabel => 'Assistent';

  @override
  String get attendeeNavHome => 'Inici';

  @override
  String get attendeeNavCommunities => 'Comunitats';

  @override
  String get attendeeNavScan => 'Escanejar';

  @override
  String get attendeeNavProfile => 'Perfil';

  @override
  String get attendeeMyQrTitle => 'El meu QR de perfil';

  @override
  String get attendeeMyQrSubtitle =>
      'Deixa que algú l\'escanegi per fer-te check-in o emparellar-vos en un repte.';

  @override
  String get attendeeMyQrTooltip => 'El meu codi QR';

  @override
  String get attendeeMyQrUnavailable =>
      'El teu QR de perfil encara no està a punt.';

  @override
  String get attendeeHomeWelcomeBack => 'Benvingut de nou';

  @override
  String get attendeeHomeNearbyEvents => 'ESDEVENIMENTS PROPERS';

  @override
  String attendeeHomeRadiusKm(String radius) {
    return '$radius km';
  }

  @override
  String get attendeeHomeGettingLocation => 'Obtenint la teva ubicació...';

  @override
  String get attendeeHomeSearchingEvents => 'Cercant esdeveniments...';

  @override
  String attendeeHomeShowingWithinRadius(String radius) {
    return 'Mostrant esdeveniments en un radi de $radius km';
  }

  @override
  String attendeeHomeEventsFound(num count) {
    return '$count trobats';
  }

  @override
  String get attendeeHomeLoadMore => 'Carregar més';

  @override
  String get attendeeHomeStatPoints => 'Punts';

  @override
  String get attendeeHomeStatChallenges => 'Reptes';

  @override
  String get attendeeHomeStatEvents => 'Esdeveniments';

  @override
  String get attendeeHomeLocationRequired => 'Cal la ubicació';

  @override
  String get attendeeHomeTryAgain => 'Torna-ho a provar';

  @override
  String get attendeeHomeOpenSettings => 'Obrir la configuració';

  @override
  String get attendeeHomeNoEventsNearby => 'No hi ha esdeveniments a prop';

  @override
  String get attendeeHomeNoEventsNearbyHint =>
      'Prova a ampliar el radi de cerca\no torna més tard per veure nous esdeveniments.';

  @override
  String get attendeeHomeAdjustRadius => 'Ajustar el radi';

  @override
  String get attendeeHomeFailedToLoadEvents =>
      'No s\'han pogut carregar els esdeveniments';

  @override
  String get attendeeHomeSearchRadius => 'Radi de cerca';

  @override
  String get attendeeHomeApply => 'Aplicar';

  @override
  String get attendeeHomeLocationDenied => 'Permís d\'ubicació denegat';

  @override
  String get attendeeHomeLocationDeniedForever =>
      'Els permisos d\'ubicació estan denegats permanentment. Activa\'ls a la configuració.';

  @override
  String get attendeeHomeLocationServicesDisabled =>
      'Els serveis d\'ubicació estan desactivats';

  @override
  String attendeeHomeLocationError(String error) {
    return 'No s\'ha pogut obtenir la ubicació: $error';
  }

  @override
  String get attendeeProfileYourStats => 'LES TEVES ESTADÍSTIQUES';

  @override
  String get attendeeProfileTotalPoints => 'Punts totals';

  @override
  String get attendeeProfileChallenges => 'Reptes';

  @override
  String get attendeeProfileEventsAttended => 'Esdeveniments assistits';

  @override
  String get attendeeProfileEditProfile => 'Editar el perfil';

  @override
  String get attendeeProfileNotifications => 'Notificacions';

  @override
  String get attendeeProfileHelpSupport => 'Ajuda i suport';

  @override
  String get attendeeProfileSignOut => 'Tancar la sessió';

  @override
  String get attendeeProfileSignOutConfirm =>
      'Segur que vols tancar la sessió?';

  @override
  String get attendeeProfileStatFriends => 'Amics';

  @override
  String get attendeeProfileStatEvents => 'Esdeveniments';

  @override
  String get attendeeProfileStatChats => 'Xats';

  @override
  String get attendeeProfileStatPoints => 'Punts';

  @override
  String get attendeeProfileMyCommunities => 'LES MEVES COMUNITATS';

  @override
  String get attendeeProfileNoCommunities =>
      'Encara no t\'has unit a cap comunitat.';

  @override
  String get attendeeProfileFindFriends => 'Cerca amics';

  @override
  String get attendeeProfileFriends => 'AMICS';

  @override
  String get attendeeProfileSeeAll => 'Mostra-ho tot';

  @override
  String get editProfileTitle => 'Edita el perfil';

  @override
  String get editProfileChangePhoto => 'Canvia la foto';

  @override
  String get editProfileNameLabel => 'Nom';

  @override
  String get editProfileNameHint => 'El teu nom';

  @override
  String get editProfileNameRequired => 'Introdueix el teu nom.';

  @override
  String get editProfileCityLabel => 'Ciutat';

  @override
  String get editProfileCityHint => 'Selecciona la teva ciutat';

  @override
  String get editProfileCitySearchHint => 'Cerca ciutats';

  @override
  String get editProfileNoCitiesFound => 'No s\'ha trobat cap ciutat';

  @override
  String get editProfileCityLoadError => 'No s\'han pogut carregar les ciutats';

  @override
  String get editProfileSave => 'Desa';

  @override
  String get editProfileSaved => 'Perfil actualitzat';

  @override
  String get editProfileSaveError =>
      'No s\'ha pogut desar el teu perfil. Torna-ho a provar.';

  @override
  String get memberProfileFriends => 'Amics';

  @override
  String get badgesScreenTitle => 'Insígnies';

  @override
  String get badgesScreenEarnedBadges => 'INSÍGNIES ACONSEGUIDES';

  @override
  String get badgesScreenAllBadges => 'TOTES LES INSÍGNIES';

  @override
  String get badgesScreenBadgesEarned => 'Insígnies aconseguides';

  @override
  String get badgesScreenFailedToLoad =>
      'No s\'han pogut carregar les insígnies';

  @override
  String get gamificationTryAgain => 'Torna-ho a provar';

  @override
  String get leaderboardScreenGlobalTitle => 'Classificació global';

  @override
  String get leaderboardScreenTitle => 'Classificació';

  @override
  String get leaderboardScreenRankings => 'CLASSIFICACIÓ';

  @override
  String get leaderboardScreenYourRanking => 'La teva posició';

  @override
  String get leaderboardScreenPoints => 'punts';

  @override
  String get leaderboardScreenNoRankings => 'Encara no hi ha classificació';

  @override
  String get leaderboardScreenNoRankingsHint =>
      'Sigues el primer a guanyar punts\ni fes-te amb el primer lloc!';

  @override
  String get leaderboardScreenFailedToLoad =>
      'No s\'ha pogut carregar la classificació';

  @override
  String get statsScreenTitle => 'Les meves estadístiques';

  @override
  String get statsScreenTotalPoints => 'Punts totals';

  @override
  String get statsScreenEvents => 'Esdeveniments';

  @override
  String get statsScreenChallenges => 'Reptes';

  @override
  String get statsScreenBadges => 'Insígnies';

  @override
  String get statsScreenDetailedStats => 'ESTADÍSTIQUES DETALLADES';

  @override
  String get statsScreenRewardsWon => 'Recompenses guanyades';

  @override
  String get statsScreenRewardsRedeemed => 'Recompenses bescanviades';

  @override
  String get statsScreenEventsDiscovered => 'Esdeveniments descoberts';

  @override
  String get statsScreenSpinsUsed => 'Tirades utilitzades';

  @override
  String get statsScreenQuickActions => 'ACCIONS RÀPIDES';

  @override
  String get statsScreenRewards => 'Recompenses';

  @override
  String get statsScreenShareComingSoon =>
      'Compartir la teva targeta de joc estarà disponible aviat!';

  @override
  String get statsScreenFailedToLoad =>
      'No s\'han pogut carregar les estadístiques';

  @override
  String get commonTryAgain => 'Torna-ho a provar';

  @override
  String get createChallengeTitle => 'Crea un repte';

  @override
  String get createChallengeSuccess => 'Repte creat correctament!';

  @override
  String get createChallengeNameLabel => 'Nom del repte';

  @override
  String get createChallengeNameHint => 'Introdueix el nom del repte';

  @override
  String get createChallengeNameRequired => 'Introdueix el nom del repte';

  @override
  String get createChallengeNameTooShort =>
      'El nom ha de tenir com a mínim 3 caràcters';

  @override
  String get createChallengeDescriptionLabel => 'Descripció';

  @override
  String get createChallengeDescriptionHint =>
      'Descriu què han de fer els assistents';

  @override
  String get createChallengeDifficultyLabel => 'Dificultat';

  @override
  String get createChallengePointsLabel => 'Punts';

  @override
  String get createChallengePointsHint => 'Punts atorgats';

  @override
  String get createChallengePointsInvalid => 'Introdueix un número vàlid';

  @override
  String get createChallengePointsMax => 'Màxim 100 punts';

  @override
  String get createChallengeResetDefault => 'Restableix el valor predeterminat';

  @override
  String get createChallengePointsDefaultHint =>
      'Predeterminat: Fàcil=5, Mitjà=15, Difícil=30 punts';

  @override
  String get createChallengeSubmit => 'CREA UN REPTE';

  @override
  String createChallengePointsValue(int points) {
    return '$points pts';
  }

  @override
  String get eventChallengesTitle => 'Reptes';

  @override
  String get eventChallengesTabAll => 'Tots els reptes';

  @override
  String get eventChallengesTabCustom => 'Personalitzats';

  @override
  String get eventChallengesEmptyAll =>
      'No hi ha reptes disponibles per a aquest esdeveniment';

  @override
  String get eventChallengesEmptyCustomOrganizer =>
      'Crea reptes personalitzats per al teu esdeveniment';

  @override
  String get eventChallengesEmptyCustom =>
      'Encara no hi ha reptes personalitzats';

  @override
  String get eventChallengesNewChallenge => 'Nou repte';

  @override
  String eventChallengesPointsAwarded(int points) {
    return '+$points pts';
  }

  @override
  String get eventChallengesSystemBadge => 'Sistema';

  @override
  String get eventChallengesStartChallenge => 'INICIA EL REPTE';

  @override
  String get eventDiscoveryTitle => 'Descobreix esdeveniments';

  @override
  String get eventDiscoveryPermissionDenied => 'Permís d\'ubicació denegat';

  @override
  String get eventDiscoveryPermissionDeniedForever =>
      'Els permisos d\'ubicació estan denegats permanentment. Activa\'ls a la configuració.';

  @override
  String get eventDiscoveryServicesDisabled =>
      'Els serveis d\'ubicació estan desactivats';

  @override
  String eventDiscoveryLocationFailed(String error) {
    return 'No s\'ha pogut obtenir la ubicació: $error';
  }

  @override
  String get eventDiscoveryGettingLocation => 'Obtenint la teva ubicació...';

  @override
  String get eventDiscoverySearching => 'Cercant esdeveniments...';

  @override
  String eventDiscoveryRadiusInfo(String radius) {
    return 'Mostrant esdeveniments en un radi de $radius km';
  }

  @override
  String eventDiscoveryFoundCount(int count) {
    return '$count trobats';
  }

  @override
  String get eventDiscoveryLoadMore => 'Carrega\'n més';

  @override
  String get eventDiscoveryLocationRequired => 'Cal la ubicació';

  @override
  String get eventDiscoveryOpenSettings => 'Obre la configuració';

  @override
  String get eventDiscoveryEmptyTitle => 'No hi ha esdeveniments a prop';

  @override
  String get eventDiscoveryEmptyBody =>
      'Prova d\'augmentar el radi de cerca\no torna més tard per veure nous esdeveniments.';

  @override
  String get eventDiscoveryAdjustRadius => 'Ajusta el radi';

  @override
  String get eventDiscoveryErrorTitle =>
      'No s\'han pogut descobrir esdeveniments';

  @override
  String get eventDiscoverySearchRadius => 'Radi de cerca';

  @override
  String eventDiscoveryRadiusKm(String radius) {
    return '$radius km';
  }

  @override
  String get eventDiscoveryApply => 'Aplica';

  @override
  String get eventQrTitle => 'Registre de l\'esdeveniment';

  @override
  String get eventQrInstructions =>
      'Els assistents poden escanejar aquest codi QR per registrar-se al teu esdeveniment';

  @override
  String get eventQrGenerating => 'Generant el codi QR...';

  @override
  String get eventQrErrorTitle => 'No s\'ha pogut generar el codi QR';

  @override
  String get eventQrCopyToken => 'Copia el testimoni';

  @override
  String get eventQrTokenCopied => 'Testimoni copiat al porta-retalls';

  @override
  String get initiateChallengeTitle => 'Inicia el repte';

  @override
  String get initiateChallengeFailed => 'No s\'ha pogut iniciar el repte';

  @override
  String get initiateChallengeSuccessTitle => 'Repte iniciat!';

  @override
  String get initiateChallengeSuccessBody =>
      'S\'avisarà el verificador perquè confirmi que has completat el repte.';

  @override
  String initiateChallengePointsAwarded(int points) {
    return '+$points pts';
  }

  @override
  String get initiateChallengeHowItWorks => 'Com funciona';

  @override
  String get initiateChallengeStep1 =>
      'Introdueix l\'ID de perfil del verificador';

  @override
  String get initiateChallengeStep2 =>
      'Completa el repte amb el verificador present';

  @override
  String get initiateChallengeStep3 =>
      'El verificador confirma que l\'has completat';

  @override
  String get initiateChallengeStep4 => 'Guanya els teus punts!';

  @override
  String get initiateChallengeVerifierLabel => 'ID de perfil del verificador';

  @override
  String get initiateChallengeVerifierHint =>
      'Introdueix l\'ID de perfil del verificador';

  @override
  String get initiateChallengeVerifierRequired =>
      'Introdueix l\'ID de perfil del verificador';

  @override
  String get initiateChallengeVerifierHelper =>
      'Demana a un altre assistent el seu ID de perfil per verificar el teu repte';

  @override
  String get initiateChallengeSubmit => 'INICIA EL REPTE';

  @override
  String get qrScannerEventFallback => 'Esdeveniment';

  @override
  String get qrScannerCheckinFailed => 'No s\'ha pogut registrar l\'entrada';

  @override
  String get qrScannerSuccessTitle => 'Registre completat!';

  @override
  String get qrScannerSuccessSubtitle => 'T\'has registrat a';

  @override
  String get qrScannerErrorTitle => 'El registre ha fallat';

  @override
  String get qrScannerClose => 'Tanca';

  @override
  String get qrScannerTitle => 'Escaneja el codi QR';

  @override
  String get qrScannerCheckingIn => 'Registrant...';

  @override
  String get qrScannerInstructionTitle =>
      'Apunta la càmera a un codi QR de Kolabing';

  @override
  String get qrScannerInstructionSubtitle =>
      'El codi de check-in d\'un esdeveniment o el QR de perfil d\'un altre membre';

  @override
  String get rewardWalletTitle => 'Les meves recompenses';

  @override
  String get rewardWalletEmptyTitle => 'Encara no hi ha recompenses';

  @override
  String get rewardWalletEmptyBody =>
      'Completa reptes i fes girar la ruleta\nper guanyar recompenses increïbles!';

  @override
  String get rewardWalletErrorTitle =>
      'No s\'han pogut carregar les recompenses';

  @override
  String get challengeCompletionDefaultName => 'Repte';

  @override
  String get challengeCompletionDefaultChallenger => 'Reptador';

  @override
  String get challengeCompletionReject => 'Rebutja';

  @override
  String get challengeCompletionVerify => 'Verifica';

  @override
  String get challengeCompletionStatusVerified => 'Verificat';

  @override
  String get challengeCompletionStatusRejected => 'Rebutjat';

  @override
  String get challengeCompletionStatusPending => 'Pendent';

  @override
  String get mediaTitleVenue => 'MOSTRA EL TEU LOCAL';

  @override
  String get mediaTitleProduct => 'MOSTRA EL TEU PRODUCTE';

  @override
  String get mediaSubtitle =>
      'Afegeix fotos perquè les comunitats vegin què ofereixes. (Mín. 1, màx. 5)';

  @override
  String get mediaSelectFromLibrary => 'SELECCIONA DE LA BIBLIOTECA';

  @override
  String get mediaSelectExistingTitle => 'Selecciona fotos existents';

  @override
  String get mediaUsePhoto => 'Fes servir la foto';

  @override
  String get mediaUsePhotos => 'Fes servir les fotos';

  @override
  String get mediaPhotosAlreadyAdded =>
      'Aquestes fotos ja són en aquest Kolab.';

  @override
  String mediaPhotosAdded(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'S\'han afegit $count fotos existents.',
      one: 'S\'ha afegit $count foto existent.',
    );
    return '$_temp0';
  }

  @override
  String mediaUploadFailed(String error) {
    return 'Ha fallat la pujada: $error';
  }

  @override
  String get mediaAddPhoto => 'Afegeix foto';

  @override
  String mediaPhotoSlot(int number) {
    return 'Foto $number';
  }

  @override
  String get offeringTitle => 'QUÈ OFEREIXES';

  @override
  String get offeringSelectAllThatApply => 'Selecciona tot el que correspongui';

  @override
  String get needsScreenTitle => 'QUÈ NECESSITES?';

  @override
  String get offeringVenueTitle => 'Local';

  @override
  String get offeringVenueSubtitle => 'Ofereix el teu espai per al kolab';

  @override
  String get offeringFoodDrinkTitle => 'Menjar i beguda inclosos';

  @override
  String get offeringFoodDrinkSubtitle =>
      'Àpats o begudes per als membres de la comunitat';

  @override
  String get offeringDiscountTitle => 'Descompte per a membres de la comunitat';

  @override
  String get offeringDiscountSubtitle => 'Preus exclusius per als participants';

  @override
  String get offeringProductsTitle => 'Productes / Mostres';

  @override
  String get offeringProductsSubtitle =>
      'Mostres de producte gratuïtes o obsequis';

  @override
  String get offeringSocialMediaTitle => 'Visibilitat a les xarxes socials';

  @override
  String get offeringSocialMediaSubtitle => 'Apareix als teus canals';

  @override
  String get offeringContentCreationTitle => 'Creació de contingut';

  @override
  String get offeringContentCreationSubtitle => 'Fotos i vídeo professionals';

  @override
  String get offeringSponsorshipTitle => 'Pressupost de col·laboració';

  @override
  String get offeringSponsorshipSubtitle => 'Suport econòmic per al kolab';

  @override
  String get offeringOtherTitle => 'Altres';

  @override
  String get offeringOtherSubtitle => 'Alguna cosa més a oferir';

  @override
  String get offeringBaseOfferLabel => 'OFERTA BÀSICA';

  @override
  String get offeringBaseOfferHelper =>
      'El que cada comunitat veurà a la teva targeta. Sigues específic perquè els responsables ho puguin avaluar d\'un cop d\'ull.';

  @override
  String get offeringBaseOfferHint =>
      'p. ex. 20% de descompte els dimarts, sala de reunions gratuïta per a grups de 10 o més';

  @override
  String get offeringExtraTermsLabel => 'CONDICIONS ADDICIONALS (OPCIONAL)';

  @override
  String get offeringExtraTermsHelper =>
      'Millors condicions que només es desbloquegen quan una comunitat proposa un kolab. Les veuen després d\'enviar-te un Kolab.';

  @override
  String get offeringAddExtraTerm => 'AFEGEIX UNA CONDICIÓ';

  @override
  String offeringTriggerIfPrefix(String condition) {
    return 'SI $condition';
  }

  @override
  String get offeringTriggerSheetTitle => 'Afegeix una condició';

  @override
  String get offeringTriggerSheetSubtitle =>
      'Només apareix després que una comunitat enviï una proposta de Kolab.';

  @override
  String get offeringTriggerWhenLabel => 'Quan';

  @override
  String get offeringTriggerWhenHint =>
      'p. ex. esdeveniments mensuals recurrents';

  @override
  String get offeringTriggerThenLabel => 'Llavors ofereix';

  @override
  String get offeringTriggerThenHint =>
      'p. ex. lloguer del local gratuït a partir del tercer esdeveniment';

  @override
  String get offeringAddTerm => 'AFEGEIX LA CONDICIÓ';

  @override
  String get pastEventsSubtitle =>
      'Mostra a les comunitats quins esdeveniments s\'han celebrat abans al teu local.';

  @override
  String get pastEventsLoadingProfileEvents =>
      'Carregant esdeveniments del perfil...';

  @override
  String get pastEventsSelectFromProfile => 'Selecciona del perfil';

  @override
  String get pastEventsAddPastEvent => 'Afegeix un esdeveniment anterior';

  @override
  String get pastEventsAllAlreadyAdded =>
      'Ja s\'han afegit tots els esdeveniments del perfil.';

  @override
  String pastEventsImported(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'S\'han importat $count esdeveniments del perfil.',
      one: 'S\'ha importat $count esdeveniment del perfil.',
    );
    return '$_temp0';
  }

  @override
  String pastEventsImportedMediaTrimmed(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'S\'han importat $count esdeveniments del perfil. Cada esdeveniment anterior admet fins a 3 fotos i 1 vídeo; el contingut sobrant s\'ha retallat.',
      one:
          'S\'ha importat $count esdeveniment del perfil. Cada esdeveniment anterior admet fins a 3 fotos i 1 vídeo; el contingut sobrant s\'ha retallat.',
    );
    return '$_temp0';
  }

  @override
  String pastEventsEventNumber(int number) {
    return 'Esdeveniment $number';
  }

  @override
  String get pastEventsEventNameLabel => 'Nom de l\'esdeveniment';

  @override
  String get pastEventsEventNameHint => 'p. ex. Trobada de benestar d\'estiu';

  @override
  String get pastEventsDateLabel => 'Data';

  @override
  String get pastEventsPartnerNameLabel => 'Nom del col·laborador';

  @override
  String get pastEventsPartnerNameHint =>
      'p. ex. Club de Corredors de la Ciutat';

  @override
  String get pastEventsPhotosLabel => 'Fotos (màx. 3)';

  @override
  String get pastEventsRecapVideoLabel => 'Vídeo resum (màx. 1)';

  @override
  String get pastEventsRecapVideoChip => 'Vídeo resum';

  @override
  String pastEventsUploadFailed(String error) {
    return 'Ha fallat la pujada: $error';
  }

  @override
  String get productDetailsSectionHeader => 'EL TEU PRODUCTE O SERVEI';

  @override
  String get productDetailsListingTitleLabel => 'Títol de l\'anunci';

  @override
  String get productDetailsListingTitleHint =>
      'p. ex. Cold brew orgànic, perfecte per a esdeveniments comunitaris';

  @override
  String get productDetailsProductNameLabel => 'Nom del producte';

  @override
  String get productDetailsProductNameHint => 'p. ex. Cafè cold brew orgànic';

  @override
  String get productDetailsProductTypeLabel => 'Tipus de producte';

  @override
  String get productDetailsDescriptionLabel => 'Descripció';

  @override
  String get productDetailsDescriptionHint =>
      'Descriu el teu producte o servei...';

  @override
  String get productDetailsOfferHeadlineLabel => 'Títol de l\'oferta';

  @override
  String get productDetailsOfferHeadlineHelper =>
      'Una línia breu que les comunitats veuran a la teva targeta.';

  @override
  String get productDetailsOfferHeadlineHint =>
      'p. ex. Gratis amb qualsevol comanda de 5 o més';

  @override
  String get productDetailsCityLabel => 'Ciutat';

  @override
  String get productDetailsSelectCityHint => 'Selecciona una ciutat';

  @override
  String get productDetailsFailedToLoadCities =>
      'No s\'han pogut carregar les ciutats';

  @override
  String get venueDetailsSectionHeader => 'DETALLS DE LA PROMOCIÓ';

  @override
  String get venueDetailsListingTitleLabel => 'Títol de l\'anunci';

  @override
  String get venueDetailsListingTitleHint =>
      'p. ex. Trobada al terrat al capvespre per a creadors locals';

  @override
  String get venueDetailsCampaignDescriptionLabel =>
      'Descripció de la campanya';

  @override
  String get venueDetailsCampaignDescriptionHint =>
      'Explica a les comunitats quin tipus d\'experiència vols oferir i per què el teu local hi encaixa a la perfecció.';

  @override
  String get venueDetailsOfferHeadlineLabel => 'Títol de l\'oferta';

  @override
  String get venueDetailsOfferHeadlineHelper =>
      'Una línia breu que les comunitats veuran a la teva targeta.';

  @override
  String get venueDetailsOfferHeadlineHint =>
      'p. ex. 20% de descompte els dimarts per a grups de 10 o més';

  @override
  String get venueDetailsPrimaryVenue => 'LOCAL PRINCIPAL';

  @override
  String get venueDetailsVenueFallback => 'Local';

  @override
  String venueDetailsTypeCapacity(String type, String capacity) {
    return '$type • Aforament $capacity';
  }

  @override
  String get communityInfoTypeHeader => 'TIPUS DE LA TEVA COMUNITAT';

  @override
  String get communityInfoTypeSubtitle =>
      'Ajuda les empreses a entendre el teu públic. Selecciona\'n fins a 3.';

  @override
  String get communityInfoCommunitySizeLabel => 'MIDA DE LA COMUNITAT';

  @override
  String get communityInfoCommunitySizeHint => 'p. ex., 500';

  @override
  String get communityInfoExpectedAttendeesLabel => 'ASSISTENTS PREVISTOS';

  @override
  String get communityInfoExpectedAttendeesHint => 'p. ex., 50';

  @override
  String get eventDetailsHeader => 'DETALLS DEL KOLAB';

  @override
  String get eventDetailsSubtitle => 'Descriu el teu kolab i el que ofereixes';

  @override
  String get eventDetailsTitleLabel => 'Títol';

  @override
  String get eventDetailsTitleHint =>
      'p. ex., Comunitat fitness x Cafeteria local';

  @override
  String get eventDetailsDescriptionLabel => 'Descripció';

  @override
  String get eventDetailsDescriptionHint =>
      'Descriu el que busques i com funcionaria aquest kolab...';

  @override
  String get eventDetailsOffersHeader => 'EL QUE OFEREIXES A CANVI';

  @override
  String get logisticsAvailabilityHeader => 'DISPONIBILITAT';

  @override
  String get logisticsAvailabilitySubtitle =>
      'Quan està disponible la teva comunitat per a aquest kolab?';

  @override
  String get logisticsLocationHeader => 'UBICACIÓ';

  @override
  String get logisticsPreferredCityLabel => 'Ciutat preferida';

  @override
  String logisticsCitiesLoadError(String error) {
    return 'Error en carregar les ciutats: $error';
  }

  @override
  String get logisticsSelectCityHint => 'Selecciona una ciutat';

  @override
  String get logisticsPreferredAreaLabel => 'Barri / zona preferida (opcional)';

  @override
  String get logisticsPreferredAreaHint => 'p. ex., Shoreditch, Kreuzberg';

  @override
  String get logisticsAvailableFromLabel => 'Disponible des de';

  @override
  String get logisticsAvailableUntilLabel => 'Disponible fins a';

  @override
  String get logisticsTimeLabel => 'Hora';

  @override
  String get logisticsDayOfWeekLabel => 'Dia de la setmana';

  @override
  String get logisticsSelectDate => 'Selecciona una data';

  @override
  String get logisticsSelectTime => 'Selecciona una hora';

  @override
  String get photoAddHeader => 'AFEGEIX UNA FOTO';

  @override
  String get photoAddSubtitle =>
      'Apareixerà a la targeta del teu kolab a Explora.';

  @override
  String get photoUseProfilePhoto =>
      'Fes servir la foto de perfil de la teva comunitat';

  @override
  String get photoDividerOr => 'O';

  @override
  String get photoChooseFromGallery =>
      'Tria de la galeria o esdeveniments anteriors';

  @override
  String get photoUploadTitle => 'Puja una foto';

  @override
  String get photoUploadMaxSize => 'Màx. 5 MB';

  @override
  String photoUploadFailed(String error) {
    return 'Error en pujar: $error';
  }

  @override
  String get photoPickerSheetTitle =>
      'Fes servir una foto de la galeria o d\'un esdeveniment anterior';

  @override
  String get photoPickerConfirmLabel => 'Fes servir la foto';

  @override
  String get photoUploadedSelectedTitle => 'Foto pujada seleccionada';

  @override
  String get photoUploadedSelectedSubtitle =>
      'Aquesta imatge apareixerà a la targeta del teu kolab a Explora.';

  @override
  String get photoUseProfilePhotoButton => 'Fes servir la foto de perfil';

  @override
  String get photoReplacePhotoButton => 'Reemplaça la foto';

  @override
  String get intentSelectionAppBarTitle => 'Nou Kolab';

  @override
  String get intentSelectionCommunityTitle => 'Què t\'agradaria fer?';

  @override
  String get intentSelectionBusinessTitle => 'Què t\'agradaria promocionar?';

  @override
  String get intentSelectionCommunitySubtitle =>
      'Tria com vols fer kolab amb negocis.';

  @override
  String get intentSelectionBusinessSubtitle =>
      'Tria què vols promocionar a les comunitats.';

  @override
  String get intentSelectionFindVenueTitle => 'Troba un local o marca';

  @override
  String get intentSelectionFindVenueSubtitle =>
      'per a l\'esdeveniment de la meva comunitat';

  @override
  String get intentSelectionBadgeFree => 'GRATIS';

  @override
  String get intentSelectionPromoteVenueTitle => 'Promociona el meu local';

  @override
  String get intentSelectionPromoteVenueSubtitle =>
      'Aconsegueix que les comunitats organitzin esdeveniments al teu local';

  @override
  String get intentSelectionPromoteProductTitle =>
      'Promociona un producte o servei';

  @override
  String get intentSelectionPromoteProductSubtitle =>
      'Aconsegueix que les comunitats mostrin els teus productes als seus esdeveniments';

  @override
  String get intentSelectionProfileLoadError =>
      'No s\'ha pogut carregar el teu perfil';

  @override
  String get intentSelectionProfileLoadErrorHint =>
      'Torna-ho a provar per continuar creant un kolab.';

  @override
  String get intentSelectionLockedTitle =>
      'Cal una subscripció activa per crear Kolabs.';

  @override
  String get intentSelectionLockedSubtitle =>
      'Millora el teu pla de negoci per publicar oportunitats de local o producte per a les comunitats.';

  @override
  String get intentSelectionUpgradeButton => 'Millora per crear';

  @override
  String get kolabFlowNoIntentSelected => 'No s\'ha seleccionat cap intenció';

  @override
  String get kolabFlowTitleFindPartner => 'Troba un soci';

  @override
  String get kolabFlowTitlePromoteVenue => 'Promociona local';

  @override
  String get kolabFlowTitlePromoteProduct => 'Promociona producte';

  @override
  String get kolabFlowPublishedTitle => 'Kolab publicat!';

  @override
  String get kolabFlowDraftSavedTitle => 'Esborrany desat!';

  @override
  String get kolabFlowPublishedMessage =>
      'El teu kolab ja és visible a Explora.';

  @override
  String get kolabFlowDraftSavedMessage => 'Pots continuar editant més tard.';

  @override
  String get myKolabsHubTitle => 'Els meus Kolabs';

  @override
  String get myKolabsHubTabOffers => 'OFERTES';

  @override
  String get myKolabsHubTabRequests => 'SOL·LICITUDS';

  @override
  String get myKolabsHubTabActive => 'ACTIUS';

  @override
  String get myKolabsHubTabFinished => 'FINALITZATS';

  @override
  String get myKolabsHubActiveEmptyTitle => 'No hi ha kolabs actius';

  @override
  String get myKolabsHubActiveEmptyMessage =>
      'Quan totes dues parts accepten una sol·licitud, el kolab apareix aquí mentre està en curs.';

  @override
  String get myKolabsHubFinishedEmptyTitle => 'Encara no hi ha res finalitzat';

  @override
  String get myKolabsHubFinishedEmptyMessage =>
      'Els kolabs completats i cancel·lats es recolliran aquí.';

  @override
  String get myKolabsHubCreateTooltip => 'Crear Kolab';

  @override
  String existingPhotoPickerSubtitle(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotos pujades anteriorment',
      one: '1 foto pujada anteriorment',
    );
    return 'Selecciona fins a $_temp0.';
  }

  @override
  String get existingPhotoPickerEmpty =>
      'Encara no hi ha fotos reutilitzables.';

  @override
  String get kolabActionBarSaveDraft => 'DESA L\'ESBORRANY';

  @override
  String get kolabActionBarPublish => 'PUBLICA';

  @override
  String get kolabReviewSectionTitleDescription => 'Títol i descripció';

  @override
  String get kolabReviewSectionWhatYouNeed => 'El que necessites';

  @override
  String get kolabReviewSectionCommunityInfo => 'Informació de la comunitat';

  @override
  String get kolabReviewSectionOffersInReturn => 'Ofertes a canvi';

  @override
  String get kolabReviewSectionLocation => 'Ubicació';

  @override
  String get kolabReviewSectionCampaignVenue => 'Campanya i local';

  @override
  String get kolabReviewSectionMedia => 'Multimèdia';

  @override
  String get kolabReviewSectionWhatYouOffer => 'El que ofereixes';

  @override
  String get kolabReviewSectionSeekingCommunities => 'Comunitats que busques';

  @override
  String get kolabReviewSectionPastEvents => 'Esdeveniments anteriors';

  @override
  String get kolabReviewSectionProductInfo => 'Informació del producte';

  @override
  String get kolabReviewSectionAvailability => 'Disponibilitat';

  @override
  String get kolabReviewFieldTitle => 'Títol';

  @override
  String get kolabReviewFieldDescription => 'Descripció';

  @override
  String get kolabReviewFieldTypes => 'Tipus';

  @override
  String get kolabReviewFieldCommunitySize => 'Mida de la comunitat';

  @override
  String get kolabReviewFieldTypicalAttendance => 'Assistència habitual';

  @override
  String get kolabReviewFieldCity => 'Ciutat';

  @override
  String get kolabReviewFieldArea => 'Zona';

  @override
  String get kolabReviewFieldVenue => 'Local';

  @override
  String get kolabReviewFieldType => 'Tipus';

  @override
  String get kolabReviewFieldCapacity => 'Aforament';

  @override
  String get kolabReviewFieldAddress => 'Adreça';

  @override
  String get kolabReviewFieldPhotosVideos => 'Fotos / Vídeos';

  @override
  String get kolabReviewFieldEvents => 'Esdeveniments';

  @override
  String get kolabReviewFieldName => 'Nom';

  @override
  String get kolabReviewFieldSchedule => 'Horari';

  @override
  String get kolabReviewEmptyNeeds => 'No s\'han seleccionat necessitats';

  @override
  String get kolabReviewEmptyCommunityInfo =>
      'No s\'ha proporcionat informació de la comunitat';

  @override
  String get kolabReviewEmptyOffers => 'No s\'han seleccionat ofertes';

  @override
  String get kolabReviewEmptyOfferings => 'No hi ha cap oferiment indicat';

  @override
  String get kolabReviewEmptyCommunities => 'No s\'han seleccionat comunitats';

  @override
  String get kolabReviewNoMedia => 'No s\'ha afegit cap multimèdia';

  @override
  String get kolabReviewNoPastEvents =>
      'No s\'han afegit esdeveniments anteriors';

  @override
  String kolabReviewMediaCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elements',
      one: '1 element',
    );
    return '$_temp0';
  }

  @override
  String kolabReviewEventsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count esdeveniments',
      one: '1 esdeveniment',
    );
    return '$_temp0';
  }

  @override
  String kolabReviewAvailabilityFrom(String date) {
    return 'Des de: $date';
  }

  @override
  String kolabReviewAvailabilityTo(String date) {
    return 'Fins a: $date';
  }

  @override
  String get myKolabCardUntitled => 'Kolab sense títol';

  @override
  String get myKolabCardActionView => 'Veure';

  @override
  String get myKolabCardActionEdit => 'Edita';

  @override
  String get myKolabCardActionPublish => 'Publica';

  @override
  String get myKolabCardActionClose => 'Tanca';

  @override
  String get myKolabCardActionDelete => 'Elimina';

  @override
  String get myKolabCardStatusPublished => 'PUBLICAT';

  @override
  String get myKolabCardStatusClosed => 'TANCAT';

  @override
  String get myKolabCardStatusCompleted => 'COMPLETAT';

  @override
  String get myKolabCardStatusDraft => 'ESBORRANY';

  @override
  String get profileEventPickerTitle =>
      'Tria entre els esdeveniments del teu perfil';

  @override
  String profileEventPickerSubtitle(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count esdeveniments',
      one: '1 esdeveniment',
    );
    return 'Selecciona fins a $_temp0 per importar.';
  }

  @override
  String get profileEventPickerImport => 'Importa esdeveniments';

  @override
  String get notificationsScreenTitle => 'Notificacions';

  @override
  String get notificationsScreenMarkAllRead => 'Marca-ho tot com a llegit';

  @override
  String get notificationsScreenEmptyTitle => 'Encara no tens notificacions';

  @override
  String get notificationsScreenEmptyBody =>
      'Quan rebis missatges o actualitzacions de les teves sol·licituds, apareixeran aquí.';

  @override
  String get notificationBellTooltip => 'Notificacions';

  @override
  String get businessFinalEmailRequired => 'El correu electrònic és obligatori';

  @override
  String get businessFinalEmailInvalid =>
      'Introdueix un correu electrònic vàlid';

  @override
  String get businessFinalPasswordRequired => 'La contrasenya és obligatòria';

  @override
  String get businessFinalPasswordTooShort =>
      'La contrasenya ha de tenir com a mínim 8 caràcters';

  @override
  String get businessFinalConfirmPasswordRequired =>
      'Confirma la teva contrasenya';

  @override
  String get businessFinalPasswordsMismatch =>
      'Les contrasenyes no coincideixen';

  @override
  String get businessFinalSignupFailed =>
      'No s\'ha pogut completar el registre';

  @override
  String get businessFinalNoInternet =>
      'Sense connexió a internet. Comprova la teva xarxa.';

  @override
  String get businessFinalErrorCopied =>
      'Detalls de l\'error copiats al porta-retalls';

  @override
  String get businessFinalCopyDetails => 'Copia els detalls';

  @override
  String get businessFinalTitleAuthenticated =>
      'Finalitza l\'alta del teu negoci';

  @override
  String get businessFinalTitleNewAccount => 'Crea el teu compte';

  @override
  String get businessFinalSubtitleAuthenticated =>
      'Revisa les teves dades importades una última vegada i desa el perfil del teu negoci.';

  @override
  String get businessFinalSubtitleNewAccount =>
      'Introdueix el teu correu electrònic i contrasenya per completar el registre';

  @override
  String get businessFinalEdit => 'Edita';

  @override
  String get businessFinalEmailLabel => 'Correu electrònic';

  @override
  String get businessFinalEmailHint => 'el@teu.correu.com';

  @override
  String get businessFinalPasswordLabel => 'Contrasenya';

  @override
  String get businessFinalPasswordHint => 'Mín. 8 caràcters';

  @override
  String get businessFinalConfirmPasswordLabel => 'Confirma la contrasenya';

  @override
  String get businessFinalConfirmPasswordHint =>
      'Torna a escriure la teva contrasenya';

  @override
  String get businessFinalAuthenticatedInfo =>
      'El teu compte ja està creat. En prémer el botó de sota es desaran aquestes dades d\'alta al perfil del teu negoci.';

  @override
  String get businessFinalCompleteButton => 'COMPLETA L\'ALTA';

  @override
  String get businessFinalCreateAccountButton => 'CREA EL COMPTE';

  @override
  String get businessFinalTermsAuthenticated =>
      'Només desem les fotos de Google seleccionades quan la sol·licitud d\'alta es completa correctament.';

  @override
  String get businessFinalTermsNewAccount =>
      'En crear un compte, acceptes les nostres Condicions del servei i la Política de privacitat';

  @override
  String get businessStep2PhotoAccessDenied =>
      'Permet l\'accés a Fotos a Configuració per afegir imatges del local.';

  @override
  String get businessStep2PhotoLibraryError =>
      'No hem pogut obrir la teva galeria de fotos. Torna-ho a provar.';

  @override
  String get businessStep2IncompleteError =>
      'Completa les dades obligatòries del negoci, afegeix com a mínim una foto del local i introdueix l\'aforament abans de continuar.';

  @override
  String get businessStep2PhoneMustStartPlus =>
      'Ha de començar per + (p. ex. +34612345678)';

  @override
  String get businessStep2PhoneDigitsOnly =>
      'Fes servir el format E.164 només amb dígits';

  @override
  String get businessStep2PhoneTooShort =>
      'Introdueix com a mínim 9 dígits després del +';

  @override
  String get businessStep2PhoneTooLong => 'El número de telèfon és massa llarg';

  @override
  String get businessStep2Title => 'Revisa les dades del teu negoci';

  @override
  String get businessStep2Subtitle =>
      'Hem importat el que hem pogut de Google. Revisa-ho, indica l\'aforament i tria la galeria final del local abans d\'acabar.';

  @override
  String get businessStep2ImportedBanner =>
      'Importat de Google. Pots editar tots els camps abans de desar.';

  @override
  String get businessStep2AddLogo => 'Afegeix el logo (opcional)';

  @override
  String get businessStep2VenueAddressLabel => 'Adreça del local';

  @override
  String get businessStep2BusinessNameLabel => 'Nom del negoci';

  @override
  String get businessStep2BusinessNameHint =>
      'Introdueix el nom del teu negoci';

  @override
  String get businessStep2BusinessTypeLabel => 'Tipus de negoci';

  @override
  String get businessStep2BusinessTypeHint =>
      'Selecciona fins a 3 categories que descriguin el teu negoci.';

  @override
  String get businessStep2BusinessTypesLoadError =>
      'No s\'han pogut carregar els tipus de negoci';

  @override
  String get businessStep2VenueTypeLabel => 'Tipus de local';

  @override
  String get businessStep2CapacityLabel => 'Aforament';

  @override
  String get businessStep2CapacityHelper =>
      'Google no proporciona l\'aforament del local, així que l\'has d\'introduir manualment.';

  @override
  String get businessStep2CapacityHint => 'A quantes persones pots acollir?';

  @override
  String get businessStep2VenuePhotosLabel => 'Fotos del local';

  @override
  String get businessStep2AboutLabel => 'Sobre el teu negoci';

  @override
  String get businessStep2AboutHint => 'Explica què fa especial el teu negoci';

  @override
  String get businessStep2PhoneLabel => 'Número de telèfon';

  @override
  String get businessStep2InstagramLabel => 'Instagram';

  @override
  String get businessStep2WebsiteLabel => 'Lloc web';

  @override
  String get businessStep2ChangeVenue => 'Canvia el local';

  @override
  String get businessStep3PhotoAccessDenied =>
      'Permet l\'accés a Fotos a Configuració per afegir imatges del local.';

  @override
  String get businessStep3PhotoLibraryError =>
      'No hem pogut obrir la teva galeria de fotos. Torna-ho a provar.';

  @override
  String get businessStep3NoPhotosError =>
      'Afegeix com a mínim una foto del local per continuar';

  @override
  String get businessStep3Title => 'Afegeix fotos del local';

  @override
  String get businessStep3Subtitle =>
      'Aquestes formaran la teva galeria reutilitzable del local, així no les hauràs de pujar cada vegada que creïs un Kolab de local.';

  @override
  String get businessStep3AddPhoto => 'Afegeix foto';

  @override
  String get businessStep5PickAddressError =>
      'Tria l\'adreça del teu local entre els suggeriments';

  @override
  String get businessStep5ImportFallback =>
      'No hem pogut importar des de Google, omple-ho manualment.';

  @override
  String get businessStep5Title => 'Tria el teu local';

  @override
  String get businessStep5Subtitle =>
      'Cerca el local del teu negoci i importarem les dades que puguem de Google abans que les revisis.';

  @override
  String get businessStep5SearchHint => 'Cerca l\'adreça del local';

  @override
  String get businessStep5HintStartTyping =>
      'Comença a escriure l\'adreça del teu local per veure suggeriments.';

  @override
  String get businessStep5HintNoMatches =>
      'Encara no hi ha coincidències. Prova d\'afegir la ciutat a l\'adreça.';

  @override
  String get businessStep5SuggestionsError =>
      'No hem pogut carregar els suggeriments de locals ara mateix.';

  @override
  String get businessStep5Importing =>
      'Important la informació del teu negoci des de Google';

  @override
  String get businessStep5PreviewTitle => 'Fotos de Google';

  @override
  String get businessStep5PreviewSubtitle =>
      'Hem importat aquestes fotos per al teu local. Prem la X per treure les que no vulguis abans de continuar. Pots afegir-ne de pròpies més tard.';

  @override
  String get businessStep5NoPhotosLeft =>
      'No queden fotos. Continua per afegir-ne de pròpies o torna enrere per triar un altre local.';

  @override
  String get businessStep5SelectedAddress => 'Adreça seleccionada';

  @override
  String get communityFinalTitle => 'Crea el teu compte';

  @override
  String get communityFinalSubtitle =>
      'Introdueix el teu correu electrònic i contrasenya per completar el registre';

  @override
  String get communityFinalEdit => 'Edita';

  @override
  String get communityFinalEmailLabel => 'Correu electrònic';

  @override
  String get communityFinalEmailHint => 'el_teu@email.com';

  @override
  String get communityFinalPasswordLabel => 'Contrasenya';

  @override
  String get communityFinalPasswordHint => 'Mín. 8 caràcters';

  @override
  String get communityFinalConfirmPasswordLabel => 'Confirma la contrasenya';

  @override
  String get communityFinalConfirmPasswordHint =>
      'Torna a introduir la teva contrasenya';

  @override
  String get communityFinalEmailRequired =>
      'El correu electrònic és obligatori';

  @override
  String get communityFinalEmailInvalid =>
      'Introdueix un correu electrònic vàlid';

  @override
  String get communityFinalPasswordRequired => 'La contrasenya és obligatòria';

  @override
  String get communityFinalPasswordMinLength =>
      'La contrasenya ha de tenir com a mínim 8 caràcters';

  @override
  String get communityFinalConfirmPasswordRequired =>
      'Confirma la teva contrasenya';

  @override
  String get communityFinalPasswordsMismatch =>
      'Les contrasenyes no coincideixen';

  @override
  String get communityFinalNoInternet =>
      'Sense connexió a internet. Comprova la teva xarxa.';

  @override
  String get communityFinalCreateAccountButton => 'CREA EL COMPTE';

  @override
  String get communityFinalTermsNotice =>
      'En crear un compte, acceptes els nostres Termes del servei i la Política de privadesa';

  @override
  String get communityStep1Title => 'Explica\'ns sobre tu';

  @override
  String get communityStep1Subtitle => 'Creem el teu perfil';

  @override
  String get communityStep1DisplayNameLabel => 'Nom visible';

  @override
  String get communityStep1NameHint => 'El teu nom o usuari';

  @override
  String get communityStep1NameRequired => 'Introdueix el teu nom visible';

  @override
  String get communityStep2Title => 'Quin tipus de comunitat ets?';

  @override
  String get communityStep2Subtitle =>
      'Ajuda els negocis a entendre la teva comunitat';

  @override
  String get communityStep2TypeRequired => 'Selecciona un tipus de comunitat';

  @override
  String get communityStep2LoadError =>
      'No s\'han pogut carregar els tipus de comunitat';

  @override
  String get communityStep3Title => 'On et trobes?';

  @override
  String get communityStep3Subtitle => 'Troba oportunitats a la teva zona';

  @override
  String get communityStep3SearchHint => 'Cerca ciutats...';

  @override
  String get communityStep3PopularCities => 'Ciutats populars:';

  @override
  String get communityStep3NoCitiesFound => 'No s\'han trobat ciutats';

  @override
  String get communityStep3LoadError => 'No s\'han pogut carregar les ciutats';

  @override
  String get communityStep3CityRequired => 'Selecciona una ciutat';

  @override
  String get communityStep4Title => 'Completa el teu perfil';

  @override
  String get communityStep4Subtitle =>
      'Afegeix les teves xarxes socials (tot opcional)';

  @override
  String get communityStep4AboutLabel => 'Sobre tu / Biografia';

  @override
  String get communityStep4AboutHint => 'Explica\'ns sobre tu...';

  @override
  String get communityStep4UsernameHint => 'usuari';

  @override
  String get communityStep4WebsiteLabel => 'Lloc web';

  @override
  String get communityStep4WebsiteHint => 'www.exemple.com';

  @override
  String get photoUploadFileTooLarge => 'La imatge ha de pesar menys de 5MB';

  @override
  String get photoUploadSelectFailed => 'No s\'ha pogut seleccionar la imatge';

  @override
  String get photoUploadSelectFailedRetry =>
      'No s\'ha pogut seleccionar la imatge. Torna-ho a provar.';

  @override
  String get photoUploadPhotosAccessDenied =>
      'Permet l\'accés a Fotos a Configuració per pujar una imatge.';

  @override
  String get photoUploadCameraAccessDenied =>
      'Permet l\'accés a la Càmera a Configuració per fer una foto.';

  @override
  String get photoUploadChooseLibrary => 'Tria de la galeria';

  @override
  String get photoUploadTakePhoto => 'Fes una foto';

  @override
  String get photoUploadChangePhoto => 'Canvia la foto';

  @override
  String get photoUploadRemovePhoto => 'Elimina la foto';

  @override
  String get photoUploadTapToChange => 'Toca per canviar';

  @override
  String get venuePhotoAddPhoto => 'Afegeix foto';

  @override
  String get venuePhotoPoweredByGoogle => 'Amb tecnologia de Google';

  @override
  String get venuePhotoEmptyTitle => 'Afegeix fotos del local';

  @override
  String get venuePhotoEmptyDescription =>
      'Conserva les fotos importades de Google, puja les teves, elimina les que no vulguis i defineix aquí l\'ordre final.';

  @override
  String get venuePhotoSourceGoogle => 'Importada de Google';

  @override
  String get venuePhotoSourceSaved => 'Foto desada';

  @override
  String get venuePhotoSourceUpload => 'Pujada';

  @override
  String venuePhotoPositionLabel(num position, num total) {
    return 'Foto $position de $total';
  }

  @override
  String get venuePhotoMoveEarlier => 'Mou abans';

  @override
  String get venuePhotoMoveLater => 'Mou després';

  @override
  String get venuePhotoRemovePhoto => 'Elimina foto';

  @override
  String get venuePhotoCredits => 'Crèdits de la foto';

  @override
  String get venuePhotoCreditsSheetTitle => 'Crèdits de la foto de Google';

  @override
  String get profileReviewsTitle => 'Ressenyes';

  @override
  String profileReviewsTitleNamed(String name) {
    return 'Ressenyes de $name';
  }

  @override
  String get profileReviewsLoadError =>
      'No s\'han pogut carregar les ressenyes.';

  @override
  String get profileReviewsEmpty => 'Encara no hi ha ressenyes.';

  @override
  String get profileReviewsEmptyBody =>
      'Les ressenyes apareixeran aquí quan aquest perfil completi el seu primer Kolab.';

  @override
  String get profileReviewsLoadMore => 'Carregar-ne més';

  @override
  String get publicProfileReputationEmptyTitle => 'Encara no hi ha ressenyes';

  @override
  String get publicProfileReputationEmptyBody =>
      'Els Kolabs completats apareixeran aquí quan els socis deixin ressenyes.';

  @override
  String publicProfileReputationReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ressenyes',
      one: '1 ressenya',
    );
    return '$_temp0';
  }

  @override
  String publicProfileReputationPartnersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count socis',
      one: '1 soci',
    );
    return '$_temp0';
  }

  @override
  String reputationCompletedKolabsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count completats',
      one: '1 completat',
    );
    return '$_temp0';
  }

  @override
  String get publicProfileAbout => 'Sobre';

  @override
  String get publicProfileLoadError => 'No s\'ha pogut carregar el perfil';

  @override
  String get publicProfilePastKolabs => 'Kolabs anteriors';

  @override
  String get publicProfileNoPastKolabs => 'Encara no hi ha kolabs anteriors';

  @override
  String get publicProfileSocialLinks => 'Xarxes socials';

  @override
  String get publicProfileSaveForLater => 'Desar per a més tard';

  @override
  String get publicProfileSendKolabProposal => 'ENVIAR UNA PROPOSTA DE KOLAB';

  @override
  String get publicProfileRecentReviews => 'Ressenyes recents';

  @override
  String get publicProfileViewMore => 'Veure\'n més';

  @override
  String get memberProfilePoints => 'Punts';

  @override
  String get memberProfileEventsAttended => 'Esdeveniments assistits';

  @override
  String get memberProfileBadges => 'Insígnies';

  @override
  String get memberProfileNoBadges => 'Encara no hi ha insígnies';

  @override
  String get referralCodeCopied => 'Codi de convidança copiat';

  @override
  String get referralScreenTitle => 'PROGRAMA DE CONVIDANCES';

  @override
  String get referralScreenYourCode => 'EL TEU CODI DE CONVIDANÇA';

  @override
  String get referralScreenCopyCode => 'COPIA EL CODI';

  @override
  String get referralScreenShareCode => 'COMPARTEIX EL CODI';

  @override
  String get referralScreenHowItWorks => 'COM FUNCIONA';

  @override
  String get referralScreenStep1Title => 'Comparteix el teu codi únic';

  @override
  String get referralScreenStep1Desc =>
      'Envia el teu codi de convidança a amics i col·legues.';

  @override
  String get referralScreenStep2Title =>
      'Un negoci se subscriu fent servir el teu codi';

  @override
  String get referralScreenStep2Desc =>
      'Quan es registren i trien un pla, introdueixen el teu codi.';

  @override
  String get referralScreenStep3TitleBusiness =>
      'Guanyes 1 mes gratis de subscripció';

  @override
  String get referralScreenStep3TitleCommunity =>
      'Guanyes 50-100 punts (EUR 10-EUR 20)';

  @override
  String get referralScreenStep3DescBusiness =>
      'El teu proper cicle de facturació s\'amplia automàticament.';

  @override
  String get referralScreenStep3DescCommunity =>
      'Els punts s\'afegeixen al teu moneder i es poden retirar.';

  @override
  String get referralScreenRewardTiers => 'NIVELLS DE RECOMPENSA';

  @override
  String get referralScreenTierBusinessCondition => 'Cada convidança amb èxit';

  @override
  String get referralScreenTierBusinessReward => '1 mes gratis';

  @override
  String get referralScreenTier1MonthCondition =>
      'L\'usuari convidat es queda 1 mes';

  @override
  String get referralScreenTier1MonthReward => '50 pts (EUR 10)';

  @override
  String get referralScreenTier4MonthCondition =>
      'L\'usuari convidat es queda 4 mesos';

  @override
  String get referralScreenTier4MonthReward => '100 pts (EUR 20)';

  @override
  String get walletScreenTitle => 'XP I REPUTACIÓ';

  @override
  String get walletScreenWaysToEarn => 'MANERES DE GUANYAR XP';

  @override
  String get walletScreenBadges => 'INSÍGNIES';

  @override
  String get walletScreenCashReferral => 'CONVIDANÇA EN EFECTIU';

  @override
  String get walletScreenXpHistory => 'HISTORIAL DE XP';

  @override
  String get walletScreenXpPoints => 'PUNTS XP';

  @override
  String walletScreenTotalXp(num count) {
    return 'XP total: $count';
  }

  @override
  String walletScreenXpToNext(num count, String tier) {
    return '$count XP per a $tier';
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
  String get walletScreenMissionPostReview => 'Publica una ressenya';

  @override
  String get walletScreenMissionShareContent => 'Comparteix contingut (UGC)';

  @override
  String get walletScreenMissionReferBusiness => 'Convida un negoci';

  @override
  String get walletScreenNoBadges => 'No hi ha insígnies disponibles';

  @override
  String get walletScreenEarnCashTitle => 'Guanya 75 € en efectiu';

  @override
  String get walletScreenEarnCashSubtitle =>
      'Convida 3 negocis amb un pla de 4 mesos';

  @override
  String get walletScreenMilestoneReached =>
      'Objectiu assolit! Sol·licita la teva recompensa en efectiu.';

  @override
  String walletScreenMilestoneProgress(
    num conversions,
    num goal,
    num remaining,
  ) {
    return '$conversions / $goal negocis convidats · en falten $remaining';
  }

  @override
  String walletScreenShareMessage(String code) {
    return 'Uneix-te a Kolabing amb el meu codi: $code';
  }

  @override
  String get walletScreenShareLink => 'COMPARTEIX L\'ENLLAÇ';

  @override
  String get walletScreenRequestCash => 'SOL·LICITA 75 €';

  @override
  String get walletScreenNoXpActivity =>
      'Encara no hi ha activitat d\'XP. Completa un kolab!';

  @override
  String get walletScreenLoadMore => 'CARREGA\'N MÉS';

  @override
  String get withdrawalScreenTitle => 'RETIRA';

  @override
  String get withdrawalRequestFailed => 'La sol·licitud de retirada ha fallat';

  @override
  String get withdrawalIbanRequired => 'L\'IBAN és obligatori';

  @override
  String get withdrawalIbanInvalid =>
      'Introdueix un IBAN vàlid (15-34 caràcters)';

  @override
  String get withdrawalAccountHolderRequired =>
      'El nom del titular és obligatori';

  @override
  String get withdrawalSuccessTitle => 'Sol·licitud enviada';

  @override
  String get withdrawalSuccessMessage =>
      'La teva sol·licitud de retirada s\'ha enviat correctament. Es processarà en 5-7 dies laborables.';

  @override
  String get withdrawalBackToWallet => 'TORNA AL MONEDER';

  @override
  String get withdrawalAvailableLabel => 'Disponible per retirar';

  @override
  String get withdrawalIbanLabel => 'IBAN';

  @override
  String get withdrawalIbanHint => 'p. ex. DE89 3704 0044 0532 0130 00';

  @override
  String get withdrawalAccountHolderLabel => 'NOM DEL TITULAR';

  @override
  String get withdrawalAccountHolderHint => 'Nom complet del compte bancari';

  @override
  String withdrawalSubmitButton(String amount) {
    return 'RETIRA EUR $amount';
  }

  @override
  String get referralBannerEarnBySharing => 'GUANYA COMPARTINT';

  @override
  String get referralBannerTagline =>
      'Convida 3 negocis → guanya 75 € en efectiu';

  @override
  String get referralBannerShareButton => 'Comparteix el codi referral';

  @override
  String get referralBannerStepReferLabel => 'Convida';

  @override
  String get referralBannerStepReferValue => '3 negocis';

  @override
  String get referralBannerStepEarnLabel => 'Guanya';

  @override
  String get referralBannerStepEarnAmount => '75 €';

  @override
  String get referralBannerStepEarnSuffix => 'en efectiu';

  @override
  String get referralSheetYourCode => 'EL TEU CODI DE CONVIDANÇA';

  @override
  String get referralSheetInstructions =>
      'Demana als negocis que facin servir aquest codi en registrar-se.';

  @override
  String get referralSheetCopyCode => 'COPIA EL CODI';

  @override
  String get referralSheetShareCode => 'COMPARTEIX EL CODI';

  @override
  String get referralSheetShareUnavailable =>
      'No es pot compartir. Codi de convidança copiat.';

  @override
  String get referralSheetShareFailed =>
      'No s\'ha pogut obrir el menú de compartir. Codi de convidança copiat.';

  @override
  String get themeSelectorTitle => 'Aparença';

  @override
  String get themeSelectorSystemLabel => 'Sistema';

  @override
  String get themeSelectorSystemDescription =>
      'Segueix la configuració del dispositiu';

  @override
  String get themeSelectorLightLabel => 'Clar';

  @override
  String get themeSelectorLightDescription => 'Utilitza sempre el tema clar';

  @override
  String get themeSelectorDarkLabel => 'Fosc';

  @override
  String get themeSelectorDarkDescription => 'Utilitza sempre el tema fosc';

  @override
  String get referralCodeFieldLabel => 'Codi de convidat (opcional)';

  @override
  String get referralCodeFieldHint => 'Enganxa el codi de convidat';

  @override
  String get discoveryQuickFilterCity => 'Ciutat';

  @override
  String get discoveryQuickFilterKolabType => 'Tipus de Kolab';

  @override
  String get discoveryQuickFilterWhatTheyOffer => 'Què ofereixen';

  @override
  String get discoveryQuickFilterAvailability => 'Disponibilitat';

  @override
  String get discoveryQuickFilterNeed => 'Oferta';

  @override
  String get discoveryQuickFilterCommunityType => 'Tipus de comunitat';

  @override
  String get discoveryQuickFilterAudienceSize => 'Mida de l\'audiència';

  @override
  String get profileGallerySectionTitle => 'Galeria';

  @override
  String get profileGallerySectionAdd => 'Afegeix';

  @override
  String get profileGallerySectionUploading => 'Pujant foto...';

  @override
  String get profileGallerySheetTitle => 'Afegeix una foto a la galeria';

  @override
  String get profileGallerySheetTakePhoto => 'Fer una foto';

  @override
  String get profileGallerySheetTakePhotoSubtitle => 'Fes servir la càmera';

  @override
  String get profileGallerySheetChooseGallery => 'Tria de la galeria';

  @override
  String get profileGallerySheetChooseGallerySubtitle =>
      'Selecciona una foto existent';

  @override
  String get profileGalleryEmptyTitleBusiness => 'Mostra el teu local';

  @override
  String get profileGalleryEmptyTitleCommunity => 'Mostra la teva comunitat';

  @override
  String get profileGalleryEmptyBodyBusiness =>
      'Afegeix fotos del teu local perquè els socis de kolab vegin el teu espai abans d\'inscriure\'s.';

  @override
  String get profileGalleryEmptyBodyCommunity =>
      'Afegeix fotos dels teus esdeveniments perquè els nous socis de kolab entenguin la teva comunitat.';

  @override
  String get profileGalleryDeleteTitle => 'Elimina la foto';

  @override
  String get profileGalleryDeleteBody =>
      'Segur que vols eliminar aquesta foto?';

  @override
  String get profileGalleryDeleteConfirm => 'Elimina';

  @override
  String get exploreFilterSearchHint =>
      'Cerca per títol, descripció o creador...';

  @override
  String get exploreFilterCity => 'Ciutat';

  @override
  String get exploreFilterCityHint => 'Escriu una ciutat';

  @override
  String get exploreFilterAvailability => 'Disponibilitat';

  @override
  String get exploreFilterKolabType => 'Tipus de Kolab';

  @override
  String get exploreFilterWhatTheyOffer => 'Què ofereixen';

  @override
  String get exploreFilterVenueType => 'Tipus de local';

  @override
  String get exploreFilterProductType => 'Tipus de producte';

  @override
  String get exploreFilterExpectedDeliverables => 'Lliuraments esperats';

  @override
  String get exploreFilterMinCommunitySize =>
      'Mida mínima de comunitat requerida';

  @override
  String get exploreFilterNeed => 'Oferta';

  @override
  String get exploreFilterCommunityType => 'Tipus de comunitat';

  @override
  String get exploreFilterAudienceSize => 'Mida de l\'audiència';

  @override
  String get exploreFilterOffersInReturn => 'Ofereix a canvi';

  @override
  String get exploreFilterVenuePreference => 'Preferència de local';

  @override
  String get exploreFilterTitle => 'Cerca i filtra';

  @override
  String get exploreFilterClearAll => 'Esborra-ho tot';

  @override
  String get exploreFilterNoMatchingCities => 'No s\'han trobat ciutats';

  @override
  String get exploreFilterCitySuggestionsError =>
      'No s\'han pogut carregar els suggeriments de ciutats';

  @override
  String exploreFilterResultsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultats trobats',
      one: '1 resultat trobat',
      zero: 'Mostrant totes les oportunitats',
    );
    return '$_temp0';
  }

  @override
  String exploreSwipeCardMatch(num score) {
    return '$score% de coincidència';
  }

  @override
  String get exploreSwipeCardBusinessOffer => 'Oferta d\'empresa';

  @override
  String get exploreSwipeCardCommunityRequest => 'Sol·licitud de comunitat';

  @override
  String exploreSwipeCardKolabsCount(num count) {
    return '$count Kolabs';
  }

  @override
  String exploreSwipeCardPreviousKolabs(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kolabs anteriors',
      one: '1 Kolab anterior',
    );
    return '$_temp0';
  }

  @override
  String get exploreSwipeCardViewDetails => 'Veure detalls';

  @override
  String get exploreDetailUnknownCreator => 'Desconegut';

  @override
  String get exploreDetailSubscribeToReveal =>
      'Subscriu-te per veure aquesta comunitat';

  @override
  String get exploreDetailCreatorBadge => 'Creador';

  @override
  String get exploreDetailLookingFor => 'Què estan buscant';

  @override
  String get exploreDetailWhatTheyOffer => 'Què ofereixen';

  @override
  String get exploreDetailCommunitySize => 'Mida de la comunitat';

  @override
  String exploreDetailScaleCommunity(num count) {
    return '$count membres';
  }

  @override
  String exploreDetailScaleExpected(num count) {
    return '~$count assistents previstos';
  }

  @override
  String get exploreDetailWhatsOffered => 'Què s\'ofereix';

  @override
  String get exploreDetailAvailableDays => 'Dies disponibles';

  @override
  String get exploreDetailUnlockToApply => 'DESBLOQUEJA PER INSCRIURE\'T';

  @override
  String get exploreDetailApplyNow => 'Inscriu-t\'hi ara';

  @override
  String get exploreDetailViewCreatorProfile => 'Veure el perfil del creador';

  @override
  String get exploreDetailPastEventPhotos => 'Fotos d\'esdeveniments passats';

  @override
  String get exploreDetailRecentMoments =>
      'Moments recents d\'aquesta comunitat';

  @override
  String get subscriptionScreenTitle => 'Subscripció';

  @override
  String get subscriptionScreenAppleError =>
      'No s\'ha pogut iniciar la compra a l\'App Store';

  @override
  String get subscriptionScreenCheckoutError =>
      'No s\'ha pogut crear la sessió de pagament';

  @override
  String get subscriptionReferralCodeApplied => 'Codi de referit aplicat.';

  @override
  String get subscriptionReactivateSuccess =>
      'Subscripció reactivada correctament';

  @override
  String get subscriptionCancelScheduledToast =>
      'La subscripció es cancel·larà al final del període de facturació';

  @override
  String get subscriptionCancelDialogTitle => 'Cancel·lar subscripció';

  @override
  String get subscriptionCancelDialogBody =>
      'La teva subscripció es mantindrà activa fins al final del període de facturació actual. Pots tornar a subscriure\'t en qualsevol moment.\n\nSegur que vols cancel·lar?';

  @override
  String get subscriptionKeepButton => 'Mantenir subscripció';

  @override
  String get subscriptionCancelButton => 'Cancel·lar subscripció';

  @override
  String get subscriptionStatusPremiumTitle => 'Negoci Premium';

  @override
  String get subscriptionStatusActiveSubtitle =>
      'La teva subscripció està activa';

  @override
  String get subscriptionStatusEndingTitle => 'Subscripció finalitzant';

  @override
  String get subscriptionStatusEndingSubtitle =>
      'Activa fins al final del període de facturació';

  @override
  String get subscriptionStatusPastDueTitle => 'Pagament fallit';

  @override
  String get subscriptionStatusPastDueSubtitle =>
      'Actualitza el teu mètode de pagament';

  @override
  String get subscriptionStatusNoPlanTitle => 'Sense pla actiu';

  @override
  String get subscriptionStatusNoPlanSubtitle =>
      'Subscriu-te per publicar oportunitats';

  @override
  String get subscriptionBenefitsTitle => 'Beneficis Premium';

  @override
  String get subscriptionBenefitPublishTitle => 'Publica oportunitats';

  @override
  String get subscriptionBenefitPublishDesc =>
      'Crea i publica ofertes de kolab';

  @override
  String get subscriptionBenefitConnectTitle => 'Connecta amb comunitats';

  @override
  String get subscriptionBenefitConnectDesc =>
      'Arriba a comunitats i creadors locals';

  @override
  String get subscriptionBenefitApplicationsTitle => 'Rep sol·licituds';

  @override
  String get subscriptionBenefitApplicationsDesc =>
      'Rep sol·licituds de comunitats interessades';

  @override
  String get subscriptionBenefitTrackTitle => 'Mesura el rendiment';

  @override
  String get subscriptionBenefitTrackDesc =>
      'Monitoritza les mètriques dels teus kolabs';

  @override
  String get subscriptionPerMonthUnit => 'EUR/mes';

  @override
  String get subscriptionPlanDetailsTitle => 'Detalls del pla';

  @override
  String get subscriptionDetailPlanLabel => 'Pla';

  @override
  String get subscriptionDetailPriceLabel => 'Preu';

  @override
  String get subscriptionPriceMonthly => '49.99 EUR/mes';

  @override
  String get subscriptionDetailCurrentPeriodLabel => 'Període actual';

  @override
  String get subscriptionDetailRenewsOnLabel => 'Es renova el';

  @override
  String get subscriptionDetailDaysRemainingLabel => 'Dies restants';

  @override
  String subscriptionDaysValue(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dies',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String get subscriptionPastDueWarningBody =>
      'El teu darrer pagament ha fallat. Actualitza el teu mètode de pagament per continuar publicant oportunitats.';

  @override
  String get subscriptionCancelPendingTitle => 'Cancel·lació programada';

  @override
  String subscriptionCancelPendingBody(String endDate) {
    return 'La teva subscripció està activa fins al $endDate. Després d\'aquesta data, no podràs publicar noves oportunitats.';
  }

  @override
  String get subscriptionEndOfBillingPeriod =>
      'el final del període de facturació';

  @override
  String get subscriptionReactivateButton => 'REACTIVAR SUBSCRIPCIÓ';

  @override
  String get subscriptionSubscribeButton => 'SUBSCRIURE\'S';

  @override
  String get subscriptionSubscribePricedButton =>
      'SUBSCRIURE\'S PER 49.99 EUR/MES';

  @override
  String get subscriptionUpdatePaymentButton =>
      'ACTUALITZAR MÈTODE DE PAGAMENT';

  @override
  String get subscriptionManageBillingButton => 'GESTIONAR FACTURACIÓ';

  @override
  String get subscriptionLoadingApplePrice =>
      'Carregant preu de l\'App Store...';

  @override
  String get subscriptionUnavailable => 'Subscripció no disponible';

  @override
  String subscriptionPricePerMonth(String price) {
    return '$price/mes';
  }

  @override
  String get subscriptionPaywallAppleError =>
      'No s\'ha pogut iniciar la compra a l\'App Store';

  @override
  String get subscriptionPaywallCheckoutError =>
      'No s\'ha pogut crear la sessió de pagament';

  @override
  String get subscriptionPaywallTitle => 'Millora a Premium';

  @override
  String get subscriptionPaywallDescription =>
      'Has utilitzat la teva sol·licitud de kolab gratuïta. Subscriu-te per crear sol·licituds il·limitades i connectar amb més comunitats.';

  @override
  String get subscriptionPaywallBenefitUnlimited =>
      'Publica sol·licituds de kolab il·limitades';

  @override
  String get subscriptionPaywallBenefitConnect =>
      'Connecta amb comunitats locals';

  @override
  String get subscriptionPaywallBenefitApplications =>
      'Rep i gestiona sol·licituds';

  @override
  String get subscriptionPaywallPerMonth => '/ mes';

  @override
  String get subscriptionPlanMonthlyLabel => 'Mensual';

  @override
  String get subscriptionPlanThreeMonthsLabel => '3 mesos';

  @override
  String get subscriptionPlanBestValueBadge => 'MILLOR PREU';

  @override
  String get subscriptionPlanPer3Months => '/ 3 mesos';

  @override
  String subscriptionPlanPerMonthEq(String price) {
    return '≈ $price/mes';
  }

  @override
  String subscriptionPlanSavePercent(int percent) {
    return 'Estalvia $percent%';
  }

  @override
  String get subscriptionPaywallSubscribeButton => 'SUBSCRIURE\'S ARA';

  @override
  String get subscriptionPaywallNotNowButton => 'Ara no';

  @override
  String get subscriptionRestorePurchasesButton => 'Restaurar compres';

  @override
  String get pastEventsStepHeader => 'KOLABS ANTERIORS (OPCIONAL)';

  @override
  String referralShareMessage(String code) {
    return 'Comparteix Kolabing i guanya: fes servir el meu codi d\'invitació $code en registrar el teu negoci.';
  }

  @override
  String get dashboardBusinessTitle => 'Panell de negoci';

  @override
  String get dashboardCommunityTitle => 'Panell de comunitat';

  @override
  String dashboardWelcomeBack(String name) {
    return 'Hola de nou, $name';
  }

  @override
  String get dashboardErrorLoad =>
      'No s\'han pogut carregar les dades del tauler';

  @override
  String get dashboardStatPublished => 'Publicades';

  @override
  String get dashboardStatPendingApplications => 'Sol·licituds pendents';

  @override
  String get dashboardStatActiveKolabs => 'Kolabs actius';

  @override
  String get dashboardStatCompleted => 'Completats';

  @override
  String get dashboardStatPending => 'Pendents';

  @override
  String get dashboardStatAccepted => 'Acceptades';

  @override
  String get dashboardCreateKolabRequest => 'CREAR SOL·LICITUD DE KOLAB';

  @override
  String get dashboardFindAKolab => 'Trobar un Kolab';

  @override
  String get dashboardMyApplications => 'Les meves sol·licituds';

  @override
  String get dashboardUpcomingKolabs => 'PROPERS KOLABS';

  @override
  String get dashboardMonthlyGoalTitle => 'OBJECTIU D\'AQUEST MES';

  @override
  String dashboardMonthlyGoalProgress(int completed, int goal) {
    return '$completed de $goal Kolabs';
  }

  @override
  String get dashboardNoUpcomingKolabs => 'Encara no hi ha kolabs propers';

  @override
  String get dashboardDefaultBusinessName => 'Negoci';

  @override
  String get dashboardDefaultCommunityName => 'Comunitat';

  @override
  String get dashboardPositioningTitle =>
      'Omple el teu negoci amb les persones adequades.';

  @override
  String get dashboardPositioningSubtitle =>
      'Crea experiències que converteixin les comunitats en visites, contingut i fidelitat.';

  @override
  String get dashboardActivityPillLabel => 'ACTIVITAT DEL NEGOCI';

  @override
  String get dashboardLiveOffersLabel => 'OFERTES ACTIVES';

  @override
  String get dashboardNewAppsLabel => 'NOVES SOL·LIC.';

  @override
  String get dashboardActiveStatLabel => 'ACTIUS';

  @override
  String get dashboardCompletedStatLabel => 'COMPLETATS';

  @override
  String get dashboardGrowSectionTitle => 'FES CRÉIXER EL TEU NEGOCI';

  @override
  String get dashboardGrowCreateTitle => 'Crear un Kolab';

  @override
  String get dashboardGrowCreateSubtitle =>
      'Publica una nova oferta perquè les comunitats hi apliquin';

  @override
  String get dashboardGrowReviewTitle => 'Revisar sol·licituds';

  @override
  String dashboardGrowReviewSubtitlePending(int count) {
    return '$count pendents de revisió';
  }

  @override
  String get dashboardGrowReviewSubtitleEmpty =>
      'No hi ha sol·licituds pendents';

  @override
  String get dashboardGrowFindSubtitle => 'Explora sol·licituds de comunitats';

  @override
  String get dashboardGrowViewKolabsTitle => 'Veure els teus Kolabs';

  @override
  String dashboardGrowViewKolabsSubtitle(int active, int completed) {
    return '$active actius · $completed completats';
  }

  @override
  String get dashboardEmptyUpcomingSubtitle =>
      'Crea un Kolab per començar a omplir el teu calendari';

  @override
  String get dashboardHeroCreateKolabButton => '+ CREAR UN KOLAB';

  @override
  String get eventHubOpenChat => 'Obrir xat de l\'esdeveniment';

  @override
  String get eventHubAttendeesTitle => 'Assistents';

  @override
  String get eventHubWaitlistTitle => 'Llista d\'espera';

  @override
  String get eventHubNoAttendees => 'Encara no s\'hi ha apuntat ningú.';

  @override
  String eventHubGoingCount(num count) {
    return '$count hi aniran';
  }

  @override
  String eventHubWaitlistCount(num count) {
    return '$count a la llista d\'espera';
  }

  @override
  String eventHubCapacity(num count) {
    return 'aforament $count';
  }

  @override
  String eventHubSpotsLeft(num count) {
    return 'queden $count plaça/ces';
  }

  @override
  String get eventHubUnlimited => 'Il·limitat';

  @override
  String get eventHubImGoing => 'Hi aniré';

  @override
  String get eventHubGoingTapToLeave => 'Hi aniràs ✓  ·  toca per sortir';

  @override
  String get eventHubJoinWaitlist => 'Unir-se a la llista d\'espera';

  @override
  String get eventHubOnWaitlistTapToLeave =>
      'A la llista d\'espera  ·  toca per sortir';

  @override
  String eventHubWaitlistPosition(num position) {
    return 'Ets el número $position a la llista d\'espera';
  }

  @override
  String get eventDetailViewCommunity => 'Veure comunitat';

  @override
  String get eventHubEdit => 'Edita';

  @override
  String get commonDelete => 'Elimina';

  @override
  String get eventHubDelete => 'Elimina l\'esdeveniment';

  @override
  String get eventHubScanCheckIns => 'Escaneja registres';

  @override
  String get eventHubDeleteConfirmTitle => 'Vols eliminar aquest esdeveniment?';

  @override
  String eventHubDeleteConfirmBody(String name) {
    return '\"$name\": s\'avisarà qui hi assisteixi o estigui en llista d\'espera que s\'ha cancel·lat.';
  }

  @override
  String get eventHubDeleteScopeThis => 'Només aquest esdeveniment';

  @override
  String get eventHubDeleteScopeFollowing =>
      'Aquest i els esdeveniments següents';

  @override
  String get eventHubDeleteScopeSeries => 'Tota la sèrie';

  @override
  String get eventHubDeleted => 'Esdeveniment eliminat';

  @override
  String get eventHubExtendSeries => 'Amplia la sèrie (+3 mesos)';

  @override
  String eventHubExtended(int count) {
    return 'Sèrie ampliada: $count dates noves';
  }

  @override
  String get eventHubExtendedNone => 'No hi ha dates noves per afegir';

  @override
  String get eventHubAddPhotos => 'Afegir fotos';

  @override
  String get eventFormNewTitle => 'Nou esdeveniment';

  @override
  String get eventFormEditTitle => 'Edita l\'esdeveniment';

  @override
  String get eventFormSave => 'Desa';

  @override
  String get eventFormPublish => 'Publica l\'esdeveniment';

  @override
  String get eventFormRepeatLabel => 'Repeteix';

  @override
  String get eventFormRepeatNone => 'No es repeteix';

  @override
  String get eventFormRepeatWeekly => 'Setmanal';

  @override
  String get eventFormRepeatBiweekly => 'Cada 2 setmanes';

  @override
  String get eventFormRepeatMonthly => 'Mensual';

  @override
  String get eventFormRepeatEnds => 'Acaba';

  @override
  String get eventFormRepeatNever => 'Mai';

  @override
  String get eventFormRepeatAfter => 'Després de';

  @override
  String get eventFormRepeatEvents => 'esdeveniments';

  @override
  String get eventFormRepeatOnDate => 'En una data';

  @override
  String get eventFormRepeatChatLabel => 'Xat de la sèrie';

  @override
  String get eventFormRepeatChatPerEvent => 'Un xat per esdeveniment';

  @override
  String get eventFormRepeatChatShared => 'Un xat compartit per a la sèrie';

  @override
  String get eventFormPublishSeries => 'Publica la sèrie';

  @override
  String get eventFormApplyTo => 'Aplica els canvis a';

  @override
  String get eventFormErrWeekday => 'Tria almenys un dia';

  @override
  String get eventFormErrEndsCount => 'Indica quants esdeveniments';

  @override
  String get eventFormErrEndsOn => 'Tria una data posterior a l\'inici';

  @override
  String get eventFormNameLabel => 'Nom';

  @override
  String get eventFormNameHint => 'Cursa 10K del dissabte';

  @override
  String get eventFormStartsLabel => 'Comença';

  @override
  String get eventFormEndsLabel => 'Acaba (opcional)';

  @override
  String get eventFormPickStart => 'Tria data i hora d\'inici';

  @override
  String get eventFormPickEnd => 'Tria data i hora de fi';

  @override
  String get eventFormLocationLabel => 'Ubicació (opcional)';

  @override
  String get eventFormLocationHint => 'Parc de la Ciutadella';

  @override
  String get eventFormCityLabel => 'Ciutat (opcional)';

  @override
  String get eventFormCityHint => 'Selecciona una ciutat';

  @override
  String get eventFormLocationSearchHint => 'Cerca el local o l\'adreça';

  @override
  String get eventFormLocationStartTyping =>
      'Comença a escriure el local o l\'adreça per veure suggeriments.';

  @override
  String get eventFormLocationNoMatches =>
      'Encara no hi ha coincidències. Prova d\'afegir la ciutat a l\'adreça.';

  @override
  String get eventFormLocationError =>
      'Ara mateix no hem pogut carregar els suggeriments d\'ubicació.';

  @override
  String eventFormCityDetected(String city) {
    return 'Ciutat: $city';
  }

  @override
  String get eventFormCityNotDetected =>
      'No s\'ha detectat cap ciutat per a aquest lloc. L\'esdeveniment no apareixerà al descobriment per ciutat.';

  @override
  String get eventFormCapacityLabel => 'Aforament (opcional)';

  @override
  String get eventFormLimit => 'Límit';

  @override
  String get eventFormWhoCanJoin => 'Qui s\'hi pot unir';

  @override
  String get eventFormAllMembers => 'Tots els membres';

  @override
  String get eventFormSelectedTiers => 'Nivells seleccionats';

  @override
  String get eventFormVisibilityLabel => 'Visibilitat';

  @override
  String get eventFormVisibilityPublic => 'Pública';

  @override
  String get eventFormVisibilityPublicHint =>
      'Apareix al descobriment de la ciutat: qualsevol la pot trobar.';

  @override
  String get eventFormVisibilityMembers => 'Membres';

  @override
  String get eventFormVisibilityMembersHint =>
      'Només els membres de la teva comunitat la poden veure.';

  @override
  String get eventFormVisibilityTier => 'Nivell específic';

  @override
  String get eventFormVisibilityTierHint =>
      'Només els membres dels nivells seleccionats la poden veure.';

  @override
  String get eventFormPhotos => 'Fotos';

  @override
  String get eventFormAddFromGallery => 'Afegir des de la galeria';

  @override
  String get eventFormPhotosAfterCreate =>
      'Les fotos es poden afegir un cop creat l\'esdeveniment.';

  @override
  String get eventFormErrName =>
      'El nom de l\'esdeveniment necessita almenys 3 caràcters.';

  @override
  String get eventFormErrStart => 'Tria una data i hora d\'inici.';

  @override
  String get eventFormErrStartFuture => 'L\'inici ha de ser en el futur.';

  @override
  String get eventFormErrEndAfterStart =>
      'El final ha de ser posterior a l\'inici.';

  @override
  String get eventFormErrCapacity =>
      'Introdueix un aforament vàlid o desactiva el límit.';

  @override
  String get eventFormErrTier =>
      'Selecciona almenys un nivell per a aquest esdeveniment.';

  @override
  String get eventFormPhotosUploaded => 'Fotos pujades.';

  @override
  String eventPhotosMaxPerAdd(int max) {
    return 'Pots afegir fins a $max fotos alhora.';
  }

  @override
  String eventPhotosTotalCapReached(int count, int max) {
    return 'Aquesta galeria ja té $count de $max fotos.';
  }

  @override
  String eventPhotosTotalCapPartial(int allowed, int max) {
    return 'Només es poden afegir $allowed fotos més (màxim $max en total).';
  }

  @override
  String get eventFormAddFromCommunity => 'Tria de la galeria de la comunitat';

  @override
  String get eventFormCommunityGalleryTitle => 'Galeria de la comunitat';

  @override
  String get eventFormCommunityGalleryEmpty =>
      'Encara no hi ha fotos a la galeria de la comunitat.';

  @override
  String eventFormCommunityGalleryAdd(int count) {
    return 'Afegeix $count fotos';
  }

  @override
  String get communityShareInvite => 'Comparteix invitació';

  @override
  String communityShareInviteMessage(String name, String url) {
    return 'Uneix-te a $name a Kolabing: $url';
  }

  @override
  String get communityShareInviteCopied => 'Enllaç d\'invitació copiat.';

  @override
  String get notifSettingsTitle => 'Notificacions';

  @override
  String get notifSettingsMessages => 'Missatges';

  @override
  String get notifSettingsMessagesSubtitle =>
      'Nous missatges de xat a les teves comunitats i esdeveniments';

  @override
  String get notifSettingsApplications => 'Noves sol·licituds';

  @override
  String get notifSettingsApplicationsSubtitle =>
      'Quan algú es postula al teu Kolab';

  @override
  String get notifSettingsCollaborations =>
      'Actualitzacions de col·laboracions';

  @override
  String get notifSettingsCollaborationsSubtitle =>
      'Canvis d\'estat als teus Kolabs';

  @override
  String get notifSettingsMarketing => 'Consells i novetats';

  @override
  String get notifSettingsMarketingSubtitle =>
      'Consells de producte i notícies ocasionals';

  @override
  String get notifSettingsSaveError =>
      'No s\'ha pogut desar la teva preferència. Torna-ho a provar.';

  @override
  String get chatsTitle => 'Xats';

  @override
  String get chatInboxTooltip => 'Xats';

  @override
  String get chatThreadFallbackTitle => 'Xat';

  @override
  String get chatSenderFallback => 'Membre';

  @override
  String get chatThreadTapToOpen => 'Toca per obrir';

  @override
  String get chatThreadNoMessagesYet => 'Encara no hi ha missatges';

  @override
  String get chatInboxEmptyTitle => 'Encara no hi ha xats';

  @override
  String get chatInboxEmptyBody =>
      'Les converses apareixeran aquí quan s\'iniciï un xat d\'un Kolab, una comunitat o un esdeveniment.';

  @override
  String get chatSectionMain => 'Principal';

  @override
  String get chatSectionCommunityChats => 'Xats de la comunitat';

  @override
  String get chatSectionEvents => 'Esdeveniments';

  @override
  String get chatSectionKolabs => 'Kolabs';

  @override
  String get chatComposerHint => 'Missatge';

  @override
  String get chatThreadEmptyMessage => 'Encara no hi ha missatges. Saluda 👋';

  @override
  String get chatManageNewChatTitle => 'Nou xat';

  @override
  String get chatManageRenameTitle => 'Reanomena el xat';

  @override
  String get chatManageNameLabel => 'Nom del xat';

  @override
  String get chatManageNameHint => 'p. ex. Directius, Socials, Filantropia';

  @override
  String get chatManageCreate => 'Crea';

  @override
  String get chatManageRename => 'Reanomena';

  @override
  String get chatManageDelete => 'Elimina';

  @override
  String get chatManageCreateChat => 'Crea un xat';

  @override
  String chatManageChatCreated(String name) {
    return 'S\'ha creat \"$name\"';
  }

  @override
  String get chatManageChatRenamed => 'S\'ha reanomenat el xat';

  @override
  String get chatManageChatDeleted => 'S\'ha eliminat el xat';

  @override
  String chatManageChatLimit(int count) {
    return 'Has arribat al límit de $count xats personalitzats.';
  }

  @override
  String get chatManageDeleteTitle => 'Vols eliminar aquest xat?';

  @override
  String chatManageDeleteBody(String name) {
    return 'Els membres perdran l\'accés a \"$name\". El pots recuperar més tard si canvies d\'opinió.';
  }

  @override
  String get chatManageWhichCommunity => 'Quina comunitat?';

  @override
  String get chatJoinSectionTitle => 'Xats als quals et pots unir';

  @override
  String get chatJoinAction => 'Uneix-t\'hi';

  @override
  String chatJoinedSnack(String name) {
    return 'T\'has unit a \"$name\"';
  }

  @override
  String get chatThreadOpenEvent => 'Obre l\'esdeveniment';

  @override
  String get chatMembersTitle => 'Membres';

  @override
  String get chatMembersEmpty => 'Encara no hi ha membres per administrar.';

  @override
  String get chatMemberRemove => 'Treu';

  @override
  String chatMemberRemoveTitle(String name) {
    return 'Vols treure $name?';
  }

  @override
  String get chatMemberRemoveBody =>
      'Perdrà l\'accés a aquest xat i no s\'hi podrà tornar a unir.';

  @override
  String chatMemberRemoved(String name) {
    return 'S\'ha tret $name';
  }

  @override
  String get chatThreadManageMembers => 'Administra els membres';

  @override
  String get communityDetailTabChats => 'Xats';

  @override
  String get communityDetailTabEvents => 'Esdeveniments';

  @override
  String get communityDetailTabMembers => 'Membres';

  @override
  String get communityDetailTabDetails => 'Detalls';

  @override
  String communityDetailTypeAndMembers(String type, int count) {
    return '$type · $count membres';
  }

  @override
  String communityDetailMembersCount(int count) {
    return '$count membres';
  }

  @override
  String get communityDetailChatsLoadError =>
      'No s\'han pogut carregar els xats';

  @override
  String get communityDetailNoChatsTitle => 'Encara no hi ha xats';

  @override
  String get communityDetailNoChatsBody =>
      'Les converses d\'aquesta comunitat apareixeran aquí.';

  @override
  String get communityDetailNoEventsTitle => 'No hi ha esdeveniments propers';

  @override
  String get communityDetailNoEventsBody =>
      'Els esdeveniments creats per a aquesta comunitat apareixeran aquí.';

  @override
  String get communityDetailEventLockedSubtitle =>
      'Bloquejat — per a un altre nivell de membres';

  @override
  String get communityDetailEventLockedSnack =>
      'Aquest esdeveniment és per a un altre nivell de membres.';

  @override
  String get communityDetailLeaderboardButton => 'Classificació del capítol';

  @override
  String get communityDetailAboutLabel => 'Sobre';

  @override
  String get communityDetailMembershipLabel => 'La teva afiliació';

  @override
  String get communityDetailRowTier => 'Nivell';

  @override
  String get communityDetailRowType => 'Tipus';

  @override
  String get communityDetailRowMembers => 'Membres';

  @override
  String get communityDetailRowRole => 'Rol';

  @override
  String get communityDetailRoleCanManage => 'Pot gestionar';

  @override
  String get communityDetailTierFallback => 'Membre';

  @override
  String get communityDetailGalleryLabel => 'Galeria i esdeveniments passats';

  @override
  String get communityDetailGalleryBody =>
      'Les fotos i els esdeveniments passats seran aquí quan es llanci el cicle de vida d\'esdeveniments (Fase 3).';

  @override
  String get communityDetailGalleryEmpty =>
      'Encara no hi ha esdeveniments passats per mostrar.';

  @override
  String get myCommunitiesNoTier => 'Encara sense nivell';

  @override
  String get myCommunitiesAdminBadge => 'ADMIN';

  @override
  String get myCommunitiesEmptyTitle => 'Encara no pertanys a cap comunitat';

  @override
  String get myCommunitiesEmptyBody =>
      'Uneix-te a una comunitat per guanyar-te el teu lloc als seus nivells i veure esdeveniments i avantatges exclusius per a membres.';

  @override
  String get communityHubEmptyTitle => 'Crea la teva comunitat';

  @override
  String get communityHubEmptyBody =>
      'Crea una comunitat per formar una llista de membres i configurar els teus propis nivells. La teva primera comunitat és gratuïta.';

  @override
  String get communityHubCreateCommunity => 'CREA COMUNITAT';

  @override
  String get communityHubSectionTiers => 'Nivells';

  @override
  String get communityHubSectionMembers => 'Membres';

  @override
  String get communityHubSectionEvents => 'Esdeveniments';

  @override
  String get communityHubSectionChats => 'Xats';

  @override
  String communityHubTypeAndMembers(String type, int count) {
    return '$type  ·  $count membres';
  }

  @override
  String get communityHubNoEvents => 'Encara no hi ha esdeveniments propers.';

  @override
  String get communityHubCreateEvent => 'Crea esdeveniment';

  @override
  String get communityHubNewChatTitle => 'Nou xat';

  @override
  String get communityHubChatNameLabel => 'Nom del xat';

  @override
  String get communityHubChatNameHint => 'p. ex. Junta, Social, Filantropia';

  @override
  String get communityHubCreate => 'Crea';

  @override
  String communityHubChatCreated(String name) {
    return '\"$name\" creat';
  }

  @override
  String communityHubChatLimit(int count) {
    return 'Pots tenir fins a $count xats';
  }

  @override
  String get communityHubAccess => 'Accés';

  @override
  String get chatManageAccess => 'Qui hi pot accedir';

  @override
  String get chatManageMembers => 'Membres';

  @override
  String get chatBlock => 'Bloqueja';

  @override
  String get chatUnblock => 'Desbloqueja';

  @override
  String get chatBlockedTag => 'Bloquejat';

  @override
  String get chatRenameHint => 'Nom del xat';

  @override
  String get chatRenamed => 'Xat reanomenat';

  @override
  String get chatDeleteTitle => 'Vols eliminar aquest xat?';

  @override
  String chatDeleteBody(String name) {
    return 'S\'eliminaran tots els missatges de \"$name\".';
  }

  @override
  String get chatDeleted => 'Xat eliminat';

  @override
  String get communityHubAccessNoTiers => 'Cap nivell';

  @override
  String get communityHubAccessAllTiers => 'Tots els nivells';

  @override
  String get communityHubAccessOneTier => '1 nivell';

  @override
  String communityHubAccessTierCount(int count) {
    return '$count nivells';
  }

  @override
  String get communityHubCreateTiersFirst =>
      'Crea primer nivells de membres per restringir els xats.';

  @override
  String communityHubAccessDialogTitle(String name) {
    return 'Qui pot accedir a \"$name\"?';
  }

  @override
  String get communityHubAccessDialogChat => 'xat';

  @override
  String get communityHubAccessDialogBody =>
      'Tu i els teus gestors sempre hi teniu accés. Tria quins nivells de membres poden obrir aquest xat.';

  @override
  String get communityHubChatAccessUpdated => 'Accés al xat actualitzat';

  @override
  String communityHubNoChatsHint(int count) {
    return 'Encara no hi ha xats. El teu xat principal i fins a $count xats personalitzats apareixeran aquí.';
  }

  @override
  String get communityHubCreateChat => 'Crea xat';

  @override
  String communityHubChatLimitReached(int count) {
    return 'S\'ha assolit el límit de xats ($count xats personalitzats).';
  }

  @override
  String get communityHubChatMain => 'Principal';

  @override
  String get communityHubChatFallback => 'Xat';

  @override
  String get communityHubChipMain => 'PRINCIPAL';

  @override
  String communityHubTierDetail(String rule, int threshold, String unit) {
    return '$rule · $threshold $unit';
  }

  @override
  String get communityHubChipDefault => 'PREDETERMINAT';

  @override
  String communityHubTierRank(int rank) {
    return '#$rank';
  }

  @override
  String get communityHubNoTiersHint =>
      'Encara no hi ha nivells. Afegeix nivells per donar als membres una escala d\'estatus.';

  @override
  String get communityHubAddTier => 'Afegeix nivell';

  @override
  String get communityHubNoMembersHint =>
      'Encara no hi ha membres. Convida persones o comparteix el teu enllaç d\'invitació.';

  @override
  String get communityHubManageMembers => 'Gestiona membres';

  @override
  String communityHubManageAllMembers(int count) {
    return 'Gestiona els $count membres';
  }

  @override
  String get communityHubMemberFallback => 'Membre';

  @override
  String get communityHubChipAdmin => 'ADMIN';

  @override
  String get communityHubLoadError =>
      'No s\'ha pogut carregar la teva comunitat';

  @override
  String get createCommunityPremiumTitle => 'Community Premium';

  @override
  String get createCommunityPremiumBody =>
      'El teu pla gratuït inclou una comunitat. Gestionar-ne més d\'una forma part de Community Premium — properament.';

  @override
  String get createCommunityTitle => 'Nova comunitat';

  @override
  String get createCommunityNameLabel => 'Nom';

  @override
  String get createCommunityNameHint =>
      'p. ex. Kappa Delta — Beta Chi, o Club de Running de la Ciutat';

  @override
  String get createCommunityNameRequired => 'El nom és obligatori';

  @override
  String get createCommunityTypeLabel => 'Tipus';

  @override
  String get createCommunityWhoCanJoin => 'Qui s\'hi pot unir';

  @override
  String get createCommunityJoinAnyone => 'Qualsevol';

  @override
  String get createCommunityJoinInviteOnly => 'Només amb invitació';

  @override
  String get createCommunitySubmit => 'CREA COMUNITAT';

  @override
  String get tierEditorEditTitle => 'Edita nivell';

  @override
  String get tierEditorNewTitle => 'Nou nivell';

  @override
  String get tierEditorDeleteTooltip => 'Elimina nivell';

  @override
  String get tierEditorDeleteTitle => 'Vols eliminar el nivell?';

  @override
  String tierEditorDeleteBody(String name) {
    return 'Vols eliminar \"$name\"? Caldrà reassignar els membres que el tinguin.';
  }

  @override
  String get tierEditorDelete => 'Elimina';

  @override
  String get tierEditorNameLabel => 'Nom';

  @override
  String get tierEditorNameHint => 'p. ex. Junta, Actiu, Capità, Entrenador';

  @override
  String get tierEditorNameRequired => 'El nom és obligatori';

  @override
  String get tierEditorRankLabel => 'Rang (més alt = més sènior)';

  @override
  String get tierEditorRankRequired => 'Introdueix un número (1 o superior)';

  @override
  String get tierEditorColourLabel => 'Color';

  @override
  String get tierEditorRuleLabel => 'Com obtenen els membres aquest nivell';

  @override
  String tierEditorThresholdLabel(String unit) {
    return 'Llindar ($unit)';
  }

  @override
  String tierEditorThresholdRequired(String unit) {
    return 'Introdueix un llindar de $unit';
  }

  @override
  String get tierEditorSave => 'DESA';

  @override
  String get tierEditorCreate => 'CREA NIVELL';

  @override
  String get rosterTitle => 'Membres';

  @override
  String get rosterInviteTooltip => 'Convida membre';

  @override
  String get rosterInviteTitle => 'Convida membre';

  @override
  String get rosterInviteBody =>
      'Afegeix un membre amb el correu del seu compte de Kolabing.';

  @override
  String get rosterInviteEmailLabel => 'Correu electrònic';

  @override
  String get rosterInviteEmailHint => 'nom@exemple.com';

  @override
  String get rosterInvite => 'Convida';

  @override
  String get rosterInviteInvalidEmail =>
      'Introdueix un correu electrònic vàlid';

  @override
  String get rosterMemberAdded => 'Membre afegit';

  @override
  String get rosterNoAccountForEmail =>
      'No s\'ha trobat cap compte de Kolabing amb aquest correu';

  @override
  String get rosterMemberFallback => 'Membre';

  @override
  String get rosterViewProfile => 'Veure el perfil';

  @override
  String get rosterEmptyTitle => 'Encara no hi ha membres';

  @override
  String get rosterInviteMember => 'Convida un membre';

  @override
  String get rosterRemoveTitle => 'Vols eliminar el membre?';

  @override
  String rosterRemoveBody(String name) {
    return 'Vols eliminar $name de la comunitat?';
  }

  @override
  String get rosterRemoveBodyFallback => 'aquest membre';

  @override
  String get rosterRemove => 'Elimina';

  @override
  String get rosterTierLabel => 'Nivell';

  @override
  String get rosterNoTier => 'Sense nivell';

  @override
  String get rosterCanManageTitle => 'Pot gestionar aquesta comunitat';

  @override
  String get rosterCanManageSubtitle =>
      'Capacitat d\'administració — independent del nivell';

  @override
  String get rosterStatusLabel => 'Estat';

  @override
  String get rosterSave => 'DESA';

  @override
  String get friendsTitle => 'Amics';

  @override
  String get friendRequestsTitle => 'Sol·licituds';

  @override
  String get friendAdd => 'Afegir amic';

  @override
  String get friendPending => 'Pendent';

  @override
  String get friendAccept => 'Accepta';

  @override
  String get friendDecline => 'Rebutja';

  @override
  String get friendFriends => 'Amics';

  @override
  String get friendRemoveTitle => 'Vols eliminar aquest amic?';

  @override
  String get friendRemoveConfirm => 'Elimina l\'amic';

  @override
  String get friendActionFailed =>
      'Alguna cosa ha anat malament. Torna-ho a provar.';

  @override
  String get friendsEmpty => 'Encara no tens amics';

  @override
  String get friendsLoadError => 'No s\'han pogut carregar els amics';

  @override
  String get friendUnknownName => 'Membre';

  @override
  String get friendCountOne => '1 amic';

  @override
  String friendCountOther(int count) {
    return '$count amics';
  }

  @override
  String get discoverCommunitiesTitle => 'Descobreix comunitats';

  @override
  String get discoverCommunitiesCta => 'Descobreix comunitats';

  @override
  String get discoverCommunitiesJoin => 'Uneix-te';

  @override
  String get discoverCommunitiesJoined => 'T\'hi has unit';

  @override
  String discoverCommunitiesJoinedToast(String name) {
    return 'T\'has unit a $name';
  }

  @override
  String get discoverCommunitiesInviteOnly => 'Només amb invitació';

  @override
  String discoverCommunitiesInviteOnlyMessage(String name) {
    return '$name és només amb invitació. Demana a un membre que t\'afegeixi.';
  }

  @override
  String get discoverCommunitiesJoinError =>
      'No s\'ha pogut unir ara mateix. Torna-ho a provar.';

  @override
  String discoverCommunitiesMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '1 membre',
    );
    return '$_temp0';
  }

  @override
  String get discoverCommunitiesEmptyTitle =>
      'Encara no hi ha res per descobrir';

  @override
  String get discoverCommunitiesEmptyBody =>
      'El descobriment de comunitats arribarà aviat. Torna per trobar i unir-te a comunitats a prop teu.';

  @override
  String get discoverCommunitiesError =>
      'No s\'han pogut carregar les comunitats. Torna-ho a provar.';

  @override
  String get commonSkip => 'Omet';

  @override
  String get handleFieldPlaceholder => 'elteunom';

  @override
  String get handleFieldHint =>
      '3-20 caràcters: minúscules, números i guions baixos.';

  @override
  String get handleFieldFormatError =>
      'Fes servir 3-20 minúscules, números o guions baixos.';

  @override
  String get handleFieldChecking => 'Comprovant disponibilitat…';

  @override
  String get handleFieldAvailable => 'Disponible';

  @override
  String get handleFieldTaken => 'Aquest nom d\'usuari no està disponible.';

  @override
  String handleFieldTakenWithSuggestion(String suggestion) {
    return 'No disponible. Prova @$suggestion';
  }

  @override
  String get handleFieldYours => 'Aquest és el teu nom d\'usuari actual.';

  @override
  String attendeeOnboardingStepCounter(int step, int total) {
    return 'Pas $step de $total';
  }

  @override
  String get attendeeOnboardingStep1Title => 'Et configurem';

  @override
  String get attendeeOnboardingStep1Subtitle =>
      'Afegeix el teu nom, tria un nom d\'usuari i una foto si vols.';

  @override
  String get attendeeOnboardingAddPhoto => 'Afegeix una foto';

  @override
  String get attendeeOnboardingNameLabel => 'El teu nom';

  @override
  String get attendeeOnboardingNameHint => 'Com vols que et diguem?';

  @override
  String get attendeeOnboardingHandleLabel => 'El teu nom d\'usuari';

  @override
  String get attendeeOnboardingStep2Title => 'On ets?';

  @override
  String get attendeeOnboardingStep2Subtitle =>
      'Tria la teva ciutat per descobrir comunitats a prop teu.';

  @override
  String get attendeeOnboardingStep3Title => 'Què t\'interessa?';

  @override
  String get attendeeOnboardingStep3Subtitle =>
      'Tria alguns interessos perquè et puguem suggerir les comunitats adequades.';

  @override
  String get attendeeOnboardingStep4Title =>
      'Uneix-te a les teves primeres comunitats';

  @override
  String get attendeeOnboardingStep4Subtitle =>
      'Toca per unir-te a les que t\'agradin. Sempre te\'n pots unir a més després.';

  @override
  String get attendeeOnboardingFinish => 'Finalitza';

  @override
  String get attendeeOnboardingForYou => 'Per a tu';

  @override
  String get editProfileHandleLabel => 'Nom d\'usuari';

  @override
  String get addFriendTitle => 'Afegeix un amic';

  @override
  String get addFriendSubtitle => 'Troba algú pel seu correu o el seu @nom.';

  @override
  String get addFriendInputHint => 'Correu o @nom';

  @override
  String get addFriendSearch => 'Cerca';

  @override
  String get addFriendNoMatch =>
      'Ningú coincideix amb aquest correu o nom d\'usuari.';

  @override
  String get addFriendUnavailable =>
      'Afegir amics no està disponible ara mateix.';

  @override
  String get addFriendError =>
      'Alguna cosa ha anat malament. Torna-ho a provar.';

  @override
  String get addFriendSelf => 'Ets tu';

  @override
  String get rosterInviteIdentifierLabel => 'Correu o @nom';

  @override
  String get rosterInviteIdentifierHint => 'nom@exemple.com o @nom';

  @override
  String get rosterInviteInvalidIdentifier =>
      'Introdueix un correu o @nom vàlid.';

  @override
  String get rosterNoAccountForIdentifier =>
      'Cap compte de Kolabing coincideix amb aquest correu o nom d\'usuari.';

  @override
  String get attendeeHomeEventsTitle => 'ESDEVENIMENTS';

  @override
  String get attendeeHomeChooseCity => 'Tria ciutat';

  @override
  String get attendeeHomeFilterToday => 'Avui';

  @override
  String get attendeeHomeFilterDate => 'Quan';

  @override
  String get attendeeHomeFilterUpcoming => 'Propers';

  @override
  String get attendeeHomeFilterThisWeek => 'Aquesta setmana';

  @override
  String get attendeeHomeFilterThisWeekend => 'Aquest cap de setmana';

  @override
  String get attendeeHomeFilterThisMonth => 'Aquest mes';

  @override
  String get attendeeHomeFilterType => 'Tipus';

  @override
  String get attendeeHomeFilterTypeAll => 'Tots els tipus';

  @override
  String get attendeeHomeExploreCommunities => 'Explora comunitats';

  @override
  String get attendeeHomePickCityTitle => 'Tria una ciutat';

  @override
  String get attendeeHomePickCityHint =>
      'Tria una ciutat per descobrir esdeveniments a prop teu.';

  @override
  String get attendeeHomeNoEventsCity =>
      'No hi ha esdeveniments en aquesta ciutat';

  @override
  String get attendeeHomeNoEventsCityHint =>
      'Prova una altra ciutat o esborra els filtres.';

  @override
  String get attendeeHomeScopeAll => 'Tots els esdeveniments';

  @override
  String get attendeeHomeScopeFollowing => 'Seguint';

  @override
  String get attendeeHomeNoFollowsTitle => 'Encara no segueixes ningú';

  @override
  String get attendeeHomeNoFollowsHint =>
      'Segueix una comunitat i tot el que organitzi apareixerà aquí.';

  @override
  String get attendeeHomeNoFollowedEventsTitle => 'Res de pròxim';

  @override
  String get attendeeHomeNoFollowedEventsHint =>
      'Les comunitats que segueixes encara no han anunciat res.';

  @override
  String get attendeeHomeFollowMore => 'Segueix més comunitats';

  @override
  String get eventPartnerBusiness => 'Negoci';

  @override
  String get eventPartnerCommunity => 'Comunitat';

  @override
  String get eventDateToday => 'Avui';

  @override
  String get eventDateTomorrow => 'Demà';

  @override
  String eventDateInDays(int days) {
    return 'D\'aquí a $days dies';
  }

  @override
  String get attendeeCommunityProfileErrorTitle =>
      'No s\'ha pogut carregar la comunitat';

  @override
  String get attendeeCommunityProfileTypeFallback => 'Comunitat';

  @override
  String attendeeCommunityProfileMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '$count membre',
      zero: 'Encara sense membres',
    );
    return '$_temp0';
  }

  @override
  String get attendeeCommunityProfileAboutTitle => 'Quant a';

  @override
  String get attendeeCommunityProfileUpcomingEventsTitle =>
      'Propers esdeveniments';

  @override
  String get attendeeCommunityProfileSeeAll => 'Veure-ho tot →';

  @override
  String get attendeeCommunityProfileNoUpcomingEvents =>
      'Encara no hi ha propers esdeveniments.';

  @override
  String get attendeeCommunityProfileJoin => 'Uneix-te a la comunitat';

  @override
  String get attendeeCommunityProfileJoinedSnack => 'T\'has unit ✓';

  @override
  String get attendeeCommunityProfileRequestToJoin => 'Sol·licitar unir-se';

  @override
  String get attendeeCommunityProfileRequested => 'Sol·licitat';

  @override
  String get attendeeCommunityProfileRequestedSnack => 'Sol·licitud enviada';

  @override
  String get attendeeCommunityProfileRequestUnavailable =>
      'Les sol·licituds encara no estan disponibles. Torna-ho a provar més tard.';

  @override
  String get attendeeCommunityProfileOpenCommunity => 'Obrir comunitat';

  @override
  String get communityDetailTabRewards => 'Recompenses';

  @override
  String get communityDetailChatsAction => 'Xats →';

  @override
  String get communityDetailTiersAction => 'Nivells';

  @override
  String get communityMembersGroupNoTier => 'Sense nivell';

  @override
  String communityMembersTierCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '$count membre',
      zero: 'Sense membres',
    );
    return '$_temp0';
  }

  @override
  String get communityMembersYou => '★ Tu';

  @override
  String communityMembersPoints(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points pts',
      one: '$points pt',
    );
    return '$_temp0';
  }

  @override
  String get communityMembersEmptyTitle => 'Encara no hi ha membres';

  @override
  String get communityMembersEmptyBody =>
      'Els membres apareixeran aquí quan s\'uneixin a aquesta comunitat.';

  @override
  String get communityMembersLoadError =>
      'No s\'han pogut carregar els membres';

  @override
  String get personalRewardsTitle => 'Recompenses';

  @override
  String get personalRewardsRedeemXpTitle => 'Bescanvia el teu XP';

  @override
  String get personalRewardsXpUnit => 'XP';

  @override
  String get personalRewardsComingSoon => 'Ben aviat';

  @override
  String personalRewardsXpCost(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points XP',
      one: '$points XP',
    );
    return '$_temp0';
  }

  @override
  String personalRewardsMyPoints(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points pts',
      one: '$points pt',
    );
    return '$_temp0';
  }

  @override
  String get personalRewardsNoRewards => 'Encara no hi ha recompenses.';

  @override
  String get personalRewardsEmptyTitle => 'Encara no hi ha recompenses';

  @override
  String get personalRewardsEmptyBody =>
      'Uneix-te a comunitats i guanya punts per desbloquejar recompenses.';

  @override
  String get personalRewardsFailedToLoad =>
      'No s\'han pogut carregar les recompenses';

  @override
  String get leaderboardEntryYou => 'Tu';

  @override
  String leaderboardEntryBadgeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count insígnies',
      one: '$count insígnia',
    );
    return '$_temp0';
  }

  @override
  String get communityRewardsComingSoonTitle => 'Recompenses ben aviat';

  @override
  String get communityRewardsComingSoonBody =>
      'Aquí apareixeran els objectius, les insígnies i les recompenses d\'aquesta comunitat.';

  @override
  String get communityRewardsPointsLabel => 'Els teus punts';

  @override
  String get communityRewardsTierLabel => 'Nivell';

  @override
  String get communityRewardsNoTier => 'Encara sense nivell';

  @override
  String get communityRewardsGoalsTitle => 'Objectius';

  @override
  String get communityRewardsBadgesTitle => 'Insígnies';

  @override
  String get communityRewardsRewardsTitle => 'Recompenses';

  @override
  String communityRewardsGoalReward(int points) {
    return '+$points pts';
  }

  @override
  String communityRewardsGoalProgress(int progress, int target) {
    return '$progress / $target';
  }

  @override
  String get communityRewardsBadgeEarned => 'Aconseguida';

  @override
  String get communityRewardsBadgeLocked => 'Bloquejada';

  @override
  String get communityRewardsRedeem => 'Bescanviar';

  @override
  String communityRewardsRewardCost(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points pts',
      one: '$points pt',
    );
    return '$_temp0';
  }

  @override
  String communityRewardsRewardStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'En queden $count',
      zero: 'Exhaurit',
    );
    return '$_temp0';
  }

  @override
  String get communityRewardsRedeemConfirmTitle =>
      'Vols bescanviar la recompensa?';

  @override
  String communityRewardsRedeemConfirmBody(int points, String title) {
    return 'Es gastaran $points punts en «$title».';
  }

  @override
  String get communityRewardsRedeemedSnack => 'Bescanviada ✓';

  @override
  String get communityRewardsGoalsEmpty => 'Encara no hi ha objectius.';

  @override
  String get communityRewardsBadgesEmpty => 'Encara no hi ha insígnies.';

  @override
  String get communityRewardsRewardsEmpty => 'Encara no hi ha recompenses.';

  @override
  String get communityRewardsAddGoal => 'Objectiu';

  @override
  String get communityRewardsAddReward => 'Recompensa';

  @override
  String get communityRewardsAddBadge => 'Insígnia';

  @override
  String get communityGoalEditorNewTitle => 'Nou objectiu';

  @override
  String get communityGoalEditorEditTitle => 'Edita l\'objectiu';

  @override
  String get communityGoalTitleLabel => 'Títol';

  @override
  String get communityGoalTitleRequired => 'Introdueix un títol';

  @override
  String get communityGoalEarnTypeLabel => 'S\'aconsegueix per';

  @override
  String get communityGoalEarnTypeEventCheckIns => 'Registres a esdeveniments';

  @override
  String get communityGoalEarnTypeChallenge => 'Repte';

  @override
  String get communityGoalEarnTypeDaysInCommunity => 'Dies a la comunitat';

  @override
  String get communityGoalTargetLabel => 'Objectiu';

  @override
  String get communityGoalTargetRequired =>
      'Introdueix un objectiu superior a 0';

  @override
  String get communityGoalRewardPointsLabel => 'Punts de recompensa';

  @override
  String get communityGoalRewardPointsRequired =>
      'Introdueix els punts de recompensa';

  @override
  String get communityRewardEditorNewTitle => 'Nova recompensa';

  @override
  String get communityRewardEditorEditTitle => 'Edita la recompensa';

  @override
  String get communityRewardTitleLabel => 'Títol';

  @override
  String get communityRewardTitleRequired => 'Introdueix un títol';

  @override
  String get communityRewardDescriptionLabel => 'Descripció';

  @override
  String get communityRewardCostLabel => 'Cost (punts)';

  @override
  String get communityRewardCostRequired => 'Introdueix un cost';

  @override
  String get communityRewardStockLabel => 'Estoc (buit = il·limitat)';

  @override
  String get communityBadgeEditorNewTitle => 'Nova insígnia';

  @override
  String get communityBadgeEditorEditTitle => 'Edita la insígnia';

  @override
  String get communityBadgeTitleLabel => 'Títol';

  @override
  String get communityBadgeTitleRequired => 'Introdueix un títol';

  @override
  String get communityBadgeCriteriaLabel => 'Criteri';

  @override
  String get communityBadgeCriteriaPointsThreshold => 'Llindar de punts';

  @override
  String get communityBadgeCriteriaEventCheckIns => 'Registres a esdeveniments';

  @override
  String get communityBadgeCriteriaDaysInCommunity => 'Dies a la comunitat';

  @override
  String get communityBadgeCriteriaChallengesCompleted => 'Reptes completats';

  @override
  String get communityBadgeValueLabel => 'Valor';

  @override
  String get communityBadgeValueRequired => 'Introdueix un valor';

  @override
  String get communityBadgeChallengesLabel => 'Reptes';

  @override
  String get communityBadgeChallengesEmpty =>
      'Encara no hi ha reptes disponibles.';

  @override
  String get communityRewardsDeleteTitle => 'Vols eliminar-ho?';

  @override
  String communityRewardsDeleteBody(String title) {
    return 'Vols eliminar «$title»? No es pot desfer.';
  }

  @override
  String get communityEventsMyView => 'La meva vista';

  @override
  String get communityEventsAttendeeView => 'Vista d\'assistent';

  @override
  String get communityEventVisibilityPublic => 'Públic';

  @override
  String get communityEventVisibilityMembers => 'Membres';

  @override
  String get communityEventVisibilityTier => 'Nivell';

  @override
  String get businessGoalTitle => 'Quin és el teu objectiu?';

  @override
  String get businessGoalSubtitle =>
      'Adaptarem la teva configuració segons el que vulguis aconseguir.';

  @override
  String get businessGoalVenueTitle => 'Omplir el meu local';

  @override
  String get businessGoalVenueDescription =>
      'Tinc un lloc físic (bar, gimnàs, botiga, estudi) i vull que hi vinguin comunitats.';

  @override
  String get businessGoalProductTitle => 'Promocionar un producte o servei';

  @override
  String get businessGoalProductDescription =>
      'Vull arribar a comunitats en una o més ciutats, sense local físic.';

  @override
  String get businessProductIdentityTitle => 'Parla\'ns de la teva marca';

  @override
  String get businessProductIdentitySubtitle =>
      'Afegeix el teu nom, categoria i logotip perquè les comunitats sàpiguen qui ets.';

  @override
  String get businessProductIdentityIncomplete =>
      'Afegeix un nom i almenys una categoria.';

  @override
  String get businessProductNameLabel => 'Nom de la marca';

  @override
  String get businessProductNameHint => 'El nom de la teva marca o empresa';

  @override
  String get businessProductCategoryLabel => 'Categoria';

  @override
  String get businessProductCategoryHint =>
      'Tria\'n fins a 3 que et descriguin millor.';

  @override
  String get businessProductTypeLabel => 'Tipus de producte';

  @override
  String get businessProductTypeHint => 'Quin tipus de producte o servei és?';

  @override
  String get businessProductCitiesTitle => 'A quines ciutats vols arribar?';

  @override
  String businessProductCitiesSubtitle(int limit) {
    return 'Pla gratuït: fins a $limit ciutats. Passa a Premium per a un abast il·limitat.';
  }

  @override
  String get businessProductCitiesRequired => 'Selecciona almenys una ciutat.';

  @override
  String businessProductCitiesLimitReached(int limit) {
    return 'El pla gratuït inclou fins a $limit ciutats. Passa a Premium per afegir-ne més.';
  }

  @override
  String businessProductCitiesCounter(int selected, int limit) {
    return '$selected de $limit ciutats seleccionades';
  }

  @override
  String get businessProductAboutTitle => 'Afegeix uns quants detalls més';

  @override
  String get businessProductAboutSubtitle =>
      'Tot és opcional, però ajuda les comunitats a decidir treballar amb tu.';

  @override
  String get businessProductOfferingLabel => 'Què ofereixes';

  @override
  String get businessProductOfferingHint =>
      'p. ex., 20% de descompte per a membres de la comunitat, mostres gratis, premis per a sortejos';

  @override
  String get venueModeBusinessVenue => 'Local del negoci';

  @override
  String get venueModeCommunityVenue => 'Local de la comunitat';

  @override
  String get venueModeNoVenue => 'Encara sense local';

  @override
  String get businessProductPhotosLabel => 'Fotos (opcional)';

  @override
  String get businessProductPhotosEmptyTitle => 'Afegeix fotos';

  @override
  String get businessProductPhotosEmptyDescription =>
      'Mostra el que ofereixes. Puja les teves fotos, elimina les que no vulguis i ordena-les aquí.';

  @override
  String get communityStep1SizeHelper =>
      'Aproximadament, quants membres té la teva comunitat?';

  @override
  String get missionsTitle => 'Missions';

  @override
  String missionsProgress(int progress, int target) {
    return '$progress/$target';
  }

  @override
  String get missionsPointsLabel => 'pts';

  @override
  String get missionsEmptyTitle => 'Encara no hi ha missions';

  @override
  String get missionsEmptyMessage =>
      'Continua fent servir Kolabing i aquí apareixeran noves missions.';

  @override
  String get missionsLoadError => 'No s\'han pogut carregar les teves missions';

  @override
  String get missionsCategoryOnboarding => 'Primers passos';

  @override
  String get missionsCategoryAttendance => 'Assistència';

  @override
  String get missionsCategoryEngagement => 'Participació';

  @override
  String get missionsCategoryContent => 'Contingut';

  @override
  String get missionsCategoryReferral => 'Recomanacions';

  @override
  String get missionsCategoryGrowth => 'Creixement';

  @override
  String get missionsCategorySocial => 'Social';

  @override
  String get missionsCategoryMilestone => 'Fites';

  @override
  String get missionsCategoryOther => 'Altres';

  @override
  String get consentAgreeLead => 'Accepto els ';

  @override
  String get consentTermsLabel => 'Termes del Servei';

  @override
  String get consentAgreeConjunction => ' i la ';

  @override
  String get consentPrivacyLabel => 'Política de Privacitat';

  @override
  String get reconsentTitle => 'Hem actualitzat els nostres termes';

  @override
  String get reconsentBody =>
      'Per continuar utilitzant Kolabing, revisa i accepta els nostres acords actualitzats.';

  @override
  String get reconsentAcceptButton => 'Accepta i continua';

  @override
  String get reconsentError =>
      'Alguna cosa ha anat malament. Torna-ho a provar.';

  @override
  String get authNoToleranceNotice =>
      'Tenim tolerància zero amb els continguts censurables i els usuaris abusius.';

  @override
  String get moderationReport => 'Denuncia';

  @override
  String get moderationBlockUser => 'Bloqueja l\'usuari';

  @override
  String get moderationReportUser => 'Denuncia l\'usuari';

  @override
  String get moderationReportKolab => 'Denuncia aquest Kolab';

  @override
  String get moderationReportReview => 'Denuncia la ressenya';

  @override
  String get moderationReportSheetTitle => 'Denuncia contingut';

  @override
  String get moderationReportSheetSubtitle =>
      'Digues-nos per què. La teva denúncia és confidencial.';

  @override
  String get moderationReasonSpam => 'Correu brossa';

  @override
  String get moderationReasonHarassment => 'Assetjament';

  @override
  String get moderationReasonInappropriate => 'Contingut inadequat';

  @override
  String get moderationReasonOther => 'Altres';

  @override
  String get moderationNoteHint => 'Afegeix detalls (opcional)';

  @override
  String get moderationSubmitReport => 'Envia la denúncia';

  @override
  String get moderationReportSuccess => 'Gràcies: hem rebut la teva denúncia.';

  @override
  String get moderationReportError =>
      'No s\'ha pogut enviar la denúncia. Torna-ho a provar.';

  @override
  String get moderationBlockConfirmTitle => 'Vols bloquejar aquest usuari?';

  @override
  String get moderationBlockConfirmBody =>
      'No veuràs el seu contingut i no et podrà contactar. El podràs desbloquejar més tard.';

  @override
  String get moderationBlockConfirmAction => 'Bloqueja';

  @override
  String get moderationBlockSuccess => 'Usuari bloquejat.';

  @override
  String get moderationBlockError =>
      'No s\'ha pogut bloquejar aquest usuari. Torna-ho a provar.';

  @override
  String get subscriptionLegalAutoRenewNotice =>
      'El pagament es carregarà al teu compte de la botiga en confirmar la compra. Les subscripcions es renoven automàticament tret que es cancel·lin com a mínim 24 hores abans que acabi el període en curs. Pots gestionar-les o cancel·lar-les quan vulguis des de la configuració del teu compte.';

  @override
  String get subscriptionLegalTermsOfUse => 'Termes d\'Ús (EULA)';

  @override
  String get subscriptionLegalPrivacyPolicy => 'Política de Privacitat';

  @override
  String get permissionScreenTitle => 'Treu el màxim partit a Kolabing';

  @override
  String get permissionScreenSubtitle =>
      'Les notificacions et mantenen al dia de missatges i col·laboracions.';

  @override
  String get permissionScreenSubtitleWithLocation =>
      'La ubicació ens ajuda a mostrar-te kolabs propers.\nLes notificacions et mantenen al dia.';

  @override
  String get permissionScreenHelper =>
      'Pots canviar-ho més tard a la configuració.';

  @override
  String get permissionLocationTitle => 'Ubicació';

  @override
  String get permissionLocationSubtitle => 'Kolabs propers';

  @override
  String get permissionNotificationsTitle => 'Notificacions';

  @override
  String get permissionNotificationsSubtitle => 'Missatges i novetats';

  @override
  String permissionDeniedDialogTitle(String permission) {
    return 'Permís de $permission';
  }

  @override
  String permissionDeniedDialogBody(String permission) {
    return 'S\'ha denegat l\'accés a $permission. Pots activar-ho des de la configuració del dispositiu.';
  }

  @override
  String get permissionDeniedDialogLater => 'Més tard';

  @override
  String get permissionDeniedDialogOpenSettings => 'Obre la configuració';

  @override
  String get subscriptionManageAppleFailed =>
      'No s\'han pogut obrir les teves subscripcions de l\'App Store. Ves a Configuració › el teu nom › Subscripcions per gestionar-la o cancel·lar-la.';

  @override
  String get qrHubTitle => 'Escaneja o comparteix';

  @override
  String get qrHubScanTitle => 'Escaneja un codi';

  @override
  String get qrHubScanSubtitle =>
      'Fes check-in en un esdeveniment o emparella\'t per jugar un repte';

  @override
  String get qrHubMyQrTitle => 'El meu codi QR';

  @override
  String get qrHubMyQrSubtitle =>
      'Deixa que algú t\'escanegi per emparellar-vos';

  @override
  String get scannerUnknownCode => 'Aquest no és un codi QR de Kolabing.';

  @override
  String get scannerOwnCode =>
      'Aquest és el teu propi codi: demana a l\'altra persona que mostri el seu.';

  @override
  String get scannerTorchTooltip => 'Activa o desactiva el flaix';

  @override
  String checkinSuccessBody(String eventName) {
    return 'Has fet check-in a $eventName.';
  }

  @override
  String checkinXpEarned(int points) {
    return '+$points XP';
  }

  @override
  String get checkinNextStep =>
      'Ara escaneja el QR de perfil d\'algú per jugar un repte junts.';

  @override
  String get checkinScanPeer => 'ESCANEJA ALGÚ';

  @override
  String peerPairedTitle(String name) {
    return 'Emparellat amb $name';
  }

  @override
  String get peerPairedSubtitle => 'Tria un repte per jugar junts.';

  @override
  String peerPairedAtEvent(String eventName) {
    return 'A $eventName';
  }

  @override
  String get peerChallengesEmpty => 'Aquest esdeveniment encara no té reptes.';

  @override
  String get peerChallengePlay => 'JUGA';

  @override
  String get peerNoSessionTitle => 'Primer fes check-in';

  @override
  String get peerNoSessionBody =>
      'Escaneja el codi QR de l\'esdeveniment per fer check-in i després emparella\'t per jugar els seus reptes.';

  @override
  String get peerNoSessionAction => 'ESCANEJA EL CODI DE L\'ESDEVENIMENT';

  @override
  String get peerInitiateBothCheckedIn =>
      'No s\'ha pogut iniciar aquest repte. Assegureu-vos que tots dos heu fet check-in en aquest esdeveniment.';

  @override
  String get peerInitiateFailed => 'No s\'ha pogut iniciar el repte.';

  @override
  String get challengeFirstChoose => 'Tria un repte';

  @override
  String get challengeFirstScanThem => 'Escaneja la persona amb qui ho faràs';

  @override
  String get communityChallengesTitle => 'Reptes';

  @override
  String get communityChallengesHubSubtitle =>
      'Tria què fan servir els teus esdeveniments';

  @override
  String get communityChallengesDefaultHint =>
      'No has triat cap, així que els teus esdeveniments fan servir tots els reptes de Kolabing. Marca\'n alguns per acotar-ho.';

  @override
  String get communityChallengesCuratedHint =>
      'Els teus esdeveniments només fan servir el que es marca aquí, més el que afegeixis a un esdeveniment concret.';

  @override
  String get communityChallengesAllowRepeat =>
      'Permetre que les mateixes dues persones el repeteixin';

  @override
  String get communityChallengesRequiresNewPerson =>
      'Només amb algú amb qui no hagin jugat';

  @override
  String get communityChallengesSaved => 'Guardat.';

  @override
  String get communityChallengesSaveFailed =>
      'No s\'ha pogut guardar. Torna-ho a provar.';

  @override
  String get communityChallengesUnavailable =>
      'La biblioteca de reptes encara no està disponible.';

  @override
  String get communityChallengesEmptyLibrary =>
      'Encara no hi ha reptes per triar.';

  @override
  String get peerInitiateAlreadyPending =>
      'Ja els has demanat que confirmin aquest repte.';

  @override
  String get peerInitiateAlreadyCompleted =>
      'Ja heu fet aquest repte. Prova un altre.';

  @override
  String get peerInitiateNeedsNewPerson =>
      'Aquest repte és per a algú amb qui encara no has jugat.';

  @override
  String get peerInitiateEventLimit =>
      'Ja has fet tots els reptes possibles en aquest esdeveniment.';

  @override
  String get verifyQrTitle => 'Fes que t\'ho confirmin';

  @override
  String verifyQrBody(String name) {
    return 'Demana a $name que escanegi aquest codi per confirmar que ho has fet.';
  }

  @override
  String get verifyQrWaiting => 'Esperant la confirmació…';

  @override
  String get verifyQrVerifiedTitle => 'Repte completat!';

  @override
  String get verifyQrRejectedTitle => 'No confirmat';

  @override
  String get verifyQrRejectedBody =>
      'Aquest no s\'ha confirmat. Pots provar un altre repte.';

  @override
  String get verifyQrTimeoutTitle => 'Encara esperant';

  @override
  String get verifyQrTimeoutBody =>
      'Encara no hi ha confirmació. Mantén aquest codi obert o torna a mostrar-lo més tard des del teu historial de reptes.';

  @override
  String get verifyQrKeepWaiting => 'SEGUEIX ESPERANT';

  @override
  String get verifyScanTitle => 'Confirma un repte';

  @override
  String verifyScanQuestion(String name, String challenge) {
    return '$name ha completat «$challenge»?';
  }

  @override
  String verifyScanQuestionFallback(String name) {
    return '$name ha completat el seu repte?';
  }

  @override
  String get verifyScanNotForYou =>
      'Aquest repte no espera la teva confirmació.';

  @override
  String get verifyScanConfirmedTitle => 'Confirmat';

  @override
  String verifyScanConfirmedBody(String name, int points) {
    return '$name ha guanyat $points XP.';
  }

  @override
  String get verifyScanRejectedTitle => 'Rebutjat';

  @override
  String get verifyScanFailed => 'No s\'ha pogut confirmar el repte.';

  @override
  String get eventHubShowCheckinQr => 'Mostra el QR de check-in';

  @override
  String get eventCheckinImHere => 'Sóc aquí';

  @override
  String get eventCheckinScanOrganizerQr => 'Escaneja el QR de l\'organitzador';

  @override
  String get eventCheckinScanSomeone => 'Escaneja algú';

  @override
  String get eventCheckinYoureIn => 'Ja hi ets. Busca algú per fer un repte.';

  @override
  String get eventCheckinPickEvent => 'A quin esdeveniment ets?';

  @override
  String get eventCheckinPickEventEmpty => 'Avui no vas a cap esdeveniment.';

  @override
  String get eventCheckinNoEventYet => 'Primer registra\'t en un esdeveniment';

  @override
  String get eventHubCheckIn => 'Fes check-in';

  @override
  String get checkinInvalidToken =>
      'Aquest codi de check-in ja no és vàlid. Demana a l\'organitzador que el mostri de nou.';

  @override
  String get checkinNotAccepting =>
      'Aquest esdeveniment no accepta check-ins ara mateix.';

  @override
  String get scannerCameraBlocked =>
      'Kolabing necessita accés a la càmera per escanejar codis QR.';

  @override
  String get scannerAlreadyCheckedIn => 'Ja havies fet check-in: tot a punt.';

  @override
  String get peerPairedTitleFallback => 'Emparellats';

  @override
  String get verifyQrBodyFallback =>
      'Demana-li que escanegi aquest codi per confirmar que ho has fet.';

  @override
  String get peerChallengesLoadFailed =>
      'No s\'han pogut carregar els reptes d\'aquest esdeveniment.';

  @override
  String get eventQrNotAuthorized =>
      'Només l\'organitzador d\'aquest esdeveniment pot mostrar el seu codi de check-in.';

  @override
  String get verifyScanErrorTitle => 'No s\'ha pogut confirmar';

  @override
  String get checkinAlreadyTitle => 'Ja tens el check-in fet';

  @override
  String get verifyScanUnreachable =>
      'No s\'ha pogut connectar amb el servidor. Comprova la connexió i torna a escanejar.';

  @override
  String get eventQrViewCheckins => 'Mostra els registres';

  @override
  String get communityFollow => 'Segueix';

  @override
  String get communityFollowing => 'Seguint';

  @override
  String get communityFollowedSnack =>
      'Ja la segueixes. Els seus esdeveniments apareixeran al teu feed.';

  @override
  String get communityUnfollowedSnack => 'Has deixat de seguir-la.';

  @override
  String get communityFollowFailed =>
      'No s\'ha pogut actualitzar. Torna-ho a provar.';

  @override
  String get communityBecomeMember => 'Fes-te membre';

  @override
  String membershipPromptTitle(String community) {
    return 'Ets a $community';
  }

  @override
  String get membershipPromptBody =>
      'Els membres tenen el xat de la comunitat, esdeveniments exclusius i les seves recompenses.';

  @override
  String get membershipPromptNotNow => 'Ara no';

  @override
  String get communityMemberBadge => 'Membre';

  @override
  String get communityApplicationTitle => 'Fes-te membre';

  @override
  String communityApplicationIntro(String community) {
    return '$community fa unes preguntes abans d\'afegir nous membres.';
  }

  @override
  String get communityApplicationOptional => 'Opcional';

  @override
  String get communityApplicationRequiredError => 'Respon a això, si us plau';

  @override
  String get communityApplicationSubmit => 'ENVIA LA SOL·LICITUD';

  @override
  String get communityApplicationSentSnack =>
      'Sol·licitud enviada. L\'organitzador la revisarà.';

  @override
  String get communityApplicationJoinedSnack => 'Ja ets membre.';

  @override
  String get communityApplicationFailed =>
      'No s\'ha pogut enviar la teva sol·licitud. Torna-ho a provar.';

  @override
  String get challengeTogetherTitle => 'Junts';

  @override
  String challengeTogetherWaiting(String name) {
    return 'Esperant que $name ho confirmi…';
  }

  @override
  String challengeTogetherEachEarns(int points) {
    return '$points XP per a cadascú';
  }

  @override
  String get challengeTogetherRevealTitle => 'Ben fet!';

  @override
  String challengeTogetherRevealBody(String name) {
    return 'Tu i $name ho heu guanyat tots dos.';
  }

  @override
  String challengeTogetherPrompt(String challenge) {
    return 'Vosaltres dos: $challenge';
  }
}
