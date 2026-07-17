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

.PHONY: run-dev run-prod ipa-dev ipa-prod serve-sim help

help:
	@echo "Targets:"
	@echo "  make run-dev    # flutter run against the DEV backend"
	@echo "  make run-prod   # flutter run against the PROD backend"
	@echo "  make ipa-dev    # build a DEV IPA (for the dev TestFlight group)"
	@echo "  make ipa-prod   # build a PROD IPA (for normal testers / release)"
	@echo "  make serve-sim  # boot the iOS sim + stream it to a browser (macOS only; see docs/ios-serve-sim-qa.md)"

run-dev:
	flutter run $(DEV_DEFINE)

# iOS Simulator QA streamed to a browser via serve-sim. macOS (Apple Silicon) ONLY —
# never on the Linux agent box, never a Flutter web stand-in. See docs/ios-serve-sim-qa.md.
serve-sim:
	./scripts/serve-sim.sh

run-prod:
	flutter run $(PROD_DEFINE)

ipa-dev:
	flutter build ipa $(DEV_DEFINE)

ipa-prod:
	flutter build ipa $(PROD_DEFINE)
