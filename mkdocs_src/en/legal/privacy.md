# Privacy Policy

**Last Updated:** May 12, 2026

Alforge Labs defines this privacy policy to explain how personal information is handled in connection with AlphaForge CLI.

## 1. Information We Collect

### 1.1 Purchase Information

When you purchase a membership through Whop, information such as your name or company name, email address, payment details, and country or region may be collected. Payment details are processed by Whop and its payment providers (e.g. Stripe); Alforge Labs does not store card-level information.

### 1.2 Information Exchanged During Authentication

When you run `alpha-forge system auth login`, the OAuth 2.0 PKCE flow sends and receives the following with the Whop API (`api.whop.com`):

- Sent to Whop: OAuth authorization code, PKCE code_verifier, refresh token (during token refresh)
- Received from Whop: access token, refresh token, user ID, membership validity
- During periodic re-verification: the access token is sent to `api.whop.com/api/v1` to confirm access to your purchased product

The retrieved tokens and authentication metadata are stored locally at `~/.config/forge/credentials.json` and are not sent to Alforge Labs servers.

### 1.3 Information We Do Not Collect

!!! info "Local-first software"
    AlphaForge CLI is local-first software. Backtest settings, optimization parameters, strategy data, trading history, positions, local files, and usage logs are not sent to Alforge Labs servers. Communication with the Whop API is limited to authentication and membership verification.

## 2. How We Use Information

- Authenticating and verifying the validity of your membership
- Sending purchase confirmations and receipts
- Sending product update notices to registered users, with opt-out available
- Providing technical support
- Meeting legal, tax, and accounting obligations

## 3. Third-Party Sharing

We do not share personal information with third parties except when necessary for payment processing and membership management through Whop (and Whop's payment processors), or when required by law. We do not sell or share data for marketing purposes.

## 4. Data Retention

- Purchase and membership information: retained according to Whop's data retention policy
- Support email: retained for two years after the support request is resolved
- Local authentication cache (`~/.config/forge/credentials.json`): retained until the user removes it or runs `alpha-forge system auth logout`

## 5. Cookies and Tracking

This website uses Google Analytics to analyze site traffic. You can opt out of measurement by disabling cookies in your browser settings.

## 6. Contact

For privacy inquiries, disclosure requests, or deletion requests, please contact:

**Email:** [support@alforgelabs.com](mailto:support@alforgelabs.com)

## Related pages

- [Trust, Safety, and Limits](trust-safety-limits.md)
- [Disclaimers](disclaimers.md)
- [End User License Agreement (EULA)](eula.md)

---

<!-- Synced from: `en/privacy.html` (Last Updated: May 12, 2026). In the event of any discrepancy between this page and the canonical `privacy.html`, the latter prevails. -->
