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
      'galleryTitle': 'Gallery',
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
      'eventOnDate': 'No upcoming events',
      'aboutMaharajContent': 'Comprehensive information and history about Gajanan Maharaj will be displayed here. The content is presented in large, legible Marathi text, designed for easy reading by elderly users.',
      'upcomingEvent': 'Upcoming Event',
      'prakatDinUtsav': 'Prakat Din Utsav',
      'aboutMaharajScreenTitle': 'Shri Sant Gajanan Maharaj',
      'aboutMaharajLocation': 'Shegaon, Maharashtra',
      'aboutMaharajPragatDin': 'Pragat Din: February 23, 1878 (Magh Vadya Saptami)',
      'aboutMaharajChant': '|| Gan Gan Ganat Bote ||',
      'cardTitleJeevanParichay': 'Introduction to Life',
      'cardContentJeevanParichay': 'Sant Shree Gajanan Maharaj is one of Maharashtra’s most revered saints, known for his simplicity, divine presence, and miraculous acts. Through His incarnation, He illuminated the paths of numerous lives in His short but divine life of 32 years.\n\nThough His origins, birth, and lineage remain unknown, His impact is eternal. For 32 years, He graced the holy land of Shegaon, transforming it into a spiritual sanctuary. He was a "Yogiraj" in the truest sense, guiding countless souls through His miraculous Leelas (divine plays) and His mere presence, which radiated peace and absolute divinity.',
      'cardTitlePragatItihas': 'History of Appearance',
      'cardContentPragatItihas': 'Maharaj first appeared in Shegaon (in the Buldhana district of Maharashtra) on February 23, 1878 (Magh Vadya Saptami).\n\nMaharaj was seen as a young man with a radiant aura, sitting in the street and picking rice grains from discarded patravali (leaf plates) to eat. This act conveyed his first profound teaching: Annam Brahmeti ("Food is Brahma/God") — food should never be wasted and that for a realized soul, all matter is one. From the moment of his appearance, devotees recognized him as a spiritually awakened soul - “Yogiraj” and “Ansuya putra” (a child of divine detachment).',
      'cardTitleShikvan': 'Teachings and Philosophy',
      'cardContentShikvan': 'Maharaj is often associated with the Avadhut Sampradaya, characterized by saints who transcend material norms, express innocence and divine madness, and live in constant union with the Supreme.\n\nHis core philosophy is encapsulated in his constant chant: "Gan Gan Ganat Bote." This mantra signifies that the individual soul (Jiva) is woven into the Universal Soul (Brahma), and God is present in every atom of existence.\n\nKey Pillars of His Teachings:\n* Annam Brahma: Respect for food as a divine entity.\n* Equality: He treated rich and poor, humans and animals, with equal love, rejecting caste and creed.\n* Karma Yoga: He emphasized doing one\'s duty without attachment to the fruit of actions.\n* Values: He guided devotees to follow the path of Bhakti (Devotion), Seva (Selfless Service), Sadachaar (Moral Conduct), and Tyag (Detachment).',
      'cardTitleSamadhi': 'Samadhi Details',
      'cardContentSamadhi': 'He spent 32 years in Shegaon, performing countless miracles (Leelas) to guide devotees toward the path of righteousness before taking Sanjeevan Samadhi — a state where a saint voluntarily exits the body while remaining conscious in the super-conscious state - on September 8, 1910 (Rishi Panchami).\n\nHis physical body rests in the Samadhi Mandir in Shegaon, but His spiritual presence is timeless. Before taking Samadhi, He assured His devotees: "I am here, though I leave my body. Do not let your devotion waver, I will always be with you to protect you."\n\nToday, Shegaon is known as the "Pandharpur of Vidarbha," where millions flock to experience the living presence of the Master.',
      'footerQuote': 'An ocean of mercy who rushes to the call of devotees',
      'socialMediaTitle': 'Social Media',
      'officialSocialMediaHandles': 'The official social media handles',
      'facebook': 'Facebook',
      'youtube': 'YouTube',
      'instagram': 'Instagram',
      'googlePhotos': 'Google Photos',
      'whatsapp': 'WhatsApp',
      'officialPage': 'Official Page',
      'videosAndStreams': 'Videos and Live Streams',
      'photosAndReels': 'Photos and Reels',
      'photoGallery': 'Festival Photo Gallery',
      'whatsappAdminContact': 'WhatsApp Group Admin Contact',
      'officialLinks': 'Official Links',
      'socialMedia': 'Social Media',
      'nityopasanaTitle': 'Nityopasana',
      'share': 'Share',
      'narrator': 'Narrator',
      'internetRequired': 'Video playback requires internet',
      'shareMessage': 'Check out this Adhyay from Gajanan Vijay Granth',
      'signupsTitle': 'Signups',
      'signupsDescription': 'Please use the links below to signup for various sevas.',
      'sundayPrasadSevaSignup': 'Sunday Prasad Seva',
      'sundayPrasadSevaSignupDescription': 'Sign up for the Sunday Prasad Cooking Seva',
      'vastralankarSevaSignup': 'Vastra-Alankar Seva',
      'vastralankarSevaSignupDescription': 'Sign up for the Vastra-Alankar Seva',
      'list': 'List',
      'searchEvent': 'Search Event...',
      'allEventsList': 'All Events List',
    },
    'mr': {
      'granthTitle': 'गजानन विजय ग्रंथ',
      'stotraTitle': 'स्तोत्र संग्रह',
      'namavaliTitle': 'अष्टोत्तरशतनामावली',
      'aartiTitle': 'आरती संग्रह',
      'bhajanTitle': 'भजन संग्रह',
      'sankalpTitle': 'साप्ताहिक अभिषेक आणि पूजा संकल्प',
      'parayanTitle': 'पारायण आयोजन',
      'aboutMaharajTitle': 'महाराजांविषयी',
      'calendarTitle': 'कार्यक्रम दिनदर्शिका',
      'donationsTitle': 'देणगी',
      'galleryTitle': 'गॅलरी',
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
      'eventOnDate': 'कोणतेही आगामी कार्यक्रम नाहीत',
      'aboutMaharajContent': 'श्री गजानन महाराजांबद्दलची सविस्तर माहिती आणि इतिहास येथे प्रदर्शित केला जाईल. सामग्री मोठ्या, सुवाच्य मराठी मजकुरात सादर केली आहे, जी वृद्ध वापरकर्त्यांना सहज वाचता येईल.',
      'upcomingEvent': 'आगामी कार्यक्रम',
      'prakatDinUtsav': 'प्रकट दिन उत्सव',
      'aboutMaharajScreenTitle': 'श्री संत गजानन महाराज',
      'aboutMaharajLocation': 'शेगाव, महाराष्ट्र',
      'aboutMaharajPragatDin': 'प्रगट दिन: २३ फेब्रुवारी १८७८ (माघ वद्य सप्तमी)',
      'aboutMaharajChant': '|| गण गण गणात बोते ||',
      'cardTitleJeevanParichay': 'जीवन परिचय',
      'cardContentJeevanParichay': 'संत श्री गजानन महाराज हे महाराष्ट्रातील एक प्रतिष्ठित संत आहेत, जे त्यांच्या साधेपणासाठी, दिव्य अस्तित्वासाठी आणि चमत्कारी कार्यांसाठी ओळखले जातात. त्यांच्या ३२ वर्षांच्या लहान पण दिव्य आयुष्यात त्यांनी अनेक लोकांच्या जीवनाचा मार्ग प्रकाशित केला.\n\nत्यांचे मूळ, जन्म आणि वंश अज्ञात असले तरी त्यांचा प्रभाव शाश्वत आहे. ३२ वर्षे त्यांनी शेगावच्या पवित्र भूमीला पावन केले आणि तिचे एका आध्यात्मिक तीर्थक्षेत्रात रूपांतर केले. ते खऱ्या अर्थाने "योगीराज" होते, ज्यांनी त्यांच्या चमत्कारी लीलांद्वारे आणि केवळ त्यांच्या उपस्थितीने असंख्य जीवांना मार्गदर्शन केले, ज्यातून शांतता आणि पूर्ण देवत्व पसरत असे.',
      'cardTitlePragatItihas': 'प्रगट इतिहास',
      'cardContentPragatItihas': 'महाराज प्रथम २३ फेब्रुवारी १८७८ (माघ वद्य सप्तमी) रोजी (महाराष्ट्रातील बुलढाणा जिल्ह्यातील) शेगाव येथे प्रकट झाले.\n\nमहाराज एका तेजस्वी तरुणाच्या रूपात रस्त्यावर बसून टाकून दिलेल्या पत्रावळीवरील अन्नाचे कण वेचून खात होते. त्यांच्या या कृतीतून त्यांची पहिली महान शिकवण मिळाली: \'अन्नं ब्रह्मेति\' (अन्न हे पूर्णब्रह्म आहे) — अन्नाची नासाडी कधीही करू नये आणि एका आत्मज्ञानी जीवासाठी सर्व पदार्थ एकसमान असतात. त्यांच्या प्रकटीकरणाच्या क्षणापासूनच भक्त त्यांना "योगीराज" म्हणून ओळखू लागले.',
      'cardTitleShikvan': 'शिकवण आणि तत्त्वज्ञान',
      'cardContentShikvan': 'त्यांची वागणूक बालकासारखी निरागस आणि काहीशी \'उन्मन\' (with divine madness) असे, आणि ते सदैव परब्रह्माशी एकरूप होऊन जगत.\n\nत्यांच्या तत्त्वज्ञानाचे सार त्यांच्या मुखी सतत असणाऱ्या "गण गण गणात बोते" या मंत्रात सामावलेले आहे. या मंत्राचा अर्थ असा आहे की, प्रत्येक जीवाचा आत्मा हा त्या विश्वव्यापी ब्रह्माचाच एक अंश आहे आणि ईश्वराचा वास चराचरातील कणाकणात आहे.\n\nत्यांच्या शिकवणीचे मुख्य स्तंभ:\n* अन्न हे पूर्णब्रह्म: अन्नाला देवाचे रूप मानून त्याचा आदर करणे.\n* समभाव: त्यांनी श्रीमंत-गरीब, उच्च-नीच किंवा मानव-प्राणी असा कोणताही भेद न करता सर्वांवर समान प्रेम केले.\n* कर्मयोग: फळाची अपेक्षा न ठेवता आपले कर्तव्य करत राहणे, यावर त्यांनी भर दिला.\n* जीवनमूल्ये: भक्ती, सेवा, सदाचार आणि त्याग या मार्गांवर चालण्याचे मार्गदर्शन त्यांनी भक्तांना केले.',
      'cardTitleSamadhi': 'समाधी विवरण',
      'cardContentSamadhi': 'महाराजांनी शेगावमध्ये ३२ वर्षे वास्तव्य केले. या काळात त्यांनी भक्तांना सन्मार्गावर आणण्यासाठी असंख्य चमत्कार (लीला) केले. त्यानंतर, ८ सप्टेंबर १९१० (ऋषी पंचमी) रोजी त्यांनी \'संजीवन समाधी\' घेतली. संजीवन समाधी ही अशी अवस्था आहे, जिथे संत स्वतःहून आपला देह त्यागतात, पण त्यांचे चैतन्य त्या समाधीत जागृत असते.\n\nत्यांचा पार्थिव देh जरी शेगावच्या समाधी मंदिरात विसावला असला, तरी त्यांचे आध्यात्मिक अस्तित्व हे काळाच्या पलीकडचे आणि शाश्वत आहे. समाधी घेण्यापूर्वी त्यांनी आपल्या भक्तांना आश्वस्त केले होते: "मी गेलो असे मानू नका, भक्तीत अंतर करू नका. तुमच्या रक्षणासाठी मी सदैव तुमच्या पाठीशी असेन."\n\nआज शेगाव हे "विदर्भाचे पंढरपूर" म्हणून ओळखले जाते, जिथे लाखो भाविक या महापुरुषाच्या अस्तित्वाची अनुभूती घेण्यासाठी येतात.',
      'footerQuote': 'भक्तांच्या हाकेला धावून जाणारे दयासागर',
      'socialMediaTitle': 'सोशल मीडिया',
      'officialSocialMediaHandles': 'अधिकृत सोशल मीडिया हँडल्स',
      'facebook': 'फेसबुक',
      'youtube': 'यूट्यूब',
      'instagram': 'इंस्टाग्राम',
      'googlePhotos': 'गूगल फोटोज़',
      'whatsapp': 'व्हॉट्सॲप',
      'officialPage': 'अधिकृत पेज',
      'videosAndStreams': 'व्हिडिओज आणि लाईव्ह स्ट्रीम्स',
      'photosAndReels': 'फोटोज आणि रील्स',
      'photoGallery': 'फोटो गॅलरी',
      'whatsappAdminContact': 'व्हॉटसअँप ग्रुप ऍडमिन कॉन्टॅक्ट',
      'officialLinks': 'अधिकृत लिंक्स',
      'socialMedia': 'सोशल मीडिया',
      'nityopasanaTitle': 'नित्योपासना',
      'share': 'शेअर करा',
      'narrator': 'निवेदक',
      'internetRequired': 'व्हिडिओ प्लेबॅकसाठी इंटरनेट आवश्यक आहे',
      'shareMessage': 'गजानन विजय ग्रंथाचा हा अध्याय नक्की ऐका',
      'signupsTitle': 'साईन-अप',
      'signupsDescription': 'विविध सेवांसाठी साइन अप करण्यासाठी कृपया खालील लिंक वापरा.',
      'sundayPrasadSevaSignup': 'रविवार प्रसाद सेवा',
      'sundayPrasadSevaSignupDescription': 'रविवार प्रसाद सेवेसाठी साइन अप करा',
      'vastralankarSevaSignup': 'वस्त्रालंकार सेवा',
      'vastralankarSevaSignupDescription': 'वस्त्रालंकार सेवेसाठी साइन अप करा',
      'list': 'यादी',
      'searchEvent': 'उत्सव शोधा...',
      'allEventsList': 'सर्व उत्सव यादी',
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
  String get galleryTitle => _localizedValues[locale.languageCode]!['galleryTitle']!;
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

  String get aboutMaharajScreenTitle => _localizedValues[locale.languageCode]!['aboutMaharajScreenTitle']!;
  String get aboutMaharajLocation => _localizedValues[locale.languageCode]!['aboutMaharajLocation']!;
  String get aboutMaharajPragatDin => _localizedValues[locale.languageCode]!['aboutMaharajPragatDin']!;
  String get aboutMaharajChant => _localizedValues[locale.languageCode]!['aboutMaharajChant']!;
  String get cardTitleJeevanParichay => _localizedValues[locale.languageCode]!['cardTitleJeevanParichay']!;
  String get cardContentJeevanParichay => _localizedValues[locale.languageCode]!['cardContentJeevanParichay']!;
  String get cardTitlePragatItihas => _localizedValues[locale.languageCode]!['cardTitlePragatItihas']!;
  String get cardContentPragatItihas => _localizedValues[locale.languageCode]!['cardContentPragatItihas']!;
  String get cardTitleShikvan => _localizedValues[locale.languageCode]!['cardTitleShikvan']!;
  String get cardContentShikvan => _localizedValues[locale.languageCode]!['cardContentShikvan']!;
  String get cardTitleSamadhi => _localizedValues[locale.languageCode]!['cardTitleSamadhi']!;
  String get cardContentSamadhi => _localizedValues[locale.languageCode]!['cardContentSamadhi']!;
  String get footerQuote => _localizedValues[locale.languageCode]!['footerQuote']!;

  String get socialMediaTitle => _localizedValues[locale.languageCode]!['socialMediaTitle']!;
  String get officialSocialMediaHandles => _localizedValues[locale.languageCode]!['officialSocialMediaHandles']!;
  String get facebook => _localizedValues[locale.languageCode]!['facebook']!;
  String get youtube => _localizedValues[locale.languageCode]!['youtube']!;
  String get instagram => _localizedValues[locale.languageCode]!['instagram']!;
  String get googlePhotos => _localizedValues[locale.languageCode]!['googlePhotos']!;
  String get whatsapp => _localizedValues[locale.languageCode]!['whatsapp']!;
  String get officialPage => _localizedValues[locale.languageCode]!['officialPage']!;
  String get videosAndStreams => _localizedValues[locale.languageCode]!['videosAndStreams']!;
  String get photosAndReels => _localizedValues[locale.languageCode]!['photosAndReels']!;
  String get photoGallery => _localizedValues[locale.languageCode]!['photoGallery']!;
  String get whatsappAdminContact => _localizedValues[locale.languageCode]!['whatsappAdminContact']!;
  String get officialLinks => _localizedValues[locale.languageCode]!['officialLinks']!;
  String get socialMedia => _localizedValues[locale.languageCode]!['socialMedia']!;
  String get nityopasanaTitle => _localizedValues[locale.languageCode]!['nityopasanaTitle']!;
  String get share => _localizedValues[locale.languageCode]!['share']!;
  String get narrator => _localizedValues[locale.languageCode]!['narrator']!;
  String get internetRequired => _localizedValues[locale.languageCode]!['internetRequired']!;
  String get shareMessage => _localizedValues[locale.languageCode]!['shareMessage']!;
  String get signupsTitle => _localizedValues[locale.languageCode]!['signupsTitle']!;
  String get signupsDescription => _localizedValues[locale.languageCode]!['signupsDescription']!;
  String get sundayPrasadSevaSignup => _localizedValues[locale.languageCode]!['sundayPrasadSevaSignup']!;
  String get sundayPrasadSevaSignupDescription => _localizedValues[locale.languageCode]!['sundayPrasadSevaSignupDescription']!;
  String get vastralankarSevaSignup => _localizedValues[locale.languageCode]!['vastralankarSevaSignup']!;
  String get vastralankarSevaSignupDescription => _localizedValues[locale.languageCode]!['vastralankarSevaSignupDescription']!;
  String get list => _localizedValues[locale.languageCode]!['list']!;
  String get searchEvent => _localizedValues[locale.languageCode]!['searchEvent']!;
  String get allEventsList => _localizedValues[locale.languageCode]!['allEventsList']!;
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
