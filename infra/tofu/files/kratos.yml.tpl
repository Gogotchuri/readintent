version: v25.4.0

dsn: $DSN

serve:
  public:
    base_url: https://${domain}/kratos/
    cors:
      enabled: true
  admin:
    base_url: http://kratos:4434/

selfservice:
  default_browser_return_url: https://${domain}/welcome
  allowed_return_urls:
    - https://${domain}

  methods:
    password:
      enabled: true
    oidc:
      enabled: true
      config:
        providers:
          - id: google
            provider: google
            client_id: ${google_oauth_client_id}
            client_secret: ${google_oauth_client_secret}
            mapper_url: "file:///etc/config/kratos/oidc.google.jsonnet"
            scope:
              - email
              - profile
              - openid
            requested_claims:
              id_token:
                email:
                  essential: true
                email_verified:
                  essential: true
    totp:
      config:
        issuer: ReadIntent
      enabled: true
    lookup_secret:
      enabled: true
    link:
      enabled: true
    code:
      enabled: true

  flows:
    error:
      ui_url: https://${domain}/error

    settings:
      ui_url: https://${domain}/settings
      privileged_session_max_age: 15m
      required_aal: highest_available

    recovery:
      enabled: true
      ui_url: https://${domain}/recovery
      use: code

    verification:
      enabled: true
      ui_url: https://${domain}/verification
      use: code
      after:
        default_browser_return_url: https://${domain}/welcome

    logout:
      after:
        default_browser_return_url: https://${domain}/login

    login:
      ui_url: https://${domain}/login
      lifespan: 10m

    registration:
      lifespan: 10m
      ui_url: https://${domain}/registration
      after:
        password:
          hooks:
            - hook: session
            - hook: show_verification_ui
        oidc:
          hooks:
            - hook: session

log:
  level: warning
  format: json
  leak_sensitive_values: false

secrets:
  cookie:
    - ${kratos_cookie_secret}
  cipher:
    - ${kratos_secret}

ciphers:
  algorithm: xchacha20-poly1305

hashers:
  algorithm: bcrypt
  bcrypt:
    cost: 12

identity:
  default_schema_id: default
  schemas:
    - id: default
      url: file:///etc/config/kratos/identity.schema.json

session:
  lifespan: 720h

courier:
  smtp:
    connection_uri: smtps://test:test@mailslurper:1025/?skip_ssl_verify=true

feature_flags:
  use_continue_with_transitions: true
