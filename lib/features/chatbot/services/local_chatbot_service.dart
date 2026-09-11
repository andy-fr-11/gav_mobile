import 'gav_knowledge_base.dart';

class LocalChatbotService {
  static String generateReply(String rawMessage) {
    final message = _normalize(rawMessage);

    if (_containsAny(message, ['bonjour', 'salut', 'bonsoir', 'coucou'])) {
      return 'Bonjour ! Je peux vous aider sur les services GAV, les rendez-vous, les commandes et les bonnes pratiques de santé visuelle.';
    }

    final knowledgeAnswer = _findKnowledgeAnswer(message);
    if (knowledgeAnswer != null) return knowledgeAnswer;

    if (_containsAny(message, [
      'qui etes vous',
      'presente gav',
      'presentation gav',
      'gilles andre vision',
      'gilles andre',
    ])) {
      return 'Gilles-André Vision SARL, ou GAV, est une entreprise camerounaise d’optique médicale créée en 2011. Elle propose des corrections visuelles, des équipements optiques, des montures, des verres, des accessoires et un suivi personnalisé. Sa devise est : « GILLES-ANDRE VISION, Un autre regard... ».';
    }

    if (_containsAny(message, [
      'adresse',
      'localisation',
      'situe',
      'ou trouver gav',
      'makèpè',
      'makepe',
      'parcours vita',
      'tradex',
    ])) {
      return 'Le siège de GAV se trouve à Makèpè, après le Parcours Vita, face à la station Tradex, à Douala au Cameroun.';
    }

    if (_containsAny(message, [
      'mission',
      'objectif gav',
      'engagement gav',
      'vision de gav',
      'devise',
    ])) {
      return 'La mission de GAV est de contribuer à l’amélioration de la santé visuelle avec des services d’optique médicale fiables, modernes et accessibles. GAV s’engage à proposer des corrections adaptées, des équipements conformes aux prescriptions, un service après-vente et un accompagnement personnalisé.';
    }

    if (_containsAny(message, [
      'activite',
      'activites',
      'que faites vous',
      'produits gav',
      'que vend gav',
    ])) {
      return 'GAV réalise des équipements optiques et propose des montures de marque, des verres correcteurs et solaires, des lunettes de sécurité, des lentilles de contact, des produits d’entretien, ainsi que des services de réparation, d’ajustage et d’entretien des lunettes.';
    }

    if (_containsAny(message, [
      'reparation',
      'reparer',
      'ajustage',
      'reglage',
      'entretien lunettes',
      'service apres vente',
      'sav',
    ])) {
      return 'GAV assure le réglage, l’ajustage, la réparation et l’entretien des lunettes, ainsi qu’un service après-vente après la livraison. Décrivez votre besoin ou prenez rendez-vous pour être orienté vers l’atelier.';
    }

    if (_containsAny(message, [
      'assurance',
      'partenaire',
      'tiers payant',
      'mutuelle',
      'chanas',
      'axa',
      'ascoma',
      'area assurances',
      'gga',
      'susu',
    ])) {
      return 'GAV travaille notamment avec CHANAS Assurances, AXA Cameroun, ASCOMA Cameroun, WTW, AREA Assurances, PASS 24 Plus, GGA Cameroun et SUSU. La prise en charge dépend de votre contrat ; présentez vos justificatifs et demandez confirmation à l’accueil.';
    }

    if (_containsAny(message, [
      'service de gav',
      'departement',
      'organisation',
      'atelier',
      'refraction',
      'accueil',
      'commercial',
    ])) {
      return 'GAV s’appuie notamment sur la direction générale, les services administratif et financier, réfraction, commercial et accueil, l’atelier de réalisation des équipements optiques, la comptabilité et le marketing-communication.';
    }

    if (_containsAny(message, [
      'equipements gav',
      'materiel gav',
      'auto refractometre',
      'frontofocometre',
      'pupillometre',
      'meuleuse',
    ])) {
      return 'L’atelier et le service de réfraction disposent notamment d’un auto-réfractomètre, d’un frontofocomètre, d’un coffret d’essai, d’un pupillomètre, de meuleuses, d’une rainureuse, d’une centreuse et d’un bac à ultrasons. L’utilisation de ces équipements est réservée au personnel qualifié.';
    }

    if (_containsAny(message, [
      'perte soudaine',
      'perte de vision',
      'vision trouble soudaine',
      'douleur intense',
      'oeil rouge douloureux',
      'flash lumineux',
      'corps flottants soudains',
      'blessure a l oeil',
      'produit chimique',
    ])) {
      return 'Une perte soudaine de vision, une douleur intense, un traumatisme, des flashs lumineux ou une apparition brutale de corps flottants nécessitent un avis médical rapide. Contactez immédiatement un professionnel de santé ou les urgences selon la gravité. Le chatbot ne peut pas évaluer une urgence.';
    }

    if (_containsAny(message, [
      'ecran',
      'ordinateur',
      'telephone',
      'fatigue visuelle',
      'yeux fatigues',
      'yeux secs',
    ])) {
      return 'Pour limiter la fatigue visuelle : appliquez la règle 20-20-20 (toutes les 20 minutes, regardez au loin pendant 20 secondes), clignez régulièrement, réduisez les reflets et gardez un éclairage adapté. Des douleurs persistantes ou une vision floue doivent être évaluées par un professionnel.';
    }

    if (_containsAny(message, [
      'lentilles',
      'lentille',
      'hygiene',
      'nettoyage',
      'produit lentille',
    ])) {
      return 'Lavez et séchez vos mains avant toute manipulation de lentilles, utilisez uniquement la solution recommandée, ne les rincez jamais avec l’eau du robinet et respectez leur durée de remplacement. Retirez-les en cas de douleur, rougeur ou baisse de vision et consultez rapidement.';
    }

    if (_containsAny(message, [
      'enfant',
      'enfants',
      'bebe',
      'scolaire',
      'myopie',
      'ecole',
    ])) {
      return 'Chez l’enfant, un dépistage visuel régulier est important, surtout en cas de maux de tête, plissement des yeux, difficultés scolaires ou antécédents familiaux. Encouragez les activités en plein air et signalez toute gêne visuelle à un professionnel de santé.';
    }

    if (_containsAny(message, [
      'soleil',
      'uv',
      'lunettes de soleil',
      'protection solaire',
    ])) {
      return 'Portez des lunettes de soleil portant une protection UV fiable, particulièrement en forte luminosité. La teinte seule ne garantit pas la protection. Demandez conseil à un opticien pour choisir une protection adaptée à votre usage.';
    }

    if (_containsAny(message, [
      'controle visuel',
      'examen de vue',
      'bilan visuel',
      'visite',
      'depistage',
    ])) {
      return 'Un contrôle visuel permet de suivre l’acuité et de repérer une évolution. Prenez rendez-vous chez GAV pour un examen adapté. Consultez plus rapidement si votre vision change, si vous avez une douleur ou si un symptôme apparaît brutalement.';
    }

    if (_containsAny(message, [
      'rendez',
      'rdv',
      'prise',
      'consultation',
      'appointment',
    ])) {
      return 'Pour prendre un rendez-vous, rendez-vous dans la section Rendez-vous de l’application. Vous pouvez choisir une consultation, un contrôle visuel ou un suivi selon votre besoin.';
    }

    if (_containsAny(message, [
      'service',
      'prestation',
      'exam',
      'lunette',
      'verre',
      'optique',
    ])) {
      return 'GAV SmartVision propose des consultations, des contrôles visuels, des lunettes et verres, ainsi que des conseils sur les équipements optiques.';
    }

    if (_containsAny(message, [
      'commande',
      'suivi commande',
      'ma commande',
      'etat commande',
      'livraison',
    ])) {
      return 'Vous pouvez suivre l’état de vos commandes depuis l’écran des commandes. Pour un détail spécifique, demandez l’aide d’un agent GAV.';
    }

    if (_containsAny(message, ['agent', 'humaine', 'personne', 'contact'])) {
      return 'Votre demande nécessite peut-être une intervention humaine. Demandez à un agent GAV de vous orienter vers le bon service.';
    }

    if (_containsAny(message, ['merci', 'thank', 'ok', 'daccord'])) {
      return 'Avec plaisir. Je reste disponible pour vous aider sur les services GAV et la prévention en santé visuelle.';
    }

    return 'Je peux vous aider sur les rendez-vous, les services GAV, les commandes et la prévention en santé visuelle : écrans, lentilles, protection UV ou dépistage. Pour un symptôme personnel, consultez un professionnel de santé.';
  }

  static bool _containsAny(String input, List<String> keywords) {
    return keywords.any(input.contains);
  }

  static String? _findKnowledgeAnswer(String message) {
    GavKnowledgeEntry? bestEntry;
    var bestScore = 0;

    for (final entry in gavKnowledgeBase) {
      var entryScore = 0;
      for (final keyword in entry.keywords) {
        final normalizedKeyword = _normalize(keyword);
        if (normalizedKeyword.length >= 4 &&
            message.contains(normalizedKeyword)) {
          entryScore = normalizedKeyword.length;
        }
      }
      if (entryScore > bestScore) {
        bestScore = entryScore;
        bestEntry = entry;
      }
    }

    return bestEntry?.answer;
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
