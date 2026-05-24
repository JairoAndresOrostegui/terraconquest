const projectId = process.env.FIREBASE_PROJECT_ID;
const apiKey = process.env.FIREBASE_WEB_API_KEY;
const email = process.env.ADMIN_EMAIL;
const password = process.env.ADMIN_PASSWORD;

if (!projectId || !apiKey || !email || !password) {
  console.error(
    'FIREBASE_PROJECT_ID, FIREBASE_WEB_API_KEY, ADMIN_EMAIL and ADMIN_PASSWORD are required.',
  );
  process.exit(1);
}

async function main() {
  const authResponse = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email,
        password,
        returnSecureToken: true,
      }),
    },
  );
  const authData = await authResponse.json();
  if (!authResponse.ok) throw new Error(JSON.stringify(authData));

  const userResponse = await fetch(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/usuarios/${authData.localId}`,
    {
      headers: {
        Authorization: `Bearer ${authData.idToken}`,
      },
    },
  );
  const userData = await userResponse.json();
  if (!userResponse.ok) throw new Error(JSON.stringify(userData));

  console.log(
    JSON.stringify(
      {
        uid: authData.localId,
        email: authData.email,
        rol: userData.fields?.rol?.stringValue,
        nombres: userData.fields?.nombres?.stringValue,
        apellidos: userData.fields?.apellidos?.stringValue,
      },
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
