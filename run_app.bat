@echo off
echo ============================================
echo   GROUPE NIKEFA - Medical Supply Marketplace
echo ============================================
echo.
echo Starting Flutter Web App...
echo.

REM Supabase Configuration
set SUPABASE_URL=https://ghtskeamnlgfndelpgeh.supabase.co
set SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdodHNrZWFtbmxnZm5kZWxwZ2VoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyNjQ0NTgsImV4cCI6MjA5MDg0MDQ1OH0.x-MUX0Mh4prOD7UGkVVTHGKy59_0urJC609m3GBo3Ps

REM Run Flutter Web with credentials
flutter run -d chrome ^
  --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
  --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%

echo.
echo App stopped.
pause
