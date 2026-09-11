const express = require('express');
const admin = require('firebase-admin');

const app = express();
const port = Number(process.env.PORT || 8080);
const openAiApiKey = process.env.OPENAI_API_KEY;
const openAiModel = process.env.OPENAI_MODEL || 'gpt-4o-mini';
const allowedOrigin = process.env.CHATBOT_ALLOWED_ORIGIN || '*';

if (!admin.apps.length) {
  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');
  if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && privateKey) {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey,
      }),
    });
  } else {
    console.warn('Firebase credentials are missing; FAQ loading and interaction logging are disabled.');
  }
}

app.use(express.json({ limit: '32kb' }));
app.use((req, res, next) => {
  res.set('Access-Control-Allow-Origin', allowedOrigin);
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }
  next();
});

async function loadFaqContext() {
  if (!admin.apps.length) return [];
  const snapshot = await admin
    .firestore()
    .collection('chatbot_faqs')
    .where('active', '==', true)
    .limit(12)
    .get();

  return snapshot.docs.map((doc) => ({
    question: String(doc.data().question ?? ''),
    answer: String(doc.data().answer ?? ''),
  }));
}

function buildSystemPrompt() {
  return `Tu es l’assistant GAV.
  Réponds en français, de manière claire, utile et concise.
  Tu aides les patients et clients pour les rendez-vous, services, boutique, commandes, FAQ et procédures.
  Utilise uniquement la FAQ fournie.
  Si tu ne sais pas une réponse sûre, réponds : "Je vous invite à contacter le service client GAV ou un agent humain pour confirmer cette information."`;
}

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

app.post('/chat', async (req, res) => {
  try {
    const question = String(req.body?.question ?? '').trim();
    if (!question) {
      res.status(400).json({ error: 'Question manquante' });
      return;
    }
    if (!openAiApiKey) {
      res.status(500).json({ error: 'La clé OpenAI est absente côté serveur.' });
      return;
    }

    const faq = await loadFaqContext();
    const faqText = faq.length
      ? faq.map((item) => `Q: ${item.question}\nR: ${item.answer}`).join('\n\n')
      : 'Aucune FAQ disponible pour le moment.';
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${openAiApiKey}`,
      },
      body: JSON.stringify({
        model: openAiModel,
        temperature: 0.4,
        messages: [
          { role: 'system', content: buildSystemPrompt() },
          { role: 'user', content: `FAQ:\n${faqText}\n\nQuestion utilisateur:\n${question}` },
        ],
      }),
    });
    const payload = await response.json();
    if (!response.ok) {
      console.error('OpenAI API error:', payload);
      res.status(502).json({ error: 'Erreur du service IA' });
      return;
    }

    const reply = payload?.choices?.[0]?.message?.content?.trim();
    if (!reply) {
      res.status(502).json({ error: 'Réponse vide du service IA' });
      return;
    }

    if (admin.apps.length) {
      await admin.firestore().collection('chatbot_interactions').add({
        question,
        answer: reply,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    res.json({ reply });
  } catch (error) {
    console.error('Chatbot failed:', error);
    res.status(500).json({ error: 'Erreur serveur interne' });
  }
});

app.listen(port, () => console.log(`GAV chatbot listening on port ${port}`));