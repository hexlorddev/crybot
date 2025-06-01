# CryBot API Documentation

## REST API Endpoints

### Authentication
```http
POST /api/v1/auth/login
POST /api/v1/auth/logout
POST /api/v1/auth/refresh
```

### Voice Commands
```http
POST /api/v1/voice/recognize
GET  /api/v1/voice/status
POST /api/v1/voice/tts
```

### Configuration
```http
GET  /api/v1/config
PUT  /api/v1/config
POST /api/v1/config/reset
```

### Plugins
```http
GET  /api/v1/plugins
POST /api/v1/plugins/install
DELETE /api/v1/plugins/{id}
PUT /api/v1/plugins/{id}/enable
```

### Analytics
```http
GET  /api/v1/analytics/usage
GET  /api/v1/analytics/performance
GET  /api/v1/analytics/errors
```