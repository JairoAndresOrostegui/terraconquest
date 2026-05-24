const { execFileSync } = require('child_process');

const projectId = process.env.FIREBASE_PROJECT_ID;

if (!projectId) {
  console.error('FIREBASE_PROJECT_ID is required.');
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

async function main() {
  const response = await fetch(
    `https://identitytoolkit.googleapis.com/admin/v2/projects/${projectId}/config?updateMask=signIn.email.enabled,signIn.email.passwordRequired`,
    {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${accessToken()}`,
        'Content-Type': 'application/json',
        'x-goog-user-project': projectId,
      },
      body: JSON.stringify({
        signIn: {
          email: {
            enabled: true,
            passwordRequired: true,
          },
        },
      }),
    },
  );

  const data = await response.json();
  if (!response.ok) throw new Error(JSON.stringify(data));
  console.log(JSON.stringify(data, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
