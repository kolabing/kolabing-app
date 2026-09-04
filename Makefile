# Kolabing — dev/prod build helpers (#17)
#
# The app is a single iOS app whose backend is chosen at BUILD time via the
# APP_ENV dart-define (see lib/config/environment.dart). One flag flips the REST
# URL, realtime/broadcast host, share host, Sentry environment and PostHog tag
# together.
#
#   APP_ENV=dev  -> https://kolabing-v2-development-uhzrzd.laravel.cloud
#   APP_ENV=prod -> https://kolabing.com
#
# Distribute the `prod` IPA to your normal testers and the `dev` IPA to a
# separate TestFlight (internal) tester group — same App Store Connect app,
# same bundle id, distinguished by build/group.
#
# IMPORTANT: produce builds through these targets (or `flutter build … --dart-define=APP_ENV=…`).
# A bare Xcode "Archive" does NOT pass the define; it falls back to the safe
# default (prod in release), so you can never accidentally ship the dev backend,
# but you also cannot produce a DEV build that way — use `make ipa-dev`.

DEV_DEFINE  := --dart-define=APP_ENV=dev
PROD_DEFINE := --dart-define=APP_ENV=prod

.PHONY: run-dev run-prod ipa-dev ipa-prod beta-dev beta-prod beta-dry verify-prod verify-dev serve-sim serve-sim-status serve-sim-stop help

help:
	@echo "Targets:"
	@echo "  make run-dev          # flutter run against the DEV backend"
	@echo "  make run-prod         # flutter run against the PROD backend"
	@echo "  make ipa-dev          # build a DEV IPA (for the dev TestFlight group)"
	@echo "  make ipa-prod         # build a PROD IPA (for normal testers / release)"
	@echo "  make beta-dev         # build AND upload a DEV build to TestFlight"
	@echo "  make beta-prod        # build AND upload a PROD build to TestFlight"
	@echo "  make beta-dry         # build + export only, upload nothing"
	@echo "  make verify-prod      # prove the last archive targets the PROD backend"
	@echo "  make verify-dev       # prove the last archive targets the DEV backend"
	@echo "  make serve-sim        # boot the iOS sim + stream it to a browser (macOS only; see docs/ios-serve-sim-qa.md)"
	@echo "  make serve-sim-status # check whether a backgrounded serve-sim (started remotely) is running"
	@echo "  make serve-sim-stop   # stop a backgrounded serve-sim"

run-dev:
	flutter run $(DEV_DEFINE)

# iOS Simulator QA streamed to a browser via serve-sim. macOS (Apple Silicon) ONLY —
# never on the Linux agent box, never a Flutter web stand-in. See docs/ios-serve-sim-qa.md.
serve-sim:
	./scripts/serve-sim.sh

# Backgrounded start/status/stop, for a human at the terminal OR the SSH remote-launch
# bridge (see docs/ios-serve-sim-qa.md, "Remote start (box -> Mac bridge)").
serve-sim-status:
	./scripts/serve-sim-remote.sh status

serve-sim-stop:
	./scripts/serve-sim-remote.sh stop

run-prod:
	flutter run $(PROD_DEFINE)

ipa-dev:
	flutter build ipa $(DEV_DEFINE)

ipa-prod:
	flutter build ipa $(PROD_DEFINE)

# -----------------------------------------------------------------------------
# TestFlight, without opening App Store Connect (#159)
#
# These bump the build number, archive, export with an App Store Connect API key
# and upload — no interactive login, no session to expire. `ipa-dev`/`ipa-prod`
# above still exist for when you only want the artefact.
#
# One-time setup: docs/release/ios-release-automation.md
# -----------------------------------------------------------------------------

beta-dev:
	./scripts/release-ios.sh dev

beta-prod:
	./scripts/release-ios.sh prod

beta-dry:
	./scripts/release-ios.sh dev --dry-run

# Read the backend host actually baked into the last archive, rather than
# trusting that the right define was passed (#202). `make beta-*` runs this
# automatically; these targets are for an archive taken through Xcode, which
# passes no define at all. Pass a path to check some other artefact:
#   ./scripts/verify-build-env.sh prod ~/Library/Developer/Xcode/Archives/…
verify-prod:
	./scripts/verify-build-env.sh prod

verify-dev:
	./scripts/verify-build-env.sh dev
