import 'challenge.dart';

/// One challenge a community has chosen, and how strictly it plays it (#150).
class CommunityChallengeSelection {
  const CommunityChallengeSelection({
    required this.challengeId,
    this.allowRepeatWithSamePerson = false,
    this.requiresNewPerson = false,
    this.challenge,
  });

  factory CommunityChallengeSelection.fromJson(Map<String, dynamic> json) =>
      CommunityChallengeSelection(
        challengeId: json['challenge_id'] as String,
        allowRepeatWithSamePerson:
            json['allow_repeat_with_same_person'] as bool? ?? false,
        requiresNewPerson: json['requires_new_person'] as bool? ?? false,
        challenge: json['challenge'] is Map<String, dynamic>
            ? Challenge.fromJson(json['challenge'] as Map<String, dynamic>)
            : null,
      );

  final String challengeId;

  /// Whether the same two people may do this one more than once (§6).
  final bool allowRepeatWithSamePerson;

  /// Whether it may only be played with someone you have not played with
  /// before, in either direction, at any event (§7).
  final bool requiresNewPerson;

  /// Present when the server sent the challenge alongside the choice.
  final Challenge? challenge;

  Map<String, dynamic> toJson() => {
    'challenge_id': challengeId,
    'allow_repeat_with_same_person': allowRepeatWithSamePerson,
    'requires_new_person': requiresNewPerson,
  };

  CommunityChallengeSelection copyWith({
    bool? allowRepeatWithSamePerson,
    bool? requiresNewPerson,
  }) => CommunityChallengeSelection(
    challengeId: challengeId,
    allowRepeatWithSamePerson:
        allowRepeatWithSamePerson ?? this.allowRepeatWithSamePerson,
    requiresNewPerson: requiresNewPerson ?? this.requiresNewPerson,
    challenge: challenge,
  );
}

/// A community's set, plus whether it has curated at all.
///
/// [curated] is the field that matters: an empty list with `curated == false`
/// means the community's events play the WHOLE library, which is the opposite
/// of "no challenges". The server sends the flag so the app never has to infer
/// which of the two an empty list means.
class CommunityChallengeSet {
  const CommunityChallengeSet({
    required this.curated,
    required this.selections,
  });

  factory CommunityChallengeSet.fromJson(Map<String, dynamic> json) =>
      CommunityChallengeSet(
        curated: json['curated'] as bool? ?? false,
        selections: ((json['challenges'] as List<dynamic>?) ?? const [])
            .map(
              (e) => CommunityChallengeSelection.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(growable: false),
      );

  final bool curated;
  final List<CommunityChallengeSelection> selections;
}
