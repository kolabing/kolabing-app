import 'package:kolabing_app/features/instagram/models/instagram_models.dart';
import 'package:kolabing_app/features/instagram/services/instagram_service.dart';
import 'package:kolabing_app/features/profile/providers/gallery_provider.dart';

/// In-memory [InstagramService] with call counters.
class FakeInstagramService implements InstagramService {
  FakeInstagramService({
    this.status,
    Map<String?, InstagramMediaPage>? pages,
    this.importResult = const InstagramImportResult(importedCount: 0),
  }) : pages = pages ?? <String?, InstagramMediaPage>{};

  InstagramStatus? status;
  Map<String?, InstagramMediaPage> pages;
  InstagramImportResult importResult;
  Uri connectUrl = Uri.parse(
    'https://www.instagram.com/oauth/authorize?client_id=1&state=signed',
  );

  Exception? statusError;
  Exception? mediaError;
  Exception? importError;

  int statusCalls = 0;
  int connectUrlCalls = 0;
  int syncCalls = 0;
  int disconnectCalls = 0;
  final List<String?> mediaCursors = [];
  final List<List<String>> importedIds = [];

  @override
  Future<InstagramStatus?> getStatus() async {
    statusCalls++;
    if (statusError != null) throw statusError!;
    return status;
  }

  @override
  Future<Uri> getConnectUrl() async {
    connectUrlCalls++;
    return connectUrl;
  }

  @override
  Future<InstagramMediaPage> getMedia({String? cursor}) async {
    mediaCursors.add(cursor);
    if (mediaError != null) throw mediaError!;
    return pages[cursor] ?? const InstagramMediaPage(items: []);
  }

  @override
  Future<InstagramImportResult> importMedia(
    List<String> ids, {
    String target = 'gallery',
    String? kolabId,
  }) async {
    importedIds.add(ids);
    if (importError != null) throw importError!;
    return importResult;
  }

  @override
  Future<void> sync() async => syncCalls++;

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    status = InstagramStatus(
      enabled: status?.enabled ?? true,
      connected: false,
    );
  }
}

/// Gallery notifier that only counts reloads (no auth, no network).
class CountingGalleryNotifier extends GalleryNotifier {
  int loads = 0;

  @override
  GalleryState build() => const GalleryState();

  @override
  Future<void> loadGallery() async => loads++;
}

InstagramMedia media(
  String id, {
  InstagramMediaType type = InstagramMediaType.image,
  bool imported = false,
}) => InstagramMedia(
  id: id,
  mediaType: type,
  mediaUrl: 'https://cdn.example/$id.jpg',
  imported: imported,
);
