# Backend — event photos endpoint + wire message_notifications into prefs API

> **Target repo:** `kolabing-v2`. Two small net-new backend pieces that unblock the
> app events/attendee completion (NF-16). Everything else the app needs (signups
> list, event-chat create, RSVP, create-upcoming) already ships on master.

## 1. Add photos to an existing event
Today photos can only be set at legacy create (`POST /events` multipart); `update`
ignores them and there's no way to add/remove later — so an upcoming event (created
JSON, no photos) can never get a gallery.

- `POST /events/{event}/photos` — multipart `photos[]`, auth: **owner / can_manage**
  of the event's community (or the event's `profile_id` owner). Reuse
  `FileUploadService` + `EventPhoto`. Enforce a **total cap of 5** (existing + new).
  Returns the updated **`EventResource`** (with `photos`). 201.
- `DELETE /events/{event}/photos/{photo}` — owner / can_manage. Verify the photo
  belongs to the event (else 404). Delete the file from storage + the row. Returns 200.
- Tests: add (201, cap enforced → 422), delete (200, foreign photo → 404), non-manager → 403.

## 2. Wire `message_notifications` into the prefs API (gap)
The column + fan-out shipped, but the API doesn't expose it:
- `UpdateNotificationPreferencesRequest`: add `'message_notifications' => ['sometimes','boolean']`
  to rules **and** to the validated/fillable list.
- `NotificationPreferenceResource`: add `'message_notifications' => $this->message_notifications`.
- (Confirm `getOrCreateNotificationPreferences` defaults it to true.)
- Test: `PUT /me/notification-preferences {message_notifications:false}` persists + `GET` returns it.

## 3. (Optional) auto-create the event chat on upcoming-event create
So the app doesn't need a separate "create chat" step — create the `event` `ChatThread`
inside the upcoming-create path. Or leave explicit (`POST /events/{id}/chat`) — app calls
it lazily on first open. **Decision: leave explicit** unless trivial; app opens-or-creates.

## Acceptance
1. Leader adds 2 photos to an existing upcoming event → 201, `EventResource.photos` has them; a 6th → 422.
2. Leader deletes a photo → 200, gone from storage + payload; non-manager → 403.
3. `PUT /me/notification-preferences {message_notifications:false}` → `GET` returns `message_notifications:false`; default is true.

## Owner: this is the backend half — built in parallel with the app (NF-16).
