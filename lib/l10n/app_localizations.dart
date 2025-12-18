import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'granthTitle': 'Gajanan Vijay Granth',
      'stotraTitle': 'Stotra Collection',
      'namavaliTitle': '108 Namavali',
      'aartiTitle': 'Aarti Collection',
      'bhajanTitle': 'Bhajan Collection',
      'sankalpTitle': 'Weekly Abhishek and Pooja Sankalp',
      'parayanTitle': 'Parayan Organization',
      'aboutMaharajTitle': 'About Maharaj',
      'calendarTitle': 'Event Calendar',
      'donationsTitle': 'Donations',
      'appName': 'Gajanan Maharaj Sevekari',
      'settings': 'Settings',
      'language': 'Language',
      'theme': 'Theme',
      'about': 'About',
      'disclaimer': 'Disclaimer',
      'lightTheme': 'Light Theme',
      'darkTheme': 'Dark Theme',
      'systemTheme': 'System Theme',
      'english': 'English',
      'marathi': 'Marathi',
      'adhyay': 'Adhyay',
      'read': 'Read',
      'listen': 'Listen',
      'stotraAvahan': 'Gajanan Maharaj Avahan',
      'stotraBavanni': 'Gajanan Maharaj Bavanni',
      'dailyAartis': 'Daily Aartis',
      'eventAartis': 'Event Aartis',
      'kakadAarti': 'Kakad Aarti',
      'madhyanAarti': 'Madhyan Aarti',
      'dhoopAarti': 'Dhoop Aarti',
      'shejAarti': 'Shej Aarti',
      'prakatDinAarti': 'Prakat Din Aarti',
      'ashadhiEkadashiAarti': 'Ashadhi Ekadashi Aarti',
      'dattaJayantiAarti': 'Datta Jayanti Aarti',
      'ramNavamiAarti': 'Ram Navami Aarti',
      'akshayTritiyaAarti': 'Akshay Tritiya Aarti',
      'rushiPanchamiAarti': 'Rushi Panchami Aarti',
      'name': 'Name',
      'bhajanGajananachya': 'Gajananachya Charani Julavu',
      'bhajanMurtiAhe': 'Murti Ahe Shegaonla',
      'location': 'Location',
      'date': 'Date',
      'selectDate': 'Select Date',
      'generateSankalp': 'Generate Sankalp',
      'sankalpGenerated': 'Sankalp for {location} on {date} will be generated here based on the Sampurna Chaturmas book.',
      'chooseParayanType': 'Choose Parayan Type:',
      'oneDayParayan': '1-Day Parayan',
      'threeDayParayan': '3-Day Parayan',
      'oneDayParayanProgress': '1-Day Parayan Progress',
      'threeDayParayanProgress': '3-Day Parayan Progress',
      'day': 'Day',
      'donationInstruction': 'Please scan the QR code or click the button below to donate. Jai Gajanan 🙏🏻',
      'donateViaZelle': 'Donate via Zelle to gajananmaharajseattle@gmail.com',
      'zelleQRCode': 'Zelle QR Code Placeholder',
      'qrCodeHere': 'QR Code Here',
      'couldNotOpenZelle': 'Could not open Zelle.',
      'eventOnDate': 'Event on selected date will be shown here.',
      'aboutMaharajContent': 'Comprehensive information and history about Gajanan Maharaj will be displayed here. The content is presented in large, legible Marathi text, designed for easy reading by elderly users.',
      'upcomingEvent': 'Upcoming Event',
      'prakatDinUtsav': 'Prakat Din Utsav',
    },
    'mr': {
      'granthTitle': 'गजानन विजय ग्रंथ',
      'stotraTitle': 'स्तोत्र संग्रह',
      'namavaliTitle': '१०८ नामावली',
      'aartiTitle': 'आरती संग्रह',
      'bhajanTitle': 'भजन संग्रह',
      'sankalpTitle': 'साप्ताहिक अभिषेक आणि पूजा संकल्प',
      'parayanTitle': 'पारायण आयोजन',
      'aboutMaharajTitle': 'महाराजांबद्दल',
      'calendarTitle': 'कार्यक्रम दिनदर्शिका',
      'donationsTitle': 'देणग्या',
      'appName': 'गजानन महाराज सेवेकरी',
      'settings': 'सेटिंग्ज',
      'language': 'भाषा',
      'theme': 'थीम',
      'about': 'बद्दल',
      'disclaimer': 'अस्वीकरण',
      'lightTheme': 'लाईट थीम',
      'darkTheme': 'डार्क थीम',
      'systemTheme': 'सिस्टम थीम',
      'english': 'इंग्रजी',
      'marathi': 'मराठी',
      'adhyay': 'अध्याय',
      'read': 'वाचा',
      'listen': 'ऐका',
      'stotraAvahan': 'गजानन महाराज आवाहन',
      'stotraBavanni': 'गजानन महाराज बावन्नी',
      'dailyAartis': 'दैनंदिन आरत्या',
      'eventAartis': 'विशेष आरत्या',
      'kakadAarti': 'काकड आरती',
      'madhyanAarti': 'मध्यान आरती',
      'dhoopAarti': 'धूप आरती',
      'shejAarti': 'शेज आरती',
      'prakatDinAarti': 'प्रकट दिन आरती',
      'ashadhiEkadashiAarti': 'आषाढी एकादशी आरती',
      'dattaJayantiAarti': 'दत्त जयंती आरती',
      'ramNavamiAarti': 'राम नवमी आरती',
      'akshayTritiyaAarti': 'अक्षय तृतीया आरती',
      'rushiPanchamiAarti': 'ऋषी पंचमी आरती',
      'name': 'नाव',
      'bhajanGajananachya': 'गजाननाच्या चरणी जुळवु',
      'bhajanMurtiAhe': 'मूर्ती आहे शेगावला',
      'location': 'स्थान',
      'date': 'तारीख',
      'selectDate': 'तारीख निवडा',
      'generateSankalp': 'संकल्प तयार करा',
      'sankalpGenerated': '{location} साठी {date} रोजीचा संकल्प येथे संपूर्ण चातुर्मास पुस्तकानुसार तयार केला जाईल.',
      'chooseParayanType': 'पारायण प्रकार निवडा:',
      'oneDayParayan': '१-दिवसीय पारायण',
      'threeDayParayan': '३-दिवसीय पारायण',
      'oneDayParayanProgress': '१-दिवसीय पारायण प्रगती',
      'threeDayParayanProgress': '३-दिवसीय पारायण प्रगती',
      'day': 'दिवस',
      'donationInstruction': 'कृपया देणगीसाठी QR कोड स्कॅन करा किंवा खालील बटणावर क्लिक करा. जय गजानन 🙏🏻',
      'donateViaZelle': 'gajananmaharajseattle@gmail.com वर Zelle द्वारे देणगी द्या',
      'zelleQRCode': 'Zelle QR कोड',
      'qrCodeHere': 'येथे QR कोड',
      'couldNotOpenZelle': 'Zelle उघडू शकलो नाही.',
      'eventOnDate': ' निवडलेल्या तारखेचे कार्यक्रम येथे दर्शविले जातील.',
      'aboutMaharajContent': 'श्री गजानन महाराजांबद्दलची सविस्तर माहिती आणि इतिहास येथे प्रदर्शित केला जाईल. सामग्री मोठ्या, सुवाच्य मराठी मजकुरात सादर केली आहे, जी वृद्ध वापरकर्त्यांना सहज वाचता येईल.',
      'upcomingEvent': 'आगामी कार्यक्रम',
      'prakatDinUtsav': 'प्रकट दिन उत्सव',
    }
  };

  String get granthTitle => _localizedValues[locale.languageCode]!['granthTitle']!;
  String get stotraTitle => _localizedValues[locale.languageCode]!['stotraTitle']!;
  String get namavaliTitle => _localizedValues[locale.languageCode]!['namavaliTitle']!;
  String get aartiTitle => _localizedValues[locale.languageCode]!['aartiTitle']!;
  String get bhajanTitle => _localizedValues[locale.languageCode]!['bhajanTitle']!;
  String get sankalpTitle => _localizedValues[locale.languageCode]!['sankalpTitle']!;
  String get parayanTitle => _localizedValues[locale.languageCode]!['parayanTitle']!;
  String get aboutMaharajTitle => _localizedValues[locale.languageCode]!['aboutMaharajTitle']!;
  String get calendarTitle => _localizedValues[locale.languageCode]!['calendarTitle']!;
  String get donationsTitle => _localizedValues[locale.languageCode]!['donationsTitle']!;
  String get appName => _localizedValues[locale.languageCode]!['appName']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get theme => _localizedValues[locale.languageCode]!['theme']!;
  String get about => _localizedValues[locale.languageCode]!['about']!;
  String get disclaimer => _localizedValues[locale.languageCode]!['disclaimer']!;
  String get lightTheme => _localizedValues[locale.languageCode]!['lightTheme']!;
  String get darkTheme => _localizedValues[locale.languageCode]!['darkTheme']!;
  String get systemTheme => _localizedValues[locale.languageCode]!['systemTheme']!;
  String get english => _localizedValues[locale.languageCode]!['english']!;
  String get marathi => _localizedValues[locale.languageCode]!['marathi']!;
  String get adhyay => _localizedValues[locale.languageCode]!['adhyay']!;
  String get read => _localizedValues[locale.languageCode]!['read']!;
  String get listen => _localizedValues[locale.languageCode]!['listen']!;
  String get stotraAvahan => _localizedValues[locale.languageCode]!['stotraAvahan']!;
  String get stotraBavanni => _localizedValues[locale.languageCode]!['stotraBavanni']!;
  String get dailyAartis => _localizedValues[locale.languageCode]!['dailyAartis']!;
  String get eventAartis => _localizedValues[locale.languageCode]!['eventAartis']!;
  String get kakadAarti => _localizedValues[locale.languageCode]!['kakadAarti']!;
  String get madhyanAarti => _localizedValues[locale.languageCode]!['madhyanAarti']!;
  String get dhoopAarti => _localizedValues[locale.languageCode]!['dhoopAarti']!;
  String get shejAarti => _localizedValues[locale.languageCode]!['shejAarti']!;
  String get prakatDinAarti => _localizedValues[locale.languageCode]!['prakatDinAarti']!;
  String get ashadhiEkadashiAarti => _localizedValues[locale.languageCode]!['ashadhiEkadashiAarti']!;
  String get dattaJayantiAarti => _localizedValues[locale.languageCode]!['dattaJayantiAarti']!;
  String get ramNavamiAarti => _localizedValues[locale.languageCode]!['ramNavamiAarti']!;
  String get akshayTritiyaAarti => _localizedValues[locale.languageCode]!['akshayTritiyaAarti']!;
  String get rushiPanchamiAarti => _localizedValues[locale.languageCode]!['rushiPanchamiAarti']!;
  String get name => _localizedValues[locale.languageCode]!['name']!;
  String get bhajanGajananachya => _localizedValues[locale.languageCode]!['bhajanGajananachya']!;
  String get bhajanMurtiAhe => _localizedValues[locale.languageCode]!['bhajanMurtiAhe']!;
  String get location => _localizedValues[locale.languageCode]!['location']!;
  String get date => _localizedValues[locale.languageCode]!['date']!;
  String get selectDate => _localizedValues[locale.languageCode]!['selectDate']!;
  String get generateSankalp => _localizedValues[locale.languageCode]!['generateSankalp']!;
  String getSankalpGenerated(String location, String date) => _localizedValues[locale.languageCode]!['sankalpGenerated']!.replaceAll('{location}', location).replaceAll('{date}', date);
  String get chooseParayanType => _localizedValues[locale.languageCode]!['chooseParayanType']!;
  String get oneDayParayan => _localizedValues[locale.languageCode]!['oneDayParayan']!;
  String get threeDayParayan => _localizedValues[locale.languageCode]!['threeDayParayan']!;
  String get oneDayParayanProgress => _localizedValues[locale.languageCode]!['oneDayParayanProgress']!;
  String get threeDayParayanProgress => _localizedValues[locale.languageCode]!['threeDayParayanProgress']!;
  String get day => _localizedValues[locale.languageCode]!['day']!;
  String get donationInstruction => _localizedValues[locale.languageCode]!['donationInstruction']!;
  String get donateViaZelle => _localizedValues[locale.languageCode]!['donateViaZelle']!;
  String get zelleQRCode => _localizedValues[locale.languageCode]!['zelleQRCode']!;
  String get qrCodeHere => _localizedValues[locale.languageCode]!['qrCodeHere']!;
  String get couldNotOpenZelle => _localizedValues[locale.languageCode]!['couldNotOpenZelle']!;
  String get eventOnDate => _localizedValues[locale.languageCode]!['eventOnDate']!;
  String get aboutMaharajContent => _localizedValues[locale.languageCode]!['aboutMaharajContent']!;
  String get upcomingEvent => _localizedValues[locale.languageCode]!['upcomingEvent']!;
  String get prakatDinUtsav => _localizedValues[locale.languageCode]!['prakatDinUtsav']!;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'mr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
