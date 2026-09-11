class GavKnowledgeEntry {
  final List<String> keywords;
  final String answer;

  const GavKnowledgeEntry({required this.keywords, required this.answer});
}

const gavKnowledgeBase = <GavKnowledgeEntry>[
  // GAV : identité et implantation
  GavKnowledgeEntry(
    keywords: ['gav', 'gilles andre vision', 'entreprise'],
    answer:
        'Gilles-André Vision SARL, ou GAV, est une entreprise camerounaise spécialisée dans l’optique médicale.',
  ),
  GavKnowledgeEntry(
    keywords: ['creation gav', 'création gav', 'annee creation'],
    answer:
        'GAV a été créée en 2011 pour contribuer à l’amélioration de la santé visuelle des populations.',
  ),
  GavKnowledgeEntry(
    keywords: ['devise gav', 'slogan gav', 'un autre regard'],
    answer:
        'La devise de GAV est : « GILLES-ANDRE VISION, Un autre regard... ».',
  ),
  GavKnowledgeEntry(
    keywords: ['mission gav', 'mission entreprise'],
    answer:
        'La mission de GAV est de proposer des services d’optique médicale fiables, modernes et accessibles pour améliorer la santé visuelle.',
  ),
  GavKnowledgeEntry(
    keywords: ['vision gav', 'objectif gav'],
    answer:
        'GAV ambitionne de devenir une référence nationale de l’optique médicale grâce à un service de proximité et des équipements de qualité.',
  ),
  GavKnowledgeEntry(
    keywords: ['adresse gav', 'siege gav', 'siège gav'],
    answer:
        'Le siège de GAV est situé à Makèpè, après le Parcours Vita, face à la station Tradex, à Douala au Cameroun.',
  ),
  GavKnowledgeEntry(
    keywords: ['localisation gav', 'trouver gav', 'ou est gav', 'où est gav'],
    answer:
        'Pour trouver GAV, rendez-vous à Makèpè, après le Parcours Vita, face à la station Tradex, à Douala.',
  ),
  GavKnowledgeEntry(
    keywords: ['quartier gav', 'makepe', 'makèpè', 'parcours vita'],
    answer:
        'GAV se trouve dans le quartier Makèpè, après le Parcours Vita, face à la station Tradex.',
  ),
  GavKnowledgeEntry(
    keywords: ['contact gav', 'telephone gav', 'téléphone gav', 'whatsapp gav'],
    answer:
        'Les coordonnées de contact doivent être confirmées auprès de l’accueil GAV. Évitez de partager des informations médicales sensibles dans un canal non vérifié.',
  ),
  GavKnowledgeEntry(
    keywords: [
      'horaire gav',
      'horaires gav',
      'horaires',
      'heures ouverture',
      'ouvert gav',
    ],
    answer:
        'Les horaires peuvent varier. Consultez les informations officielles de GAV ou demandez confirmation à l’accueil GAV avant de vous déplacer.',
  ),

  // Services et parcours client
  GavKnowledgeEntry(
    keywords: ['services gav', 'prestations gav'],
    answer:
        'GAV propose des consultations, contrôles visuels, corrections visuelles, équipements optiques, vente de montures et verres, accessoires, entretien et suivi personnalisé.',
  ),
  GavKnowledgeEntry(
    keywords: ['consultation optique', 'consultation'],
    answer:
        'Une consultation permet d’évaluer votre besoin visuel et de vous orienter vers la correction ou le service adapté. Prenez rendez-vous avec GAV.',
  ),
  GavKnowledgeEntry(
    keywords: ['controle visuel', 'contrôle visuel'],
    answer:
        'Le contrôle visuel aide à suivre l’acuité visuelle et à repérer une évolution. Il ne remplace pas un examen médical lorsqu’un symptôme est présent.',
  ),
  GavKnowledgeEntry(
    keywords: ['examen vue', 'bilan visuel', 'examen de vue'],
    answer:
        'Pour un examen de vue, prenez rendez-vous afin que le personnel qualifié puisse vous accueillir dans de bonnes conditions.',
  ),
  GavKnowledgeEntry(
    keywords: ['prendre rendez vous', 'prise rendez vous', 'rendez-vous gav'],
    answer:
        'Vous pouvez utiliser la rubrique Rendez-vous de l’application ou contacter l’accueil GAV pour être orienté.',
  ),
  GavKnowledgeEntry(
    keywords: ['modifier rendez vous', 'annuler rendez vous'],
    answer:
        'Pour modifier ou annuler un rendez-vous, consultez votre rendez-vous dans l’application ou prévenez l’accueil GAV dès que possible.',
  ),
  GavKnowledgeEntry(
    keywords: ['ordonnance', 'prescription'],
    answer:
        'Apportez votre ordonnance lors de la commande d’un équipement. La correction doit être réalisée conformément aux indications du professionnel compétent.',
  ),
  GavKnowledgeEntry(
    keywords: ['suivi patient', 'suivi client'],
    answer:
        'GAV assure un suivi personnalisé des clients, depuis le conseil et la réalisation de l’équipement jusqu’au service après-vente.',
  ),
  GavKnowledgeEntry(
    keywords: ['conseil sante visuelle', 'conseils santé visuelle'],
    answer:
        'GAV propose des conseils personnalisés en santé visuelle. Pour un symptôme ou une baisse de vision, demandez un avis professionnel.',
  ),
  GavKnowledgeEntry(
    keywords: ['prix consultation', 'tarif consultation', 'cout consultation'],
    answer:
        'Les tarifs peuvent dépendre du service demandé. Demandez le tarif actualisé à l’accueil GAV avant la prestation.',
  ),
  GavKnowledgeEntry(
    keywords: ['prix lunettes', 'tarif lunettes', 'cout lunettes'],
    answer:
        'Le prix dépend de la monture, des verres, des traitements et des options choisies. GAV peut préparer un devis adapté à votre besoin.',
  ),
  GavKnowledgeEntry(
    keywords: ['devis optique', 'devis lunettes'],
    answer:
        'Un devis peut être établi selon votre correction, la monture, les verres et les traitements souhaités. Demandez-le à l’accueil ou au service commercial.',
  ),
  GavKnowledgeEntry(
    keywords: ['delai fabrication', 'délai fabrication', 'delai livraison'],
    answer:
        'Le délai dépend de la correction, des verres et de la disponibilité de la monture. Demandez une estimation lors de la commande.',
  ),
  GavKnowledgeEntry(
    keywords: ['commande lunettes', 'commander lunettes'],
    answer:
        'Pour commander des lunettes, choisissez une monture, présentez votre prescription si nécessaire, puis validez les verres et options avec le service commercial.',
  ),
  GavKnowledgeEntry(
    keywords: ['recuperer lunettes', 'retrait commande', 'livraison commande'],
    answer:
        'Le retrait ou la livraison dépend des modalités choisies. Consultez le statut de votre commande ou contactez l’accueil GAV.',
  ),

  // Produits et équipements optiques
  GavKnowledgeEntry(
    keywords: ['montures marque', 'monture marque', 'montures'],
    answer:
        'GAV propose des montures de marque. Le choix dépend de la morphologie, du confort, du style et de la correction.',
  ),
  GavKnowledgeEntry(
    keywords: ['verres correcteurs', 'verre correcteur'],
    answer:
        'Les verres correcteurs sont choisis selon la prescription, les besoins visuels et l’usage quotidien. Un professionnel peut vous conseiller.',
  ),
  GavKnowledgeEntry(
    keywords: ['verres solaires', 'verre solaire', 'lunettes soleil'],
    answer:
        'GAV propose des verres et lunettes solaires. Vérifiez toujours que les lunettes offrent une protection UV fiable, car une teinte seule ne suffit pas.',
  ),
  GavKnowledgeEntry(
    keywords: ['lunettes securite', 'lunettes sécurité', 'protection travail'],
    answer:
        'GAV propose des lunettes de sécurité adaptées à certains usages professionnels. Le modèle doit être choisi selon le risque et les normes applicables.',
  ),
  GavKnowledgeEntry(
    keywords: ['lentilles contact', 'lentilles de contact'],
    answer:
        'GAV propose des accessoires et lentilles de contact selon les disponibilités. Un accompagnement professionnel est important avant toute première adaptation.',
  ),
  GavKnowledgeEntry(
    keywords: [
      'produit entretien verre',
      'nettoyer verres',
      'produit nettoyage',
    ],
    answer:
        'Utilisez un produit conçu pour les verres optiques et un tissu propre adapté. Évitez les produits ménagers et les tissus abrasifs.',
  ),
  GavKnowledgeEntry(
    keywords: ['accessoires optiques', 'accessoires lunettes'],
    answer:
        'Les accessoires optiques peuvent inclure des produits d’entretien, étuis et solutions liés aux équipements. Demandez les disponibilités à GAV.',
  ),
  GavKnowledgeEntry(
    keywords: ['choisir monture', 'quelle monture'],
    answer:
        'Le choix d’une monture tient compte de la morphologie, du confort, de la correction, de la solidité et de l’usage. Un opticien peut vous guider.',
  ),
  GavKnowledgeEntry(
    keywords: ['traitement verres', 'anti reflet', 'anti-rayure'],
    answer:
        'Les traitements des verres dépendent de vos usages et de votre budget. Demandez au professionnel les avantages et limites de chaque option.',
  ),
  GavKnowledgeEntry(
    keywords: ['mesure pupillaire', 'distance pupillaire'],
    answer:
        'La distance pupillaire est une mesure importante pour le centrage des verres. Elle doit être réalisée avec précision par un professionnel.',
  ),
  GavKnowledgeEntry(
    keywords: ['auto refractometre', 'auto-réfractomètre'],
    answer:
        'L’auto-réfractomètre aide à obtenir une mesure automatisée de la réfraction. Le résultat doit être interprété et complété par un professionnel.',
  ),
  GavKnowledgeEntry(
    keywords: ['frontofocometre', 'frontofocomètre'],
    answer:
        'Le frontofocomètre sert à lire la puissance des verres et à vérifier certaines caractéristiques d’un équipement optique.',
  ),
  GavKnowledgeEntry(
    keywords: ['coffret essai', 'verres essai'],
    answer:
        'Le coffret d’essai permet de présenter différentes corrections et d’aider à déterminer la correction adaptée lors d’une évaluation.',
  ),
  GavKnowledgeEntry(
    keywords: ['meuleuse optique', 'meuleuse'],
    answer:
        'La meuleuse sert à découper et ajuster les verres selon le calibre de la monture. Cette opération est réalisée par un personnel formé.',
  ),
  GavKnowledgeEntry(
    keywords: ['bac ultrasons', 'ultra son', 'nettoyage lunettes'],
    answer:
        'Le bac à ultrasons permet un nettoyage adapté de certains équipements. Demandez conseil avant d’y placer une monture ou un accessoire.',
  ),

  // Atelier, réparation et qualité
  GavKnowledgeEntry(
    keywords: [
      'atelier gav',
      'realisation equipements',
      'réalisation équipements',
    ],
    answer:
        'L’atelier de GAV réalise les équipements optiques en tenant compte de la monture, de la correction et des mesures nécessaires.',
  ),
  GavKnowledgeEntry(
    keywords: ['reparer lunettes', 'réparer lunettes', 'lunettes cassees'],
    answer:
        'GAV peut vous orienter pour une réparation ou un ajustage. Apportez la monture afin que l’atelier évalue ce qui est possible.',
  ),
  GavKnowledgeEntry(
    keywords: ['lunettes desserrees', 'branches lunettes', 'reglage lunettes'],
    answer:
        'Un réglage professionnel peut améliorer le maintien et le confort. Évitez de forcer les branches ou de chauffer vous-même la monture.',
  ),
  GavKnowledgeEntry(
    keywords: ['verre raye', 'verres rayes', 'rayure lunettes'],
    answer:
        'Une rayure ne peut généralement pas être retirée par un nettoyage. Demandez à GAV si le remplacement du verre est nécessaire.',
  ),
  GavKnowledgeEntry(
    keywords: ['lunettes tordues', 'monture tordue'],
    answer:
        'Ne redressez pas fortement une monture tordue vous-même. Un atelier peut vérifier les risques et effectuer un ajustage si cela est possible.',
  ),
  GavKnowledgeEntry(
    keywords: ['service apres vente', 'service après-vente', 'sav lunettes'],
    answer:
        'GAV assure un service après-vente après la livraison. Conservez votre facture et contactez l’accueil en cas de problème.',
  ),
  GavKnowledgeEntry(
    keywords: ['qualite equipements', 'normes optiques'],
    answer:
        'GAV vise des prestations professionnelles et des équipements adaptés aux prescriptions. Les caractéristiques exactes doivent être confirmées sur le devis.',
  ),
  GavKnowledgeEntry(
    keywords: ['garantie lunettes', 'garantie equipement'],
    answer:
        'Les conditions de garantie dépendent de l’équipement et de la vente. Demandez les conditions applicables au moment du devis ou de la livraison.',
  ),
  GavKnowledgeEntry(
    keywords: ['entretien monture', 'entretenir lunettes'],
    answer:
        'Rangez vos lunettes dans leur étui, nettoyez-les avec un produit adapté et évitez de les poser sur les verres ou de les exposer à une forte chaleur.',
  ),
  GavKnowledgeEntry(
    keywords: ['perdre lunettes', 'lunettes perdues'],
    answer:
        'En cas de perte, contactez GAV pour étudier une nouvelle commande. Une nouvelle mesure ou une prescription à jour peut être nécessaire.',
  ),

  // Prévention et santé visuelle générale
  GavKnowledgeEntry(
    keywords: [
      'fatigue ecran',
      'fatigue visuelle',
      'fatigue des yeux',
      'yeux fatigues',
    ],
    answer:
        'Pour limiter la fatigue visuelle, appliquez la règle 20-20-20 : toutes les 20 minutes, regardez au loin pendant 20 secondes. Faites des pauses, clignez régulièrement et réduisez les reflets.',
  ),
  GavKnowledgeEntry(
    keywords: ['regle 20 20 20', '20 20 20'],
    answer:
        'La règle 20-20-20 consiste à regarder un objet éloigné pendant 20 secondes toutes les 20 minutes d’écran.',
  ),
  GavKnowledgeEntry(
    keywords: ['distance ecran', 'position ordinateur'],
    answer:
        'Placez l’écran à une distance confortable, légèrement sous le niveau des yeux, avec une luminosité et un contraste adaptés à la pièce.',
  ),
  GavKnowledgeEntry(
    keywords: ['lumiere ecran', 'eclairage ecran', 'reflet ecran'],
    answer:
        'Évitez les reflets directs sur l’écran et privilégiez un éclairage régulier. Ajustez la luminosité sans rendre l’écran beaucoup plus lumineux que la pièce.',
  ),
  GavKnowledgeEntry(
    keywords: ['yeux secs', 'secheresse oculaire'],
    answer:
        'Clignez régulièrement, faites des pauses et évitez un flux d’air direct vers les yeux. Si la sécheresse persiste ou devient douloureuse, demandez un avis professionnel.',
  ),
  GavKnowledgeEntry(
    keywords: ['cligner yeux', 'clignement yeux'],
    answer:
        'Le clignement aide à répartir le film lacrymal. Il peut diminuer lors d’un écran prolongé, d’où l’intérêt des pauses et du clignement volontaire.',
  ),
  GavKnowledgeEntry(
    keywords: ['soleil yeux', 'protection uv', 'uv yeux'],
    answer:
        'Protégez vos yeux avec des lunettes portant une protection UV fiable. La couleur sombre d’un verre ne garantit pas à elle seule la protection.',
  ),
  GavKnowledgeEntry(
    keywords: ['lunettes soleil enfant', 'enfant soleil'],
    answer:
        'Les enfants doivent aussi protéger leurs yeux d’une forte exposition solaire avec une protection UV adaptée et un chapeau.',
  ),
  GavKnowledgeEntry(
    keywords: ['fumer yeux', 'tabac vision'],
    answer:
        'Le tabac peut contribuer à plusieurs problèmes de santé, y compris oculaires. Réduire ou arrêter le tabac est bénéfique pour la santé générale.',
  ),
  GavKnowledgeEntry(
    keywords: ['alimentation yeux', 'nutrition yeux'],
    answer:
        'Une alimentation variée participe à la santé générale. Elle ne remplace pas un contrôle visuel ni une prise en charge lorsqu’un symptôme apparaît.',
  ),
  GavKnowledgeEntry(
    keywords: ['sommeil yeux', 'repos yeux'],
    answer:
        'Un sommeil suffisant et des pauses régulières peuvent aider à réduire la sensation de fatigue visuelle, sans remplacer un avis si les symptômes persistent.',
  ),
  GavKnowledgeEntry(
    keywords: ['eau yeux', 'laver yeux'],
    answer:
        'Évitez de frotter les yeux. En cas de projection irritante, rincez abondamment avec de l’eau propre et demandez rapidement un avis médical si la gêne persiste.',
  ),
  GavKnowledgeEntry(
    keywords: ['frotter yeux', 'se frotter yeux'],
    answer:
        'Évitez de vous frotter les yeux, surtout avec des mains sales. Cela peut irriter la surface de l’œil et favoriser une infection.',
  ),
  GavKnowledgeEntry(
    keywords: ['maquillage yeux', 'cosmetique yeux'],
    answer:
        'Ne partagez pas votre maquillage, retirez-le avant de dormir et cessez de l’utiliser en cas d’irritation. Respectez les durées de conservation.',
  ),
  GavKnowledgeEntry(
    keywords: ['infection oeil', 'oeil rouge', 'œil rouge'],
    answer:
        'Un œil rouge peut avoir plusieurs causes. S’il est douloureux, accompagné d’une baisse de vision, d’une forte sensibilité à la lumière ou d’un écoulement important, consultez rapidement.',
  ),
  GavKnowledgeEntry(
    keywords: ['douleur oeil', 'douleur œil', 'mal yeux'],
    answer:
        'Une douleur oculaire importante ou persistante doit être évaluée par un professionnel. Une douleur intense avec baisse de vision est une situation urgente.',
  ),
  GavKnowledgeEntry(
    keywords: ['vision floue', 'vue trouble'],
    answer:
        'Une vision floue peut avoir différentes causes. Si elle apparaît soudainement, s’aggrave ou concerne un seul œil, demandez rapidement un avis professionnel.',
  ),
  GavKnowledgeEntry(
    keywords: [
      'perte vision',
      'perte vue',
      'perte brutale vision',
      'perte brutale',
    ],
    answer:
        'Une perte brutale de vision est une urgence potentielle. Contactez immédiatement les urgences ou un professionnel de santé.',
  ),
  GavKnowledgeEntry(
    keywords: ['flash lumineux', 'eclairs yeux', 'éclairs yeux'],
    answer:
        'Des flashs lumineux nouveaux ou des corps flottants apparus brutalement nécessitent un avis ophtalmologique rapide, surtout s’ils s’accompagnent d’une ombre ou d’un voile.',
  ),
  GavKnowledgeEntry(
    keywords: ['corps flottants', 'mouches yeux', 'mouches volantes'],
    answer:
        'Des corps flottants peuvent être bénins, mais leur apparition brutale, surtout avec des flashs ou un voile, doit être évaluée rapidement.',
  ),
  GavKnowledgeEntry(
    keywords: ['traumatisme oeil', 'choc oeil', 'choc œil'],
    answer:
        'Après un choc à l’œil, ne frottez pas et ne forcez pas l’ouverture. Demandez rapidement un avis médical, surtout en cas de douleur ou de baisse de vision.',
  ),
  GavKnowledgeEntry(
    keywords: ['produit chimique oeil', 'produit oeil'],
    answer:
        'En cas de produit chimique dans l’œil, rincez immédiatement et abondamment à l’eau propre pendant plusieurs minutes et contactez sans attendre les urgences.',
  ),
  GavKnowledgeEntry(
    keywords: ['pression yeux', 'tension yeux'],
    answer:
        'La pression oculaire ne peut pas être évaluée de façon fiable par une conversation. Un contrôle professionnel est nécessaire lorsqu’il est indiqué.',
  ),
  GavKnowledgeEntry(
    keywords: ['diabete yeux', 'diabète yeux'],
    answer:
        'Le diabète peut affecter les yeux. Un suivi médical et des contrôles visuels réguliers sont importants, même en l’absence de symptômes.',
  ),
  GavKnowledgeEntry(
    keywords: ['hypertension yeux', 'tension arterielle yeux'],
    answer:
        'L’hypertension peut avoir des conséquences générales et oculaires. Suivez votre prise en charge médicale et signalez tout changement visuel.',
  ),
  GavKnowledgeEntry(
    keywords: [
      'controle regulier yeux',
      'contrôle régulier yeux',
      'frequence examen',
    ],
    answer:
        'La fréquence d’un contrôle dépend de l’âge, des antécédents, de la correction et des symptômes. Un professionnel peut proposer un calendrier adapté.',
  ),
  GavKnowledgeEntry(
    keywords: ['urgence ophtalmologique', 'urgence yeux'],
    answer:
        'Perte brutale de vision, douleur intense, traumatisme, flashs nouveaux ou voile visuel nécessitent un avis médical urgent. Le chatbot ne remplace pas les urgences.',
  ),

  // Enfants et adolescents
  GavKnowledgeEntry(
    keywords: ['enfant vision', 'vue enfant'],
    answer:
        'Chez l’enfant, surveillez le plissement des yeux, les maux de tête, la difficulté à lire, une mauvaise coordination ou une gêne à l’école, et demandez un dépistage.',
  ),
  GavKnowledgeEntry(
    keywords: ['bebe yeux', 'bébé yeux'],
    answer:
        'Chez le bébé, tout comportement visuel inhabituel, reflet blanc, œil qui dévie ou absence de réaction à la lumière mérite un avis médical.',
  ),
  GavKnowledgeEntry(
    keywords: ['myopie enfant', 'myopie enfants'],
    answer:
        'La myopie de l’enfant doit être suivie par un professionnel. Les activités extérieures et les pauses visuelles sont de bonnes habitudes, sans remplacer le suivi.',
  ),
  GavKnowledgeEntry(
    keywords: ['ecole vision', 'école vision', 'lecture enfant'],
    answer:
        'Une difficulté à voir le tableau, lire ou se concentrer peut être liée à la vision. Un contrôle visuel permet d’évaluer la situation.',
  ),
  GavKnowledgeEntry(
    keywords: ['ecran enfant', 'écran enfant'],
    answer:
        'Pour les enfants, alternez les activités sur écran avec des pauses et des activités à distance et en plein air. Adaptez les règles à l’âge et aux recommandations professionnelles.',
  ),

  // Lentilles et hygiène
  GavKnowledgeEntry(
    keywords: ['hygiene lentilles', 'hygiène lentilles'],
    answer:
        'Lavez et séchez vos mains avant de manipuler vos lentilles. Ne les rincez jamais avec l’eau du robinet et utilisez uniquement la solution recommandée.',
  ),
  GavKnowledgeEntry(
    keywords: ['dormir lentilles', 'dormir avec lentilles'],
    answer:
        'Ne dormez pas avec vos lentilles sauf indication explicite d’un professionnel. Respectez le mode de port prescrit.',
  ),
  GavKnowledgeEntry(
    keywords: ['douche lentilles', 'baignade lentilles', 'piscine lentilles'],
    answer:
        'Évitez le contact des lentilles avec l’eau, la douche et la piscine. Demandez conseil pour une protection adaptée lors des activités aquatiques.',
  ),
  GavKnowledgeEntry(
    keywords: ['solution lentilles', 'liquide lentilles'],
    answer:
        'Utilisez la solution recommandée et respectez sa date de péremption. Ne complétez pas une ancienne solution dans l’étui.',
  ),
  GavKnowledgeEntry(
    keywords: ['etui lentilles', 'étui lentilles'],
    answer:
        'Nettoyez et remplacez régulièrement l’étui selon les recommandations. Laissez-le sécher et ne le partagez jamais.',
  ),
  GavKnowledgeEntry(
    keywords: ['lentilles douleur', 'lentilles rougeur'],
    answer:
        'Retirez les lentilles en cas de douleur, rougeur, gêne importante ou baisse de vision et consultez rapidement un professionnel.',
  ),
  GavKnowledgeEntry(
    keywords: ['lentilles duree', 'durée lentilles', 'remplacement lentilles'],
    answer:
        'Respectez la durée de remplacement prévue pour vos lentilles, même si elles semblent encore confortables.',
  ),
  GavKnowledgeEntry(
    keywords: [
      'premieres lentilles',
      'première lentilles',
      'adaptation lentilles',
    ],
    answer:
        'Une première adaptation de lentilles nécessite des mesures, des conseils d’hygiène et un suivi par un professionnel qualifié.',
  ),

  // Assurances, confidentialité et orientation
  GavKnowledgeEntry(
    keywords: ['assurance gav', 'assurances partenaires'],
    answer:
        'GAV a développé des partenariats avec CHANAS Assurances, AXA Cameroun, ASCOMA Cameroun, WTW, AREA Assurances, PASS 24 Plus, GGA Cameroun et SUSU.',
  ),
  GavKnowledgeEntry(
    keywords: ['prise en charge assurance', 'remboursement assurance'],
    answer:
        'La prise en charge dépend de votre contrat et de l’organisme concerné. Demandez confirmation à l’accueil avec vos justificatifs.',
  ),
  GavKnowledgeEntry(
    keywords: ['pass 24 plus', 'tiers payant gav'],
    answer:
        'PASS 24 Plus fait partie des partenaires cités par GAV dans le domaine du tiers payant santé. Confirmez les conditions applicables à votre contrat.',
  ),
  GavKnowledgeEntry(
    keywords: ['donnees medicales', 'données médicales', 'confidentialite'],
    answer:
        'Ne partagez dans le chat que les informations nécessaires. Pour une ordonnance ou des données sensibles, utilisez les canaux officiels et sécurisés de GAV.',
  ),
  GavKnowledgeEntry(
    keywords: ['parler agent', 'agent humain', 'conseiller gav'],
    answer:
        'Pour une demande personnalisée, un tarif, une assurance, un dossier ou un symptôme, demandez à être orienté vers un agent GAV ou un professionnel de santé.',
  ),
  GavKnowledgeEntry(
    keywords: ['conduite nuit', 'conduire nuit', 'vision nuit'],
    answer:
        'Une gêne importante lors de la conduite de nuit peut nécessiter un contrôle visuel et une vérification de vos verres. Évitez de conduire si votre vision ne vous permet pas de le faire en sécurité.',
  ),
  GavKnowledgeEntry(
    keywords: [
      'nouvelles lunettes',
      'nouvelle correction',
      'adaptation lunettes',
    ],
    answer:
        'Une courte période d’adaptation peut être nécessaire avec de nouvelles lunettes. En cas de gêne persistante, maux de tête importants ou vision déformée, revenez vers GAV pour une vérification.',
  ),
  GavKnowledgeEntry(
    keywords: ['lunettes travail', 'securite travail', 'sécurité travail'],
    answer:
        'Pour choisir une protection visuelle au travail, identifiez les risques liés à votre activité et demandez un équipement adapté aux exigences professionnelles.',
  ),
  GavKnowledgeEntry(
    keywords: ['apres livraison', 'après livraison', 'verification lunettes'],
    answer:
        'Après la livraison, vérifiez le confort, le maintien et la vision. En cas de problème, contactez GAV rapidement afin que le réglage ou le suivi nécessaire puisse être réalisé.',
  ),
  GavKnowledgeEntry(
    keywords: ['confort visuel', 'confort yeux', 'bien voir'],
    answer:
        'Pour préserver votre confort visuel, alternez les activités de près et de loin, faites des pauses lors des écrans et faites contrôler votre vision en cas de gêne persistante.',
  ),
];
