.PHONY: test-mobile-e2e test-mobile-e2e-auth test-mobile-e2e-discovery \
        test-mobile-e2e-listing test-mobile-e2e-booking test-mobile-e2e-handoff \
        test-mobile-e2e-messaging test-mobile-e2e-profile test-mobile-e2e-disputes \
        test-mobile-e2e-ratings test-mobile-e2e-cloud _e2e-clean-drivers \
        _e2e-cloud-preflight

MAESTRO = ~/.maestro/bin/maestro
E2E_ENV = $(shell grep -v '^\#' mobile/e2e/config/dev.env | grep -v '^$$' | sed 's/^/-e /')

# Cloud E2E configuration (overridable via env)
#   MAESTRO_CLOUD_API_KEY  required — set via env or GitHub Actions secret
#   E2E_APP_BINARY         path to .apk (Android) or .app/.ipa (iOS) to upload
#   E2E_BACKEND_URL        public URL of the backend the uploaded build will hit
MAESTRO_CLOUD_API_KEY ?=
E2E_APP_BINARY ?= mobile/android/app/build/outputs/apk/release/app-release.apk
E2E_BACKEND_URL ?=

# Kill stale Maestro driver/xcodebuild processes that can hog port 7001
_e2e-clean-drivers:
	@-pkill -f 'maestro-driver-iosUITests-Runner' 2>/dev/null || true
	@-pkill -f 'xcodebuild test-without-building.*maestro-driver' 2>/dev/null || true
	@sleep 1

# Run the full E2E suite (all flows)
test-mobile-e2e: _e2e-clean-drivers
	cd mobile && $(MAESTRO) test e2e/flows/ $(E2E_ENV)

# Run auth flows only
test-mobile-e2e-auth:
	cd mobile && $(MAESTRO) test e2e/flows/auth/ $(E2E_ENV)

# Run discovery flows only
test-mobile-e2e-discovery:
	cd mobile && $(MAESTRO) test e2e/flows/discovery/ $(E2E_ENV)

# Run listing flows only
test-mobile-e2e-listing:
	cd mobile && $(MAESTRO) test e2e/flows/listing/ $(E2E_ENV)

# Run booking flows only
test-mobile-e2e-booking:
	cd mobile && $(MAESTRO) test e2e/flows/booking/ $(E2E_ENV)

# Run handoff flows only
test-mobile-e2e-handoff:
	cd mobile && $(MAESTRO) test e2e/flows/handoff/ $(E2E_ENV)

# Run messaging flows only
test-mobile-e2e-messaging:
	cd mobile && $(MAESTRO) test e2e/flows/messaging/ $(E2E_ENV)

# Run profile flows only
test-mobile-e2e-profile:
	cd mobile && $(MAESTRO) test e2e/flows/profile/ $(E2E_ENV)

# Run dispute flows only
test-mobile-e2e-disputes:
	cd mobile && $(MAESTRO) test e2e/flows/disputes/ $(E2E_ENV)

# Run ratings flows only
test-mobile-e2e-ratings:
	cd mobile && $(MAESTRO) test e2e/flows/ratings/ $(E2E_ENV)

# Preflight checks for cloud E2E — fails fast with a useful message if config is missing
_e2e-cloud-preflight:
	@if [ -z "$(MAESTRO_CLOUD_API_KEY)" ]; then \
	  echo "ERROR: MAESTRO_CLOUD_API_KEY is not set."; \
	  echo "  Generate one at https://console.mobile.dev/ and export it, or set it as a GitHub Actions secret."; \
	  exit 1; \
	fi
	@if [ ! -f "$(E2E_APP_BINARY)" ]; then \
	  echo "ERROR: app binary not found at: $(E2E_APP_BINARY)"; \
	  echo "  Build it first (e.g. cd mobile && npx expo prebuild -p android && cd android && ./gradlew assembleRelease)"; \
	  echo "  or override with: make test-mobile-e2e-cloud E2E_APP_BINARY=/path/to/app.apk"; \
	  exit 1; \
	fi
	@if [ -z "$(E2E_BACKEND_URL)" ]; then \
	  echo "ERROR: E2E_BACKEND_URL is not set."; \
	  echo "  The uploaded app cannot reach localhost from Maestro Cloud — it needs a public backend URL."; \
	  echo "  Export E2E_BACKEND_URL=https://your-backend.example.com (must be set at app build time, not run time)."; \
	  exit 1; \
	fi

# Run the full E2E suite on Maestro Cloud against an uploaded build
# Usage: make test-mobile-e2e-cloud MAESTRO_CLOUD_API_KEY=xxx E2E_APP_BINARY=path/to/app.apk E2E_BACKEND_URL=https://...
test-mobile-e2e-cloud: _e2e-cloud-preflight
	$(MAESTRO) cloud \
	  --apiKey="$(MAESTRO_CLOUD_API_KEY)" \
	  --async=false \
	  "$(E2E_APP_BINARY)" \
	  mobile/e2e/flows/
