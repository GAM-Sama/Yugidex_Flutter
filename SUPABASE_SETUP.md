# Configuración de Supabase para Yugidex

## ⚠️ Error de Conexión

Si ves errores como:
```
AuthRetryableFetchException: Connection timed out
SocketException: Connection timed out
```

Esto significa que hay problemas de conexión con Supabase.

## 🔧 Soluciones

### 1. Verificar Proyecto Supabase

1. Ve a [Supabase Dashboard](https://supabase.com/dashboard)
2. Busca tu proyecto (debería ser `tjjjowhlbcbocktbihie` o similar)
3. **Verifica que el proyecto esté activo**:
   - En Settings → General, asegúrate de que el proyecto esté "Active"
   - Si está "Paused", haz clic en "Resume" para reactivarlo

### 2. Obtener Credenciales Correctas

1. En tu proyecto Supabase, ve a Settings → API
2. Copia la **Project URL** (debe ser algo como `https://tjjjowhlbcbocktbihie.supabase.co`)
3. Copia la **anon/public key** (empieza con `eyJhbGciOiJIUzI1NiIs...`)

### 3. Actualizar Archivo .env

Edita el archivo `.env` en la raíz del proyecto:

```env
SUPABASE_URL=https://tjjjowhlbcbocktbihie.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
N8N_WEBHOOK_URL=https://primary-production-6c347.up.railway.app/webhook-test
```

### 4. Configuración del Webhook

El webhook es necesario para el procesamiento de cartas. Asegúrate de que:
- La URL del webhook esté correcta
- El servidor backend esté activo
- Las políticas RLS estén configuradas correctamente

### 5. Reiniciar la Aplicación

Después de actualizar las credenciales:

```bash
flutter clean
flutter pub get
flutter run
```

## 🆘 Si el Proyecto Está Pausado

Si tu proyecto Supabase está pausado por inactividad:

1. Ve al dashboard de Supabase
2. Selecciona tu proyecto
3. En Settings → General, haz clic en "Resume"
4. Espera 2-3 minutos para que se reactive completamente
5. Verifica que las credenciales sigan siendo las mismas

## 📝 Notas Importantes

- **Nunca** subas el archivo `.env` al repositorio (está en .gitignore)
- Usa el archivo `.env.example` como plantilla
- Las credenciales pueden cambiar si reactivas un proyecto pausado
- El timeout de conexión suele ser temporal, prueba reiniciar la app

## 🔍 Diagnóstico

Para verificar que todo esté configurado correctamente:

1. Revisa que no haya errores en la consola al iniciar la app
2. La pantalla de splash debería mostrar "Error de Conexión" si hay problemas
3. Usa el botón "Reintentar" para probar la conexión nuevamente
