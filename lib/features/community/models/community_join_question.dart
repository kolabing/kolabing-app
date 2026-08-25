import 'package:flutter/foundation.dart';

/// A question a community leader asks before admitting a member (#138).
///
/// Communities may ask nothing at all — that is the default and the common
/// case, and it keeps joining a single tap. A leader who wants to know who is
/// coming in can add up to five of these, and then joining routes through an
/// application instead.
@immutable
class CommunityJoinQuestion {
  const CommunityJoinQuestion({
    required this.id,
    required this.prompt,
    this.position = 1,
    this.required = true,
  });

  factory CommunityJoinQuestion.fromJson(Map<String, dynamic> json) =>
      CommunityJoinQuestion(
        id: json['id']?.toString() ?? '',
        prompt: json['prompt']?.toString() ?? '',
        position: (json['position'] as num?)?.toInt() ?? 1,
        // Absent means required: the safer reading, since submitting a blank
        // answer to a question the backend considers required is refused.
        required: json['required'] as bool? ?? true,
      );

  final String id;
  final String prompt;
  final int position;

  // ignore: avoid_field_initializers_in_const_classes
  final bool required;

  bool get isValid => id.isNotEmpty && prompt.isNotEmpty;
}

/// One answer, as `POST /communities/{id}/join-requests` expects it.
@immutable
class CommunityJoinAnswer {
  const CommunityJoinAnswer({required this.questionId, required this.answer});

  final String questionId;
  final String answer;

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'answer': answer,
  };
}
