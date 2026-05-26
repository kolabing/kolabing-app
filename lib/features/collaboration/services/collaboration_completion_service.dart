import '../models/collaboration.dart';
import '../providers/collaboration_detail_provider.dart';

Future<Collaboration> completeCollaboration(String collaborationId) =>
    markCollaborationCompleted(collaborationId);
