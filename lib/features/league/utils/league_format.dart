import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../models/league_models.dart';

String _locale(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

/// "2026-09" / "2026-09-01" -> "September" (localised). Any other label is
/// shown as the backend sent it.
String? formatLeagueMonth(BuildContext context, String? month) {
  if (month == null) return null;
  final match = RegExp(r'^(\d{4})-(\d{2})').firstMatch(month);
  if (match == null) return month;
  final date = DateTime(int.parse(match.group(1)!), int.parse(match.group(2)!));
  final label = DateFormat.MMMM(_locale(context)).format(date);
  return label.isEmpty ? month : label[0].toUpperCase() + label.substring(1);
}

/// Short day + month, e.g. "30 Sep" / "Sep 30".
String formatLeagueDate(BuildContext context, DateTime date) =>
    DateFormat.MMMd(_locale(context)).format(date.toLocal());

/// "Barcelona league" or the generic fallback.
String leagueTitle(AppLocalizations l10n, LeagueCity? city) =>
    city == null ? l10n.leagueTitleFallback : l10n.leagueTitle(city.name);

/// Localised name of an organiser level (raw text for unknown values).
String organiserLevelName(
  AppLocalizations l10n,
  OrganiserLevelKind kind,
  String raw,
) {
  switch (kind) {
    case OrganiserLevelKind.newcomer:
      return l10n.levelNameNew;
    case OrganiserLevelKind.rising:
      return l10n.levelNameRising;
    case OrganiserLevelKind.trusted:
      return l10n.levelNameTrusted;
    case OrganiserLevelKind.top:
      return l10n.levelNameTop;
    case OrganiserLevelKind.unknown:
      return raw.isEmpty ? raw : raw[0].toUpperCase() + raw.substring(1);
  }
}

/// Renders a criterion value against its target, by unit:
/// rank -> "#4 / top 3", ratio -> "82% / 60%", hours -> "9 h / 24 h",
/// counts and check-ins -> "1/3".
String formatCriterionProgress(
  BuildContext context,
  AppLocalizations l10n,
  LevelCriterion criterion,
) {
  final locale = _locale(context);
  String number(num v) => NumberFormat.decimalPattern(locale).format(v);

  if (criterion.unit == 'rank') {
    final value = criterion.value == null
        ? '–'
        : '#${number(criterion.value!)}';
    if (criterion.target == null) return value;
    return '$value / ${l10n.levelRankTarget(number(criterion.target!))}';
  }

  String one(num? v) {
    if (v == null) return '–';
    switch (criterion.unit) {
      case 'ratio':
        return NumberFormat.percentPattern(locale).format(v);
      case 'hours':
        return l10n.levelHoursValue(number(v));
      default:
        return number(v);
    }
  }

  if (criterion.target == null) return one(criterion.value);
  final isPlainCount = criterion.unit != 'ratio' && criterion.unit != 'hours';
  return isPlainCount
      ? '${one(criterion.value)}/${one(criterion.target)}'
      : '${one(criterion.value)} / ${one(criterion.target)}';
}
