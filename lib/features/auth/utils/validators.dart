class AuthValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est obligatoire.';
    }

    const emailPattern =
        r"^[a-zA-Z0-9_+\-]+(?:\.[a-zA-Z0-9_+\-]+)*@[a-zA-Z0-9\-]+(?:\.[a-zA-Z0-9\-]+)*\.[a-zA-Z]{2,}";
    final regex = RegExp(emailPattern);
    if (!regex.hasMatch(value.trim())) {
      return 'Veuillez saisir une adresse email valide.';
    }
    return null;
  }

  static String? validateEmailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est obligatoire.';
    }
    if (validateEmail(value) == null || isPhoneNumber(value)) {
      return null;
    }
    return 'Veuillez saisir un email ou un numéro de téléphone valide.';
  }

  static bool isPhoneNumber(String value) {
    final sanitized = value.replaceAll(RegExp(r'[\s\-().+]'), '');
    final cameroonPattern = RegExp(r'^(?:237|\+237)?[23689]\d{7}$');
    final genericPattern = RegExp(r'^[0-9]{8,15}$');
    return cameroonPattern.hasMatch(sanitized) ||
        genericPattern.hasMatch(sanitized);
  }

  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est obligatoire.';
    }
    final password = value.trim();
    if (password.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Le mot de passe doit contenir une majuscule.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Le mot de passe doit contenir une minuscule.';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Le mot de passe doit contenir un chiffre.';
    }
    if (!RegExp(r'[!@#\$%\^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Le mot de passe doit contenir un caractère spécial.';
    }
    return null;
  }

  static String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est obligatoire.';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est obligatoire.';
    }
    if (!isPhoneNumber(value)) {
      return 'Veuillez saisir un numéro de téléphone valide.';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est obligatoire.';
    }
    if (value.trim() != password.trim()) {
      return 'Les mots de passe ne correspondent pas.';
    }
    return null;
  }
}
