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


  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email é obrigatório';
    }


    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
    );


    if (!emailRegex.hasMatch(email)) {
      return 'Email inválido';
    }


    return null;
  }
}



