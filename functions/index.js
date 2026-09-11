const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const OPENAI_MODEL = process.env.OPENAI_MODEL || 'gpt-4o-mini';

async function loadFaqContext() {
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

exports.gavChatbot = functions.https.onRequest(async (req, res) => {
  try {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Méthode non autorisé' });
      return;
    }

    const question = String(req.body?.question ?? '').trim();
    if (!question) {
      res.status(400).json({ error: 'Question manquante' });
      return;
    }

    if (!OPENAI_API_KEY) {
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
        Authorization: `Bearer ${OPENAI_API_KEY}`,
      },
      body: JSON.stringify({
        model: OPENAI_MODEL,
        temperature: 0.4,
        messages: [
          { role: 'system', content: buildSystemPrompt() },
          {
            role: 'user',
            content: `FAQ:\n${faqText}\n\nQuestion utilisateur:\n${question}`,
          },
        ],
      }),
    });

    const payload = await response.json();

    if (!response.ok) {
      console.error('OpenAI API error:', payload);
      res.status(502).json({
        error: 'Erreur du service IA',
        details: payload?.error?.message ?? 'Erreur inconnue',
      });
      return;
    }

    const reply = payload?.choices?.[0]?.message?.content?.trim();
    if (!reply) {
      res.status(502).json({ error: 'Réponse vide du service IA' });
      return;
    }

    await admin.firestore().collection('chatbot_interactions').add({
      question,
      answer: reply,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.json({ reply });
  } catch (error) {
    console.error('gavChatbot failed:', error);
    res.status(500).json({ error: 'Erreur serveur interne' });
  }
});
