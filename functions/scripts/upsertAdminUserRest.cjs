const { execFileSync } = require('child_process');

const projectId = process.env.FIREBASE_PROJECT_ID;
const apiKey = process.env.FIREBASE_WEB_API_KEY;
const email = process.env.ADMIN_EMAIL;
const password = process.env.ADMIN_PASSWORD;
const nombres = process.env.ADMIN_NOMBRES || '';
const apellidos = process.env.ADMIN_APELLIDOS || '';

if (!projectId || !apiKey || !email || !password) {
  console.error(
    'FIREBASE_PROJECT_ID, FIREBASE_WEB_API_KEY, ADMIN_EMAIL and ADMIN_PASSWORD are required.',
  );
  process.exit(1);
}

function accessToken() {
  return (
    process.env.GCLOUD_ACCESS_TOKEN
    || execFileSync('gcloud', ['auth', 'print-access-token'], {
      encoding: 'utf8',
    }).trim()
  );
}

async function authRequest(path, body) {
  const response = await fetch(
    `https://identitytoolkit.googleapis.com/v1/${path}?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    },
  );
  const data = await response.json();

  if (!response.ok) {
    const message = data.error?.message || response.statusText;
    const error = new Error(message);
    error.code = message;
    throw error;
  }

  return data;
}

function firestoreValue(value) {
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'number') return { integerValue: String(value) };
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  return { nullValue: null };
}

async function writeUserDocument(uid) {
  const token = accessToken();
  const now = new Date();
  const fields = {
    uid,
    correo: email,
    nombres,
    apellidos,
    nombreUsuario: `${nombres} ${apellidos}`.trim(),
    tipoDocumento: 'cc',
    numeroDocumento: '',
    telefonoContacto: '',
    rol: 'admin',
    estado: 'activo',
    rubies: 0,
    creadoEn: now,
    actualizadoEn: now,
    ultimoLogin: now,
  };

  const response = await fetch(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/usuarios/${uid}`,
    {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        'x-goog-user-project': projectId,
      },
      body: JSON.stringify({
        fields: Object.fromEntries(
          Object.entries(fields).map(([key, value]) => [key, firestoreValue(value)]),
        ),
      }),
    },
  );

  const data = await response.json();
  if (!response.ok) {
    throw new Error(JSON.stringify(data));
  }
}

async function main() {
  let authData;

  try {
    authData = await authRequest('accounts:signUp', {
      email,
      password,
      returnSecureToken: true,
    });
  } catch (error) {
    if (error.code !== 'EMAIL_EXISTS') throw error;

    authData = await authRequest('accounts:signInWithPassword', {
      email,
      password,
      returnSecureToken: true,
    });
  }

  await writeUserDocument(authData.localId);
  console.log(JSON.stringify({ uid: authData.localId, email }, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
