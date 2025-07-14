class Validators {
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Telefone é obrigatório';
    }


    final cleanedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');


    if (cleanedPhone.length < 10 || cleanedPhone.length > 11) {
      return 'Telefone inválido';
    }


    return null;
  }
}



