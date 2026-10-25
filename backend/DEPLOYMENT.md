# Backend deployment

The mobile application talks to the backend over HTTPS. The backend must be
deployed independently of the development computer.

## Deploy with Render

1. Push this project to a private GitHub repository.
2. Create a new **Web Service** on Render and select the repository.
3. Set the service root directory to `backend`.
4. Use:
   - Build command: `npm ci`
   - Start command: `npm start`
5. Add these environment variables in Render:
   - `MONGODB_URI`: the MongoDB Atlas connection string
   - `NODE_ENV`: `production`
   - `HOST`: `0.0.0.0`
   - `CORS_ORIGINS`: the web app origin, or leave empty for mobile-only use
6. Deploy and verify:
   `https://YOUR-SERVICE.onrender.com/api/health`

In Render, set the health check path to `/api/health`. The service must first
return an HTTP response on the Render-provided `PORT`; the database connection
can finish afterward. A healthy response contains `"status":"ok"` and
`"database":"connected"`. If it contains `"status":"degraded"`, check the
MongoDB Atlas URI and Network Access settings.

For MongoDB Atlas, add Render's outbound access in **Network Access**. For
initial testing you can use `0.0.0.0/0`, then restrict access when your
deployment setup supports a stable outbound IP.

## Build the Android app

Use the HTTPS URL assigned by the host, including `/api`:

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=https://YOUR-SERVICE.onrender.com/api
```

The generated APK is at:
`build/app/outputs/flutter-apk/app-release.apk`.

Do not put the MongoDB connection string in the Flutter app. It belongs only
in the backend host's environment variables.

## Docker deployment

The `backend/Dockerfile` is ready for any container host:

```powershell
docker build -t expense-tracker-api .\backend
docker run -p 5000:5000 `
  -e MONGODB_URI="your-secret-connection-string" `
  -e NODE_ENV=production `
  expense-tracker-api
```

For production, put the container behind the host's HTTPS reverse proxy or
managed HTTPS endpoint rather than exposing plain HTTP directly.
